// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/services/note_services/note_batch_operations_service.dart';
import 'package:sinan_note/services/note_services/note_security_service.dart';
import 'package:sinan_note/services/note_services/note_side_effect_service.dart';
import 'package:sinan_note/services/note_services/note_state_service.dart';
import 'package:sinan_note/services/note_services/version_control_service.dart';
import 'package:sinan_note/services/security/vault_service.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';

class NotesProvider extends ChangeNotifier {
  late final NoteStateService _stateService;
  late final SqliteDatabaseService _dbService;
  late final NoteSecurityService _securityService;
  late final NoteSideEffectService _sideEffectService;
  late final NoteBatchOperationsService _batchService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  int _refreshStamp = 0;
  int get refreshStamp => _refreshStamp;

  NotesProvider({SqliteDatabaseService? dbService}) {
    _dbService = dbService ?? SqliteDatabaseService();
    _stateService = NoteStateService();
    _securityService = NoteSecurityService();
    _sideEffectService = NoteSideEffectService();
    _batchService = NoteBatchOperationsService(
        _dbService, _stateService, _sideEffectService);

    // ✅ Wire up sync completion callback to refresh UI
    _stateService.onSyncCompleted = _refreshAfterSync;
  }

  bool get isInitialDataLoaded => _stateService.isInitialDataLoaded;
  NoteStateService get stateService => _stateService;
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

  Future<void> refreshAllNotes({bool force = false}) async {
    if (_isLoading && !force) return;
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

  /// Called by NoteStateService after background sync completes
  Future<void> _refreshAfterSync() async {
    try {
      final notes = await _dbService.getAllNotes();
      _stateService.updateAllNotes(notes);
      _refreshStamp++;
      notifyListeners();
    } catch (_) {
      // Silent failure for background sync refresh
    }
  }

  /// تحميل الملاحظات في الخلفية عند أول تشغيل.
  /// يستخدم fire-and-forget لعدم تأخير الـ UI.
  /// للتحميل المتزامن استخدم [refreshAllNotes] مباشرة.
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

  Future<void> fetchTrashedNotes() async => await refreshAllNotes();
  Future<void> fetchArchivedNotes() async => await refreshAllNotes();

  List<Note> searchNotes(String query) => _stateService.searchNotes(query);

  // ─── Factory Methods ──────────────────────────────────────────────────────

  /// ينشئ ملاحظة افتراضية جاهزة للمحرر — سيد القصر يبني، الأميرة تطلب فقط.
  ///
  /// [mode]          : نوع الملاحظة
  /// [colorIndex]    : لون الملاحظة (من SettingsProvider.getDefaultColorIndex)
  /// [categoryIds]   : تصنيفات مختارة مسبقاً (اختياري)
  Note createDefaultNote({
    required NoteMode mode,
    required int colorIndex,
    List<int>? categoryIds,
  }) {
    return Note(
      title: '',
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: colorIndex,
      noteType: mode.name,
      isChecklist: mode == NoteMode.checklist,
      isProfessional: mode == NoteMode.code,
      categoryIds: categoryIds ?? [],
    );
  }

  /// ينشئ ملاحظة من نص مشارك (Share Intent) — كود مستورد من خارج التطبيق.
  Note createSharedNote({
    required String title,
    required String content,
    required int colorIndex,
  }) {
    return Note(
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: colorIndex,
      noteType: NoteMode.code.name,
    );
  }

  ///
  /// يتولى تحديد [noteType] و [initialContent] بناءً على [mode].
  Note createDefaultLockedNote({required NoteMode mode}) {
    final String noteType;
    final bool isChecklist;
    final bool isProfessional;
    final String initialContent;

    switch (mode) {
      case NoteMode.checklist:
        noteType = 'checklist';
        isChecklist = true;
        isProfessional = false;
        initialContent = '{"title":"","items":[]}';
        break;
      case NoteMode.code:
        noteType = 'code';
        isChecklist = false;
        isProfessional = true;
        initialContent = '';
        break;
      default:
        noteType = 'simple';
        isChecklist = false;
        isProfessional = false;
        initialContent = '';
    }

    return Note(
      title: '',
      content: initialContent,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: 0,
      noteType: noteType,
      isLocked: true,
      isChecklist: isChecklist,
      isProfessional: isProfessional,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

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
    // copyWith على الملاحظة الموجودة في الـ state — بدلاً من قراءة DB إضافية
    final existing = _stateService.getNoteById(id);
    if (existing != null) {
      _stateService.updateNote(existing.copyWith(
        isArchived: true,
        updatedAt: DateTime.now(),
      ));
    }
    notifyListeners();
    return result;
  }

  Future<int> unarchiveNote(int id) async {
    final result = await _dbService.unarchiveNote(id);
    final existing = _stateService.getNoteById(id);
    if (existing != null) {
      _stateService.updateNote(existing.copyWith(
        isArchived: false,
        updatedAt: DateTime.now(),
      ));
    }
    notifyListeners();
    return result;
  }

  Future<int> trashNote(int id) async {
    await _sideEffectService.cancelReminderSideEffect(id);
    final result = await _dbService.trashNote(id);
    final existing = _stateService.getNoteById(id);
    if (existing != null) {
      _stateService.updateNote(existing.copyWith(
        isTrashed: true,
        updatedAt: DateTime.now(),
      ));
    }
    notifyListeners();
    return result;
  }

  Future<int> restoreNote(int id) async {
    final result = await _dbService.restoreNote(id);
    final existing = _stateService.getNoteById(id);
    if (existing != null) {
      _stateService.updateNote(existing.copyWith(
        isTrashed: false,
        isArchived: false,
        updatedAt: DateTime.now(),
      ));
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

  // insertNote حُذف — استخدم addNote مباشرة (P4)

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
    // لا حاجة لـ refreshAllNotes() — _stateService.updateNote() يُحدّث الـ state مباشرة
  }

  Future<int> duplicateNote(int id, {String copyLabel = 'Copy'}) async {
    final note = await _dbService.getNoteById(id);
    if (note == null) return -1;

    final copy = note.copyWith(
      id: null,
      title: note.title.isEmpty ? copyLabel : '${note.title} - $copyLabel',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPinned: false,
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
