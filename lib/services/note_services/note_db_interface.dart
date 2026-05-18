// Copyright © 2025 Apex Flow Group. All rights reserved.



import 'package:sinan_note/models/category.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_version.dart';

abstract class NoteDbInterface {
  // Core
  Future<int>        insertNote(Note note);
  Future<Note?>      getNoteById(int id);
  Future<int>        updateNote(Note note);
  Future<bool>       deleteNote(int id);
  Future<List<Note>> getAllNotes();
  Future<List<Note>> getNotes({int? limit, int? offset});

  // Filters
  Future<List<Note>> getArchivedNotes();
  Future<List<Note>> getTrashedNotes();
  Future<List<Note>> getLockedNotes();
  Future<List<Note>> searchNotes(String query, {int limit});

  // State changes
  Future<int> archiveNote(int id);
  Future<int> unarchiveNote(int id);
  Future<int> trashNote(int id);
  Future<int> restoreNote(int id);

  // Reminders
  Future<List<Note>> getUpcomingReminders();
  Future<List<Note>> getNotesForWidget();
  Future<List<Note>> getScheduledReminders();
  Future<List<Note>> getExpiredReminders();

  // Versions
  Future<void>             logNoteVersion(NoteVersion version);
  Future<List<NoteVersion>> getNoteHistory(int noteId);
  Future<NoteVersion?>     getLastNoteVersion(int noteId);
  Future<void>             keepMaxVersions(int noteId, int maxLimit);
  Future<int>              deleteNoteVersions(int noteId);

  // Categories
  Future<List<NoteCategory>> getAllCategories();
  Future<int>                insertCategory(NoteCategory cat);
  Future<void>               updateCategory(NoteCategory cat);
  Future<void>               deleteCategory(int id);

  // Lifecycle
  Future<void> closeDB();
  Future<void> reopenDatabase();
  Future<void> runLegacyHistoryCleanup();
}

