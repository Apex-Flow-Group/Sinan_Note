// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/core/utils/note_content_utils.dart';
import 'package:apex_note/models/category.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_version.dart';
import 'package:apex_note/services/diagnostics/apex_error_manager.dart';
import 'package:apex_note/services/note_services/note_db_interface.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IsarDatabaseService implements NoteDbInterface {
  static Isar? _isar;
  static IsarDatabaseService? _instance;
  static Completer<Isar>? _initCompleter;

  // Singleton
  factory IsarDatabaseService() {
    _instance ??= IsarDatabaseService._();
    return _instance!;
  }

  IsarDatabaseService._();

  static Future<void> initialize() async {
    if (_isar != null && _isar!.isOpen) return;
    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }
    _initCompleter = Completer<Isar>();
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (int i = 0; i < 3; i++) {
        try {
          final existing = Isar.getInstance('sinan_notes');
          if (existing != null && existing.isOpen) {
            _isar = existing;
          } else {
            _isar = await Isar.open(
              [NoteSchema, NoteVersionSchema, NoteCategorySchema],
              directory: dir.path,
              name: 'sinan_notes',
            );
          }
          break;
        } catch (e) {
          if (i == 2) rethrow;
          await Future.delayed(Duration(milliseconds: 300 * (i + 1)));
        }
      }
      _initCompleter!.complete(_isar!);
    } catch (e) {
      final c = _initCompleter!;
      _initCompleter = null;
      c.completeError(e);
      rethrow;
    }
  }

  Future<Isar> get database async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    await IsarDatabaseService.initialize();
    return _isar!;
  }

  // CRUD Operations
  final _writeLock = <String, Completer<void>>{};

  static String _getPlainContent(String content) => NoteContentUtils.toDisplayText(content);

  Future<int> insertNote(Note note) async {
    return await ApexErrorManager.monitorDB(() async {
      note.normalizedTitle = Note.normalize(note.title);
      note.normalizedContent = Note.normalize(_getPlainContent(note.content));

      while (_writeLock.containsKey('insert')) {
        await _writeLock['insert']!.future;
      }
      _writeLock['insert'] = Completer<void>();

      try {
        final isar = await database;
        final id = await isar.writeTxn(() async {
          note.updatedAt = DateTime.now();
          return await isar.notes.put(note);
        });
        return id;
      } finally {
        _writeLock['insert']!.complete();
        _writeLock.remove('insert');
      }
    }, name: 'InsertNote');
  }

  @override
  Future<Note?> getNoteById(int id) async {
    final isar = await database;
    return await isar.notes.get(id);
  }

  Future<List<Note>> getNotes({int? limit, int? offset}) async {
    return await ApexErrorManager.monitorDB(() async {
      final isar = await database;
      var query = isar.notes
          .filter()
          .isArchivedEqualTo(false)
          .isTrashedEqualTo(false)
          .isLockedEqualTo(false)
          .sortByIsPinnedDesc()
          .thenByUpdatedAtDesc();

      if (offset != null && limit != null) {
        return await query.offset(offset).limit(limit).findAll();
      } else if (offset != null) {
        return await query.offset(offset).findAll();
      } else if (limit != null) {
        return await query.limit(limit).findAll();
      }

      return await query.findAll();
    }, name: 'GetNotes');
  }

  Future<List<Note>> getAllNotes() async {
    return await ApexErrorManager.monitorDB(() async {
      final isar = await database;
      return await isar.notes
          .where()
          .sortByIsPinnedDesc()
          .thenByUpdatedAtDesc()
          .findAll();
    }, name: 'GetAll');
  }

  Future<List<Note>> getArchivedNotes() async {
    final isar = await database;
    return await isar.notes
        .filter()
        .isArchivedEqualTo(true)
        .isTrashedEqualTo(false)
        .isLockedEqualTo(false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<List<Note>> getTrashedNotes() async {
    final isar = await database;
    return await isar.notes
        .filter()
        .isTrashedEqualTo(true)
        .isLockedEqualTo(false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  @override
  Future<List<Note>> getLockedNotes() async {
    final isar = await database;
    return await isar.notes
        .filter()
        .isLockedEqualTo(true)
        .isTrashedEqualTo(false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  @override
  Future<int> updateNote(Note note) async {
    return await ApexErrorManager.monitorDB(() async {
      note.normalizedTitle = Note.normalize(note.title);
      note.normalizedContent = Note.normalize(_getPlainContent(note.content));

      final lockKey = 'update_${note.id}';
      while (_writeLock.containsKey(lockKey)) {
        await _writeLock[lockKey]!.future;
      }
      _writeLock[lockKey] = Completer<void>();

      try {
        final isar = await database;
        final id = await isar.writeTxn(() async {
          note.updatedAt = DateTime.now();
          return await isar.notes.put(note);
        });
        return id;
      } finally {
        _writeLock[lockKey]!.complete();
        _writeLock.remove(lockKey);
      }
    }, name: 'UpdateNote');
  }

  Future<bool> deleteNote(int id) async {
    return await ApexErrorManager.monitorDB(() async {
      await deleteNoteVersions(id);
      final isar = await database;
      final deleted = await isar.writeTxn(() async {
        return await isar.notes.delete(id);
      });
      if (deleted) await _recordDeletion(id);
      return deleted;
    }, name: 'DeleteNote');
  }

  /// تسجيل الحذف في SharedPreferences للمزامنة
  static Future<void> _recordDeletion(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('deleted_note_ids') ?? [];
    final entry = '$id:${DateTime.now().millisecondsSinceEpoch}';
    if (!existing.any((e) => e.startsWith('$id:'))) {
      existing.add(entry);
      // احتفظ بآخر 1000 حذف فقط
      if (existing.length > 1000) existing.removeRange(0, existing.length - 1000);
      await prefs.setStringList('deleted_note_ids', existing);
    }
  }

  /// جلب قائمة المحذوفات: {id: deletedAt}
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

  /// مسح سجلات الحذف القديمة (أقدم من 30 يوم)
  static Future<void> cleanOldDeletions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('deleted_note_ids') ?? [];
    final cutoff = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final filtered = list.where((e) {
      final parts = e.split(':');
      final ms = int.tryParse(parts.length == 2 ? parts[1] : '');
      return ms != null && ms > cutoff;
    }).toList();
    await prefs.setStringList('deleted_note_ids', filtered);
  }

  Future<int> archiveNote(int id) async {
    final isar = await database;
    final note = await getNoteById(id);
    if (note == null) return 0;

    note.isArchived = true;
    note.updatedAt = DateTime.now();
    return await isar.writeTxn(() => isar.notes.put(note));
  }

  Future<int> unarchiveNote(int id) async {
    final isar = await database;
    final note = await getNoteById(id);
    if (note == null) return 0;

    note.isArchived = false;
    note.updatedAt = DateTime.now();
    return await isar.writeTxn(() => isar.notes.put(note));
  }

  Future<int> trashNote(int id) async {
    final isar = await database;
    final note = await getNoteById(id);
    if (note == null) return 0;

    note.isTrashed = true;
    note.updatedAt = DateTime.now();
    return await isar.writeTxn(() => isar.notes.put(note));
  }

  Future<int> restoreNote(int id) async {
    final isar = await database;
    final note = await getNoteById(id);
    if (note == null) return 0;

    note.isTrashed = false;
    note.isArchived = false;
    note.updatedAt = DateTime.now();
    return await isar.writeTxn(() => isar.notes.put(note));
  }

  // Search with full-text support and limit
  Future<List<Note>> searchNotes(String query, {int limit = 100}) async {
    final isar = await database;
    return await isar.notes
        .filter()
        .isLockedEqualTo(false)
        .isTrashedEqualTo(false)
        .group((q) => q
            .titleContains(query, caseSensitive: false)
            .or()
            .contentContains(query, caseSensitive: false))
        .sortByUpdatedAtDesc()
        .limit(limit) // ✅ Limit search results
        .findAll();
  }

  // Reminder queries
  Future<List<Note>> getUpcomingReminders() async {
    final isar = await database;
    final now = DateTime.now();
    return await isar.notes
        .filter()
        .reminderDateTimeIsNotNull()
        .reminderDateTimeGreaterThan(now)
        .recurrenceRuleIsNull()
        .isTrashedEqualTo(false)
        .isLockedEqualTo(false)
        .sortByReminderDateTime()
        .findAll();
  }

  Future<List<Note>> getNotesForWidget() async {
    final isar = await database;
    final now = DateTime.now();
    return await isar.notes
        .filter()
        .reminderDateTimeIsNotNull()
        .reminderDateTimeGreaterThan(now)
        .isLockedEqualTo(false)
        .isTrashedEqualTo(false)
        .sortByReminderDateTime()
        .limit(5)
        .findAll();
  }

  Future<List<Note>> getScheduledReminders() async {
    final isar = await database;
    return await isar.notes
        .filter()
        .recurrenceRuleIsNotNull()
        .isTrashedEqualTo(false)
        .isLockedEqualTo(false)
        .sortByReminderDateTime()
        .findAll();
  }

  Future<List<Note>> getExpiredReminders() async {
    final isar = await database;
    final now = DateTime.now();
    return await isar.notes
        .filter()
        .reminderDateTimeIsNotNull()
        .reminderDateTimeLessThan(now)
        .isTrashedEqualTo(false)
        .isLockedEqualTo(false)
        .sortByReminderDateTimeDesc()
        .findAll();
  }

  // Version control
  Future<void> logNoteVersion(NoteVersion version) async {
    final isar = await database;
    await isar.writeTxn(() async {
      await isar.noteVersions.put(version);
    });
    await keepMaxVersions(version.noteId, 50);
  }

  Future<List<NoteVersion>> getNoteHistory(int noteId) async {
    final isar = await database;
    return await isar.noteVersions
        .filter()
        .noteIdEqualTo(noteId)
        .sortByTimestampDesc()
        .findAll();
  }

  Future<NoteVersion?> getLastNoteVersion(int noteId) async {
    final isar = await database;
    return await isar.noteVersions
        .filter()
        .noteIdEqualTo(noteId)
        .sortByTimestampDesc()
        .findFirst();
  }

  Future<void> keepMaxVersions(int noteId, int maxLimit) async {
    final isar = await database;
    final versions = await isar.noteVersions
        .filter()
        .noteIdEqualTo(noteId)
        .sortByTimestampDesc()
        .findAll();

    if (versions.length > maxLimit) {
      final toDelete = versions.skip(maxLimit).map((v) => v.id).toList();
      await isar.writeTxn(() async {
        await isar.noteVersions.deleteAll(toDelete);
      });
    }
  }

  Future<int> deleteNoteVersions(int noteId) async {
    final isar = await database;
    final versions =
        await isar.noteVersions.filter().noteIdEqualTo(noteId).findAll();

    await isar.writeTxn(() async {
      await isar.noteVersions.deleteAll(versions.map((v) => v.id).toList());
    });

    return versions.length;
  }

  Future<void> closeDB() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }

  Future<void> reopenDatabase() async {
    await closeDB();
    await IsarDatabaseService.initialize();
  }

  Future<void> runLegacyHistoryCleanup() async {
    // Not needed for Isar
  }

  Future<List<NoteCategory>> getAllCategories() async {
    final isar = await database;
    return await isar.noteCategorys.where().sortBySortOrder().findAll();
  }
}
