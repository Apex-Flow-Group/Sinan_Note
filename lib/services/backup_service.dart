// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../config/flavor_config.dart';
import 'apex_error_manager.dart';
import 'database_service.dart';

class BackupService {
  Future<Directory> _getBackupDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download/SinanBackup');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        throw Exception('لا يمكن الوصول لمجلد التنزيلات');
      }
      final backupDir = Directory(join(downloadsDir.path, 'SinanBackup'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      return backupDir;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Try manageExternalStorage first (Android 11+)
    var status = await Permission.manageExternalStorage.status;
    if (status.isGranted) return true;
    
    status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    // Fallback to storage permission (Android 10 and below)
    status = await Permission.storage.status;
    if (status.isGranted) return true;
    
    status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> exportDatabase() async {
    await ApexErrorManager.monitorCritical(() async {
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'notes.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) throw Exception('لا توجد قاعدة بيانات');

      final now = DateTime.now();
      final fileName =
          'ApexNote_Backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}.db';

      if (FlavorConfig.isGooglePlay) {
        // Google Play: Use scoped storage with file picker
        final params = SaveFileDialogParams(
          sourceFilePath: dbPath,
          fileName: fileName,
          mimeTypesFilter: ['application/octet-stream'],
        );
        final result = await FlutterFileDialog.saveFile(params: params);
        if (result == null) throw Exception('تم إلغاء الحفظ');
      } else {
        // F-Droid: Direct path with MANAGE_EXTERNAL_STORAGE
        final hasPermission = await _requestStoragePermission();
        if (!hasPermission) throw Exception('يجب منح إذن التخزين');
        
        final directory = await _getBackupDirectory();
        final outputPath = join(directory.path, fileName);
        await dbFile.copy(outputPath);
      }
    }, 'Backup_Export');
  }

  Future<String> exportDatabaseToPath(String directoryPath) async {
    return await ApexErrorManager.monitorCritical(() async {
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'notes.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) throw Exception('لا توجد قاعدة بيانات');

      final now = DateTime.now();
      final fileName =
          'ApexNote_Backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}.db';

      final outputPath = join(directoryPath, fileName);
      await dbFile.copy(outputPath);
      return outputPath;
    }, 'Backup_ExportToPath');
  }

  Future<void> shareDatabase() async {
    try {
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'notes.db');
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        final now = DateTime.now();
        final fileName =
            'ApexNote_Backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}.db';

        final tempDir = await getTemporaryDirectory();
        final tempPath = join(tempDir.path, fileName);

        await dbFile.copy(tempPath);

        await Share.shareXFiles(
          [
            XFile(tempPath,
                mimeType: 'application/octet-stream', name: fileName)
          ],
          subject: 'نسخة احتياطية - Sinan Note',
          text: 'احفظ هذا الملف في مكان آمن لاستعادة بياناتك لاحقاً.',
        );
      }
    } catch (e) {
      throw Exception('فشل في مشاركة قاعدة البيانات: $e');
    }
  }

  Future<int> checkLocalNotesCount() async {
    try {
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'notes.db');
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) return 0;

      final db = await openDatabase(dbPath, readOnly: true);
      final count = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM notes')) ??
          0;
      await db.close();
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<String?> pickBackupFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowedExtensions: null,
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

      // التحقق من صحة الملف
      try {
        final testDb = await openDatabase(backupPath, readOnly: true);
        final count = Sqflite.firstIntValue(
            await testDb.rawQuery('SELECT COUNT(*) FROM notes'));
        await testDb.close();
        if (count == null) throw Exception('قاعدة بيانات غير صالحة');
      } catch (e) {
        throw Exception('الملف ليس قاعدة بيانات صالحة: $e');
      }

      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'notes.db');
      final backupDbPath = join(dbFolder, 'notes_backup.db');

      final dbFile = File(dbPath);
      if (await dbFile.exists()) await dbFile.copy(backupDbPath);

      try {
        if (await dbFile.exists()) await dbFile.delete();
        await sourceFile.copy(dbPath);

        final db = await openDatabase(dbPath, readOnly: true);
        final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM notes'));
        await db.close();

        if (await File(backupDbPath).exists()) {
          await File(backupDbPath).delete();
        }
        debugPrint('✓ Database replaced with $count notes');
        
        // CRITICAL: Reinitialize database connection after file replacement
        await DatabaseService().reopenDatabase();
      } catch (e) {
        if (await File(backupDbPath).exists()) {
          await File(backupDbPath).copy(dbPath);
          await File(backupDbPath).delete();
        }
        throw Exception('فشل الاستبدال');
      }
    }, 'Backup_Replace');
  }

  Future<int> mergeDatabase(String backupPath) async {
    return await ApexErrorManager.monitorCritical(() async {
      File sourceFile = File(backupPath);
      if (!await sourceFile.exists()) throw Exception('الملف غير موجود');

      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'notes.db');

      final backupDb = await openDatabase(backupPath, readOnly: true);
      final backupNotes = await backupDb.query('notes');
      await backupDb.close();

      final currentDb = await openDatabase(dbPath);
      int merged = 0;
      int skipped = 0;

      for (var noteMap in backupNotes) {
        final title = noteMap['title'] as String?;
        final content = noteMap['content'] as String?;

        final existing = await currentDb.query('notes',
            where: 'title = ? AND content = ?',
            whereArgs: [title, content],
            limit: 1);

        if (existing.isEmpty) {
          final newNote = Map<String, dynamic>.from(noteMap);
          newNote.remove('id');
          await currentDb.insert('notes', newNote);
          merged++;
        } else {
          skipped++;
        }
      }

      await currentDb.close();
      debugPrint('✓ Merged $merged notes, skipped $skipped duplicates');
      return merged;
    }, 'Backup_Merge');
  }

  /// Prepare sanitized database for transfer/backup (excludes locked notes)
  /// Returns: (tempDbPath, lockedNotesCount)
  /// SECURITY: Locked notes are NEVER transferred
  Future<(String, int)> prepareSanitizedDatabase() async {
    return await ApexErrorManager.monitorCritical(() async {
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, 'notes.db');
      final tempDbPath = join(dbFolder, 'notes_transfer_temp.db');

      // Check locked notes count
      final db = await openDatabase(dbPath, readOnly: true);
      final lockedCount = Sqflite.firstIntValue(await db
              .rawQuery('SELECT COUNT(*) FROM notes WHERE isLocked = 1')) ??
          0;
      await db.close();

      // Copy database
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) throw Exception('Database not found');
      await dbFile.copy(tempDbPath);

      // Sanitize: Remove locked notes
      final tempDb = await openDatabase(tempDbPath);
      await tempDb.delete('notes', where: 'isLocked = 1');
      await tempDb.close();

      debugPrint('✓ Sanitized DB prepared: $lockedCount locked notes excluded');
      return (tempDbPath, lockedCount);
    }, 'Backup_Sanitize');
  }

  /// Clean up temporary sanitized database
  Future<void> cleanupSanitizedDatabase() async {
    try {
      final dbFolder = await getDatabasesPath();
      final tempDbPath = join(dbFolder, 'notes_transfer_temp.db');
      final tempFile = File(tempDbPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
        debugPrint('✓ Temp sanitized DB cleaned up');
      }
    } catch (e) {
      debugPrint('⚠ Failed to cleanup temp DB: $e');
    }
  }
}
