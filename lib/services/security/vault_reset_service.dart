// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نتيجة عملية إعادة تعيين الخزنة
enum VaultResetStatus {
  idle,
  authenticating,
  backingUp,
  decrypting,
  generatingNewKey,
  reEncrypting,
  replacingDatabase,
  completed,
  failed,
}

/// معلومات التقدم
class VaultResetProgress {
  final VaultResetStatus status;
  final int totalNotes;
  final int processedNotes;
  final String? errorMessage;
  final String? newRecoveryCode;

  const VaultResetProgress({
    required this.status,
    this.totalNotes = 0,
    this.processedNotes = 0,
    this.errorMessage,
    this.newRecoveryCode,
  });

  double get progress {
    if (totalNotes == 0) return 0;
    return processedNotes / totalNotes;
  }
}

/// حارس يمنع LockedNotesScreen من الخروج أثناء عملية الريست
class VaultResetGuard {
  static bool isActive = false;
}

/// خدمة إعادة تعيين تشفير الخزنة
/// تنسخ القاعدة قبل البدء وتستعيدها لو فشلت العملية
class VaultResetService {
  static final VaultResetService _instance = VaultResetService._();
  factory VaultResetService() => _instance;
  VaultResetService._();

  static const _backupRetentionDays = 15;
  static const _backupPrefix = 'vault_reset_backup_';
  static const _prefsBackupKey = 'vault_reset_backup_path';
  static const _prefsBackupDateKey = 'vault_reset_backup_date';

  final _progressController = StreamController<VaultResetProgress>.broadcast();
  Stream<VaultResetProgress> get progressStream => _progressController.stream;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// مسار ملف قاعدة البيانات
  Future<String> _getDbPath() => SqliteDatabaseService.getDbPath();

  /// مسار النسخة الاحتياطية
  Future<String> _getBackupPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(dir.path, '$_backupPrefix$timestamp.isar');
  }

  /// إعطاء الـ UI فرصة للتحديث بين العمليات الثقيلة
  Future<void> _yieldToUI() async {
    await Future.delayed(Duration.zero);
  }

  /// تنفيذ عملية إعادة التعيين الكاملة
  Future<VaultResetProgress> executeReset({
    required String newPassword,
  }) async {
    if (_isRunning) {
      return const VaultResetProgress(
        status: VaultResetStatus.failed,
        errorMessage: 'عملية إعادة التعيين قيد التنفيذ بالفعل',
      );
    }

    _isRunning = true;
    String? backupPath;

    try {
      // ═══════════════════════════════════════════════════════════════
      // الخطوة 1: نسخ القاعدة احتياطياً قبل أي تعديل
      // ═══════════════════════════════════════════════════════════════
      _emit(const VaultResetProgress(status: VaultResetStatus.backingUp));
      await _yieldToUI();

      final dbPath = await _getDbPath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return _fail('ملف قاعدة البيانات غير موجود');
      }

      backupPath = await _getBackupPath();
      await dbFile.copy(backupPath);
      AppLogger.debug('[VaultReset] 📦 Database backed up to: $backupPath');

      await _saveBackupRecord(backupPath);

      // ═══════════════════════════════════════════════════════════════
      // الخطوة 2: قراءة المفتاح الحالي (الخزنة مفتوحة بالبصمة)
      // ═══════════════════════════════════════════════════════════════
      Key oldMasterKey;
      try {
        oldMasterKey = await VaultService.getMasterKey();
      } catch (e) {
        return _fail('فشل قراءة مفتاح التشفير الحالي');
      }

      // ═══════════════════════════════════════════════════════════════
      // الخطوة 3: جلب كل الملاحظات المشفرة
      // ═══════════════════════════════════════════════════════════════
      final dbService = SqliteDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();

      if (lockedNotes.isEmpty) {
        VaultService.wipeMasterKey(oldMasterKey);
        return await _resetKeysOnly(newPassword);
      }

      final totalNotes = lockedNotes.length;
      _emit(VaultResetProgress(
        status: VaultResetStatus.decrypting,
        totalNotes: totalNotes,
        processedNotes: 0,
      ));
      await _yieldToUI();

      // ═══════════════════════════════════════════════════════════════
      // الخطوة 4: فك تشفير كل الملاحظات (بالمفتاح القديم)
      // ═══════════════════════════════════════════════════════════════
      final decryptedNotes = <Note>[];
      for (int i = 0; i < lockedNotes.length; i++) {
        final note = lockedNotes[i];
        final decryptedTitle =
            VaultService.decryptWithKey(note.title, oldMasterKey);
        final decryptedContent =
            VaultService.decryptWithKey(note.content, oldMasterKey);

        decryptedNotes.add(note.copyWith(
          title: decryptedTitle,
          content: decryptedContent,
        ));

        _emit(VaultResetProgress(
          status: VaultResetStatus.decrypting,
          totalNotes: totalNotes,
          processedNotes: i + 1,
        ));

        // yield كل 3 ملاحظات لتحديث الـ UI بسلاسة
        if ((i + 1) % 3 == 0 || i == lockedNotes.length - 1) {
          await _yieldToUI();
        }
      }

      // مسح المفتاح القديم من الذاكرة فوراً
      VaultService.wipeMasterKey(oldMasterKey);

      // ═══════════════════════════════════════════════════════════════
      // الخطوة 5: إنشاء مفتاح جديد + كود استرداد جديد
      // (عملية ثقيلة — PBKDF2 100k iterations)
      // ═══════════════════════════════════════════════════════════════
      _emit(VaultResetProgress(
        status: VaultResetStatus.generatingNewKey,
        totalNotes: totalNotes,
        processedNotes: totalNotes,
      ));
      await _yieldToUI();

      // setupVault ثقيلة (PBKDF2) — نعطي الـ UI frame واحد قبلها
      await Future.delayed(const Duration(milliseconds: 16));
      final newRecoveryCode = await VaultService.setupVault(newPassword);
      await _yieldToUI();

      Key newMasterKey;
      try {
        newMasterKey = await VaultService.getMasterKey();
      } catch (e) {
        await _restoreFromBackup(backupPath);
        return _fail('فشل إنشاء المفتاح الجديد');
      }

      // ═══════════════════════════════════════════════════════════════
      // الخطوة 6: إعادة تشفير كل الملاحظات (بالمفتاح الجديد)
      // ═══════════════════════════════════════════════════════════════
      _emit(VaultResetProgress(
        status: VaultResetStatus.reEncrypting,
        totalNotes: totalNotes,
        processedNotes: 0,
      ));
      await _yieldToUI();

      for (int i = 0; i < decryptedNotes.length; i++) {
        final note = decryptedNotes[i];

        final iv1 = IV.fromSecureRandom(16);
        final iv2 = IV.fromSecureRandom(16);
        final encrypter = Encrypter(AES(newMasterKey));

        final encryptedTitle = note.title.isNotEmpty
            ? '${iv1.base64}:${encrypter.encrypt(note.title, iv: iv1).base64}'
            : '';
        final encryptedContent = note.content.isNotEmpty
            ? '${iv2.base64}:${encrypter.encrypt(note.content, iv: iv2).base64}'
            : '';

        final reEncryptedNote = note.copyWith(
          title: encryptedTitle,
          content: encryptedContent,
          updatedAt: DateTime.now(),
        );

        await dbService.updateNote(reEncryptedNote);

        _emit(VaultResetProgress(
          status: VaultResetStatus.reEncrypting,
          totalNotes: totalNotes,
          processedNotes: i + 1,
        ));

        // yield كل 2 ملاحظات (الكتابة للقاعدة أثقل)
        if ((i + 1) % 2 == 0 || i == decryptedNotes.length - 1) {
          await _yieldToUI();
        }
      }

      // مسح المفتاح الجديد من الذاكرة
      VaultService.wipeMasterKey(newMasterKey);

      // ═══════════════════════════════════════════════════════════════
      // الخطوة 7: اكتمال — الاحتفاظ بالنسخة القديمة 15 يوم
      // ═══════════════════════════════════════════════════════════════
      final result = VaultResetProgress(
        status: VaultResetStatus.completed,
        totalNotes: totalNotes,
        processedNotes: totalNotes,
        newRecoveryCode: newRecoveryCode,
      );
      _emit(result);

      AppLogger.debug(
          '[VaultReset] ✅ Reset completed. $totalNotes notes re-encrypted.');

      return result;
    } catch (e, stack) {
      AppLogger.debug('[VaultReset] ❌ Fatal error: $e\n$stack');

      if (backupPath != null) {
        await _restoreFromBackup(backupPath);
      }

      return _fail('خطأ غير متوقع — تمت استعادة القاعدة القديمة');
    } finally {
      _isRunning = false;
    }
  }

  /// استعادة القاعدة من النسخة الاحتياطية
  Future<void> _restoreFromBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) return;

      final dbService = SqliteDatabaseService();
      await dbService.closeDB();

      final dbPath = await _getDbPath();
      await backupFile.copy(dbPath);

      await dbService.reopenDatabase();
      AppLogger.debug('[VaultReset] 🔄 Restored database from backup');
    } catch (e) {
      AppLogger.debug('[VaultReset] ❌ Failed to restore backup: $e');
    }
  }

  /// إعادة تعيين المفاتيح فقط (لا توجد ملاحظات مشفرة)
  Future<VaultResetProgress> _resetKeysOnly(String newPassword) async {
    _emit(const VaultResetProgress(
      status: VaultResetStatus.generatingNewKey,
    ));
    await _yieldToUI();
    await Future.delayed(const Duration(milliseconds: 16));

    await VaultService.clearVault();
    final newRecoveryCode = await VaultService.setupVault(newPassword);

    final result = VaultResetProgress(
      status: VaultResetStatus.completed,
      newRecoveryCode: newRecoveryCode,
    );
    _emit(result);
    return result;
  }

  /// حفظ سجل النسخة الاحتياطية
  Future<void> _saveBackupRecord(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsBackupKey, path);
    await prefs.setString(
        _prefsBackupDateKey, DateTime.now().toIso8601String());
  }

  /// حذف النسخ الاحتياطية المنتهية (أقدم من 15 يوم)
  static Future<void> cleanExpiredBackups() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync();

      for (final entity in files) {
        if (entity is File &&
            p.basename(entity.path).startsWith(_backupPrefix)) {
          final stat = await entity.stat();
          final age = DateTime.now().difference(stat.modified);
          if (age.inDays > _backupRetentionDays) {
            await entity.delete();
            AppLogger.debug(
                '[VaultReset] 🗑️ Deleted expired backup: ${entity.path}');
          }
        }
      }
    } catch (e) {
      AppLogger.debug('[VaultReset] Cleanup error: $e');
    }
  }

  VaultResetProgress _fail(String message) {
    final result = VaultResetProgress(
      status: VaultResetStatus.failed,
      errorMessage: message,
    );
    _emit(result);
    _isRunning = false;
    return result;
  }

  void _emit(VaultResetProgress progress) {
    _progressController.add(progress);
  }

  void dispose() {
    _progressController.close();
  }
}
