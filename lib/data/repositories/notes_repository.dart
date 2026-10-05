// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:sinan_note/data/repositories/vault_repository.dart';
import 'package:sinan_note/data/services/database/note_mapper.dart';
import 'package:sinan_note/data/services/note_side_effects.dart';
import 'package:sinan_note/data/services/sync/tombstone_store.dart';
import 'package:sinan_note/data/services/vault/vault_cipher.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_version.dart';
import 'package:sinan_note/domain/versioning.dart';
import 'package:sqflite/sqflite.dart';

/// المصدر الوحيد للملاحظات، والكاتب الوحيد لجدول `notes`.
///
/// - الملاحظات غير المقفلة في ذاكرة مرتبة ([notes])، وكل كتابة تحدّثها ثم
///   تُخطر المستمعين.
/// - الملاحظة المقفلة تُشفَّر هنا فقط، عند الكتابة، بمفتاح [VaultRepository]؛
///   وتُفك عند القراءة فقط والخزنة مفتوحة. خارج هذا الصنف هي دائماً نص واضح
///   بعلامة `isLocked = true`، فلا يحتاج أحد لحراسة التشفير.
/// - لا نسخ سابقة لملاحظة مقفلة، ولا فهرس بحث مشتق من نصها.
class NotesRepository extends ChangeNotifier {
  NotesRepository({
    required Database db,
    required VaultRepository vault,
    required NoteSideEffects sideEffects,
    required DeletionLog deletionLog,
    DateTime Function()? clock,
  })  : _db = db,
        _vault = vault,
        _sideEffects = sideEffects,
        _deletionLog = deletionLog,
        _now = clock ?? DateTime.now;

  final Database _db;
  final VaultRepository _vault;
  final NoteSideEffects _sideEffects;
  final DeletionLog _deletionLog;
  final DateTime Function() _now;

  List<Note> _notes = const [];
  bool _isLoaded = false;

  /// يزداد مع كل كتابة محلية (لا مع [load]) — ما تراقبه المزامنة لترفع
  /// التغييرات، دون أن تعيد تحميلُها بعد المزامنة تشغيلَها من جديد.
  final localWrites = ValueNotifier(0);

  /// كل الملاحظات غير المقفلة (النشطة والمؤرشفة والمحذوفة)، المثبّتة أولاً ثم
  /// الأحدث تعديلاً.
  List<Note> get notes => _notes;
  bool get isLoaded => _isLoaded;

  Note? cached(int id) {
    for (final n in _notes) {
      if (n.id == id) return n;
    }
    return null;
  }

  // ── القراءة ──────────────────────────────────────────────────────────────

  /// يعيد تحميل الذاكرة من القاعدة (عند البدء وبعد أي كتابة خارجية:
  /// مزامنة، استعادة نسخة).
  Future<void> load() async {
    final rows = await _db.query('notes', where: 'isLocked = 0');
    _notes = _sorted(rows.map(NoteMapper.fromMap));
    _isLoaded = true;
    notifyListeners();
  }

  /// الملاحظات المقفلة مفكوكة. يرمي `VaultLockedException` والخزنة مقفلة.
  Future<List<Note>> lockedNotes() async {
    final rows = await _db.query('notes', where: 'isLocked = 1');
    return _sorted(rows.map((row) => _unseal(NoteMapper.fromMap(row))));
  }

  /// ملاحظة واحدة كما هي الآن في القاعدة (مفكوكة إن كانت مقفلة).
  Future<Note?> find(int id) async {
    final row = await _row(id);
    if (row == null) return null;
    return row.isLocked ? _unseal(row) : row;
  }

  // ── الكتابة ──────────────────────────────────────────────────────────────

  /// يضيف ملاحظة جديدة (id = null) أو يحدّث موجودة. يُرجعها كما حُفظت.
  Future<Note> save(Note note) async {
    final stored = await _write(note);
    _remember(stored);
    await _sideEffects.noteChanged(_sealed(stored));
    _changedLocally();
    return stored;
  }

  /// يغيّر خصائص لا تمس النص، على الصف المخزن مباشرة: لا يحتاج الخزنة
  /// مفتوحة للملاحظة المقفلة، ونصها المشفّر يبقى كما هو.
  Future<Note?> updateMeta(
    int id, {
    int? colorIndex,
    bool? isPinned,
    Object? reminderDateTime = _keep,
    String? recurrenceRule,
    List<int>? categoryIds,
    bool? isHiddenFromHome,
  }) async {
    final current = await _row(id);
    if (current == null) return null;
    return save(current.copyWith(
      colorIndex: colorIndex,
      isPinned: isPinned,
      reminderDateTime: reminderDateTime,
      recurrenceRule: recurrenceRule,
      categoryIds: categoryIds,
      isHiddenFromHome: isHiddenFromHome,
    ));
  }

  /// يقلب التثبيت. يُرجع الحالة الجديدة، أو null إن لم توجد الملاحظة.
  Future<bool?> togglePinned(int id) async {
    final current = await _row(id);
    if (current == null) return null;
    return (await updateMeta(id, isPinned: !current.isPinned))?.isPinned;
  }

  Future<void> archive(List<int> ids) =>
      _setFlags(ids, (n) => n.copyWith(isArchived: true));

  Future<void> unarchive(List<int> ids) =>
      _setFlags(ids, (n) => n.copyWith(isArchived: false));

  Future<void> trash(List<int> ids) =>
      _setFlags(ids, (n) => n.copyWith(isTrashed: true));

  /// من السلة أو الأرشيف إلى الملاحظات النشطة.
  Future<void> restore(List<int> ids) =>
      _setFlags(ids, (n) => n.copyWith(isTrashed: false, isArchived: false));

  /// حذف نهائي، مع النسخ السابقة.
  Future<void> delete(List<int> ids) async {
    if (ids.isEmpty) return;
    final uuids = <String>[];
    await _db.transaction((txn) async {
      for (final id in ids) {
        final row = await txn.query('notes',
            columns: ['uuid'], where: 'id = ?', whereArgs: [id]);
        if (row.isNotEmpty) uuids.add(row.single['uuid'] as String);
        await txn.delete('note_versions', where: 'noteId = ?', whereArgs: [id]);
        await txn.delete('notes', where: 'id = ?', whereArgs: [id]);
      }
    });
    await _deletionLog.notesDeleted(uuids);
    _notes = [
      for (final n in _notes)
        if (!ids.contains(n.id)) n
    ];
    for (final id in ids) {
      await _sideEffects.noteRemoved(id);
    }
    _changedLocally();
  }

  /// يقفل أو يفك قفل ملاحظة. يرمي `VaultLockedException` والخزنة مقفلة،
  /// و`VaultDecryptionException` إن تعذّر فكها — فلا يتغير شيء.
  Future<void> setLocked(int id, bool locked) async {
    final current = await find(id);
    if (current == null || current.isLocked == locked) return;
    final changed = current.copyWith(isLocked: locked, updatedAt: _now());
    await _db.transaction((txn) async {
      await txn
          .update('notes', _toRow(changed), where: 'id = ?', whereArgs: [id]);
      // نسخ ما قبل القفل نص واضح — لا تبقى بعده
      if (locked) {
        await txn.delete('note_versions', where: 'noteId = ?', whereArgs: [id]);
      }
    });
    if (locked) {
      _notes = [
        for (final n in _notes)
          if (n.id != id) n
      ];
    } else {
      _remember(changed);
    }
    await _sideEffects.noteChanged(_sealed(changed));
    _changedLocally();
  }

  /// نسخة مستقلة بهوية جديدة. يُرجع الملاحظة الجديدة.
  Future<Note?> duplicate(int id, {required String copyLabel}) async {
    final original = await find(id);
    if (original == null) return null;
    final title =
        original.title.isEmpty ? copyLabel : '${original.title} - $copyLabel';
    return save(
        original.asNew(at: _now()).copyWith(title: title, isPinned: false));
  }

  /// يغيّر نوع الملاحظة ومحتواها، بعد حفظ نسخة من حالتها السابقة.
  Future<Note?> convertType(
    int id, {
    required String content,
    required String noteType,
    required bool isChecklist,
  }) async {
    final current = await find(id);
    if (current == null) return null;
    await _recordVersion(current, VersionTrigger.forced);
    return save(current.copyWith(
      content: content,
      noteType: noteType,
      isChecklist: isChecklist,
      isProfessional: noteType == 'code',
      updatedAt: _now(),
    ));
  }

  // ── الاستيراد ────────────────────────────────────────────────────────────

  /// يدمج ملاحظات واردة (نسخة احتياطية/ملف) دون حذف أو استبدال أي ملاحظة
  /// محلية، في transaction واحدة:
  /// - نفس الـ uuid ← تبقى النسخة الأحدث تعديلاً (بالـ id المحلي).
  /// - مطابقة تماماً (وقت الإنشاء والعنوان والمحتوى) ← مكررة، تُتجاهل —
  ///   هكذا تُعرف ملاحظات النسخ القديمة التي لا تحمل uuid.
  /// - غير ذلك ← تُضاف بـ id جديد.
  /// المقفلة المشفّرة تبقى كما هي؛ المقفلة بنص واضح تُشفَّر، فإن كانت الخزنة
  /// مقفلة يرمي `VaultLockedException` قبل أي كتابة. يُرجع عدد ما أُضيف
  /// أو حُدّث، والرقم المحلي لكل واردة (بما فيها المكررة) بالـ uuid الوارد.
  Future<({int written, Map<String, int> localIds})> merge(
      List<Note> incoming) async {
    final rows = await _db.query('notes');
    final local = rows.map(NoteMapper.fromMap).toList();
    final byUuid = {for (final n in local) n.uuid: n};
    final byFingerprint = {for (final n in local) n.fingerprint: n};

    final writes = <Note>[];
    // uuid الوارد ← uuid الملاحظة التي تمثله (محلية أو أول وارد بنفس البصمة)
    final sameAs = <String, String>{};
    for (final note in incoming) {
      final existing = byUuid[note.uuid] ?? byFingerprint[note.fingerprint];
      if (existing == null) {
        writes.add(note.copyWith(id: null));
        byUuid[note.uuid] = note;
        byFingerprint[note.fingerprint] = note;
        sameAs[note.uuid] = note.uuid;
        continue;
      }
      sameAs[note.uuid] = existing.uuid;
      if (existing.id != null &&
          existing.uuid == note.uuid &&
          note.updatedAt.isAfter(existing.updatedAt)) {
        writes.add(note.copyWith(id: existing.id));
      }
    }
    final idByUuid = {
      for (final n in local)
        if (n.id != null) n.uuid: n.id!,
    };
    final rowsToWrite = [for (final n in writes) (n, _toRow(n))];
    await _db.transaction((txn) async {
      for (final (note, row) in rowsToWrite) {
        if (note.id == null) {
          idByUuid[note.uuid] = await txn.insert('notes', row..remove('id'));
        } else {
          await txn.update('notes', row, where: 'id = ?', whereArgs: [note.id]);
        }
      }
    });
    if (writes.isNotEmpty) {
      await load();
      _changedLocally();
    }
    return (
      written: writes.length,
      localIds: {
        for (final MapEntry(:key, :value) in sameAs.entries)
          if (idByUuid[value] case final id?) key: id,
      },
    );
  }

  /// يستبدل الملاحظات غير المقفلة بالواردة، في transaction واحدة. ملاحظات
  /// الخزنة المحلية لا تُمس. نفس شروط التشفير في [merge].
  /// يُرجع الرقم المحلي لكل واردة بالـ uuid.
  Future<Map<String, int>> replaceUnlocked(List<Note> incoming) async {
    final rowsToWrite = [
      for (final n in incoming) (n.uuid, _toRow(n.copyWith(id: null)))
    ];
    final localIds = <String, int>{};
    await _db.transaction((txn) async {
      await txn.delete('note_versions',
          where: 'noteId IN (SELECT id FROM notes WHERE isLocked = 0)');
      await txn.delete('notes', where: 'isLocked = 0');
      for (final (uuid, row) in rowsToWrite) {
        localIds[uuid] = await txn.insert('notes', row..remove('id'),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    await load();
    _changedLocally();
    return localIds;
  }

  /// يضيف نسخاً سابقة مستوردة ([versions]: الرقم المحلي للملاحظة ← نسخها).
  /// المقفلة لا تأخذ نسخاً، والموجودة (نفس الوقت والمحتوى) لا تتكرر،
  /// ويبقى لكل ملاحظة أحدث [VersionPolicy.maxVersionsPerNote].
  Future<void> importVersions(Map<int, List<NoteVersion>> versions) async {
    if (versions.isEmpty) return;
    await _db.transaction((txn) async {
      for (final MapEntry(key: id, value: list) in versions.entries) {
        final note = await txn.query('notes',
            columns: ['isLocked'], where: 'id = ?', whereArgs: [id]);
        if (note.isEmpty || note.single['isLocked'] != 0) continue;
        final existing = {
          for (final r in await txn.query('note_versions',
              columns: ['timestamp', 'content'],
              where: 'noteId = ?',
              whereArgs: [id]))
            (r['timestamp'], r['content']),
        };
        for (final v in list) {
          final timestamp = v.timestamp.toUtc().toIso8601String();
          if (!existing.add((timestamp, v.content))) continue;
          await txn.insert('note_versions', {
            'noteId': id,
            'title': v.title,
            'content': v.content,
            'timestamp': timestamp,
            'action': v.action,
            'noteType': v.noteType,
          });
        }
        await txn.rawDelete(
          'DELETE FROM note_versions WHERE noteId = ? AND id NOT IN '
          '(SELECT id FROM note_versions WHERE noteId = ? '
          'ORDER BY timestamp DESC LIMIT ?)',
          [id, id, VersionPolicy.maxVersionsPerNote],
        );
      }
    });
  }

  // ── التصنيفات والمزامنة ──────────────────────────────────────────────────

  /// ينقل الملاحظات من التصنيف [from] إلى [to]، أو يزيله منها إن كان null.
  /// على الصفوف المخزنة مباشرة: لا يحتاج الخزنة، ولا يُعد تعديلاً للملاحظة.
  Future<void> reassignCategory(int from, {int? to}) async {
    final rows = await _db.query('notes',
        columns: ['id', 'categoryIds', 'isHiddenFromHome'],
        where: "(',' || categoryIds || ',') LIKE ?",
        whereArgs: ['%,$from,%']);
    if (rows.isEmpty) return;
    await _db.transaction((txn) async {
      for (final row in rows) {
        final ids = (row['categoryIds'] as String)
            .split(',')
            .map(int.tryParse)
            .whereType<int>()
            .where((id) => id != from)
            .toList();
        if (to != null && !ids.contains(to)) ids.add(to);
        await txn.update(
          'notes',
          {
            'categoryIds': ids.join(','),
            // مخفية من الرئيسية لأنها في تصنيف؟ بلا تصنيف تعود للظهور
            if (ids.isEmpty) 'isHiddenFromHome': 0,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    });
    await load();
  }

  /// يطبق نتيجة دمج المزامنة في transaction واحدة: يكتب [incoming] (بالـ
  /// uuid؛ المقفلة محلياً لا تُمس) ويحذف [removed]. ليس كتابة محلية فلا
  /// يُطلق [localWrites]، ولا يُسجَّل الحذف (جاء من الطرف الآخر).
  Future<void> applySync(
      {required List<Note> incoming, required Set<String> removed}) async {
    if (incoming.isEmpty && removed.isEmpty) return;
    final rows = await _db.query('notes', columns: ['id', 'uuid', 'isLocked']);
    final local = {for (final r in rows) r['uuid'] as String: r};
    final written = <Note>[];
    final deletedIds = <int>[];
    await _db.transaction((txn) async {
      for (final note in incoming) {
        if (note.isLocked) continue;
        final existing = local[note.uuid];
        if (existing == null) {
          final row = _toRow(note)..remove('id');
          written.add(note.copyWith(id: await txn.insert('notes', row)));
        } else if (existing['isLocked'] == 0) {
          final id = existing['id'] as int;
          await txn.update('notes', _toRow(note.copyWith(id: id)),
              where: 'id = ?', whereArgs: [id]);
          written.add(note.copyWith(id: id));
        }
      }
      for (final uuid in removed) {
        final existing = local[uuid];
        if (existing == null || existing['isLocked'] != 0) continue;
        final id = existing['id'] as int;
        await txn.delete('note_versions', where: 'noteId = ?', whereArgs: [id]);
        await txn.delete('notes', where: 'id = ?', whereArgs: [id]);
        deletedIds.add(id);
      }
    });
    await load();
    for (final note in written) {
      await _sideEffects.noteChanged(note);
    }
    for (final id in deletedIds) {
      await _sideEffects.noteRemoved(id);
    }
  }

  // ── الخزنة ───────────────────────────────────────────────────────────────

  /// يفك قفل كل الملاحظات المقفلة (قبل حذف الخزنة). يفك كل شيء في الذاكرة
  /// أولاً: إن تعذّر فك أي ملاحظة يرمي قبل أي كتابة، فلا يضيع شيء.
  Future<void> unlockAll() async {
    final opened = [
      for (final n in await lockedNotes())
        n.copyWith(isLocked: false, updatedAt: _now()),
    ];
    if (opened.isEmpty) return;
    await _db.transaction((txn) async {
      for (final n in opened) {
        await txn.update('notes', NoteMapper.toMap(n),
            where: 'id = ?', whereArgs: [n.id]);
      }
    });
    opened.forEach(_remember);
    for (final n in opened) {
      await _sideEffects.noteChanged(n);
    }
    _changedLocally();
  }

  /// يحذف كل الملاحظات المقفلة نهائياً (حذف الخزنة بمحتواها). لا يحتاج
  /// الخزنة مفتوحة.
  Future<void> deleteAllLocked() async {
    final rows =
        await _db.query('notes', columns: ['id'], where: 'isLocked = 1');
    await delete([for (final r in rows) r['id'] as int]);
  }

  /// يعيد تشفير قيم الصيغة القديمة (AES-CTR) بالصيغة الحالية. يُستدعى بعد
  /// فتح الخزنة؛ في transaction واحدة.
  Future<int> migrateLegacyCiphertext() async {
    final rows = await _db.query('notes', where: 'isLocked = 1');
    final legacy = rows.map(NoteMapper.fromMap).where((n) =>
        VaultCipher.isLegacy(n.title) || VaultCipher.isLegacy(n.content));
    final migrated = [for (final n in legacy) _sealed(_unseal(n))];
    if (migrated.isEmpty) return 0;
    await _db.transaction((txn) async {
      for (final n in migrated) {
        await txn.update('notes', NoteMapper.toMap(n)..addAll(_noIndex),
            where: 'id = ?', whereArgs: [n.id]);
      }
    });
    return migrated.length;
  }

  /// يعيد تشفير كل القيم المقفلة بـ [reseal] في transaction واحدة — لتدوير
  /// مفتاح الخزنة (`VaultRepository.rotateKey`). أي فشل يُرجع كل شيء.
  Future<void> resealAll(String Function(String sealed) reseal) async {
    final rows = await _db.query('notes', where: 'isLocked = 1');
    await _db.transaction((txn) async {
      for (final n in rows.map(NoteMapper.fromMap)) {
        await txn.update(
          'notes',
          {
            'title': n.title.isEmpty ? '' : reseal(n.title),
            'content': n.content.isEmpty ? '' : reseal(n.content),
          },
          where: 'id = ?',
          whereArgs: [n.id],
        );
      }
    });
  }

  // ── النسخ السابقة ────────────────────────────────────────────────────────

  /// يحفظ نسخة من الملاحظة كما هي مخزّنة الآن، حسب [VersionPolicy]. لا نسخ
  /// للملاحظات المقفلة أبداً — يُقرأ ذلك من القاعدة لا من المستدعي.
  Future<void> recordVersion(int id, VersionTrigger trigger) async {
    final stored = await _row(id);
    if (stored != null) await _recordVersion(stored, trigger);
  }

  /// ملاحظات غير مقفلة لها نسخ سابقة.
  Future<List<Note>> notesWithHistory() async {
    final rows = await _db.query('notes',
        where: 'isLocked = 0 AND id IN (SELECT noteId FROM note_versions)');
    return _sorted(rows.map(NoteMapper.fromMap));
  }

  /// يعيد الملاحظة إلى [version] بعد حفظ حالتها الحالية كنسخة.
  Future<Note?> restoreVersion(int id, NoteVersion version) async {
    final current = await _row(id);
    if (current == null || current.isLocked) return null;
    await _recordVersion(current, VersionTrigger.forced);
    final noteType =
        version.noteType.isNotEmpty ? version.noteType : current.noteType;
    return save(current.copyWith(
      title: version.title,
      content: version.content,
      noteType: noteType,
      isChecklist: noteType == 'checklist',
      isProfessional: noteType == 'code',
      updatedAt: _now(),
    ));
  }

  Future<void> _recordVersion(Note note, VersionTrigger trigger) async {
    final id = note.id;
    if (id == null || note.isLocked) return;
    final last = await lastVersion(id);
    if (!VersionPolicy.shouldRecord(
        trigger: trigger,
        last: last,
        title: note.title,
        content: note.content)) {
      return;
    }
    await _db.transaction((txn) async {
      await txn.insert('note_versions', {
        'noteId': id,
        'title': note.title,
        'content': note.content,
        'timestamp': _now().toUtc().toIso8601String(),
        'action': trigger.action,
        'noteType': note.noteType,
      });
      await txn.rawDelete(
        'DELETE FROM note_versions WHERE noteId = ? AND id NOT IN '
        '(SELECT id FROM note_versions WHERE noteId = ? '
        'ORDER BY timestamp DESC LIMIT ?)',
        [id, id, VersionPolicy.maxVersionsPerNote],
      );
    });
  }

  Future<List<NoteVersion>> history(int noteId) async {
    final rows = await _db.query('note_versions',
        where: 'noteId = ?', whereArgs: [noteId], orderBy: 'timestamp DESC');
    return rows.map(NoteMapper.versionFromMap).toList();
  }

  Future<NoteVersion?> lastVersion(int noteId) async {
    final rows = await _db.query('note_versions',
        where: 'noteId = ?',
        whereArgs: [noteId],
        orderBy: 'timestamp DESC',
        limit: 1);
    return rows.isEmpty ? null : NoteMapper.versionFromMap(rows.first);
  }

  // ── داخلي ────────────────────────────────────────────────────────────────

  static const _keep = Object();

  /// الملاحظة المقفلة لا فهرس بحث لها مشتق من نصها.
  static const _noIndex = {'normalizedTitle': '', 'normalizedContent': ''};

  Future<Note> _write(Note note) async {
    final row = _toRow(note);
    if (note.id == null) {
      row.remove('id');
      return note.copyWith(id: await _db.insert('notes', row));
    }
    await _db.update('notes', row, where: 'id = ?', whereArgs: [note.id]);
    return note;
  }

  Future<void> _setFlags(List<int> ids, Note Function(Note) change) async {
    if (ids.isEmpty) return;
    final now = _now();
    final changed = <Note>[];
    for (final id in ids) {
      final current = await _row(id);
      if (current != null) {
        changed.add(change(current).copyWith(updatedAt: now));
      }
    }
    await _db.transaction((txn) async {
      for (final n in changed) {
        // الصف كما هو مخزن (مشفّر إن كان مقفلاً) — الأعلام فقط تتغير
        await txn.update(
            'notes', NoteMapper.toMap(n)..addAll(n.isLocked ? _noIndex : {}),
            where: 'id = ?', whereArgs: [n.id]);
      }
    });
    for (final n in changed) {
      if (!n.isLocked) _remember(n);
      await _sideEffects.noteChanged(n);
    }
    _changedLocally();
  }

  Map<String, Object?> _toRow(Note note) {
    final sealed = _sealed(note);
    final row = NoteMapper.toMap(sealed);
    return note.isLocked ? (row..addAll(_noIndex)) : row;
  }

  /// النسخة المخزنة: المقفلة بعنوان ومحتوى مشفرين (الفارغ يبقى فارغاً).
  Note _sealed(Note note) {
    if (!note.isLocked) return note;
    String seal(String text) =>
        text.isEmpty || VaultCipher.isSealed(text) ? text : _vault.seal(text);
    return note.copyWith(title: seal(note.title), content: seal(note.content));
  }

  Note _unseal(Note stored) {
    String open(String text) =>
        VaultCipher.isSealed(text) ? _vault.open(text) : text;
    return stored.copyWith(
        title: open(stored.title), content: open(stored.content));
  }

  Future<Note?> _row(int id) async {
    final rows =
        await _db.query('notes', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : NoteMapper.fromMap(rows.first);
  }

  void _remember(Note note) {
    if (note.isLocked) return;
    _notes = _sorted([
      for (final n in _notes)
        if (n.id != note.id) n,
      note,
    ]);
  }

  void _changedLocally() {
    localWrites.value++;
    notifyListeners();
  }

  @override
  void dispose() {
    localWrites.dispose();
    super.dispose();
  }

  static List<Note> _sorted(Iterable<Note> notes) => List.unmodifiable(
        notes.toList()
          ..sort((a, b) {
            if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
            return b.updatedAt.compareTo(a.updatedAt);
          }),
      );
}
