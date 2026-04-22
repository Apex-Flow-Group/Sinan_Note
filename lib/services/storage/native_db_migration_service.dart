// Copyright © 2025 Apex Flow Group. All rights reserved.
//
// NativeDbMigrationService
// يقرأ كل الملاحظات من Isar ويكتبها في sinan_notes.db (SQLite)
// بنفس schema الـ React Native — يعمل مرة واحدة فقط
//
// المسار الذي يكتب فيه:
//   Android: /data/data/<pkg>/databases/sinan_notes.db
// وهو نفس المسار الذي يفتحه op-sqlite في Native تلقائياً.

import 'dart:io';

import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class NativeDbMigrationService {
  static const _doneKey = 'native_db_migration_v2_done';
  static const _dbName  = 'sinan_notes.db';

  /// يُشغَّل مرة واحدة فقط — آمن للاستدعاء في كل مرة
  static Future<int> runIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_doneKey) == true) return 0;

    try {
      final count = await _migrate();
      await prefs.setBool(_doneKey, true);
      return count;
    } catch (e) {
      // silent fail — لا نوقف التطبيق
      await prefs.setBool(_doneKey, true);
      return 0;
    }
  }

  static Future<int> _migrate() async {
    final isarService = IsarDatabaseService();
    final notes      = await isarService.getAllNotes();
    final categories = await isarService.getAllCategories();
    final deletedIds = await IsarDatabaseService.getDeletedNoteIds();

    final dbPath = await _getDbPath();
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(_createNotesSql);
        await db.execute(_createCategoriesSql);
        await db.execute(_createDeletedNotesSql);
        await db.execute(_createNoteVersionsSql);
      },
    );

    // تأكد من وجود الجداول حتى لو كانت قاعدة البيانات موجودة مسبقاً
    await db.execute(_createNotesSql);
    await db.execute(_createCategoriesSql);
    await db.execute(_createDeletedNotesSql);
    await db.execute(_createNoteVersionsSql);

    int count = 0;
    await db.transaction((txn) async {
      // 1. النوتات
      for (final note in notes) {
        await txn.insert('notes', _noteToMap(note),
            conflictAlgorithm: ConflictAlgorithm.ignore);
        count++;
      }
      // 2. الكتالوجات
      for (final cat in categories) {
        await txn.insert(
          'categories',
          {'id': cat.id, 'name': cat.name, 'sortOrder': cat.sortOrder},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      // 3. سجلات الحذف
      for (final entry in deletedIds.entries) {
        await txn.insert(
          'deleted_notes',
          {'noteId': entry.key, 'deletedAt': entry.value.millisecondsSinceEpoch},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });

    await db.close();
    return count;
  }

  /// مسار databases — نفس ما يستخدمه op-sqlite في Native
  static Future<String> _getDbPath() async {
    if (Platform.isAndroid) {
      // op-sqlite يفتح من getDatabasesPath() مباشرة
      final dbDir = await getDatabasesPath();
      return p.join(dbDir, _dbName);
    }
    // iOS: Documents directory
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbName);
  }

  /// نفس CREATE TABLEs في DatabaseService.ts
  static const _createNotesSql = '''
    CREATE TABLE IF NOT EXISTS notes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL DEFAULT '',
      normalizedTitle TEXT NOT NULL DEFAULT '',
      normalizedContent TEXT NOT NULL DEFAULT '',
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      colorIndex INTEGER NOT NULL DEFAULT 0,
      isArchived INTEGER NOT NULL DEFAULT 0,
      isTrashed INTEGER NOT NULL DEFAULT 0,
      reminderDateTime TEXT,
      isLocked INTEGER NOT NULL DEFAULT 0,
      noteType TEXT NOT NULL DEFAULT 'simple',
      recurrenceRule TEXT,
      isCompleted INTEGER NOT NULL DEFAULT 0,
      isProfessional INTEGER NOT NULL DEFAULT 0,
      isPinned INTEGER NOT NULL DEFAULT 0,
      isChecklist INTEGER NOT NULL DEFAULT 0,
      categoryIds TEXT NOT NULL DEFAULT '',
      isHiddenFromHome INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const _createCategoriesSql = '''
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      sortOrder INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const _createDeletedNotesSql = '''
    CREATE TABLE IF NOT EXISTS deleted_notes (
      noteId INTEGER PRIMARY KEY,
      deletedAt INTEGER NOT NULL
    )
  ''';

  static const _createNoteVersionsSql = '''
    CREATE TABLE IF NOT EXISTS note_versions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      noteId INTEGER NOT NULL,
      title TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL DEFAULT '',
      timestamp TEXT NOT NULL,
      action TEXT NOT NULL DEFAULT 'updated'
    )
  ''';

  static Map<String, dynamic> _noteToMap(dynamic note) {
    // تحويل noteType مطابق لـ noteModeFromDb في Native
    String noteType = note.noteType ?? 'simple';
    if (noteType == 'pro' || noteType == 'professional') noteType = 'code';

    return {
      'id':               note.id,
      'title':            note.title ?? '',
      'content':          note.content ?? '',
      'normalizedTitle':  _normalize(note.title ?? ''),
      'normalizedContent': _normalize(note.content ?? ''),
      'createdAt':        note.createdAt.toUtc().toIso8601String(),
      'updatedAt':        note.updatedAt.toUtc().toIso8601String(),
      'colorIndex':       (note.colorIndex as int).clamp(0, 11),
      'isArchived':       note.isArchived == true ? 1 : 0,
      'isTrashed':        note.isTrashed  == true ? 1 : 0,
      'reminderDateTime': note.reminderDateTime?.toUtc().toIso8601String(),
      'isLocked':         note.isLocked   == true ? 1 : 0,
      'noteType':         noteType,
      'recurrenceRule':   note.recurrenceRule,
      'isCompleted':      note.isCompleted    == true ? 1 : 0,
      'isProfessional':   note.isProfessional == true ? 1 : 0,
      'isPinned':         note.isPinned       == true ? 1 : 0,
      'isChecklist':      note.isChecklist    == true ? 1 : 0,
      'categoryIds':      (note.categoryIds as List?)?.join(',') ?? '',
      'isHiddenFromHome': note.isHiddenFromHome == true ? 1 : 0,
    };
  }

  /// نفس normalizeArabic في Native
  static String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase();
  }
}
