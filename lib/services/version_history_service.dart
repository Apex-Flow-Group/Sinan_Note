// Copyright © 2025 Apex Flow Group. All rights reserved.



import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_version.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import 'package:sinan_note/services/version_control_service.dart';

/// Version History Service - UI layer for smart version control
/// Uses VersionControlService settings for consistency
class VersionHistoryService {
  final _dbService = SqliteDatabaseService();
  final _versionControl = VersionControlService();

  // Use same max versions as smart control
  static const int maxVersionsToShow = 20;

  Future<List<Note>> getNotesWithHistory() async {
    final allNotes = await _dbService.getAllNotes();
    
    final notesWithHistory = <Note>[];
    for (var note in allNotes) {
      if (note.isLocked) continue;
      final versions = await _dbService.getNoteHistory(note.id!);
      if (versions.isNotEmpty) {
        notesWithHistory.add(note);
      }
    }
    
    return notesWithHistory;
  }

  Future<List<NoteVersion>> getNoteVersions(int noteId) async {
    final versions = await _dbService.getNoteHistory(noteId);
    return versions.take(maxVersionsToShow).toList();
  }

  Future<void> restoreVersion(int noteId, NoteVersion version) async {
    final note = await _dbService.getNoteById(noteId);
    if (note == null) return;

    await _versionControl.smartLogVersion(
      noteId: noteId,
      title: note.title,
      content: note.content,
      isManualAction: true,
      noteType: note.noteType,
      forceLog: true,
    );

    final restoredNoteType =
        version.noteType.isNotEmpty ? version.noteType : note.noteType;
    final restored = note.copyWith(
      title: version.title,
      content: version.content,
      noteType: restoredNoteType,
      isChecklist: restoredNoteType == 'checklist',
      updatedAt: DateTime.now(),
    );

    await _dbService.updateNote(restored);
  }

  Future<int> getVersionCount(int noteId) async {
    final versions = await _dbService.getNoteHistory(noteId);
    return versions.length;
  }

  Future<List<Note>> getAllNotesDebug() async {
    return await _dbService.getAllNotes();
  }
}

