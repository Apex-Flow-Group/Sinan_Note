// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/core/utils/logger.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/diagnostics/apex_error_manager.dart';
import 'package:sinan_note/services/security/vault_service.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';

class BackupService {
  String _backupFileName() {
    final now = DateTime.now();
    return 'SinanNote_Backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.db';
  }

  Future<String> _getDbFilePath() => SqliteDatabaseService.getDbPath();

  Future<void> exportDatabase() async {
    await ApexErrorManager.monitorCritical(() async {
      final dbPath = await _getDbFilePath();
      if (!await File(dbPath).exists()) {
        throw Exception('ملف قاعدة البيانات غير موجود');
      }

      final fileName = _backupFileName();
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, fileName);
      await File(dbPath).copy(tempPath);

      final params = SaveFileDialogParams(
        sourceFilePath: tempPath,
        fileName: fileName,
        mimeTypesFilter: ['application/octet-stream'],
      );
      final result = await FlutterFileDialog.saveFile(params: params);
      if (result == null) throw Exception('تم إلغاء الحفظ');
    }, 'Backup_Export');
  }

  Future<String> exportDatabaseToPath(String directoryPath) async {
    return await ApexErrorManager.monitorCritical(() async {
      final dbPath = await _getDbFilePath();
      if (!await File(dbPath).exists()) {
        throw Exception('ملف قاعدة البيانات غير موجود');
      }

      final fileName = _backupFileName();
      final outputPath = join(directoryPath, fileName);
      await File(dbPath).copy(outputPath);
      return outputPath;
    }, 'Backup_ExportToPath');
  }

  Future<void> shareDatabase() async {
    try {
      final dbPath = await _getDbFilePath();
      if (!await File(dbPath).exists()) {
        throw Exception('ملف قاعدة البيانات غير موجود');
      }

      final fileName = _backupFileName();
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, fileName);
      await File(dbPath).copy(tempPath);

      await Share.shareXFiles(
        [XFile(tempPath, mimeType: 'application/octet-stream', name: fileName)],
        subject: 'نسخة احتياطية - Sinan Note',
        text: 'احفظ هذا الملف في مكان آمن لاستعادة بياناتك لاحقاً.',
      );
    } catch (e) {
      throw Exception('فشل في مشاركة النسخة الاحتياطية: $e');
    }
  }

  Future<int> checkLocalNotesCount() async {
    try {
      final dbService = SqliteDatabaseService();
      final notes = await dbService.getAllNotes();
      return notes.length;
    } catch (e) {
      return 0;
    }
  }

  Future<String?> pickBackupFile() async {
    try {
      final path = await FlutterFileDialog.pickFile(
        params: const OpenFileDialogParams(),
      );
      return path;
    } catch (e) {
      throw Exception('فشل في اختيار الملف: $e');
    }
  }

  Future<void> replaceDatabase(String backupPath) async {
    await ApexErrorManager.monitorCritical(() async {
      File sourceFile = File(backupPath);
      if (!await sourceFile.exists()) throw Exception('الملف غير موجود');

      final json = await sourceFile.readAsString();
      final dynamic jsonData = jsonDecode(json);

      List<dynamic> notesData;
      Map<String, dynamic>? vaultData;

      // Check if new format (with version and vault_data)
      if (jsonData is Map<String, dynamic>) {
        notesData = jsonData['notes'] ?? [];
        vaultData = jsonData['vault_data'];

        // Restore vault data if exists
        if (vaultData != null) {
          await VaultService.restoreVaultDataFromBackup(vaultData);
          AppLogger.debug('[Restore] Vault data restored from backup');
        }
      } else {
        // Old format (array of notes)
        notesData = jsonData;
      }

      final dbService = SqliteDatabaseService();

      // Clear and insert notes
      final existing = await dbService.getAllNotes();
      for (final n in existing) {
        if (n.id != null) await dbService.deleteNote(n.id!);
      }
      for (var noteMap in notesData) {
        final note = Note.fromMap(noteMap);
        await dbService.upsertNote(note);
      }

      // مسح sync state — بعد الاستعادة الجهاز يجب أن يرفع لـ Drive أولاً
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_upload_timestamp');
      await prefs.remove('last_known_drive_md5');
      await prefs.remove('deleted_note_ids');

      AppLogger.debug(
          '[Replace] Database replaced with ${notesData.length} notes');
    }, 'Backup_Replace');
  }

  Future<int> mergeDatabase(String backupPath) async {
    return await ApexErrorManager.monitorCritical(() async {
      File sourceFile = File(backupPath);
      if (!await sourceFile.exists()) throw Exception('الملف غير موجود');

      final json = await sourceFile.readAsString();
      final dynamic jsonData = jsonDecode(json);

      List<dynamic> notesData;
      Map<String, dynamic>? vaultData;

      // Check if new format (with version and vault_data)
      if (jsonData is Map<String, dynamic>) {
        notesData = jsonData['notes'] ?? [];
        vaultData = jsonData['vault_data'];

        // Restore vault data if exists
        if (vaultData != null) {
          await VaultService.restoreVaultDataFromBackup(vaultData);
          AppLogger.debug('[Restore] Vault data restored from backup');
        }
      } else {
        // Old format (array of notes)
        notesData = jsonData;
      }

      final dbService = SqliteDatabaseService();

      int merged = 0;
      for (var noteMap in notesData) {
        final note = Note.fromMap(noteMap);
        await dbService.upsertNote(note);
        merged++;
      }

      AppLogger.debug('[Merge] Merged $merged notes');

      // مسح sync state — بعد الدمج الجهاز يجب أن يرفع لـ Drive أولاً
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_upload_timestamp');
      await prefs.remove('last_known_drive_md5');
      await prefs.remove('deleted_note_ids');

      return merged;
    }, 'Backup_Merge');
  }

  Future<(String, int)> prepareSanitizedDatabase() async {
    return await ApexErrorManager.monitorCritical(() async {
      final dbService = SqliteDatabaseService();
      final allNotes = await dbService.getAllNotes();

      final unlockedNotes = allNotes.where((n) => !n.isLocked).toList();
      final lockedCount = allNotes.length - unlockedNotes.length;

      final json = jsonEncode(unlockedNotes.map((n) => n.toMap()).toList());

      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'notes_transfer_temp.json');
      await File(tempPath).writeAsString(json);

      AppLogger.debug(
          '[Sanitize] Backup prepared: $lockedCount locked notes excluded');
      return (tempPath, lockedCount);
    }, 'Backup_Sanitize');
  }

  Future<void> cleanupSanitizedDatabase() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'notes_transfer_temp.json');
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
        AppLogger.debug('[Cleanup] Temp sanitized backup cleaned up');
      }
    } catch (e) {
      AppLogger.debug('[Error] Failed to cleanup temp backup: $e');
    }
  }
}

