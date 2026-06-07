// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_version.dart';
import 'package:sinan_note/services/version_history_service.dart';

const double kColMin = 200.0;
const double kColMax = 480.0;
const double kColDefaultNotes = 280.0;
const double kColDefaultVersions = 240.0;

class VersionHistoryController extends ChangeNotifier {
  final _service = VersionHistoryService();

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
    final notes = await _service.getNotesWithHistory();
    notesWithHistory = notes.where((n) => !n.isLocked).toList();
    isLoading = false;
    notifyListeners();
  }

  Future<void> selectNote(Note note) async {
    selectedNote = note;
    selectedVersion = null;
    selectedNoteVersions = [];
    loadingVersions = true;
    notifyListeners();

    final versions = await _service.getNoteVersions(note.id!);
    selectedNoteVersions = versions;
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

  Future<void> restoreVersion(
      NoteVersion version, Note note, NotesProvider notesProvider) async {
    await _service.restoreVersion(note.id!, version);
    // أخبر NotesProvider بالتغيير حتى تتحدث الشاشة الرئيسية
    await notesProvider.refreshAllNotes();
    await loadNotes();
  }

  Future<int> getVersionCount(int noteId) => _service.getVersionCount(noteId);

  List<Note> get filteredNotes {
    var notes = notesWithHistory;
    if (searchQuery.trim().isNotEmpty) {
      final q = Note.normalize(searchQuery);
      notes = notes
          .where((n) =>
              n.normalizedTitle.contains(q) || n.normalizedContent.contains(q))
          .toList();
    }
    if (sortBy == 'title') {
      notes.sort((a, b) => a.title.compareTo(b.title));
    } else {
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return notes;
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

