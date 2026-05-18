// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/core/utils/note_content_utils.dart';
import 'package:sinan_note/models/category.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_version.dart';
import 'package:sinan_note/services/diagnostics/apex_error_manager.dart';
import 'package:sinan_note/services/note_services/note_db_interface.dart';
import 'package:sqflite/sqflite.dart';

class SqliteDatabaseService implements NoteDbInterface {
  static Database? _db;
  static SqliteDatabaseService? _instance;
  static Completer<Database>? _initCompleter;

  static const _dbName = 'sinan_notes.db';
  static const _dbVersion = 4;

  factory SqliteDatabaseService() {
    _instance ??= SqliteDatabaseService._();
    return _instance!;
  }

  static String? _dbPathOverride;

  /// للاختبارات فقط — يُعيد تعيين الـ singleton
  static void resetInstance() {
    _db = null;
    _instance = null;
    _initCompleter = null;
    _dbPathOverride = null;
  }

  /// للاختبارات فقط — يسمح باستخدام ':memory:' لعزل كل اختبار
  static void overrideDbPath(String path) {
    _dbPathOverride = path;
  }

  SqliteDatabaseService._();

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_db != null && _db!.isOpen) return;
    if (_initCompleter != null) {
      // إذا الـ completer مكتمل لكن _db null — أعد التهيئة
      if (_initCompleter!.isCompleted && (_db == null || !_db!.isOpen)) {
        _initCompleter = null;
      } else {
        await _initCompleter!.future;
        return;
      }
    }
    _initCompleter = Completer<Database>();
    try {
      final path = await _dbPath();
      _db = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: (db, _) => _createTables(db),
        onUpgrade: (db, oldVersion, newVersion) async {
          // Always ensure tables exist
          await _createTables(db);
          // v4: add noteType column to note_versions if missing
          if (oldVersion < 4) {
            await _migrateToV4(db);
          }
        },
      );
      _initCompleter!.complete(_db!);
    } catch (e) {
      final c = _initCompleter!;
      _initCompleter = null;
      c.completeError(e);
      rethrow;
    }
  }

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    await initialize();
    if (_db == null || !_db!.isOpen) {
      // إعادة محاولة — قد يكون completer قديم
      _initCompleter = null;
      await initialize();
    }
    return _db!;
  }

  // ── DB Path ───────────────────────────────────────────────────────────────

  /// مسار ملف قاعدة البيانات — مشترك مع BackupService و VaultResetService
  static Future<String> getDbPath() async {
    if (_dbPathOverride != null) return _dbPathOverride!;
    if (Platform.isAndroid) {
      return p.join(await getDatabasesPath(), _dbName);
    }
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbName);
  }

  static Future<String> _dbPath() => getDbPath();

  static Future<void> _createTables(Database db) async {
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _plainContent(String content) =>
      NoteContentUtils.toDisplayText(content);

  static Map<String, dynamic> _noteToMap(Note note) {
    String noteType = note.noteType;
    if (noteType == 'pro' || noteType == 'professional') noteType = 'code';
    return {
      if (note.id != null) 'id': note.id,
      'title': note.title,
      'content': note.content,
      'normalizedTitle': Note.normalize(note.title),
      'normalizedContent': Note.normalize(_plainContent(note.content)),
      'createdAt': note.createdAt.toUtc().toIso8601String(),
      'updatedAt': note.updatedAt.toUtc().toIso8601String(),
      'colorIndex': note.colorIndex.clamp(0, 12),
      'isArchived': note.isArchived ? 1 : 0,
      'isTrashed': note.isTrashed ? 1 : 0,
      'reminderDateTime': note.reminderDateTime?.toUtc().toIso8601String(),
      'isLocked': note.isLocked ? 1 : 0,
      'noteType': noteType,
      'recurrenceRule': note.recurrenceRule,
      'isCompleted': note.isCompleted ? 1 : 0,
      'isProfessional': note.isProfessional ? 1 : 0,
      'isPinned': note.isPinned ? 1 : 0,
      'isChecklist': note.isChecklist ? 1 : 0,
      'categoryIds': note.categoryIds.join(','),
      'isHiddenFromHome': note.isHiddenFromHome ? 1 : 0,
    };
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  @override
  Future<int> insertNote(Note note) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final map = _noteToMap(note)
        ..['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      map.remove('id'); // let AUTOINCREMENT assign
      return await db.insert('notes', map,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }, name: 'InsertNote');
  }

  /// يحافظ على الـ id الأصلي — للمزامنة فقط
  Future<void> upsertNote(Note note) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final map = _noteToMap(note);
      await db.insert('notes', map,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }, name: 'UpsertNote');
  }

  @override
  Future<Note?> getNoteById(int id) async {
    final db = await database;
    final rows = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Note.fromMap(rows.first);
  }

  @override
  Future<List<Note>> getNotes({int? limit, int? offset}) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      return (await db.query(
        'notes',
        where:
            'isArchived=0 AND isTrashed=0 AND isLocked=0 AND isHiddenFromHome=0',
        orderBy: 'isPinned DESC, updatedAt DESC',
        limit: limit,
        offset: offset,
      ))
          .map(Note.fromMap)
          .toList();
    }, name: 'GetNotes');
  }

  @override
  Future<List<Note>> getAllNotes() async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      return (await db.query('notes', orderBy: 'isPinned DESC, updatedAt DESC'))
          .map(Note.fromMap)
          .toList();
    }, name: 'GetAll');
  }

  @override
  Future<List<Note>> getArchivedNotes() async {
    final db = await database;
    return (await db.query('notes',
            where: 'isArchived=1 AND isTrashed=0 AND isLocked=0',
            orderBy: 'updatedAt DESC'))
        .map(Note.fromMap)
        .toList();
  }

  @override
  Future<List<Note>> getTrashedNotes() async {
    final db = await database;
    return (await db.query('notes',
            where: 'isTrashed=1 AND isLocked=0', orderBy: 'updatedAt DESC'))
        .map(Note.fromMap)
        .toList();
  }

  @override
  Future<List<Note>> getLockedNotes() async {
    final db = await database;
    return (await db.query('notes',
            where: 'isLocked=1 AND isTrashed=0', orderBy: 'updatedAt DESC'))
        .map(Note.fromMap)
        .toList();
  }

  @override
  Future<int> updateNote(Note note) async {
    return await ApexErrorManager.monitorDB(() async {
      final db = await database;
      final map = _noteToMap(note)
        ..['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      await db.update('notes', map, where: 'id = ?', whereArgs: [note.id]);
      return note.id!;
    }, name: 'UpdateNote');
  }

  @override
  Future<bool> deleteNote(int id) async {
    return await ApexErrorManager.monitorDB(() async {
      await deleteNoteVersions(id);
      final db = await database;
      final count = await db.delete('notes', where: 'id = ?', whereArgs: [id]);
      if (count > 0) await _recordDeletion(id);
      return count > 0;
    }, name: 'DeleteNote');
  }

  @override
  Future<int> archiveNote(int id) async {
    final db = await database;
    return await db.update(
        'notes',
        {
          'isArchived': 1,
          'updatedAt': DateTime.now().toUtc().toIso8601String()
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  @override
  Future<int> unarchiveNote(int id) async {
    final db = await database;
    return await db.update(
        'notes',
        {
          'isArchived': 0,
          'updatedAt': DateTime.now().toUtc().toIso8601String()
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  @override
  Future<int> trashNote(int id) async {
    final db = await database;
    return await db.update('notes',
        {'isTrashed': 1, 'updatedAt': DateTime.now().toUtc().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> restoreNote(int id) async {
    final db = await database;
    return await db.update(
        'notes',
        {
          'isTrashed': 0,
          'isArchived': 0,
          'updatedAt': DateTime.now().toUtc().toIso8601String()
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  // ── Search ────────────────────────────────────────────────────────────────

  @override
  Future<List<Note>> searchNotes(String query, {int limit = 100}) async {
    final db = await database;
    final normalized = Note.normalize(query);
    final like = '%$normalized%';
    return (await db.query(
      'notes',
      where: 'isLocked=0 AND isTrashed=0 AND '
          '(normalizedTitle LIKE ? OR normalizedContent LIKE ? OR title LIKE ? OR content LIKE ?)',
      whereArgs: [like, like, '%$query%', '%$query%'],
      orderBy: 'updatedAt DESC',
      limit: limit,
    ))
        .map(Note.fromMap)
        .toList();
  }

  // ── Reminders ─────────────────────────────────────────────────────────────

  @override
  Future<List<Note>> getUpcomingReminders() async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    return (await db.query(
      'notes',
      where: 'reminderDateTime IS NOT NULL AND reminderDateTime > ? '
          'AND recurrenceRule IS NULL AND isTrashed=0 AND isLocked=0',
      whereArgs: [now],
      orderBy: 'reminderDateTime ASC',
    ))
        .map(Note.fromMap)
        .toList();
  }

  @override
  Future<List<Note>> getNotesForWidget() async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    return (await db.query(
      'notes',
      where: 'reminderDateTime IS NOT NULL AND reminderDateTime > ? '
          'AND isLocked=0 AND isTrashed=0',
      whereArgs: [now],
      orderBy: 'reminderDateTime ASC',
      limit: 5,
    ))
        .map(Note.fromMap)
        .toList();
  }

  @override
  Future<List<Note>> getScheduledReminders() async {
    final db = await database;
    return (await db.query(
      'notes',
      where: 'recurrenceRule IS NOT NULL AND isTrashed=0 AND isLocked=0',
      orderBy: 'reminderDateTime ASC',
    ))
        .map(Note.fromMap)
        .toList();
  }

  @override
  Future<List<Note>> getExpiredReminders() async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();
    return (await db.query(
      'notes',
      where: 'reminderDateTime IS NOT NULL AND reminderDateTime < ? '
          'AND isTrashed=0 AND isLocked=0',
      whereArgs: [now],
      orderBy: 'reminderDateTime DESC',
    ))
        .map(Note.fromMap)
        .toList();
  }

  // ── Version Control ───────────────────────────────────────────────────────

  static const int _maxVersionsPerNote = 5;

  @override
  Future<void> logNoteVersion(NoteVersion version) async {
    final db = await database;
    await db.insert('note_versions', {
      'noteId': version.noteId,
      'title': version.title,
      'content': version.content,
      'timestamp': version.timestamp.toUtc().toIso8601String(),
      'action': version.action,
      'noteType': version.noteType,
    });
    await keepMaxVersions(version.noteId, _maxVersionsPerNote);
  }

  @override
  Future<List<NoteVersion>> getNoteHistory(int noteId) async {
    final db = await database;
    return (await db.query('note_versions',
            where: 'noteId = ?',
            whereArgs: [noteId],
            orderBy: 'timestamp DESC'))
        .map(_versionFromMap)
        .toList();
  }

  @override
  Future<NoteVersion?> getLastNoteVersion(int noteId) async {
    final db = await database;
    final rows = await db.query('note_versions',
        where: 'noteId = ?',
        whereArgs: [noteId],
        orderBy: 'timestamp DESC',
        limit: 1);
    return rows.isEmpty ? null : _versionFromMap(rows.first);
  }

  @override
  Future<void> keepMaxVersions(int noteId, int maxLimit) async {
    final db = await database;
    final rows = await db.query('note_versions',
        where: 'noteId = ?', whereArgs: [noteId], orderBy: 'timestamp DESC');
    if (rows.length > maxLimit) {
      final toDelete = rows.skip(maxLimit).map((r) => r['id'] as int).toList();
      await db.delete('note_versions',
          where: 'id IN (${toDelete.map((_) => '?').join(',')})',
          whereArgs: toDelete);
    }
  }

  @override
  Future<int> deleteNoteVersions(int noteId) async {
    final db = await database;
    return await db
        .delete('note_versions', where: 'noteId = ?', whereArgs: [noteId]);
  }

  NoteVersion _versionFromMap(Map<String, dynamic> m) {
    return NoteVersion.create(
      noteId: m['noteId'] as int,
      title: m['title'] as String,
      content: m['content'] as String,
      timestamp: DateTime.parse(m['timestamp'] as String),
      action: m['action'] as String? ?? 'updated',
      noteType: m['noteType'] as String? ?? 'simple',
    )..id = m['id'] as int;
  }

  // ── Categories ────────────────────────────────────────────────────────────

  @override
  Future<List<NoteCategory>> getAllCategories() async {
    final db = await database;
    return (await db.query('categories', orderBy: 'sortOrder ASC'))
        .map(_categoryFromMap)
        .toList();
  }

  @override
  Future<int> insertCategory(NoteCategory cat) async {
    final db = await database;
    final map = {'name': cat.name, 'sortOrder': cat.sortOrder};
    if (cat.id != 0) map['id'] = cat.id as Object;
    return await db.insert('categories', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateCategory(NoteCategory cat) async {
    final db = await database;
    await db.update(
        'categories', {'name': cat.name, 'sortOrder': cat.sortOrder},
        where: 'id = ?', whereArgs: [cat.id]);
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  NoteCategory _categoryFromMap(Map<String, dynamic> m) => NoteCategory(
        id: m['id'] as int,
        name: m['name'] as String,
        sortOrder: m['sortOrder'] as int? ?? 0,
      );

  // ── Deleted IDs (sync) ────────────────────────────────────────────────────

  static Future<void> _recordDeletion(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('deleted_note_ids') ?? [];
    final entry = '$id:${DateTime.now().millisecondsSinceEpoch}';
    if (!existing.any((e) => e.startsWith('$id:'))) {
      existing.add(entry);
      if (existing.length > 1000) {
        existing.removeRange(0, existing.length - 1000);
      }
      await prefs.setStringList('deleted_note_ids', existing);
    }
  }

  static Future<Map<int, DateTime>> getDeletedNoteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('deleted_note_ids') ?? [];
    final map = <int, DateTime>{};
    for (final e in list) {
      final parts = e.split(':');
      if (parts.length == 2) {
        final id = int.tryParse(parts[0]);
        final ms = int.tryParse(parts[1]);
        if (id != null && ms != null) {
          map[id] = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }
    }
    return map;
  }

  static Future<void> cleanOldDeletions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('deleted_note_ids') ?? [];
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;
    final filtered = list.where((e) {
      final parts = e.split(':');
      final ms = int.tryParse(parts.length == 2 ? parts[1] : '');
      return ms != null && ms > cutoff;
    }).toList();
    await prefs.setStringList('deleted_note_ids', filtered);
  }

  // ── Misc ──────────────────────────────────────────────────────────────────

  @override
  Future<void> closeDB() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
    _initCompleter = null;
  }

  @override
  Future<void> reopenDatabase() async {
    await closeDB();
    _initCompleter = null;
    await initialize();
  }

  @override
  Future<void> runLegacyHistoryCleanup() async {}
}

