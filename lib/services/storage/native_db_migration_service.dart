// Copyright © 2025 Apex Flow Group. All rights reserved.
//
// NativeDbMigrationService
// يقرأ كل البيانات من Isar ويكتبها في sinan_notes.db (SQLite)
// بنفس schema الـ React Native — يعمل عند كل تشغيل (sync كامل)
//
// يشمل: notes, categories, note_versions, deleted_notes, vault_notes

import 'dart:io';

import 'package:apex_note/models/note_version.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class NativeDbMigrationService {
  static const _dbName = 'sinan_notes.db';
  static const _dbVersion = 3;

  /// يُشغَّل عند كل تشغيل — sync كامل من Isar إلى SQLite
  static Future<void> runIfNeeded() async {
    try {
      await _sync();
    } catch (_) {
      // silent fail — لا نوقف التطبيق
    }
  }

  static Future<void> _sync() async {
    final isarService = IsarDatabaseService();

    // جلب كل البيانات من Isar بالتوازي
    final notes      = await isarService.getAllNotes();
    final categories = await isarService.getAllCategories();
    final deletedIds = await IsarDatabaseService.getDeletedNoteIds();
    final versions   = await _getAllVersions(isarService);

    final db = await _openDb();

    try {
      await db.transaction((txn) async {
        // ── 1. Notes (upsert) ─────────────────────────────────────────────
        for (final note in notes) {
          await txn.insert(
            'notes',
            _noteToMap(note),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // ── 2. Categories (upsert) ────────────────────────────────────────
        for (final cat in categories) {
          await txn.insert(
            'categories',
            {
              'id':        cat.id,
              'name':      cat.name,
              'sortOrder': cat.sortOrder,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // ── 3. Deleted notes (upsert) ─────────────────────────────────────
        for (final entry in deletedIds.entries) {
          await txn.insert(
            'deleted_notes',
            {
              'noteId':    entry.key,
              'deletedAt': entry.value.millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // ── 4. Note versions (upsert) ─────────────────────────────────────
        for (final v in versions) {
          await txn.insert(
            'note_versions',
            {
              'id':        v.id,
              'noteId':    v.noteId,
              'title':     v.title,
              'content':   v.content,
              'timestamp': v.timestamp.toUtc().toIso8601String(),
              'action':    v.action,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } finally {
      await db.close();
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static Future<List<NoteVersion>> _getAllVersions(
      IsarDatabaseService isarService) async {
    try {
      // نجلب كل الـ notes ثم versions لكل note
      final notes = await isarService.getAllNotes();
      final allVersions = <NoteVersion>[];
      for (final note in notes) {
        if (note.id != null) {
          final versions = await isarService.getNoteHistory(note.id!);
          allVersions.addAll(versions);
        }
      }
      return allVersions;
    } catch (_) {
      return [];
    }
  }

  static Future<Database> _openDb() async {
    final dbPath = await _getDbPath();
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db); // CREATE TABLE IF NOT EXISTS — آمن دائماً
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute(_createNotesSql);
    await db.execute(_createCategoriesSql);
    await db.execute(_createDeletedNotesSql);
    await db.execute(_createNoteVersionsSql);
  }

  static Future<String> _getDbPath() async {
    if (Platform.isAndroid) {
      final dbDir = await getDatabasesPath();
      return p.join(dbDir, _dbName);
    }
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbName);
  }

  static Map<String, dynamic> _noteToMap(dynamic note) {
    String noteType = note.noteType ?? 'simple';
    if (noteType == 'pro' || noteType == 'professional') noteType = 'code';

    return {
      'id':                note.id,
      'title':             note.title ?? '',
      'content':           note.content ?? '',
      'normalizedTitle':   _normalize(note.title ?? ''),
      'normalizedContent': _normalize(note.content ?? ''),
      'createdAt':         (note.createdAt as DateTime).toUtc().toIso8601String(),
      'updatedAt':         (note.updatedAt as DateTime).toUtc().toIso8601String(),
      'colorIndex':        ((note.colorIndex as int?) ?? 0).clamp(0, 11),
      'isArchived':        note.isArchived == true ? 1 : 0,
      'isTrashed':         note.isTrashed  == true ? 1 : 0,
      'reminderDateTime':  (note.reminderDateTime as DateTime?)?.toUtc().toIso8601String(),
      'isLocked':          note.isLocked   == true ? 1 : 0,
      'noteType':          noteType,
      'recurrenceRule':    note.recurrenceRule,
      'isCompleted':       note.isCompleted    == true ? 1 : 0,
      'isProfessional':    note.isProfessional == true ? 1 : 0,
      'isPinned':          note.isPinned       == true ? 1 : 0,
      'isChecklist':       note.isChecklist    == true ? 1 : 0,
      'categoryIds':       ((note.categoryIds as List?)?.join(',')) ?? '',
      'isHiddenFromHome':  note.isHiddenFromHome == true ? 1 : 0,
    };
  }

  static String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase();
  }

  // ── SQL schemas ────────────────────────────────────────────────────────────

  static const _createNotesSql = '''
    CREATE TABLE IF NOT EXISTS notes (
      id                INTEGER PRIMARY KEY,
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
      noteType          TEXT    NOT NULL DEFAULT 'simple',
      recurrenceRule    TEXT,
      isCompleted       INTEGER NOT NULL DEFAULT 0,
      isProfessional    INTEGER NOT NULL DEFAULT 0,
      isPinned          INTEGER NOT NULL DEFAULT 0,
      isChecklist       INTEGER NOT NULL DEFAULT 0,
      categoryIds       TEXT    NOT NULL DEFAULT '',
      isHiddenFromHome  INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const _createCategoriesSql = '''
    CREATE TABLE IF NOT EXISTS categories (
      id        INTEGER PRIMARY KEY,
      name      TEXT    NOT NULL,
      sortOrder INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const _createDeletedNotesSql = '''
    CREATE TABLE IF NOT EXISTS deleted_notes (
      noteId    INTEGER PRIMARY KEY,
      deletedAt INTEGER NOT NULL
    )
  ''';

  static const _createNoteVersionsSql = '''
    CREATE TABLE IF NOT EXISTS note_versions (
      id        INTEGER PRIMARY KEY,
      noteId    INTEGER NOT NULL,
      title     TEXT    NOT NULL DEFAULT '',
      content   TEXT    NOT NULL DEFAULT '',
      timestamp TEXT    NOT NULL,
      action    TEXT    NOT NULL DEFAULT 'updated'
    )
  ''';
}
