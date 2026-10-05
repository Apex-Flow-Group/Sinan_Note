// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/domain/categories.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_category.dart';
import 'package:sinan_note/domain/sync/tombstones.dart';

/// ما يجب أن يتغير محلياً لتصبح الحالة اتحاد الجهازين.
class SyncPlan {
  const SyncPlan({
    required this.incoming,
    required this.removedNotes,
    required this.addedCategories,
    required this.removedCategories,
    required this.tombstones,
  });

  /// ملاحظات من الطرف الآخر تُكتب محلياً: جديدة، أو أحدث من نسختها المحلية
  /// (وتحمل حينها uuid النسخة المحلية). أرقام تصنيفاتها أرقام الطرف الآخر.
  final List<Note> incoming;

  /// uuid ملاحظات محلية حُذفت بعد آخر تعديل لها.
  final Set<String> removedNotes;

  /// أسماء تصنيفات من الطرف الآخر غير موجودة محلياً.
  final List<String> addedCategories;

  /// أرقام تصنيفات محلية حُذفت في الطرف الآخر.
  final Set<int> removedCategories;

  /// اتحاد الشواهد بعد إسقاط القديم منها.
  final Tombstones tombstones;

  bool get changesLocal =>
      incoming.isNotEmpty ||
      removedNotes.isNotEmpty ||
      addedCategories.isNotEmpty ||
      removedCategories.isNotEmpty;
}

/// دمج حالتين بلا فقد — بلا حالة ولا I/O.
///
/// - الهوية بالـ uuid؛ ملاحظة بلا uuid مشترك (ملفات قديمة) تُعرف ببصمتها.
/// - الأحدث تعديلاً يفوز.
/// - الحذف بالشاهد وحده، وتعديل لاحق للحذف يعيد الملاحظة.
/// - الملاحظات المقفلة لا تُزامن ولا تُمس.
abstract final class SyncMerge {
  static SyncPlan plan({
    required List<Note> local,
    required List<NoteCategory> localCategories,
    required Tombstones localTombstones,
    required List<Note> remote,
    required List<String> remoteCategories,
    required Tombstones remoteTombstones,
    required DateTime now,
  }) {
    final tombstones = localTombstones.union(remoteTombstones).prune(now);
    final mine = [
      for (final n in local)
        if (!n.isLocked) n
    ];
    final byUuid = {for (final n in mine) n.uuid: n};
    final byFingerprint = {for (final n in mine) n.fingerprint: n};

    final incoming = <Note>[];
    final seen = <String>{};
    for (final theirs in remote) {
      if (theirs.isLocked) continue;
      final match = byUuid[theirs.uuid] ?? byFingerprint[theirs.fingerprint];
      final note = match == null ? theirs : theirs.copyWith(uuid: match.uuid);
      if (!seen.add(note.uuid)) continue;
      if (tombstones.deletes(note.uuid, note.updatedAt)) continue;
      if (match == null || note.updatedAt.isAfter(match.updatedAt)) {
        incoming.add(note);
      }
    }

    final removedNotes = {
      for (final n in mine)
        if (tombstones.deletes(n.uuid, n.updatedAt)) n.uuid
    };

    final deleted = tombstones.deletesCategory;
    final localNames = {
      for (final c in localCategories) CategoryPolicy.sameNameKey(c.name)
    };
    final added = <String>[];
    for (final name in remoteCategories) {
      if (deleted(name)) continue;
      if (localNames.add(CategoryPolicy.sameNameKey(name))) added.add(name);
    }

    return SyncPlan(
      incoming: incoming,
      removedNotes: removedNotes,
      addedCategories: added,
      removedCategories: {
        for (final c in localCategories)
          if (deleted(c.name)) c.id
      },
      tombstones: tombstones,
    );
  }
}
