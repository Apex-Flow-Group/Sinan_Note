// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/logger.dart';
import '../../models/note.dart';
import '../../models/note_version.dart';
import '../diagnostics/apex_error_manager.dart';

class IsarDatabaseService {
  static Isar? _isar;

  Future<Isar> get database async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [NoteSchema, NoteVersionSchema],
      directory: dir.path,
      name: 'sinan_notes',
    );
    
    return _isar!;
  }

  // CRUD Operations
  Future<int> insertNote(Note note) async {
    return await ApexErrorManager.monitorDB(() async {
      AppLogger.info('insertNote called - title: ${note.title}', 'DB');
      final isar = await database;
      final id = await isar.writeTxn(() async {
        note.updatedAt = DateTime.now();
        return await isar.notes.put(note);
      });
      AppLogger.success('Note inserted with ID: $id', 'DB');
      return id;
    }, name: 'InsertNote');
  }

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

  Future<List<Note>> getLockedNotes() async {
    final isar = await database;
    return await isar.notes
        .filter()
        .isLockedEqualTo(true)
        .isTrashedEqualTo(false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<int> updateNote(Note note) async {
    return await ApexErrorManager.monitorDB(() async {
      AppLogger.info('updateNote called - ID: ${note.id}, title: ${note.title}', 'DB');
      final isar = await database;
      final id = await isar.writeTxn(() async {
        note.updatedAt = DateTime.now();
        return await isar.notes.put(note);
      });
      AppLogger.success('Note updated with ID: $id', 'DB');
      return id;
    }, name: 'UpdateNote');
  }

  Future<bool> deleteNote(int id) async {
    return await ApexErrorManager.monitorDB(() async {
      await deleteNoteVersions(id);
      final isar = await database;
      return await isar.writeTxn(() async {
        return await isar.notes.delete(id);
      });
    }, name: 'DeleteNote');
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

  // Search with full-text support
  Future<List<Note>> searchNotes(String query) async {
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
    AppLogger.info('logNoteVersion - noteId: ${version.noteId}, action: ${version.action}', 'DB');
    final isar = await database;
    await isar.writeTxn(() async {
      await isar.noteVersions.put(version);
    });
    AppLogger.success('Version saved successfully', 'DB');
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
    final versions = await isar.noteVersions
        .filter()
        .noteIdEqualTo(noteId)
        .findAll();
    
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
    await database;
  }

  Future<void> runLegacyHistoryCleanup() async {
    // Not needed for Isar
  }
}
