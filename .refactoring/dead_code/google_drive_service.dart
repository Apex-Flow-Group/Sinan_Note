// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/models/category.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/cloud/google_drive_auth.dart';
import 'package:apex_note/services/cloud/google_drive_merge.dart';
import 'package:apex_note/services/storage/compression_service.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveService {
  // ── Auth delegates ────────────────────────────────────────────────────────
  static bool get isSignedIn => GoogleDriveAuth.isSignedIn;
  static String? get currentUserEmail => GoogleDriveAuth.currentUserEmail;
  static DateTime? _lastSyncTime;
  static DateTime? get lastSyncTime => _lastSyncTime;

  static Future<void> initializeSignIn() async {
    await GoogleDriveAuth.initializeSignIn();
    await loadAutoSyncState();
  }

  static Future<bool> signIn() => GoogleDriveAuth.signIn();
  static Future<void> signOut() async {
    await GoogleDriveAuth.signOut();
    _lastSyncTime = null;
    await setAutoSync(false);
  }

  // ── Auto sync state ───────────────────────────────────────────────────────
  static final ValueNotifier<bool> autoSyncEnabled = ValueNotifier(false);

  static Future<void> loadAutoSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    autoSyncEnabled.value = prefs.getBool('google_drive_auto_sync') ?? false;
  }

  static Future<void> setAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('google_drive_auto_sync', value);
    autoSyncEnabled.value = value;
  }

  // ── Rate limiting ─────────────────────────────────────────────────────────
  static final ValueNotifier<bool> isSyncing = ValueNotifier(false);

  static bool _isUploading = false;
  static bool _isDownloading = false;
  static DateTime? _lastUploadTime;
  static int _uploadCount = 0;
  static const _maxUploadsPerHour = 180;

  // ── Dirty tracking (رفع فقط عند وجود تغييرات) ────────────────────────────
  static bool _hasPendingChanges = false;

  /// يُستدعى عند تعديل/إضافة/حذف ملاحظة لتعليم أن هناك تغييرات تحتاج رفع
  static void markDirty() {
    _hasPendingChanges = true;
  }

  /// هل هناك تغييرات محلية لم تُرفع بعد؟
  static bool get hasPendingChanges => _hasPendingChanges;

  // ── Internet check ────────────────────────────────────────────────────────
  static Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('www.googleapis.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Smart startup sync (no dialog) ───────────────────────────────────────
  static Future<void> smartSyncOnStartup() async {
    if (GoogleDriveAuth.driveApi == null) return;
    if (!await _hasInternet()) return;

    isSyncing.value = true;
    try {
      var driveFile = await GoogleDriveAuth.findFile('sinan_backup.gz');

      if (driveFile == null) {
        await uploadDatabase(null);
        return;
      }

      final driveModified = driveFile.modifiedTime;
      if (driveModified == null) {
        await uploadDatabase(null);
        return;
      }

      // نقارن وقت Drive بآخر رفع محلي
      final prefs = await _getPrefs();
      final lastUploadMs = prefs.getInt('last_upload_timestamp');
      final lastUpload = lastUploadMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastUploadMs)
          : null;

      // لا يوجد تاريخ رفع محلي — جهاز جديد أو بعد استعادة backup
      // ادمج مع Drive بدل Overwrite — يحمي النوتات المحلية ويدمجها مع Drive
      if (lastUpload == null) {
        AppLogger.info(
            'First sync on this device → silent merge', 'GoogleDrive');
        await _silentMerge();
        return;
      }

      // Drive أحدث من آخر رفع محلي → اجلب من Drive
      final driveIsNewer =
          driveModified.isAfter(lastUpload.add(const Duration(seconds: 10)));

      if (driveIsNewer) {
        AppLogger.info('Drive is newer → silent merge', 'GoogleDrive');
        await _silentMerge();
      } else if (_hasPendingChanges) {
        AppLogger.info('Local has pending changes → uploading', 'GoogleDrive');
        await uploadDatabase(null);
        await prefs.setInt(
            'last_upload_timestamp', DateTime.now().millisecondsSinceEpoch);
      } else {
        AppLogger.info('No pending changes → skip upload', 'GoogleDrive');
      }
    } catch (e) {
      AppLogger.error('Smart sync failed', 'GoogleDrive', e);
    } finally {
      _lastSyncTime = DateTime.now();
      if (!_isDownloading && !_isUploading) {
        isSyncing.value = false;
      }
    }
  }

  static Future<SharedPreferences> _getPrefs() =>
      SharedPreferences.getInstance();

  // ── Silent merge (note-level, no dialog) ─────────────────────────────────
  static Future<void> silentMerge() => _silentMerge();
  static Future<void> _silentMerge() async {
    if (_isDownloading || _isUploading) return;
    _isDownloading = true;
    isSyncing.value = true;
    try {
      final file = await GoogleDriveAuth.findFile('sinan_backup.gz');
      if (file == null) {
        _isDownloading = false;
        isSyncing.value = false;
        return;
      }

      // جلب MD5 الحالي من Drive
      final currentMd5 = file.md5Checksum;
      final prefs = await _getPrefs();
      final lastKnownMd5 = prefs.getString('last_known_drive_md5');
      final isFastPath = currentMd5 != null &&
          lastKnownMd5 != null &&
          currentMd5 == lastKnownMd5;

      AppLogger.info(
        isFastPath ? 'Fast path: MD5 match' : 'Merge path: MD5 changed',
        'GoogleDrive',
      );

      // جلب محتوى Drive
      final response = await GoogleDriveAuth.driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(join(tempDir.path, 'drive_silent.gz'));
      final sink = tempFile.openWrite();
      await response.stream.forEach((chunk) => sink.add(chunk));
      await sink.close();

      final json = CompressionService.decompress(await tempFile.readAsBytes());
      final dynamic jsonData = jsonDecode(json);
      await tempFile.delete();

      final List<dynamic> driveList = jsonData is Map<String, dynamic>
          ? (jsonData['notes'] as List? ?? [])
          : jsonData as List;
      final List<dynamic> driveCats = jsonData is Map<String, dynamic>
          ? (jsonData['categories'] as List? ?? [])
          : [];

      // سجلات الحذف من Drive
      final driveDeletedRaw =
          (jsonData is Map ? (jsonData['deleted_ids'] as Map? ?? {}) : {});
      final driveDeleted = <int, DateTime>{};
      driveDeletedRaw.forEach((k, v) {
        final id = int.tryParse(k.toString());
        final ms = v is int ? v : int.tryParse(v.toString());
        if (id != null && ms != null) {
          driveDeleted[id] = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      });

      final localDeleted = await SqliteDatabaseService.getDeletedNoteIds();

      // بناء allDeleted حسب المسار
      final allDeleted = <int, DateTime>{};

      if (isFastPath) {
        // Fast Path: الجهاز يملك الحقيقة الكاملة — طبّق كل deleted_ids بدون قيود
        allDeleted.addAll(localDeleted);
        driveDeleted.forEach((id, dt) {
          if (!allDeleted.containsKey(id) || dt.isAfter(allDeleted[id]!)) {
            allDeleted[id] = dt;
          }
        });
      } else {
        // Merge Path: الجهاز لا يعرف آخر حالة Drive
        // لا تطبّق deleted_ids محلية بشكل أعمى — سيتم التحكيم لاحقاً بمقارنة التواريخ
        // فقط أضف deleted_ids من Drive (Drive موثوق دائماً)
        allDeleted.addAll(driveDeleted);
      }

      final dbService = SqliteDatabaseService();
      final localNotes = await dbService.getAllNotes();
      final driveNotes = driveList
          .where((m) => (m['isLocked'] ?? 0) == 0)
          .map((m) => Note.fromMap(m))
          .toList();

      // بناء المدمج: الأحدث يفوز
      final Map<int, Note> merged = {};
      for (final n in localNotes) {
        if (n.id != null && !n.isLocked) merged[n.id!] = n;
      }
      for (final n in driveNotes) {
        if (n.id == null) continue;
        final local = merged[n.id!];
        if (local == null || n.updatedAt.isAfter(local.updatedAt)) {
          merged[n.id!] = n;
        }
      }

      // تطبيق الحذف — الأحدث يفوز
      if (isFastPath) {
        // Fast Path: طبّق كل الحذف بالمنطق العادي
        allDeleted.forEach((id, deletedAt) {
          final note = merged[id];
          if (note != null && deletedAt.isAfter(note.updatedAt)) {
            merged.remove(id);
          }
        });
      } else {
        // Merge Path: لكل نوتة في Drive تحكّم بمقارنة deletedAt vs updatedAt
        for (final n in driveNotes) {
          if (n.id == null) continue;
          if (localDeleted.containsKey(n.id)) {
            final deletedAt = localDeleted[n.id]!;
            if (deletedAt.isAfter(n.updatedAt)) {
              // نية الحذف أحدث — احذف
              merged.remove(n.id);
            } else {
              // تعديل جهاز آخر أحدث — ألغِ الحذف واحتفظ بالنوتة
              merged[n.id!] = n;
            }
          }
        }
        // طبّق deleted_ids من Drive بالمنطق العادي
        driveDeleted.forEach((id, deletedAt) {
          final note = merged[id];
          if (note != null && deletedAt.isAfter(note.updatedAt)) {
            merged.remove(id);
          }
        });
      }

      // حفظ النتيجة في قاعدة البيانات
      final allLocal = await dbService.getAllNotes();
      final mergedIds = merged.keys.toSet();
      for (final n in allLocal) {
        if (n.id != null && !n.isLocked && !mergedIds.contains(n.id)) {
          await dbService.deleteNote(n.id!);
        }
      }
      for (final n in merged.values) {
        await dbService.upsertNote(n);
      }

      // دمج الكتالوجات
      final existingCats = await dbService.getAllCategories();
      final existingIds = existingCats.map((c) => c.id).toSet();
      final driveCatIds = driveCats.map((c) => c['id'] as int).toSet();
      for (final c in driveCats) {
        final catId = c['id'] as int;
        final cat = NoteCategory(
          id: catId,
          name: c['name'] as String,
          sortOrder: c['sortOrder'] as int? ?? 0,
        );
        if (existingIds.contains(catId)) {
          await dbService.updateCategory(cat);
        } else {
          await dbService.insertCategory(cat);
        }
      }
      for (final c in existingCats) {
        if (!driveCatIds.contains(c.id)) {
          await dbService.deleteCategory(c.id);
        }
      }

      _lastSyncTime = DateTime.now();
      AppLogger.success(
        '${isFastPath ? "Fast" : "Merge"} path done: ${merged.length} notes',
        'GoogleDrive',
      );
    } catch (e) {
      AppLogger.error('Silent merge failed', 'GoogleDrive', e);
      _isDownloading = false;
      isSyncing.value = false;
      return; // Don't proceed to upload on merge failure
    }
    _isDownloading = false;
    // رفع بعد انتهاء الدمج كاملاً — uploadDatabase manages isSyncing in its finally
    await uploadDatabase(null);
  }

  // ── Upload (العادية فقط — الخزنة محلية دائماً) ───────────────────────────
  static Future<bool> uploadDatabase(dynamic context) async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');
    if (!await _hasInternet()) throw Exception('No internet connection');

    if (_lastUploadTime != null) {
      final elapsed = DateTime.now().difference(_lastUploadTime!);
      // تجاوز rate limit إذا كانت المزامنة مطلوبة من merge
      if (elapsed > const Duration(hours: 1)) _uploadCount = 0;
      if (_uploadCount >= _maxUploadsPerHour) return false;
    }

    if (_isUploading) return false;
    _isUploading = true;
    isSyncing.value = true;

    try {
      _lastUploadTime = DateTime.now();
      _uploadCount++;

      final dbService = SqliteDatabaseService();
      final allNotes = await dbService.getAllNotes();

      // الخزنة محلية دائماً — لا نرفع المشفر أبداً
      final notes = allNotes.where((n) => !n.isLocked).toList();

      final categories = await dbService.getAllCategories();
      final deletedIds = await SqliteDatabaseService.getDeletedNoteIds();
      await SqliteDatabaseService.cleanOldDeletions();

      final backupData = <String, dynamic>{
        'version': '2.0',
        'created_at': DateTime.now().toIso8601String(),
        'notes': notes.map((n) => n.toMap()).toList(),
        'categories': categories
            .map((c) => {'id': c.id, 'name': c.name, 'sortOrder': c.sortOrder})
            .toList(),
        'deleted_ids': deletedIds
            .map((id, dt) => MapEntry('$id', dt.millisecondsSinceEpoch)),
      };

      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'sinan_backup.gz');
      await File(tempPath)
          .writeAsBytes(CompressionService.compress(jsonEncode(backupData)));

      final backupFile = File(tempPath);
      const fileName = 'sinan_backup.gz';
      final existingFile = await GoogleDriveAuth.findFile(fileName);
      final media =
          drive.Media(backupFile.openRead(), await backupFile.length());

      if (existingFile != null) {
        await GoogleDriveAuth.driveApi!.files
            .update(drive.File(), existingFile.id!, uploadMedia: media);
      } else {
        await GoogleDriveAuth.driveApi!.files.create(
          drive.File()
            ..name = fileName
            ..mimeType = 'application/gzip',
          uploadMedia: media,
        );
      }

      await backupFile.delete();
      _lastSyncTime = DateTime.now();
      _hasPendingChanges = false;
      final prefs = await _getPrefs();
      await prefs.setInt(
          'last_upload_timestamp', _lastSyncTime!.millisecondsSinceEpoch);

      // حفظ MD5 بعد الرفع الناجح — أساس Fast Path
      final uploadedFile = await GoogleDriveAuth.findFile(fileName);
      if (uploadedFile?.md5Checksum != null) {
        await prefs.setString(
            'last_known_drive_md5', uploadedFile!.md5Checksum!);
      }

      // مسح deleted_ids بعد الرفع — تم تطبيقها بنجاح
      await prefs.remove('deleted_note_ids');

      AppLogger.success('Uploaded ${notes.length} notes', 'GoogleDrive');
      return true;
    } catch (e) {
      AppLogger.error('Upload failed', 'GoogleDrive', e);
      return false;
    } finally {
      _isUploading = false;
      if (!_isDownloading) isSyncing.value = false;
    }
  }

  // ── Download ──────────────────────────────────────────────────────────────
  static Future<bool> downloadDatabase(dynamic context) async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');
    if (!await _hasInternet()) throw Exception('No internet connection');
    if (_isDownloading) return false;
    _isDownloading = true;
    isSyncing.value = true;

    try {
      final file = await GoogleDriveAuth.findFile('sinan_backup.gz');
      if (file == null) throw Exception('No backup found in Drive');

      final response = await GoogleDriveAuth.driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(join(tempDir.path, 'drive_backup.gz'));
      final sink = tempFile.openWrite();
      await response.stream.forEach((chunk) => sink.add(chunk));
      await sink.close();

      final json = CompressionService.decompress(await tempFile.readAsBytes());
      final dynamic jsonData = jsonDecode(json);
      await tempFile.delete();

      final List<dynamic> notesList = jsonData is Map<String, dynamic>
          ? (jsonData['notes'] ?? [])
          : jsonData;
      final List<dynamic> categoriesList = jsonData is Map<String, dynamic>
          ? (jsonData['categories'] ?? [])
          : [];

      // فقط النوتات غير المشفرة — الخزنة محلية دائماً
      final regularNotes =
          notesList.where((m) => (m['isLocked'] ?? 0) == 0).toList();

      final dbService = SqliteDatabaseService();
      final lockedLocal = await dbService.getLockedNotes();
      // حذف النوتات العادية وإدراج نوتات Drive مع الحفاظ على الـ id
      final allLocal = await dbService.getAllNotes();
      for (final n in allLocal) {
        if (n.id != null && !n.isLocked) await dbService.deleteNote(n.id!);
      }
      for (final m in regularNotes) {
        await dbService.upsertNote(Note.fromMap(m));
      }
      for (final n in lockedLocal) {
        await dbService.updateNote(n);
      }
      // استعادة الكتالوجات
      if (categoriesList.isNotEmpty) {
        final existingCats = await dbService.getAllCategories();
        for (final c in existingCats) {
          await dbService.deleteCategory(c.id);
        }
        for (final c in categoriesList) {
          await dbService.insertCategory(NoteCategory(
            id: c['id'] as int,
            name: c['name'] as String,
            sortOrder: c['sortOrder'] as int? ?? 0,
          ));
        }
      }

      _lastSyncTime = DateTime.now();
      // مسح deleted_ids المحلية — بعد Download لا تعد موثوقة
      final prefs = await _getPrefs();
      await prefs.remove('deleted_note_ids');
      await prefs.setInt(
          'last_upload_timestamp', _lastSyncTime!.millisecondsSinceEpoch);
      _hasPendingChanges = false;
      AppLogger.success(
          'Downloaded ${regularNotes.length} notes', 'GoogleDrive');
      return true;
    } catch (e) {
      AppLogger.error('Download failed', 'GoogleDrive', e);
      return false;
    } finally {
      _isDownloading = false;
      if (!_isUploading) isSyncing.value = false;
    }
  }

  // ── Merge ─────────────────────────────────────────────────────────────────
  static Future<bool> mergeWithDrive(dynamic context) {
    return GoogleDriveMerge.mergeWithDrive(
      context,
      uploadFn: uploadDatabase,
    );
  }

  // ── Queries ───────────────────────────────────────────────────────────────
  static Future<bool> hasBackupInDrive() async {
    if (GoogleDriveAuth.driveApi == null) return false;
    try {
      return await GoogleDriveAuth.findFile('sinan_backup.gz') != null;
    } catch (_) {
      return false;
    }
  }

  static Future<int> getDriveNotesCount() async {
    if (GoogleDriveAuth.driveApi == null) return 0;
    try {
      final file = await GoogleDriveAuth.findFile('sinan_backup.gz');
      if (file == null) return 0;

      final response = await GoogleDriveAuth.driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> data = [];
      await for (final chunk in response.stream) {
        data.addAll(chunk);
      }

      final jsonString = CompressionService.decompress(data);
      final dynamic jsonData = jsonDecode(jsonString);

      if (jsonData is Map<String, dynamic>) {
        return (jsonData['notes'] as List?)?.length ?? 0;
      } else if (jsonData is List) {
        return jsonData.length;
      }
      return 0;
    } catch (e) {
      AppLogger.error('Get Drive notes count error', 'GoogleDrive', e);
      return 0;
    }
  }
}
