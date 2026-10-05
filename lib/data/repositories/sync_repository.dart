// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sinan_note/data/repositories/categories_repository.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/data/services/key_value_store.dart';
import 'package:sinan_note/data/services/sync/drive_sync_remote.dart';
import 'package:sinan_note/data/services/sync/sync_snapshot.dart';
import 'package:sinan_note/data/services/sync/tombstone_store.dart';
import 'package:sinan_note/domain/errors.dart' show SyncException;
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/sync/sync_merge.dart';
import 'package:sinan_note/domain/sync/tombstones.dart';

/// مزامنة الملاحظات غير المقفلة والتصنيفات مع لقطة في السحابة.
///
/// - عملية واحدة في كل مرة.
/// - لا يُكتب فوق السحابة إلا وهي الملف نفسه الذي رفعه هذا الجهاز آخر مرة؛
///   غير ذلك يُدمج أولاً ([SyncMerge]) ثم يُرفع الاتحاد.
/// - فشل الشبكة أو Drive يرمي [SyncException] ولا يُقرأ كسحابة فارغة.
/// - ملف الإصدارات السابقة ([legacy]) يُقرأ ويُدمج كلما تغيّر، ولا يُكتب
///   فيه أبداً: جهاز لم يُحدَّث بعد يبقى على ملفه سليماً، وتصل تعديلاته
///   إلى الأجهزة المحدَّثة.
class SyncRepository extends ChangeNotifier {
  SyncRepository({
    required NotesRepository notes,
    required CategoriesRepository categories,
    required TombstoneStore tombstones,
    required SyncRemote remote,
    SyncRemote? legacy,
    required KeyValueStore store,
    DateTime Function()? clock,
  })  : _legacy = legacy,
        _notes = notes,
        _store = store,
        _categories = categories,
        _tombstones = tombstones,
        _remote = remote,
        _now = clock ?? (() => DateTime.now().toUtc()) {
    _notes.localWrites.addListener(_markDirty);
    _categories.localWrites.addListener(_markDirty);
  }

  final NotesRepository _notes;
  final CategoriesRepository _categories;
  final TombstoneStore _tombstones;
  final SyncRemote _remote;
  final SyncRemote? _legacy;
  final KeyValueStore _store;
  final DateTime Function() _now;

  static const _md5Key = 'sync_last_md5';
  static const _syncedAtKey = 'sync_last_at';
  static const _dirtyKey = 'sync_dirty';
  static const _autoSyncKey = 'google_drive_auto_sync';
  static const _legacyMd5Key = 'sync_legacy_md5';
  static const _legacyIdsKey = 'sync_legacy_uuids';

  Future<void> _queue = Future.value();
  bool _isSyncing = false;
  bool _dirty = false;
  bool _autoSync = false;
  DateTime? _lastSyncedAt;

  bool get isSignedIn => _remote.isSignedIn;
  String? get accountEmail => _remote.accountEmail;

  /// المزامنة في الخلفية بعد كل تعديل محلي.
  bool get autoSync => _autoSync;
  bool get isSyncing => _isSyncing;
  bool get hasPendingChanges => _dirty;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  /// يقرأ حالة آخر مزامنة. التغييرات غير المرفوعة تبقى معلّمة بعد إعادة
  /// التشغيل.
  Future<void> initialize() async {
    _dirty = await _store.getBool(_dirtyKey) ?? true;
    _autoSync = await _store.getBool(_autoSyncKey) ?? false;
    final at = await _store.getInt(_syncedAtKey);
    _lastSyncedAt = at == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(at, isUtc: true);
    notifyListeners();
  }

  // ── الحساب ───────────────────────────────────────────────────────────────

  Future<void> restoreSession() async {
    await _remote.restoreSession();
    notifyListeners();
  }

  Future<bool> signIn() async {
    final ok = await _remote.signIn();
    notifyListeners();
    return ok;
  }

  /// يخرج ويوقف المزامنة التلقائية. حالة آخر مزامنة تُنسى: حساب آخر يبدأ
  /// بدمج لا بالكتابة فوق ملفه.
  Future<void> signOut() async {
    await _remote.signOut();
    await setAutoSync(false);
    await _store.setString(_md5Key, '');
    await _store.setString(_legacyMd5Key, '');
    _lastSyncedAt = null;
    notifyListeners();
  }

  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    await _store.setBool(_autoSyncKey, value);
    notifyListeners();
  }

  // ── المزامنة ─────────────────────────────────────────────────────────────

  /// يرفع التغييرات، أو يدمج أولاً إن تغيّرت السحابة منذ آخر رفع من هنا.
  Future<void> sync() => _exclusive(() async {
        final absorbed = await _absorbLegacy();
        final file = await _remote.stat();
        if (file != null && !await _isOurs(file)) {
          await _mergeRemote();
        } else if (file != null && !_dirty && !absorbed) {
          return;
        }
        await _upload();
      });

  /// "استخدم ما على الجهاز": يكتب حالة الجهاز فوق السحابة، ويُعدّ ما في
  /// ملف الإصدارات السابقة الآن مقروءاً.
  Future<void> overwriteRemote() => _exclusive(() async {
        await _skipLegacy();
        await _upload();
      });

  /// "استخدم ما في Drive": يستبدل ملاحظات الجهاز غير المقفلة بما في السحابة
  /// (أو بملف الإصدارات السابقة إن لم يوجد غيره). التصنيفات تُضاف ولا
  /// يُحذف منها شيء.
  Future<void> replaceLocal() => _exclusive(() async {
        final snapshot = await _read() ?? await _legacySnapshot();
        if (snapshot == null) throw const SyncException('No backup in Drive');
        await _categories.ensureNamed(snapshot.categories.values);
        await _notes
            .replaceUnlocked(_withLocalCategories(snapshot, snapshot.notes));
        await _tombstones
            .write((await _tombstones.read()).union(snapshot.tombstones));
        await _skipLegacy();
        final file = await _remote.stat();
        await _markSynced(file?.md5);
      });

  /// عدد الملاحظات في السحابة، أو null إن لم تكن فيها نسخة.
  Future<int?> remoteNoteCount() async =>
      (await _read())?.notes.length ?? (await _legacySnapshot())?.notes.length;

  Future<bool> hasRemote() async =>
      await _remote.stat() != null || await _legacy?.stat() != null;

  // ── داخلي ────────────────────────────────────────────────────────────────

  Future<void> _mergeRemote() async {
    final snapshot = await _read();
    if (snapshot != null) await _apply(snapshot);
  }

  /// يدمج ملف الإصدارات السابقة إن تغيّر منذ آخر قراءة. يُرجع true إن
  /// تغيّر شيء محلياً (فيُرفع).
  Future<bool> _absorbLegacy() async {
    final legacy = _legacy;
    if (legacy == null) return false;
    final file = await legacy.stat();
    if (file == null || file.md5 == await _store.getString(_legacyMd5Key)) {
      return false;
    }
    final snapshot = await _legacySnapshot();
    final changed = snapshot != null && await _apply(snapshot);
    await _store.setString(_legacyMd5Key, file.md5 ?? '');
    return changed;
  }

  /// يُعدّ ملف الإصدارات السابقة بحالته الحالية مدموجاً.
  Future<void> _skipLegacy() async {
    final file = await _legacy?.stat();
    if (file != null) await _store.setString(_legacyMd5Key, file.md5 ?? '');
  }

  /// لقطة ملف الإصدارات السابقة. ملفه بلا uuid، فتُعطى كل ملاحظة هوية
  /// ثابتة بـ (رقمها في الملف + وقت إنشائها) تُحفظ بين القراءات: تعديلها
  /// على الجهاز القديم لا يكررها، وحذفها هنا (بشاهده) لا يعيدها. ما كان
  /// موجوداً قبل التحديث يحمل الرقم نفسه محلياً فيأخذ uuid نسخته المحلية.
  Future<SyncSnapshot?> _legacySnapshot() async {
    final json = await _legacy?.read();
    if (json == null) return null;
    final snapshot = SyncSnapshot.fromJson(json);
    final saved = await _store.getString(_legacyIdsKey);
    final ids = saved == null || saved.isEmpty
        ? <String, String>{}
        : (jsonDecode(saved) as Map).cast<String, String>();
    for (final n in _notes.notes) {
      ids.putIfAbsent(_legacyIdentity(n), () => n.uuid);
    }
    final notes = [
      for (final n in snapshot.notes)
        n.copyWith(uuid: ids.putIfAbsent(_legacyIdentity(n), () => n.uuid)),
    ];
    await _store.setString(_legacyIdsKey, jsonEncode(ids));
    return SyncSnapshot(
      notes: notes,
      categories: snapshot.categories,
      tombstones: const Tombstones(),
      hideProFromHome: snapshot.hideProFromHome,
    );
  }

  static String _legacyIdentity(Note n) =>
      '${n.id}:${n.createdAt.millisecondsSinceEpoch}';

  /// يدمج [snapshot] محلياً. يُرجع true إن تغيّر شيء.
  Future<bool> _apply(SyncSnapshot snapshot) async {
    final plan = SyncMerge.plan(
      local: _notes.notes,
      localCategories: _categories.categories,
      localTombstones: await _tombstones.read(),
      remote: snapshot.notes,
      remoteCategories: snapshot.categories.values.toList(),
      remoteTombstones: snapshot.tombstones,
      now: _now(),
    );
    await _categories.removeSynced(plan.removedCategories);
    await _categories.ensureNamed(plan.addedCategories);
    await _notes.applySync(
      incoming: _withLocalCategories(snapshot, plan.incoming),
      removed: plan.removedNotes,
    );
    await _tombstones.write(plan.tombstones);
    final hidePro = snapshot.hideProFromHome;
    if (hidePro != null && !_dirty) {
      await _categories.applySyncedHideProFromHome(hidePro);
    }
    return plan.changesLocal;
  }

  Future<void> _upload() async {
    await _setDirty(false);
    final snapshot = SyncSnapshot(
      notes: _notes.notes,
      categories: {for (final c in _categories.categories) c.id: c.name},
      tombstones: await _tombstones.read(),
      hideProFromHome: _categories.hideProFromHome,
    );
    try {
      final file = await _remote.write(snapshot.toJson(_now()));
      await _markSynced(file.md5);
    } on Object {
      await _setDirty(true);
      rethrow;
    }
  }

  /// أرقام تصنيفات اللقطة ← الأرقام المحلية بالاسم. لقطة بلا تصنيفات
  /// (الإصدار 1) تُبقي تصنيفات الملاحظة المحلية.
  List<Note> _withLocalCategories(SyncSnapshot snapshot, List<Note> notes) {
    final localByUuid = {for (final n in _notes.notes) n.uuid: n};
    return [
      for (final n in notes)
        n.copyWith(
          categoryIds: snapshot.categories.isEmpty
              ? localByUuid[n.uuid]?.categoryIds ?? const []
              : {
                  for (final id in n.categoryIds)
                    if (snapshot.categories[id] case final name?)
                      if (_categories.byName(name) case final local?) local.id,
                }.toList(),
        ),
    ];
  }

  Future<SyncSnapshot?> _read() async {
    final json = await _remote.read();
    return json == null ? null : SyncSnapshot.fromJson(json);
  }

  Future<bool> _isOurs(RemoteFile file) async {
    final ours = await _store.getString(_md5Key);
    return ours != null && ours.isNotEmpty && ours == file.md5;
  }

  Future<void> _markSynced(String? md5) async {
    if (md5 != null) await _store.setString(_md5Key, md5);
    _lastSyncedAt = _now();
    await _store.setInt(_syncedAtKey, _lastSyncedAt!.millisecondsSinceEpoch);
    await _setDirty(false);
  }

  void _markDirty() {
    if (!_dirty) _setDirty(true);
  }

  Future<void> _setDirty(bool value) async {
    _dirty = value;
    await _store.setBool(_dirtyKey, value);
  }

  Future<void> _exclusive(Future<void> Function() operation) {
    final run = _queue.then((_) async {
      _isSyncing = true;
      notifyListeners();
      try {
        await operation();
      } finally {
        _isSyncing = false;
        notifyListeners();
      }
    });
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  @override
  void dispose() {
    _notes.localWrites.removeListener(_markDirty);
    _categories.localWrites.removeListener(_markDirty);
    super.dispose();
  }
}
