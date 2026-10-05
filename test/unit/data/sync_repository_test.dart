import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/data/repositories/sync_repository.dart';
import 'package:sinan_note/data/services/sync/drive_sync_remote.dart';
import 'package:sinan_note/domain/errors.dart';
import 'package:sinan_note/domain/models/note.dart';

import '../../helpers/test_data_layer.dart';
import '../../test_setup.dart';

/// Drive في الذاكرة يتشاركه "الجهازان". الـ JSON يمر بـ encode/decode كما
/// في الحقيقة، و md5 يتغير مع كل كتابة.
class FakeDrive implements SyncRemote {
  String? _file;
  int _version = 0;
  int writes = 0;
  bool failing = false;

  Object? get contents => _file == null ? null : jsonDecode(_file!);
  set contents(Object? json) {
    _file = json == null ? null : jsonEncode(json);
    _version++;
  }

  void _check() {
    if (failing) throw const SyncException('offline');
  }

  @override
  bool get isSignedIn => true;
  @override
  String? get accountEmail => 'me@example.com';
  @override
  Future<void> restoreSession() async {}
  @override
  Future<bool> signIn() async => true;
  @override
  Future<void> signOut() async {}

  @override
  Future<RemoteFile?> stat() async {
    _check();
    return _file == null ? null : RemoteFile(md5: 'v$_version');
  }

  @override
  Future<Object?> read() async {
    _check();
    return contents;
  }

  @override
  Future<RemoteFile> write(Map<String, Object?> json) async {
    _check();
    writes++;
    contents = json;
    return RemoteFile(md5: 'v$_version');
  }
}

class Device {
  Device._(this.data, this.sync);

  final TestDataLayer data;
  final SyncRepository sync;

  static Future<Device> create(FakeDrive drive, DateTime Function() clock,
      {FakeDrive? legacy}) async {
    final data = await TestDataLayer.create(clock: clock);
    final sync = SyncRepository(
      notes: data.notes,
      categories: data.categories,
      tombstones: data.tombstones,
      remote: drive,
      legacy: legacy,
      store: data.store,
      clock: clock,
    );
    await sync.initialize();
    return Device._(data, sync);
  }

  List<String> get titles =>
      data.notes.notes.map((n) => n.title).toList()..sort();

  Future<Note> write(String title, {DateTime? at}) => data.notes.save(Note(
      title: title,
      content: 'c',
      createdAt: at ?? DateTime.utc(2026),
      updatedAt: at ?? DateTime.utc(2026)));

  Future<void> dispose() async {
    sync.dispose();
    await data.dispose();
  }
}

void main() {
  late FakeDrive drive;
  late Device a;
  late Device b;
  var now = DateTime.utc(2026, 6, 1);
  DateTime clock() => now;

  setUpAll(initializeTestEnvironment);

  setUp(() async {
    now = DateTime.utc(2026, 6, 1);
    drive = FakeDrive();
    a = await Device.create(drive, clock);
    b = await Device.create(drive, clock);
  });

  tearDown(() async {
    await a.dispose();
    await b.dispose();
  });

  test('notes written on two devices end up on both', () async {
    await a.write('from A');
    await b.write('from B');
    await a.sync.sync();
    await b.sync.sync();
    await a.sync.sync();
    expect(a.titles, ['from A', 'from B']);
    expect(b.titles, ['from A', 'from B']);
  });

  test('the same numeric id on two devices does not overwrite', () async {
    final mine = await a.write('A first note');
    final theirs = await b.write('B first note');
    expect(mine.id, theirs.id, reason: 'both devices start at id 1');
    await a.sync.sync();
    await b.sync.sync();
    expect(b.titles, ['A first note', 'B first note']);
  });

  test('a deletion propagates, and survives a device that missed it',
      () async {
    final note = await a.write('doomed');
    await a.sync.sync();
    await b.sync.sync();
    expect(b.titles, ['doomed']);

    final c = await Device.create(drive, clock);
    await c.sync.sync();
    expect(c.titles, ['doomed']);

    now = now.add(const Duration(hours: 1));
    await a.data.notes.delete([note.id!]);
    await a.sync.sync();
    await b.sync.sync();
    expect(b.titles, isEmpty);

    // b uploaded after a; the tombstone must still be in Drive for c
    await c.sync.sync();
    expect(c.titles, isEmpty, reason: 'not resurrected by c');
    await c.dispose();
  });

  test('an edit made after a deletion keeps the note', () async {
    final note = await a.write('kept');
    await a.sync.sync();
    await b.sync.sync();

    now = now.add(const Duration(hours: 1));
    await a.data.notes.delete([note.id!]);
    await a.sync.sync();

    now = now.add(const Duration(hours: 1));
    final onB = b.data.notes.notes.single;
    await b.data.notes.save(onB.copyWith(content: 'edited', updatedAt: now));
    await b.sync.sync();
    await a.sync.sync();
    expect(a.data.notes.notes.single.content, 'edited');
  });

  test('a network failure is an error, never an empty Drive', () async {
    await b.write('on Drive');
    await b.sync.sync();
    await a.write('local');

    drive.failing = true;
    await expectLater(a.sync.sync(), throwsA(isA<SyncException>()));
    expect(a.sync.hasPendingChanges, isTrue);

    drive.failing = false;
    await a.sync.sync();
    expect(a.titles, ['local', 'on Drive']);
  });

  test('uploads directly only over its own last upload', () async {
    await a.write('one');
    await a.sync.sync();
    final before = drive.contents;
    await a.sync.sync();
    expect(drive.contents, before, reason: 'nothing changed: no upload');

    await b.write('two');
    await b.sync.sync();
    await a.write('three');
    await a.sync.sync();
    expect(a.titles, ['one', 'three', 'two'],
        reason: 'Drive changed elsewhere: merged, not overwritten');
  });

  test('categories sync by name and deletions propagate', () async {
    await a.data.categories.add('Work');
    final work = a.data.categories.categories.single;
    await a.data.notes.save(Note(
        title: 'n',
        content: 'c',
        createdAt: now,
        updatedAt: now,
        categoryIds: [work.id]));
    await b.data.categories.add('Home');
    await b.sync.sync();
    await a.sync.sync();
    await b.sync.sync();

    final onB = b.data.categories.byName('work')!;
    expect(b.data.notes.notes.single.categoryIds, [onB.id],
        reason: 'mapped to the local id of the same name');
    expect(a.data.categories.categories.map((c) => c.name),
        containsAll(['Work', 'Home']));

    await b.data.categories.delete(onB.id);
    await b.sync.sync();
    await a.sync.sync();
    expect(a.data.categories.byName('Work'), isNull);
    expect(a.data.notes.notes.single.categoryIds, isEmpty);
  });

  test('locked notes never leave the device', () async {
    await a.data.vault.setUp('Pass123!');
    await a.data.notes.save(Note(
        title: 'secret',
        content: 'c',
        createdAt: now,
        updatedAt: now,
        isLocked: true));
    await a.write('open');
    await a.sync.sync();
    expect(jsonEncode(drive.contents), isNot(contains('secret')));
    await b.sync.sync();
    expect(b.titles, ['open']);
  });

  test('replaceLocal keeps local vault notes and requires a backup', () async {
    await expectLater(a.sync.replaceLocal(), throwsA(isA<SyncException>()));
    await b.write('drive copy');
    await b.sync.sync();
    await a.write('replaced');
    await a.sync.replaceLocal();
    expect(a.titles, ['drive copy']);
  });

  test('reads a version 2 file written by the previous app', () async {
    drive.contents = {
      'version': '2.0',
      'notes': [
        {
          'id': 5,
          'title': 'old format',
          'content': 'c',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
          'isLocked': 0,
          'categoryIds': '9',
        }
      ],
      'categories': [
        {'id': 9, 'name': 'Legacy', 'sortOrder': 0}
      ],
      'deleted_ids': {'3': 1},
    };
    await a.sync.sync();
    expect(a.titles, ['old format']);
    final legacy = a.data.categories.byName('Legacy')!;
    expect(a.data.notes.notes.single.categoryIds, [legacy.id]);

    // syncing again does not duplicate the note that had no uuid
    await a.sync.sync();
    expect(a.titles, ['old format']);
    expect((drive.contents! as Map)['version'], '3');
  });

  group('a device not yet updated (legacy file)', () {
    late FakeDrive legacy;
    late Device updated;

    /// ملف كتبه الإصدار السابق: بلا uuid، والأرقام أرقامه.
    Map<String, Object?> oldFile(List<(int, String, String, int)> notes) => {
          'version': '2.0',
          'notes': [
            for (final (id, title, content, editedHour) in notes)
              {
                'id': id,
                'title': title,
                'content': content,
                'createdAt': DateTime.utc(2026).toIso8601String(),
                'updatedAt': DateTime.utc(2026)
                    .add(Duration(hours: editedHour))
                    .toIso8601String(),
                'isLocked': 0,
              }
          ],
          'categories': const [],
          'deleted_ids': const {},
        };

    setUp(() async {
      legacy = FakeDrive();
      updated = await Device.create(drive, clock, legacy: legacy);
    });
    tearDown(() => updated.dispose());

    test('its file is read and merged, and never written', () async {
      legacy.contents = oldFile([(1, 'from old phone', 'c', 0)]);
      final writesBefore = legacy.writes;
      await updated.write('from new phone', at: DateTime.utc(2026, 3));
      await updated.sync.sync();

      expect(updated.titles, ['from new phone', 'from old phone']);
      expect(legacy.writes, writesBefore, reason: 'the old file is untouched');
      final onDrive = (drive.contents! as Map)['notes'] as List;
      expect(onDrive, hasLength(2), reason: 'the new file has both');
    });

    test('an edit on the old device updates the same note, no duplicate',
        () async {
      // ملاحظة موجودة قبل التحديث: نفس الرقم ووقت الإنشاء على الجهازين
      final note = await updated.data.notes.save(Note(
          title: 'shared',
          content: 'before',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026)));
      legacy.contents = oldFile([(note.id!, 'shared', 'edited on old', 5)]);
      await updated.sync.sync();
      expect(updated.data.notes.notes.single.content, 'edited on old');

      legacy.contents = oldFile([(note.id!, 'shared', 'edited again', 6)]);
      await updated.sync.sync();
      expect(updated.data.notes.notes.single.content, 'edited again');
    });

    test('a note deleted here does not come back when the old file changes',
        () async {
      legacy.contents = oldFile([(1, 'doomed', 'c', 0)]);
      await updated.sync.sync();
      now = now.add(const Duration(hours: 1));
      await updated.data.notes.delete([updated.data.notes.notes.single.id!]);
      await updated.sync.sync();

      legacy.contents =
          oldFile([(1, 'doomed', 'c', 0), (2, 'new on old phone', 'c', 0)]);
      await updated.sync.sync();
      expect(updated.titles, ['new on old phone']);
    });

    test('an unchanged old file is not merged again', () async {
      legacy.contents = oldFile([(1, 'once', 'c', 0)]);
      await updated.sync.sync();
      final uploads = drive.writes;
      await updated.sync.sync();
      expect(drive.writes, uploads, reason: 'nothing new: no upload');
    });

    test('a fresh updated device restores from the old file', () async {
      legacy.contents = oldFile([(1, 'a', 'c', 0), (2, 'b', 'c', 0)]);
      final fresh = await Device.create(FakeDrive(), clock, legacy: legacy);
      expect(await fresh.sync.remoteNoteCount(), 2);
      await fresh.sync.replaceLocal();
      expect(fresh.titles, ['a', 'b']);
      await fresh.dispose();
    });
  });
}
