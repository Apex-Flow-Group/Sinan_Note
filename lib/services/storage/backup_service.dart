// Copyright © 2025 Apex Flow Group. All rights reserved.

import '../../core/utils/logger.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../diagnostics/apex_error_manager.dart';
import 'isar_database_service.dart';
import '../../models/note.dart';

class BackupService {
  Future<void> exportDatabase() async {
    await ApexErrorManager.monitorCritical(() async {
      final dbService = IsarDatabaseService();
      final notes = await dbService.getAllNotes();
      
      final json = jsonEncode(notes.map((n) => n.toMap()).toList());
      
      final now = DateTime.now();
      final fileName = 'SinanNote_Backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
      
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, fileName);
      await File(tempPath).writeAsString(json);
      
      final params = SaveFileDialogParams(
        sourceFilePath: tempPath,
        fileName: fileName,
        mimeTypesFilter: ['application/json'],
      );
      final result = await FlutterFileDialog.saveFile(params: params);
      if (result == null) throw Exception('تم إلغاء الحفظ');
    }, 'Backup_Export');
  }

  Future<String> exportDatabaseToPath(String directoryPath) async {
    return await ApexErrorManager.monitorCritical(() async {
      final dbService = IsarDatabaseService();
      final notes = await dbService.getAllNotes();
      
      final json = jsonEncode(notes.map((n) => n.toMap()).toList());
      
      final now = DateTime.now();
      final fileName = 'SinanNote_Backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
      final outputPath = join(directoryPath, fileName);
      
      await File(outputPath).writeAsString(json);
      return outputPath;
    }, 'Backup_ExportToPath');
  }

  Future<void> shareDatabase() async {
    try {
      final dbService = IsarDatabaseService();
      final notes = await dbService.getAllNotes();
      
      final json = jsonEncode(notes.map((n) => n.toMap()).toList());
      
      final now = DateTime.now();
      final fileName = 'SinanNote_Backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
      
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, fileName);
      await File(tempPath).writeAsString(json);
      
      await Share.shareXFiles(
        [XFile(tempPath, mimeType: 'application/json', name: fileName)],
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      return result?.files.single.path;
    } catch (e) {
      throw Exception('فشل في اختيار الملف');
    }
  }

  Future<void> replaceDatabase(String backupPath) async {
    await ApexErrorManager.monitorCritical(() async {
      File sourceFile = File(backupPath);
      if (!await sourceFile.exists()) throw Exception('الملف غير موجود');
      
      final json = await sourceFile.readAsString();
      final List<dynamic> data = jsonDecode(json);
      
      final dbService = IsarDatabaseService();
      final isar = await dbService.database;
      
      // Clear and insert without version logging
      await isar.writeTxn(() async {
        await isar.notes.clear();
        for (var noteMap in data) {
          final note = Note.fromMap(noteMap);
          note.updatedAt = DateTime.now();
          await isar.notes.put(note);
        }
      });
      
      AppLogger.debug('✓ Database replaced with ${data.length} notes');
    }, 'Backup_Replace');
  }

  Future<int> mergeDatabase(String backupPath) async {
    return await ApexErrorManager.monitorCritical(() async {
      File sourceFile = File(backupPath);
      if (!await sourceFile.exists()) throw Exception('الملف غير موجود');
      
      final json = await sourceFile.readAsString();
      final List<dynamic> data = jsonDecode(json);
      
      final dbService = IsarDatabaseService();
      final isar = await dbService.database;
      
      int merged = 0;
      await isar.writeTxn(() async {
        for (var noteMap in data) {
          final note = Note.fromMap(noteMap);
          note.updatedAt = DateTime.now();
          await isar.notes.put(note);
          merged++;
        }
      });
      
      AppLogger.debug('✓ Merged $merged notes');
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
      
      AppLogger.debug('✓ Sanitized backup prepared: $lockedCount locked notes excluded');
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
        AppLogger.debug('✓ Temp sanitized backup cleaned up');
      }
    } catch (e) {
      AppLogger.debug('⚠ Failed to cleanup temp backup: $e');
    }
  }
}
