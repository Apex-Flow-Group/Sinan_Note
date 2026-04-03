// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/models/note.dart';

/// Abstract interface for database operations used by security service.
/// Allows mocking in tests without depending on Isar directly.
abstract class NoteDbInterface {
  Future<List<Note>> getLockedNotes();
  Future<Note?> getNoteById(int id);
  Future<int> updateNote(Note note);
}
