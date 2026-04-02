// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/diagnostics/apex_error_manager.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  String _backupFileName() {
    final now = DateTime.now();
    return 'SinanNote_Backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.sinannote';
  }

  Future<String> _getIsarFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, 'sinan_notes.isar');
  }

  Future<void> exportDatabase() async {
    await ApexErrorManager.monitorCritical(() async {
      final isarPath = await _getIsarFilePath();
      if (!await File(isarPath).exists())
        // ignore: curly_braces_in_flow_control_structures
        throw Exception('ملف قاعدة البيانات غير موجود');

      final fileName = _backupFileName();
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, fileName);
      await File(isarPath).copy(tempPath);

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
      final isarPath = await _getIsarFilePath();
      if (!await File(isarPath).exists()) {
        throw Exception('ملف قاعدة البيانات غير موجود');
      }

      final fileName = _backupFileName();
      final outputPath = join(directoryPath, fileName);
      await File(isarPath).copy(outputPath);
      return outputPath;
    }, 'Backup_ExportToPath');
  }

  Future<void> shareDatabase() async {
    try {
      final isarPath = await _getIsarFilePath();
      if (!await File(isarPath).exists()) {
        throw Exception('ملف قاعدة البيانات غير موجود');
      }

      final fileName = _backupFileName();
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, fileName);
      await File(isarPath).copy(tempPath);

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
      final dbService = IsarDatabaseService();
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

      final dbService = IsarDatabaseService();
      final isar = await dbService.database;

      // Clear and insert notes
      await isar.writeTxn(() async {
        await isar.notes.clear();
        for (var noteMap in notesData) {
          final note = Note.fromMap(noteMap);
          note.updatedAt = DateTime.now();
          await isar.notes.put(note);
        }
      });

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

      final dbService = IsarDatabaseService();
      final isar = await dbService.database;

      int merged = 0;
      await isar.writeTxn(() async {
        for (var noteMap in notesData) {
          final note = Note.fromMap(noteMap);
          note.updatedAt = DateTime.now();
          await isar.notes.put(note);
          merged++;
        }
      });

      AppLogger.debug('[Merge] Merged $merged notes');
      return merged;
    }, 'Backup_Merge');
  }

  Future<(String, int)> prepareSanitizedDatabase() async {
    return await ApexErrorManager.monitorCritical(() async {
      final dbService = IsarDatabaseService();
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
