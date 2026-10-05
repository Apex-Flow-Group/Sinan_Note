import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_category.dart';
import 'package:sinan_note/domain/sync/sync_merge.dart';
import 'package:sinan_note/domain/sync/tombstones.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 1);
  DateTime at(int hours) => t0.add(Duration(hours: hours));
  final now = at(100);

  Note note(String uuid, {int edited = 0, String? title, bool? locked}) => Note(
        uuid: uuid,
        title: title ?? uuid,
        content: 'c',
        createdAt: t0,
        updatedAt: at(edited),
        isLocked: locked ?? false,
      );

  SyncPlan plan({
    List<Note> local = const [],
    List<Note> remote = const [],
    Tombstones mine = const Tombstones(),
    Tombstones theirs = const Tombstones(),
    List<NoteCategory> localCategories = const [],
    List<String> remoteCategories = const [],
  }) =>
      SyncMerge.plan(
        local: local,
        localCategories: localCategories,
        localTombstones: mine,
        remote: remote,
        remoteCategories: remoteCategories,
        remoteTombstones: theirs,
        now: now,
      );

  group('notes', () {
    test('a note missing on one side is added, never deleted', () {
      final p = plan(local: [note('a')], remote: [note('b')]);
      expect(p.incoming.map((n) => n.uuid), ['b']);
      expect(p.removedNotes, isEmpty);
    });

    test('the newer edit wins; the older side is not written', () {
      expect(
          plan(local: [note('a', edited: 1)], remote: [note('a', edited: 2)])
              .incoming
              .single
              .updatedAt,
          at(2));
      expect(
          plan(local: [note('a', edited: 3)], remote: [note('a', edited: 2)])
              .incoming,
          isEmpty);
    });

    test('same numeric id on two devices is two different notes', () {
      final p = plan(
        local: [note('a', title: 'mine').copyWith(id: 7)],
        remote: [note('b', title: 'theirs').copyWith(id: 7)],
      );
      expect(p.incoming.single.title, 'theirs');
      expect(p.removedNotes, isEmpty);
    });

    test('a file without shared uuids is matched by fingerprint', () {
      final local = note('local-uuid', edited: 1, title: 'same');
      final legacy = note('fresh-random-uuid', edited: 5, title: 'same');
      final p = plan(local: [local], remote: [legacy]);
      expect(p.incoming.single.uuid, 'local-uuid');

      expect(
          plan(local: [local], remote: [note('x', edited: 1, title: 'same')])
              .incoming,
          isEmpty,
          reason: 'identical legacy copy is not duplicated');
    });

    test('a tombstone deletes on both sides unless edited afterwards', () {
      final deleted = Tombstones(notes: {'a': at(5)});
      expect(plan(local: [note('a', edited: 1)], theirs: deleted).removedNotes,
          {'a'});
      expect(plan(remote: [note('a', edited: 1)], mine: deleted).incoming,
          isEmpty);
      expect(plan(local: [note('a', edited: 9)], theirs: deleted).removedNotes,
          isEmpty,
          reason: 'edited after the deletion');
    });

    test('tombstones accumulate across devices and expire', () {
      final p = plan(
        mine: Tombstones(notes: {'a': at(1)}),
        theirs: Tombstones(notes: {
          'b': at(2),
          'old': now.subtract(Tombstones.lifetime + const Duration(days: 1)),
        }),
      );
      expect(p.tombstones.notes.keys, unorderedEquals(['a', 'b']));
    });

    test('locked notes are never synced or touched', () {
      final p = plan(
        local: [note('a', locked: true)],
        remote: [note('b', locked: true)],
        theirs: Tombstones(notes: {'a': at(5)}),
      );
      expect(p.incoming, isEmpty);
      expect(p.removedNotes, isEmpty);
    });
  });

  group('categories', () {
    const work = NoteCategory(id: 3, name: 'Work');

    test('matched by name, case-insensitively; missing ones added', () {
      final p = plan(
          localCategories: [work],
          remoteCategories: ['work', 'Ideas', 'ideas']);
      expect(p.addedCategories, ['Ideas']);
      expect(p.removedCategories, isEmpty);
    });

    test('a deleted category is removed and not re-added', () {
      final deleted = const Tombstones().withCategory('WORK', at(1));
      expect(plan(localCategories: [work], theirs: deleted).removedCategories,
          {3});
      expect(plan(remoteCategories: ['Work'], mine: deleted).addedCategories,
          isEmpty);
    });

    test('creating it again after the deletion wins', () {
      final history = const Tombstones()
          .withCategory('Work', at(1))
          .withRevivedCategory('work', at(2));
      expect(plan(localCategories: [work], theirs: history).removedCategories,
          isEmpty);
    });
  });

  test('tombstones survive a JSON round trip', () {
    final t = const Tombstones()
        .withNotes(['a'], at(1))
        .withCategory('Work', at(2))
        .withRevivedCategory('Work', at(3));
    final back = Tombstones.fromJson(t.toJson());
    expect(back.notes, t.notes);
    expect(back.categories, t.categories);
    expect(back.revivedCategories, t.revivedCategories);
  });
}
