// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/domain/editing.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/versioning.dart';

export 'package:sinan_note/domain/editing.dart' show NoteDraft;

/// مصدر ما في المحرر الآن — يملكه الـ View لأنه يملك المتحكمات.
abstract interface class DraftSource {
  /// المسودة إن تغيّر شيء منذ آخر أخذ (أو دائماً مع [force])، ويعدّها
  /// الـ View محفوظة. null: لا شيء للحفظ.
  NoteDraft? takeDraft({required bool force});

  /// مسودة أُخذت ولم تُكتب: يعيدها الـ View غير محفوظة.
  void restoreDraft();
}

/// جلسة تحرير ملاحظة واحدة: المالك الوحيد لحفظها.
///
/// - ما في المحرر يُلتقط لحظة طلب الحفظ (فيصح عند الإغلاق والخروج للخلفية)،
///   والكتابة في طابور واحد: لا يُسقط حفظٌ أبداً، والطلبات قبل بدء الكتابة
///   تُدمج فيُكتب أحدثها.
/// - الحفظ دمج ثلاثي مع المخزّن ([NoteDraft.mergeInto]): لا يرجع تثبيتاً أو
///   لوناً أو تذكيراً تغيّر خارج المحرر وهو مفتوح.
/// - الأرشفة والسلة تُنهيان الجلسة: لا حفظ بعدها يعيد الملاحظة.
/// - الخطأ يبقى في [error]؛ لا يُبتلع.
class EditorViewModel extends ChangeNotifier {
  EditorViewModel({
    required NotesRepository notes,
    Note? note,
    bool locked = false,
    DateTime Function()? clock,
  })  : _notes = notes,
        _id = note?.id,
        _base = note == null ? null : NoteDraft.of(note),
        _locked = locked || (note?.isLocked ?? false),
        _now = clock ?? DateTime.now;

  final NotesRepository _notes;
  final DateTime Function() _now;
  final bool _locked;
  int? _id;
  NoteDraft? _base;
  DraftSource? _source;

  bool _closed = false;
  bool _disposed = false;
  bool _savedSinceAck = false;
  Object? _error;

  Future<void> _tail = Future.value();
  Future<bool>? _pending;
  NoteDraft? _pendingDraft;
  bool _pendingManual = false;

  int? get noteId => _id;
  bool get isLocked => _locked;

  /// أُرشفت أو نُقلت للسلة أو حُذفت: لا حفظ بعد الآن.
  bool get isClosed => _closed;

  /// آخر فشل حفظ، أو null.
  Object? get error => _error;

  void attach(DraftSource source) => _source = source;

  /// يحفظ ما في المحرر إن تغيّر ([force]: حتى لو لم يتغيّر). [manual]: حفظ
  /// صريح يسجّل نسخة. يُرجع true إن كُتب شيء.
  Future<bool> save({bool manual = false, bool force = false}) {
    if (_closed) return Future.value(false);
    final draft = _source?.takeDraft(force: force);
    if (draft != null) _pendingDraft = draft;
    _pendingManual |= manual;
    if (_pendingDraft == null) return _pending ?? Future.value(false);
    return _pending ??= _enqueue();
  }

  /// يكتمل حين تُكتب كل الطلبات حتى الآن (قبل إقفال الخزنة مثلاً).
  Future<void> flush() => _tail;

  /// يحفظ ما في المحرر بعد تحويله ([change]: صيغة أو نوع آخر)، كحفظ صريح.
  Future<bool> saveAs(NoteDraft Function(NoteDraft current) change) {
    if (_closed) return Future.value(false);
    final draft = _source?.takeDraft(force: true);
    if (draft == null) return Future.value(false);
    _pendingDraft = change(draft);
    _pendingManual = true;
    return _pending ??= _enqueue();
  }

  Future<bool> _enqueue() {
    final run = _tail.then((_) {
      final draft = _pendingDraft!;
      final manual = _pendingManual;
      _pending = null;
      _pendingDraft = null;
      _pendingManual = false;
      return _write(draft, manual: manual);
    });
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }

  /// كُتب شيء منذ آخر سؤال؟ (لرسالة "تم الحفظ" عند الخروج)
  bool takeSavedFlag() {
    final saved = _savedSinceAck;
    _savedSinceAck = false;
    return saved;
  }

  /// يحفظ أولاً ثم ينقل للأرشيف وينهي الجلسة.
  Future<bool> archive() => _finishWith((id) => _notes.archive([id]));

  /// يحفظ أولاً ثم ينقل للسلة وينهي الجلسة.
  Future<bool> trash() => _finishWith((id) => _notes.trash([id]));

  /// يحفظ أولاً ثم يقلب التثبيت. يُرجع الحالة الجديدة، أو null.
  Future<bool?> togglePinned() async {
    await save();
    final id = _id;
    if (id == null || _closed) return null;
    return _notes.togglePinned(id);
  }

  /// يحفظ أولاً ثم ينسخ الملاحظة. يُرجع النسخة، أو null.
  Future<Note?> duplicate({required String copyLabel}) async {
    await save();
    final id = _id;
    if (id == null) return null;
    return _notes.duplicate(id, copyLabel: copyLabel);
  }

  /// إن فشل الحفظ قبلها لا تُنفَّذ: تعديلات المستخدم لا تُترك خلفها.
  Future<bool> _finishWith(Future<void> Function(int id) action) async {
    await save();
    final id = _id;
    if (id == null || _closed || _error != null) return false;
    _closed = true;
    await action(id);
    _notify();
    return true;
  }

  Future<bool> _write(NoteDraft draft, {required bool manual}) async {
    if (_closed) return false;
    try {
      final written = await _persist(draft);
      if (written && manual && _id != null) {
        await _notes.recordVersion(_id!, VersionTrigger.manual);
      }
      _error = null;
      _notify();
      return written;
    } on Object catch (e) {
      _source?.restoreDraft();
      _error = e;
      _notify();
      return false;
    }
  }

  Future<bool> _persist(NoteDraft draft) async {
    final id = _id;
    final base = _base;
    if (id == null) {
      // جديدة: لا تُنشأ فارغة، إلا ملاحظة خزنة جديدة (تُنشأ لتظهر فيها)
      if (draft.isEmpty && !_locked) return false;
      final saved = await _notes.save(draft.toNewNote(now: _now(), locked: _locked));
      _id = saved.id;
      return _wrote(draft);
    }
    final stored = await _notes.find(id);
    if (stored == null || stored.isTrashed) {
      // حُذفت أو نُقلت للسلة من مكان آخر: لا تُعاد
      _closed = true;
      return false;
    }
    if (base != null && draft.emptiedSince(base) && !_locked) {
      // مسح المستخدم كل ما فيها: إلى السلة
      _closed = true;
      await _notes.trash([id]);
      return false;
    }
    await _notes.save(draft.mergeInto(stored,
        base: base ?? NoteDraft.of(stored), now: _now()));
    return _wrote(draft);
  }

  bool _wrote(NoteDraft draft) {
    _base = draft;
    _savedSinceAck = true;
    return true;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// يفتح جلسات التحرير ويتتبعها حتى تكتمل كتابتها — فيُكمل حفظها قبل إقفال
/// الخزنة ولو أُغلق المحرر.
class EditorSessions {
  EditorSessions({required NotesRepository notes}) : _notes = notes;

  final NotesRepository _notes;
  final _live = <EditorViewModel>{};

  EditorViewModel open(Note? note, {bool locked = false}) {
    final session = _Session(this, notes: _notes, note: note, locked: locked);
    _live.add(session);
    return session;
  }

  Future<void> flush() => Future.wait([for (final s in _live.toList()) s.flush()]);
}

class _Session extends EditorViewModel {
  _Session(this._sessions,
      {required super.notes, super.note, super.locked = false});

  final EditorSessions _sessions;

  @override
  void dispose() {
    flush().whenComplete(() => _sessions._live.remove(this));
    super.dispose();
  }
}
