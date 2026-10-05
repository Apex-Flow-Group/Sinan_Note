// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// مخطط قاعدة الملاحظات وترحيلاتها — المصدر الوحيد لبنية الجداول.
abstract final class NotesSchema {
  static const version = 6;

  static Future<void> create(Database db) async {
    await _createTables(db);
    await _createUuidIndex(db);
  }

  static Future<void> upgrade(Database db, int from) async {
    // الجداول الناقصة أولاً (بلا فهرس uuid: العمود يُضاف في v6)
    await _createTables(db);
    if (from < 4) await _migrateToV4(db);
    if (from < 5) await _migrateToV5(db);
    if (from < 6) await _migrateToV6(db);
  }

  /// الملاحظة المقفلة لا تُحفظ لها نسخ نصية واضحة. يحذف ما تركته الإصدارات
  /// السابقة (القفل لم يكن يحذف السجل) — رخيص ومتكرر بأمان.
  static Future<void> onOpen(Database db) async {
    await db.delete('note_versions',
        where: 'noteId IN (SELECT id FROM notes WHERE isLocked = 1)');
  }

  static Future<void> _createTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        title             TEXT    NOT NULL DEFAULT '',
        content           TEXT    NOT NULL DEFAULT '',
        normalizedTitle   TEXT    NOT NULL DEFAULT '',
        normalizedContent TEXT    NOT NULL DEFAULT '',
        createdAt         TEXT    NOT NULL,
        updatedAt         TEXT    NOT NULL,
        colorIndex        INTEGER NOT NULL DEFAULT 0,
        isArchived        INTEGER NOT NULL DEFAULT 0,
        isTrashed         INTEGER NOT NULL DEFAULT 0,
        reminderDateTime  TEXT,
        isLocked          INTEGER NOT NULL DEFAULT 0,
        uuid              TEXT    NOT NULL DEFAULT '',
        noteType          TEXT    NOT NULL DEFAULT 'simple',
        recurrenceRule    TEXT,
        isCompleted       INTEGER NOT NULL DEFAULT 0,
        isProfessional    INTEGER NOT NULL DEFAULT 0,
        isPinned          INTEGER NOT NULL DEFAULT 0,
        isChecklist       INTEGER NOT NULL DEFAULT 0,
        categoryIds       TEXT    NOT NULL DEFAULT '',
        isHiddenFromHome  INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT    NOT NULL,
        sortOrder INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_versions (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        noteId    INTEGER NOT NULL,
        title     TEXT    NOT NULL DEFAULT '',
        content   TEXT    NOT NULL DEFAULT '',
        timestamp TEXT    NOT NULL,
        action    TEXT    NOT NULL DEFAULT 'updated',
        noteType  TEXT    NOT NULL DEFAULT 'simple'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deleted_notes (
        noteId    INTEGER PRIMARY KEY,
        deletedAt INTEGER NOT NULL
      )
    ''');
    // Indexes
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_updated   ON notes (updatedAt DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_pinned    ON notes (isPinned DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_notes_reminder  ON notes (reminderDateTime)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_versions_noteId ON note_versions (noteId)');
  }

  /// v6: هوية ثابتة لكل ملاحظة (uuid) — المطابقة بين الأجهزة والنسخ
  /// الاحتياطية بها بدل رقم الصف المحلي. داخل transaction واحدة.
  static Future<void> _migrateToV6(Database db) async {
    await db.transaction((txn) async {
      final cols = await txn.rawQuery('PRAGMA table_info(notes)');
      if (!cols.any((c) => c['name'] == 'uuid')) {
        await txn.execute(
            "ALTER TABLE notes ADD COLUMN uuid TEXT NOT NULL DEFAULT ''");
      }
      final rows =
          await txn.query('notes', columns: ['id'], where: "uuid = ''");
      final batch = txn.batch();
      for (final row in rows) {
        batch.update('notes', {'uuid': const Uuid().v4()},
            where: 'id = ?', whereArgs: [row['id']]);
      }
      await batch.commit(noResult: true);
      await _createUuidIndex(txn);
    });
  }

  static Future<void> _migrateToV5(Database db) async {
    try {
      await db.execute(
        "UPDATE notes SET isHiddenFromHome = 0 WHERE isHiddenFromHome = 1 AND (categoryIds IS NULL OR categoryIds = '')",
      );
    } catch (_) {}
  }

  /// v4 migration: add noteType column to note_versions if it doesn't exist.
  /// Needed for devices that had the old NativeDbMigrationService schema.
  static Future<void> _migrateToV4(Database db) async {
    try {
      final cols = await db.rawQuery('PRAGMA table_info(note_versions)');
      final hasNoteType = cols.any((c) => c['name'] == 'noteType');
      if (!hasNoteType) {
        await db.execute(
          "ALTER TABLE note_versions ADD COLUMN noteType TEXT NOT NULL DEFAULT 'simple'",
        );
      }
    } catch (_) {
      // If migration fails, the table will be recreated on next onCreate
    }
  }

  static Future<void> _createUuidIndex(DatabaseExecutor db) => db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_notes_uuid ON notes (uuid)');
}
