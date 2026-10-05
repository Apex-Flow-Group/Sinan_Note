// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_version.dart';

const double kColMin = 200.0;
const double kColMax = 480.0;
const double kColDefaultNotes = 280.0;
const double kColDefaultVersions = 240.0;

class VersionHistoryController extends ChangeNotifier {
  VersionHistoryController({required NotesRepository notes}) : _notes = notes;

  final NotesRepository _notes;

  List<Note> notesWithHistory = [];
  bool isLoading = true;
  String searchQuery = '';
  String sortBy = 'date';

  Note? selectedNote;
  List<NoteVersion> selectedNoteVersions = [];
  bool loadingVersions = false;
  NoteVersion? selectedVersion;

  Future<void> loadNotes() async {
    isLoading = true;
    notifyListeners();
    notesWithHistory = await _notes.notesWithHistory();
    isLoading = false;
    notifyListeners();
  }

  Future<void> selectNote(Note note) async {
    selectedNote = note;
    selectedVersion = null;
    selectedNoteVersions = [];
    loadingVersions = true;
    notifyListeners();

    selectedNoteVersions = await _notes.history(note.id!);
    loadingVersions = false;
    notifyListeners();
  }

  void selectVersion(NoteVersion version) {
    selectedVersion = version;
    notifyListeners();
  }

  void clearNote() {
    selectedNote = null;
    selectedNoteVersions = [];
    selectedVersion = null;
    notifyListeners();
  }

  void clearVersion() {
    selectedVersion = null;
    notifyListeners();
  }

  /// يمر بالمستودع: الشاشة الرئيسية والمزامنة ترى التغيير مباشرة.
  Future<void> restoreVersion(NoteVersion version, Note note) async {
    await _notes.restoreVersion(note.id!, version);
    await loadNotes();
  }

  Future<int> getVersionCount(int noteId) async =>
      (await _notes.history(noteId)).length;

  /// قائمة جديدة في كل مرة — لا تعدّل [notesWithHistory].
  List<Note> get filteredNotes {
    final query = searchQuery.trim();
    return [
      for (final n in notesWithHistory)
        if (query.isEmpty || n.matches(query)) n,
    ]..sort(sortBy == 'title'
        ? (a, b) => a.title.compareTo(b.title)
        : (a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static IconData getActionIcon(String action) {
    switch (action) {
      case 'manual_save':
        return Icons.save;
      case 'auto_save':
        return Icons.update;
      case 'created':
        return Icons.add_circle;
      case 'archived':
        return Icons.archive;
      case 'restored':
        return Icons.restore;
      default:
        return Icons.edit;
    }
  }

  static Color getActionColor(String action) {
    switch (action) {
      case 'manual_save':
        return Colors.green;
      case 'auto_save':
        return Colors.blue;
      case 'created':
        return Colors.purple;
      case 'archived':
        return Colors.orange;
      case 'restored':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
