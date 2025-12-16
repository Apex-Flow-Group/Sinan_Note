// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../models/note_version.dart';
import 'apex_error_manager.dart';

class DatabaseService {
  static Database? _database;
  static bool _isInitializing = false;

  Future<Database> get database async {
    // If database is closed, reopen it
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    
    // Prevent concurrent initialization
    if (_isInitializing) {
      // Wait for initialization to complete
      int attempts = 0;
      while (_isInitializing && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      if (_database != null && _database!.isOpen) {
        return _database!;
      }
    }
    
    _isInitializing = true;
    try {
      _database = await _initDB();
      return _database!;
    } finally {
      _isInitializing = false;
    }
  }

  Future<Database> _initDB() async {
    await _migrateOldDatabase();

    String dbPath;
    if (Platform.isLinux || Platform.isWindows) {
      final appDir = await getApplicationDocumentsDirectory();
      dbPath = join(appDir.path, 'ApexNote', 'notes.db');
      await Directory(dirname(dbPath)).create(recursive: true);
    } else {
      dbPath = join(await getDatabasesPath(), 'notes.db');
    }
    String path = dbPath;
    return await openDatabase(
      path,
      version: 8,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            createdAt TEXT,
            updatedAt TEXT,
            colorValue INTEGER,
            colorIndex INTEGER DEFAULT 0,
            isArchived INTEGER DEFAULT 0,
            isTrashed INTEGER DEFAULT 0,
            reminderDateTime TEXT,
            passwordHash TEXT,
            isLocked INTEGER DEFAULT 0,
            noteType TEXT DEFAULT 'simple',
            recurrenceRule TEXT,
            isCompleted INTEGER DEFAULT 0,
            isProfessional INTEGER DEFAULT 0,
            isPinned INTEGER DEFAULT 0,
            isChecklist INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS note_versions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            note_id INTEGER,
            title TEXT,
            content TEXT,
            timestamp TEXT,
            action TEXT,
            FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
          )
        ''');

        // Performance indexes
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_notes_status ON notes(isLocked, isTrashed, isArchived)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_notes_reminder ON notes(reminderDateTime)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_notes_updated ON notes(updatedAt)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_notes_pinned ON notes(isPinned)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_versions_note ON note_versions(note_id)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Version 1 -> 2: Add password and lock columns
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE notes ADD COLUMN passwordHash TEXT');
          } catch (e) {
            // Column already exists, skip
          }
          try {
            await db.execute(
                'ALTER TABLE notes ADD COLUMN isLocked INTEGER DEFAULT 0');
          } catch (e) {
            // Column already exists, skip
          }
        }

        // Version 2 -> 3: Add noteType column
        if (oldVersion < 3) {
          try {
            await db.execute(
                'ALTER TABLE notes ADD COLUMN noteType TEXT DEFAULT "simple"');
          } catch (e) {
            // Column already exists, skip
          }
        }

        // Version 3 -> 4: Add note_versions table
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS note_versions(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              note_id INTEGER,
              title TEXT,
              content TEXT,
              timestamp TEXT,
              action TEXT,
              FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
            )
          ''');
        }

        // Version 4 -> 5: Add advanced reminder columns
        if (oldVersion < 5) {
          try {
            await db
                .execute('ALTER TABLE notes ADD COLUMN recurrenceRule TEXT');
          } catch (e) {
            // Column already exists
          }
          try {
            await db.execute(
                'ALTER TABLE notes ADD COLUMN isCompleted INTEGER DEFAULT 0');
          } catch (e) {
            // Column already exists
          }
          try {
            await db.execute(
                'ALTER TABLE notes ADD COLUMN isProfessional INTEGER DEFAULT 0');
          } catch (e) {
            // Column already exists
          }
        }

        // Version 5 -> 6: Add isPinned column
        if (oldVersion < 6) {
          try {
            await db.execute(
                'ALTER TABLE notes ADD COLUMN isPinned INTEGER DEFAULT 0');
          } catch (e) {
            // Column already exists
          }
        }

        // Version 6 -> 7: Add isChecklist column
        if (oldVersion < 7) {
          try {
            await db.execute(
                'ALTER TABLE notes ADD COLUMN isChecklist INTEGER DEFAULT 0');
          } catch (e) {
            // Column already exists
          }

          // Add performance indexes if upgrading from old version
          try {
            await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_notes_status ON notes(isLocked, isTrashed, isArchived)');
            await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_notes_reminder ON notes(reminderDateTime)');
            await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_notes_updated ON notes(updatedAt)');
            await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_notes_pinned ON notes(isPinned)');
            await db.execute(
                'CREATE INDEX IF NOT EXISTS idx_versions_note ON note_versions(note_id)');
          } catch (e) {
            // Indexes already exist
          }
        }

        // Version 7 -> 8: Add colorIndex column (DATA RESCUE MIGRATION)
        if (oldVersion < 8) {
          try {
            await db.execute(
                'ALTER TABLE notes ADD COLUMN colorIndex INTEGER DEFAULT 0');
            if (kDebugMode) {
              print('✅ Migration: colorIndex column added successfully');
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ colorIndex column already exists: $e');
            }
          }
        }
      },
    );
  }

  Future<int> insertNote(Note note) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      // تحديث updatedAt لضمان ظهور النوت في المقدمة
      final noteMap = note.toMap();
      noteMap['updatedAt'] = DateTime.now().toIso8601String();
      return await db.insert('notes', noteMap);
    }, name: 'Insert_${note.id}');
  }

  Future<Note?> getNoteById(int id) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return maps.isNotEmpty ? Note.fromMap(maps.first) : null;
    }, name: 'GetById_$id');
  }

  Future<List<Note>> getNotes({int? limit, int? offset}) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: 'isArchived = ? AND isTrashed = ? AND isLocked = ?',
        whereArgs: [0, 0, 0],
        orderBy: 'isPinned DESC, updatedAt DESC',
        limit: limit,
        offset: offset,
      );
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    }, name: 'GetNotes');
  }

  Future<List<Note>> getAllNotes() async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        orderBy: 'isPinned DESC, updatedAt DESC',
      );
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    }, name: 'GetAll');
  }

  Future<List<Note>> getArchivedNotes() async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: 'isArchived = ? AND isTrashed = ? AND isLocked = ?',
        whereArgs: [1, 0, 0],
        orderBy: 'updatedAt DESC',
      );
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    }, name: 'GetArchived');
  }

  Future<List<Note>> getTrashedNotes() async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: 'isTrashed = ? AND isLocked = ?',
        whereArgs: [1, 0],
        orderBy: 'updatedAt DESC',
      );
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    }, name: 'GetTrashed');
  }

  // SECURITY: Locked notes - Only accessible from LockedNotesScreen
  Future<List<Note>> getLockedNotes() async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where: 'isLocked = ? AND isTrashed = 0',
        whereArgs: [1],
        orderBy: 'updatedAt DESC',
      );
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    }, name: 'GetLocked');
  }

  Future<int> archiveNote(int id) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      return await db.update('notes',
          {'isArchived': 1, 'updatedAt': DateTime.now().toIso8601String()},
          where: 'id = ?', whereArgs: [id]);
    }, name: 'Archive_$id');
  }

  Future<int> unarchiveNote(int id) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      return await db.update(
        'notes',
        {'isArchived': 0, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }, name: 'Unarchive_$id');
  }

  Future<int> trashNote(int id) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      return await db.update('notes',
          {'isTrashed': 1, 'updatedAt': DateTime.now().toIso8601String()},
          where: 'id = ?', whereArgs: [id]);
    }, name: 'Trash_$id');
  }

  Future<int> restoreNote(int id) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      return await db.update('notes',
          {'isTrashed': 0, 'updatedAt': DateTime.now().toIso8601String()},
          where: 'id = ?', whereArgs: [id]);
    }, name: 'Restore_$id');
  }

  Future<int> updateNote(Note note) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      // تحديث updatedAt لضمان ظهور النوت في المقدمة
      final noteMap = note.toMap();
      noteMap['updatedAt'] = DateTime.now().toIso8601String();
      return await db
          .update('notes', noteMap, where: 'id = ?', whereArgs: [note.id]);
    }, name: 'Update_${note.id}');
  }

  Future<int> deleteNote(int id) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    }, name: 'Delete_$id');
  }

  Future<void> logNoteVersion(NoteVersion version) async {
    await ApexErrorManager.monitorDB(() async {
      final db = await database;
      await db.insert('note_versions', version.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }, name: 'LogVersion_${version.noteId}');
  }

  Future<List<NoteVersion>> getNoteHistory(int noteId) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'note_versions',
        where: 'note_id = ?',
        whereArgs: [noteId],
        orderBy: 'timestamp DESC',
      );
      return List.generate(maps.length, (i) => NoteVersion.fromMap(maps[i]));
    }, name: 'GetHistory_$noteId');
  }

  /// Get last version only (for smart version control)
  Future<NoteVersion?> getLastNoteVersion(int noteId) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final res = await db.query(
        'note_versions',
        where: 'note_id = ?',
        whereArgs: [noteId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );
      if (res.isNotEmpty) return NoteVersion.fromMap(res.first);
      return null;
    }, name: 'GetLastVersion_$noteId');
  }

  /// Smart pruning: Keep only newest X versions
  Future<void> keepMaxVersions(int noteId, int maxLimit) async {
    await ApexErrorManager.monitorDB(() async {
      final db = await database;
      await db.rawDelete('''
        DELETE FROM note_versions 
        WHERE note_id = ? 
        AND id NOT IN (
          SELECT id FROM note_versions 
          WHERE note_id = ? 
          ORDER BY timestamp DESC 
          LIMIT ?
        )
      ''', [noteId, noteId, maxLimit]);
    }, name: 'PruneVersions_$noteId');
  }

  Future<void> _migrateOldDatabase() async {
    try {
      final dbDir = await getDatabasesPath();
      final newPath = join(dbDir, 'notes.db');

      // List of old database names to check (in priority order)
      final oldDatabaseNames = [
        'apex_notes.db', // Legacy name
        'sinan_notes.db', // Alternative name
        'my_notes.db', // Generic name
        'app.db', // Common generic name
        'old_notes.db', // Backup name
        'notes_backup.db', // Backup variant
      ];

      final newFile = File(newPath);

      // Only migrate if new database doesn't exist
      if (!await newFile.exists()) {
        for (final oldName in oldDatabaseNames) {
          final oldPath = join(dbDir, oldName);
          final oldFile = File(oldPath);

          if (await oldFile.exists()) {
            // Verify old database is valid SQLite file
            try {
              final testDb = await openDatabase(oldPath, readOnly: true);
              await testDb.close();

              // Copy to new location
              await oldFile.copy(newPath);
              if (kDebugMode) {
                print('✓ Data migrated from $oldName to notes.db');
              }

              // Delete old file after successful migration
              try {
                await oldFile.delete();
                if (kDebugMode) {
                  print('✓ Old database $oldName removed');
                }
              } catch (e) {
                if (kDebugMode) {
                  print('⚠ Could not delete old database: $e');
                }
              }
              break; // Stop after first successful migration
            } catch (e) {
              if (kDebugMode) {
                print('⚠ Skipping invalid database $oldName: $e');
              }
              continue; // Try next database
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration check: $e');
      }
    }
  }

  // Advanced Reminder Methods
  Future<List<Note>> getUpcomingReminders() async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where:
            'noteType = ? AND reminderDateTime > ? AND recurrenceRule IS NULL AND isTrashed = 0 AND isLocked = 0',
        whereArgs: ['reminder', now],
        orderBy: 'reminderDateTime ASC',
      );
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    }, name: 'GetUpcomingReminders');
  }

  // SECURITY: Get reminders for widget (excludes locked notes)
  Future<List<Note>> getNotesForWidget() async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where:
            'noteType = ? AND reminderDateTime > ? AND isLocked = 0 AND isTrashed = 0',
        whereArgs: ['reminder', now],
        orderBy: 'reminderDateTime ASC',
        limit: 5,
      );
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    }, name: 'GetWidget');
  }

  Future<List<Note>> getScheduledReminders() async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where:
            'noteType = ? AND recurrenceRule IS NOT NULL AND isTrashed = 0 AND isLocked = 0',
        whereArgs: ['reminder'],
        orderBy: 'reminderDateTime ASC',
      );
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    }, name: 'GetScheduled');
  }

  Future<List<Note>> getExpiredReminders() async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where:
            'noteType = ? AND reminderDateTime < ? AND isTrashed = 0 AND isLocked = 0',
        whereArgs: ['reminder', now],
        orderBy: 'reminderDateTime DESC',
      );
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    }, name: 'GetExpired');
  }

  // SECURITY: Search notes - Excludes locked notes
  Future<List<Note>> searchNotes(String query) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notes',
        where:
            'isLocked = 0 AND isTrashed = 0 AND (title LIKE ? OR content LIKE ?)',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'updatedAt DESC',
      );
      return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
    }, name: 'Search');
  }

  Future<int> deleteNoteVersions(int noteId) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      return await db
          .delete('note_versions', where: 'note_id = ?', whereArgs: [noteId]);
    }, name: 'DeleteVersions_$noteId');
  }

  Future<void> closeDB() async {
    if (_database != null && _database!.isOpen) {
      try {
        await _database!.close();
      } catch (e) {
        debugPrint('⚠ Error closing database: $e');
      }
      _database = null;
    }
  }

  /// Force reopen database after file replacement
  /// CRITICAL: Must be called after replaceDatabase() operation
  Future<void> reopenDatabase() async {
    if (_database != null) {
      try {
        await _database!.close();
      } catch (e) {
        debugPrint('⚠ Error closing old database: $e');
      }
      _database = null;
    }
    // Force reinitialization
    _database = await _initDB();
    debugPrint('✓ Database reopened successfully');
  }

  /// One-time legacy history cleanup (Deep Clean Operation)
  /// Removes old versions for notes with >20 versions
  Future<void> runLegacyHistoryCleanup() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if cleanup already done
    bool isCleaned = prefs.getBool('is_legacy_history_cleaned_v1') ?? false;
    if (isCleaned) return;

    if (kDebugMode) print('🧹 Starting legacy history cleanup...');
    final db = await database;

    try {
      // Find notes with >20 versions
      final List<Map<String, dynamic>> targetNotes = await db.rawQuery('''
        SELECT note_id, COUNT(*) as count 
        FROM note_versions 
        GROUP BY note_id 
        HAVING count > 20
      ''');

      if (targetNotes.isEmpty) {
        if (kDebugMode) print('✅ No cleanup needed');
        await prefs.setBool('is_legacy_history_cleaned_v1', true);
        return;
      }

      if (kDebugMode) print('⚠️ Found ${targetNotes.length} notes with excess versions. Cleaning...');

      // Batch cleanup using transaction
      await db.transaction((txn) async {
        for (var row in targetNotes) {
          int noteId = row['note_id'];
          await txn.rawDelete('''
            DELETE FROM note_versions 
            WHERE note_id = ? 
            AND id NOT IN (
              SELECT id FROM note_versions 
              WHERE note_id = ? 
              ORDER BY timestamp DESC 
              LIMIT 20
            )
          ''', [noteId, noteId]);
        }
      });

      if (kDebugMode) print('🎉 Database cleanup completed successfully!');
      await prefs.setBool('is_legacy_history_cleaned_v1', true);
    } catch (e) {
      if (kDebugMode) print('❌ Cleanup error: $e');
    }
  }
}
