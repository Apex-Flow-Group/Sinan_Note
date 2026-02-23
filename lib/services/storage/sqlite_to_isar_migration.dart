// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SqliteToIsarMigration {
  static Future<void> migrateIfNeeded() async {
    try {
      final dbPath = await _getSqlitePath();
      
      if (!await File(dbPath).exists()) {
        return;
      }
      
      if (await _getMigrationFlag()) {
        return;
      }

      await _migrateEncryptionKey();
      await _performMigration(dbPath);
      await _setMigrationFlag();
      
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> _performMigration(String dbPath) async {
    final db = await openDatabase(dbPath, readOnly: true);
    final isarDb = IsarDatabaseService();
    
    int successCount = 0;
    int errorCount = 0;
    
    try {
      final maps = await db.query('notes');
      debugPrint('🔄 Starting migration of ${maps.length} notes...');
      
      for (final map in maps) {
        try {
          String content = map['content'] as String? ?? '';
          String title = map['title'] as String? ?? '';
          bool isChecklist = (map['isChecklist'] as int? ?? 0) == 1 || (map['is_checklist'] as int? ?? 0) == 1;
          String? passwordHash = map['passwordHash'] as String?;
          
          // Detect encrypted content
          bool hasEncryptedContent = false;
          try {
            hasEncryptedContent = VaultService.isEncrypted(content);
            if (hasEncryptedContent) {
              debugPrint('🔒 Detected encrypted content for note: $title');
            }
          } catch (e) {
            debugPrint('⚠️ Encryption detection failed for note: $title, falling back to passwordHash logic: $e');
            hasEncryptedContent = false;
          }
          
          bool hasPasswordHash = passwordHash != null && passwordHash.isNotEmpty;
          
          // Set isLocked if content is encrypted OR passwordHash exists
          bool isLocked = hasEncryptedContent || hasPasswordHash;
          
          final note = Note(
            title: title,
            content: content,
            createdAt: _parseDateTime(map, 'createdAt', 'created_at'),
            updatedAt: _parseDateTime(map, 'updatedAt', 'updated_at'),
            colorIndex: map['colorIndex'] as int? ?? map['color_index'] as int? ?? 0,
            isPinned: _parseBool(map, 'isPinned', 'is_pinned'),
            isArchived: _parseBool(map, 'isArchived', 'is_archived'),
            isTrashed: _parseBool(map, 'isTrashed', 'is_trashed'),
            isLocked: isLocked,
            isChecklist: isChecklist,
            reminderDateTime: _parseOptionalDateTime(map, 'reminderDateTime', 'reminder_date_time'),
            recurrenceRule: map['recurrenceRule'] as String? ?? map['recurrence_rule'] as String?,
          );
          
          await isarDb.insertNote(note);
          successCount++;
        } catch (e) {
          errorCount++;
          debugPrint('❌ Failed to migrate note: $e');
          debugPrint('   Note title: ${map['title']}, ID: ${map['id']}');
        }
      }
      
      debugPrint('✅ Migration completed: $successCount succeeded, $errorCount failed');
    } finally {
      await db.close();
    }
  }

  static Future<String> _getSqlitePath() async {
    // On Android, old SQLite was in databases directory
    if (Platform.isAndroid) {
      final databasesPath = await getDatabasesPath();
      return join(databasesPath, 'notes.db');
    }
    // On Linux/Windows
    final appDir = await getApplicationDocumentsDirectory();
    return join(appDir.path, 'ApexNote', 'notes.db');
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

  static Future<void> _migrateEncryptionKey() async {
    // المفتاح موجود بالفعل - نفس package name
  }

  // Helper method for parsing DateTime fields
  static DateTime _parseDateTime(Map<String, dynamic> map, String key1, String key2) {
    final value = map[key1] ?? map[key2];
    if (value != null) {
      try {
        return DateTime.parse(value as String);
      } catch (e) {
        debugPrint('⚠️ Failed to parse DateTime for $key1/$key2: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Helper method for parsing boolean fields
  static bool _parseBool(Map<String, dynamic> map, String key1, String key2) {
    return (map[key1] as int? ?? map[key2] as int? ?? 0) == 1;
  }

  // Helper method for parsing optional DateTime fields
  static DateTime? _parseOptionalDateTime(Map<String, dynamic> map, String key1, String key2) {
    final value = map[key1] ?? map[key2];
    if (value != null) {
      try {
        return DateTime.parse(value as String);
      } catch (e) {
        debugPrint('⚠️ Failed to parse optional DateTime for $key1/$key2: $e');
        return null;
      }
    }
    return null;
  }
}
