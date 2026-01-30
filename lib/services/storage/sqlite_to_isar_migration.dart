// Copyright © 2025 Apex Flow Group. All rights reserved.

import '../../core/utils/logger.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../storage/isar_database_service.dart';
import '../../models/note.dart';

class SqliteToIsarMigration {
  static Future<void> migrateIfNeeded() async {
    try {
      final dbPath = await _getSqlitePath();
      if (!await File(dbPath).exists()) {
        AppLogger.debug('✅ No SQLite database - fresh install');
        return;
      }

      if (await _getMigrationFlag()) {
        AppLogger.debug('✅ Already migrated to Isar');
        return;
      }

      AppLogger.debug('🔄 Starting SQLite → Isar migration...');
      await _performMigration(dbPath);
      await _setMigrationFlag();
      AppLogger.debug('✅ Migration completed successfully');
      
    } catch (e) {
      AppLogger.debug('❌ Migration failed: $e');
    }
  }

  static Future<void> _performMigration(String dbPath) async {
    final db = await openDatabase(dbPath, readOnly: true);
    final isarDb = IsarDatabaseService();
    
    try {
      final maps = await db.query('notes');
      AppLogger.debug('📦 Found ${maps.length} notes to migrate');
      
      for (final map in maps) {
        final note = Note(
          title: map['title'] as String? ?? '',
          content: map['content'] as String? ?? '',
          createdAt: DateTime.parse(map['created_at'] as String),
          updatedAt: DateTime.parse(map['updated_at'] as String),
          colorIndex: map['color_index'] as int? ?? 0,
          isPinned: (map['is_pinned'] as int? ?? 0) == 1,
          isArchived: (map['is_archived'] as int? ?? 0) == 1,
          isTrashed: (map['is_trashed'] as int? ?? 0) == 1,
          isLocked: (map['is_locked'] as int? ?? 0) == 1,
          isChecklist: (map['is_checklist'] as int? ?? 0) == 1,
          reminderDateTime: map['reminder_date_time'] != null
              ? DateTime.parse(map['reminder_date_time'] as String)
              : null,
          recurrenceRule: map['recurrence_rule'] as String?,
        );
        
        await isarDb.insertNote(note);
      }
      
      AppLogger.debug('✅ Migrated ${maps.length} notes');
    } finally {
      await db.close();
    }
  }

  static Future<String> _getSqlitePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    if (Platform.isLinux || Platform.isWindows) {
      return join(appDir.path, 'ApexNote', 'notes.db');
    }
    return join(appDir.path, 'notes.db');
  }

  static Future<bool> _getMigrationFlag() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final flagFile = File(join(dir.path, '.isar_migrated'));
      return await flagFile.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<void> _setMigrationFlag() async {
    final dir = await getApplicationDocumentsDirectory();
    final flagFile = File(join(dir.path, '.isar_migrated'));
    await flagFile.writeAsString('1');
  }
}
