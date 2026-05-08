// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/note_services/note_batch_operations_service.dart';
import 'package:apex_note/services/note_services/note_security_service.dart';
import 'package:apex_note/services/note_services/note_side_effect_service.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:apex_note/services/version_control_service.dart';
import 'package:flutter/widgets.dart';

class NotesProvider extends ChangeNotifier {
  late final NoteStateService _stateService;
  late final IsarDatabaseService _dbService;
  late final NoteSecurityService _securityService;
  late final NoteSideEffectService _sideEffectService;
  late final NoteBatchOperationsService _batchService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  int _refreshStamp = 0;
  int get refreshStamp => _refreshStamp;

  NotesProvider({IsarDatabaseService? dbService}) {
    _dbService = dbService ?? IsarDatabaseService();
    _stateService = NoteStateService();
    _securityService = NoteSecurityService();
    _sideEffectService = NoteSideEffectService();
    _batchService = NoteBatchOperationsService(
        _dbService, _stateService, _sideEffectService);
  }

  bool get isInitialDataLoaded => _stateService.isInitialDataLoaded;
  List<Note> get activeNotes => _stateService.activeNotes;
  List<Note> get notes => activeNotes;
  List<Note> get archivedNotes => _stateService.archivedNotes;
  List<Note> get trashedNotes => _stateService.trashedNotes;
  List<Note> get reminderNotes => _stateService.reminderNotes;
  List<Note> get lockedNotes => _stateService.lockedNotes;
  bool get isVaultUnlocked => _securityService.isVaultUnlocked;

  void unlockVault() => _securityService.unlockVault();

  void lockVault() {
    _securityService.lockVault();
    _securityService.clearLockedSession(_stateService);
    notifyListeners();
  }

  Future<void> refreshAllNotes() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final notes = await _dbService.getAllNotes();
      _stateService.updateAllNotes(notes);
      _refreshStamp++;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNotes({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _stateService.isInitialDataLoaded) return;

    // ✅ Load in background without blocking UI
    refreshAllNotes().then((_) {
      // Silently loaded
    }).catchError((e) {});
  }

  Future<List<Note>> getNotes() async {
    await refreshAllNotes();
    return activeNotes;
  }

  Future<void> fetchNotes() async => await refreshAllNotes();
  Future<void> fetchTrashedNotes() async => await refreshAllNotes();
  Future<void> fetchArchivedNotes() async => await refreshAllNotes();

  List<Note> searchNotes(String query) => _stateService.searchNotes(query);

  Future<int> addNote(Note note) async {
    Note noteToInsert = note;
    if (note.isLocked && note.content.isNotEmpty) {
      final encryptedTitle = note.title.isNotEmpty
          ? await VaultService.encryptWithMasterKey(note.title)
          : '';
      final encryptedContent =
          await VaultService.encryptWithMasterKey(note.content);
      noteToInsert =
          note.copyWith(title: encryptedTitle, content: encryptedContent);
    }

    final id = await _dbService.insertNote(noteToInsert);
    _stateService.addNote(noteToInsert.copyWith(id: id));
    await _sideEffectService
        .handleReminderSideEffect(noteToInsert.copyWith(id: id));
    _refreshStamp++;
    notifyListeners();
    return id;
  }

  Future<int> insertNote(Note note) async => addNote(note);

  Future<int> updateNote(Note note, {bool silent = false}) async {
    Note noteToUpdate = note;
    if (note.isLocked && note.content.isNotEmpty) {
      if (!VaultService.isEncrypted(note.content)) {
        final encryptedTitle = note.title.isNotEmpty
            ? await VaultService.encryptWithMasterKey(note.title)
            : '';
        final encryptedContent =
            await VaultService.encryptWithMasterKey(note.content);
        noteToUpdate =
            note.copyWith(title: encryptedTitle, content: encryptedContent);
      }
    }

    final result = await _dbService.updateNote(noteToUpdate);
    _stateService.updateNote(noteToUpdate);
    await _sideEffectService.handleReminderSideEffect(note);
    await _sideEffectService.checkAndUpdateIfPinned(note);
    if (!silent) {
      _refreshStamp++;
      notifyListeners();
    }
    return result;
  }

  Future<int> deleteNote(int id) async {
    await _sideEffectService.cancelReminderSideEffect(id);
    final result = await _dbService.deleteNote(id) ? 1 : 0;
    _stateService.removeNote(id);
    await _sideEffectService.checkAndResetIfPinned(id);
    notifyListeners();
    return result;
  }

  Future<int> archiveNote(int id) async {
    await _sideEffectService.cancelReminderSideEffect(id);
    final result = await _dbService.archiveNote(id);
    final note = await _dbService.getNoteById(id);
    if (note != null) _stateService.updateNote(note);
    notifyListeners();
    return result;
  }

  Future<int> unarchiveNote(int id) async {
    final result = await _dbService.unarchiveNote(id);
    final note = await _dbService.getNoteById(id);
    if (note != null) _stateService.updateNote(note);
    notifyListeners();
    return result;
  }

  Future<int> trashNote(int id) async {
    await _sideEffectService.cancelReminderSideEffect(id);
    final result = await _dbService.trashNote(id);
    final note = await _dbService.getNoteById(id);
    if (note != null) _stateService.updateNote(note);
    notifyListeners();
    return result;
  }

  Future<int> restoreNote(int id) async {
    final result = await _dbService.restoreNote(id);
    final note = await _dbService.getNoteById(id);
    if (note != null) {
      _stateService.updateNote(note);
      _stateService.sortNotes(immediate: true);
    }
    notifyListeners();
    return result;
  }

  Future<int> addOrUpdateNote(Note note, {bool silent = false}) async {
    if (note.id != null) {
      await updateNote(note, silent: silent);
      return note.id!;
    } else {
      return await addNote(note);
    }
  }

  Future<void> convertNoteType(
    int id, {
    required String newContent,
    required String newNoteType,
    required bool isChecklist,
  }) async {
    final note = await _dbService.getNoteById(id);
    if (note == null) return;

    // حفظ نسخة من الحالة الحالية قبل التحويل
    await VersionControlService().smartLogVersion(
      noteId: id,
      title: note.title,
      content: note.content,
      isManualAction: true,
      noteType: note.noteType,
      forceLog: true,
    );

    final updated = note.copyWith(
      content: newContent,
      noteType: newNoteType,
      isChecklist: isChecklist,
      isProfessional: newNoteType == 'code' || newNoteType == 'pro',
      updatedAt: DateTime.now(),
    );
    await _dbService.updateNote(updated);
    _stateService.updateNote(updated);
    _refreshStamp++;
    notifyListeners();
    await refreshAllNotes();
  }

  Future<int> duplicateNote(int id) async {
    final note = await _dbService.getNoteById(id);
    if (note == null) {
      return -1;
    }

    // Create completely new note without ID
    final copy = Note(
      title: note.title.isEmpty ? 'Copy' : '${note.title} - Copy',
      content: note.content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: note.colorIndex,
      noteType: note.noteType,
      isChecklist: note.isChecklist,
      isProfessional: note.isProfessional,
      isLocked: note.isLocked,
      categoryIds: note.categoryIds,
      reminderDateTime: note.reminderDateTime,
      recurrenceRule: note.recurrenceRule,
    );

    final newId = await addNote(copy);
    return newId;
  }

  Future<void> trashNotes(List<int> ids) async {
    await _batchService.batchTrashNotes(ids);
    notifyListeners();
  }

  Future<void> restoreNotes(List<int> ids) async {
    await _batchService.batchRestoreNotes(ids);
    notifyListeners();
  }

  Future<void> archiveNotes(List<int> ids) async {
    await _batchService.batchArchiveNotes(ids);
    notifyListeners();
  }

  Future<void> unarchiveNotes(List<int> ids) async {
    await _batchService.batchUnarchiveNotes(ids);
    notifyListeners();
  }

  Future<void> fetchLockedNotes() async {
    final notes = await _securityService.fetchAndDecryptLockedNotes(_dbService);
    _stateService.updateLockedNotes(notes);
    notifyListeners();
  }

  Future<List<Note>> fetchAndDecryptLockedNotes() async {
    return await _securityService.fetchAndDecryptLockedNotes(_dbService);
  }

  Future<void> toggleLockStatus(int id, bool lockStatus) async {
    await _securityService.toggleLockStatus(id, lockStatus, _dbService);
    final note = await _dbService.getNoteById(id);
    if (note != null) {
      if (lockStatus) {
        _stateService.removeNote(id);
        _stateService.updateLockedNotes([...lockedNotes, note]);
      } else {
        _stateService
            .updateLockedNotes(lockedNotes.where((n) => n.id != id).toList());
        _stateService.addNote(note);
      }
    }
    notifyListeners();
  }

  void clearLockedSession({bool notify = true}) {
    _securityService.clearLockedSession(_stateService);
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _stateService.dispose();
    super.dispose();
  }
}
