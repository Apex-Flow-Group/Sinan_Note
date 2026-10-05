// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/data/repositories/vault_repository.dart';
import 'package:sinan_note/domain/errors.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_mode.dart';
import 'package:sinan_note/domain/models/note_version.dart';
import 'package:sinan_note/domain/versioning.dart';

/// ViewModel الملاحظات المشترك للشاشات التي لم تنتقل بعد إلى ViewModel خاص
/// بميزتها. لا حالة ولا منطق تخزين هنا: كل شيء من [NotesRepository]،
/// والقوائم المشتقة تُحسب مرة لكل تغيير.
class NotesProvider extends ChangeNotifier {
  NotesProvider({
    required NotesRepository notes,
    required VaultRepository vault,
  })  : _notes = notes,
        _vault = vault {
    _notes.addListener(_onNotesChanged);
    _vault.addListener(_onVaultChanged);
  }

  final NotesRepository _notes;
  final VaultRepository _vault;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// يتغير مع كل تغيير في الملاحظات — للواجهات التي تقارن لقطات.
  int get refreshStamp => _refreshStamp;
  int _refreshStamp = 0;

  bool get isInitialDataLoaded => _notes.isLoaded;

  // ── القوائم المشتقة ──────────────────────────────────────────────────────

  List<Note>? _active, _archived, _trashed, _reminders;

  List<Note> get notes => activeNotes;

  List<Note> get activeNotes => _active ??= List.unmodifiable(
      _notes.notes.where((n) => !n.isTrashed && !n.isArchived));

  List<Note> get archivedNotes => _archived ??= List.unmodifiable(
      _notes.notes.where((n) => n.isArchived && !n.isTrashed));

  List<Note> get trashedNotes =>
      _trashed ??= List.unmodifiable(_notes.notes.where((n) => n.isTrashed));

  /// التذكيرات القادمة — يُعاد حسابها عند كل تغيير.
  List<Note> get reminderNotes =>
      _reminders ??= List.unmodifiable(_notes.notes.where((n) =>
          !n.isTrashed &&
          n.reminderDateTime != null &&
          n.reminderDateTime!.isAfter(DateTime.now())));

  Note? cachedNote(int id) => _notes.cached(id);

  List<Note> searchNotes(String query) =>
      activeNotes.where((n) => n.matches(query)).take(100).toList();

  void _onNotesChanged() {
    _active = _archived = _trashed = _reminders = null;
    _refreshStamp++;
    if (_silent) return;
    notifyListeners();
  }

  /// حفظ صامت (الحفظ التلقائي أثناء الكتابة): البيانات تتحدث، والقوائم خلف
  /// المحرر لا تُعاد بناؤها مع كل حفظ.
  bool _silent = false;

  Future<Note> _save(Note note, {required bool silent}) async {
    _silent = silent;
    try {
      return await _notes.save(note);
    } finally {
      _silent = false;
    }
  }

  // ── التحميل ──────────────────────────────────────────────────────────────

  Future<void> refreshAllNotes({bool force = false}) async {
    if (_isLoading && !force) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _notes.load();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// أول تحميل في الخلفية دون انتظار.
  Future<void> loadNotes({bool force = false}) async {
    if (_isLoading || (!force && _notes.isLoaded)) return;
    await refreshAllNotes();
  }

  Future<List<Note>> getNotes() async {
    await refreshAllNotes();
    return activeNotes;
  }

  Future<void> fetchTrashedNotes() => refreshAllNotes();
  Future<void> fetchArchivedNotes() => refreshAllNotes();

  // ── إنشاء ────────────────────────────────────────────────────────────────

  Note createDefaultNote({
    required NoteMode mode,
    required int colorIndex,
    List<int>? categoryIds,
  }) {
    final now = DateTime.now();
    return Note(
      title: '',
      content: '',
      createdAt: now,
      updatedAt: now,
      colorIndex: colorIndex,
      noteType: mode.name,
      isChecklist: mode == NoteMode.checklist,
      isProfessional: mode == NoteMode.code,
      categoryIds: categoryIds ?? const [],
    );
  }

  /// ملاحظة من نص مشارك (Share Intent) — كود مستورد من خارج التطبيق.
  Note createSharedNote({
    required String title,
    required String content,
    required int colorIndex,
  }) {
    final now = DateTime.now();
    return Note(
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      colorIndex: colorIndex,
      noteType: NoteMode.code.name,
    );
  }

  Note createDefaultLockedNote({required NoteMode mode}) {
    final now = DateTime.now();
    return Note(
      title: '',
      content: mode == NoteMode.checklist ? '{"title":"","items":[]}' : '',
      createdAt: now,
      updatedAt: now,
      noteType: switch (mode) {
        NoteMode.checklist => 'checklist',
        NoteMode.code => 'code',
        _ => 'simple',
      },
      isLocked: true,
      isChecklist: mode == NoteMode.checklist,
      isProfessional: mode == NoteMode.code,
    );
  }

  // ── كتابة ────────────────────────────────────────────────────────────────

  Future<int> addNote(Note note) async => (await _notes.save(note)).id!;

  Future<int> updateNote(Note note, {bool silent = false}) async {
    await _save(note, silent: silent);
    return 1;
  }

  Future<int> addOrUpdateNote(Note note, {bool silent = false}) async =>
      (await _save(note, silent: silent)).id!;

  Future<Note?> updateNoteMeta(
    int id, {
    int? colorIndex,
    bool? isPinned,
    Object? reminderDateTime = _keep,
    List<int>? categoryIds,
    bool? isHiddenFromHome,
  }) =>
      _notes.updateMeta(id,
          colorIndex: colorIndex,
          isPinned: isPinned,
          categoryIds: categoryIds,
          isHiddenFromHome: isHiddenFromHome,
          reminderDateTime: identical(reminderDateTime, _keep)
              ? _notes.cached(id)?.reminderDateTime
              : reminderDateTime);

  static const _keep = Object();

  Future<bool?> togglePinned(int id) => _notes.togglePinned(id);

  Future<int> deleteNote(int id) async {
    await _notes.delete([id]);
    return 1;
  }

  Future<int> archiveNote(int id) async {
    await _notes.archive([id]);
    return 1;
  }

  Future<int> unarchiveNote(int id) async {
    await _notes.unarchive([id]);
    return 1;
  }

  Future<int> trashNote(int id) async {
    await _notes.trash([id]);
    return 1;
  }

  Future<int> restoreNote(int id) async {
    await _notes.restore([id]);
    return 1;
  }

  Future<void> trashNotes(List<int> ids) => _notes.trash(ids);
  Future<void> restoreNotes(List<int> ids) => _notes.restore(ids);
  Future<void> archiveNotes(List<int> ids) => _notes.archive(ids);
  Future<void> unarchiveNotes(List<int> ids) => _notes.unarchive(ids);

  Future<void> convertNoteType(
    int id, {
    required String newContent,
    required String newNoteType,
    required bool isChecklist,
  }) async {
    await _notes.convertType(id,
        content: newContent, noteType: newNoteType, isChecklist: isChecklist);
  }

  Future<int> duplicateNote(int id, {String copyLabel = 'Copy'}) async =>
      (await _notes.duplicate(id, copyLabel: copyLabel))?.id ?? -1;

  // ── النسخ السابقة ────────────────────────────────────────────────────────

  /// نسخة من الملاحظة كما هي مخزّنة؛ المقفلة لا نسخ لها أبداً.
  Future<void> recordVersion(int id, VersionTrigger trigger) =>
      _notes.recordVersion(id, trigger);

  Future<List<NoteVersion>> history(int id) => _notes.history(id);

  // ── الخزنة ───────────────────────────────────────────────────────────────

  bool get isVaultUnlocked => _vault.isUnlocked;

  List<Note> get lockedNotes => _locked;
  List<Note> _locked = const [];

  /// الملاحظات المقفلة مفكوكة. يرمي [VaultLockedException] والخزنة مقفلة.
  Future<List<Note>> fetchAndDecryptLockedNotes() async =>
      _locked = await _notes.lockedNotes();

  /// يُرجع false إن كانت الخزنة مقفلة أو تعذّر فك الملاحظة — فتبقى كما هي.
  Future<bool> toggleLockStatus(int id, bool lockStatus) async {
    try {
      await _notes.setLocked(id, lockStatus);
      return true;
    } on VaultLockedException {
      return false;
    } on VaultDecryptionException {
      return false;
    }
  }

  void _onVaultChanged() {
    if (!_vault.isUnlocked) _locked = const [];
    notifyListeners();
  }

  @override
  void dispose() {
    _notes.removeListener(_onNotesChanged);
    _vault.removeListener(_onVaultChanged);
    super.dispose();
  }
}
