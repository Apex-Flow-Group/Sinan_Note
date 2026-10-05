import 'package:encrypt/encrypt.dart' as legacy;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/data/repositories/vault_repository.dart';
import 'package:sinan_note/data/services/database/notes_schema.dart';
import 'package:sinan_note/data/services/note_side_effects.dart';
import 'package:sinan_note/data/services/sync/tombstone_store.dart';
import 'package:sinan_note/data/services/vault/vault_cipher.dart';
import 'package:sinan_note/data/services/vault/vault_key_store.dart';
import 'package:sinan_note/domain/errors.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_version.dart';
import 'package:sinan_note/domain/versioning.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../test_setup.dart';

class _RecordingEffects implements NoteSideEffects {
  final changed = <Note>[];
  final removed = <int>[];
  @override
  Future<void> noteChanged(Note note) async => changed.add(note);
  @override
  Future<void> noteRemoved(int id) async => removed.add(id);
}

NoteVersion _version(int noteId) => NoteVersion(
    noteId: noteId, title: 'x', content: 'x', timestamp: DateTime.utc(2026));

class _RecordingDeletions implements DeletionLog {
  final uuids = <String>[];
  @override
  Future<void> notesDeleted(List<String> deleted) async => uuids.addAll(deleted);
  @override
  Future<void> categoryDeleted(String name) async {}
  @override
  Future<void> categoryCreated(String name) async {}
}

void main() {
  late Database db;
  late VaultRepository vault;
  late NotesRepository repo;
  late _RecordingEffects effects;
  late _RecordingDeletions deletions;
  final t0 = DateTime.utc(2026, 1, 1);

  setUpAll(initializeTestEnvironment);

  setUp(() async {
    await const FlutterSecureStorage().deleteAll();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: NotesSchema.version,
          onCreate: (db, _) => NotesSchema.create(db),
          singleInstance: false,
        ));
    vault = VaultRepository(store: VaultKeyStore());
    await vault.setUp('Pass123!');
    effects = _RecordingEffects();
    deletions = _RecordingDeletions();
    repo = NotesRepository(
      db: db,
      vault: vault,
      sideEffects: effects,
      deletionLog: deletions,
      clock: () => t0.add(const Duration(hours: 1)),
    );
  });

  tearDown(() async {
    repo.dispose();
    vault.dispose();
    await db.close();
  });

  Note note(String title, {bool locked = false, String content = 'body'}) =>
      Note(
        title: title,
        content: content,
        createdAt: t0,
        updatedAt: t0,
        isLocked: locked,
      );

  Future<Map<String, Object?>> row(int id) async =>
      (await db.query('notes', where: 'id = ?', whereArgs: [id])).single;

  /// R2.6: المقفلة مخزنة مشفّرة، بلا فهرس بحث ولا نسخ سابقة.
  Future<void> expectStoredSealed(int id) async {
    final r = await row(id);
    expect(r['isLocked'], 1);
    for (final column in ['title', 'content']) {
      final value = r[column] as String;
      if (value.isNotEmpty) {
        expect(VaultCipher.isSealed(value), isTrue, reason: column);
      }
    }
    expect(r['normalizedTitle'], '');
    expect(r['normalizedContent'], '');
    expect(await repo.history(id), isEmpty);
  }

  group('unlocked notes', () {
    test('save adds then updates, keeping the cache sorted and notified',
        () async {
      var notified = 0;
      repo.addListener(() => notified++);

      final a = await repo.save(note('a'));
      final b = await repo.save(note('b').copyWith(isPinned: true));
      expect(repo.notes.map((n) => n.title), ['b', 'a']);

      await repo.save(
          a.copyWith(title: 'a2', updatedAt: t0.add(const Duration(days: 1))));
      expect(repo.cached(a.id!)!.title, 'a2');
      expect(repo.notes.first.id, b.id, reason: 'pinned stays first');
      expect(notified, 3);
    });

    test('load reads only unlocked notes from the database', () async {
      await repo.save(note('open'));
      await repo.save(note('secret', locked: true));
      final fresh = NotesRepository(
          db: db, vault: vault, sideEffects: effects, deletionLog: deletions);
      await fresh.load();
      expect(fresh.notes.map((n) => n.title), ['open']);
      fresh.dispose();
    });

    test('trash, restore, archive and delete in batches', () async {
      final a = await repo.save(note('a'));
      final b = await repo.save(note('b'));

      await repo.trash([a.id!, b.id!]);
      expect(repo.notes.every((n) => n.isTrashed), isTrue);
      await repo.restore([a.id!]);
      expect(repo.cached(a.id!)!.isTrashed, isFalse);
      await repo.archive([a.id!]);
      expect(repo.cached(a.id!)!.isArchived, isTrue);

      await repo.recordVersion(b.id!, VersionTrigger.manual);
      await repo.delete([b.id!]);
      expect(repo.cached(b.id!), isNull);
      expect(await repo.history(b.id!), isEmpty);
      expect(deletions.uuids, [b.uuid]);
      expect(effects.removed, [b.id]);
    });

    test('versions follow the policy and keep at most 20', () async {
      final a = await repo.save(note('a'));
      await repo.recordVersion(a.id!, VersionTrigger.manual);
      await repo.recordVersion(a.id!, VersionTrigger.manual);
      expect((await repo.history(a.id!)).length, 1, reason: 'identical');
      expect((await repo.lastVersion(a.id!))!.action, 'manual_save');

      for (var i = 0; i < 25; i++) {
        await repo.save(a.copyWith(content: 'v$i'));
        await repo.recordVersion(a.id!, VersionTrigger.forced);
      }
      expect((await repo.history(a.id!)).length, 20);
    });

    test('restoreVersion keeps the current state as a version and goes '
        'through the cache', () async {
      final a = await repo.save(note('a', content: 'first'));
      await repo.recordVersion(a.id!, VersionTrigger.manual);
      final first = (await repo.lastVersion(a.id!))!;
      await repo.save(a.copyWith(content: 'second'));

      await repo.restoreVersion(a.id!, first);

      expect(repo.cached(a.id!)!.content, 'first');
      expect((await repo.history(a.id!)).map((v) => v.content),
          containsAll(['first', 'second']));
    });

    test('notesWithHistory lists only unlocked notes that have versions',
        () async {
      final a = await repo.save(note('a'));
      await repo.save(note('b'));
      await repo.recordVersion(a.id!, VersionTrigger.manual);
      expect((await repo.notesWithHistory()).map((n) => n.title), ['a']);

      await repo.setLocked(a.id!, true);
      expect(await repo.notesWithHistory(), isEmpty);
    });
  });

  group('locked notes (R2.6)', () {
    test('stored sealed; read back decrypted and still marked locked',
        () async {
      final saved = await repo.save(note('pw', locked: true, content: ''));
      await expectStoredSealed(saved.id!);
      expect(repo.notes, isEmpty, reason: 'never in the unlocked cache');

      final read = (await repo.lockedNotes()).single;
      expect(read.title, 'pw');
      expect(read.isLocked, isTrue);
    });

    test('editing a decrypted locked note re-seals it', () async {
      final saved = await repo.save(note('t', locked: true));
      final read = (await repo.find(saved.id!))!;
      await repo.save(read.copyWith(content: 'edited'));
      await expectStoredSealed(saved.id!);
      expect((await repo.find(saved.id!))!.content, 'edited');
    });

    test('metadata changes need no open vault and keep the note sealed',
        () async {
      final saved = await repo.save(note('t', locked: true));
      vault.lock();
      await repo.updateMeta(saved.id!, colorIndex: 4);
      await repo.togglePinned(saved.id!);
      await expectStoredSealed(saved.id!);
      expect((await row(saved.id!))['colorIndex'], 4);
      expect((await row(saved.id!))['isPinned'], 1);
    });

    test('versions are never recorded for a locked note', () async {
      final saved = await repo.save(note('t', locked: true));
      await repo.recordVersion(saved.id!, VersionTrigger.forced);
      await repo.recordVersion(saved.id!, VersionTrigger.manual);
      expect(await repo.restoreVersion(saved.id!, _version(saved.id!)),
          isNull);
      await expectStoredSealed(saved.id!);
    });

    test('locking seals the note and deletes its plaintext history', () async {
      final a = await repo.save(note('diary'));
      await repo.recordVersion(a.id!, VersionTrigger.manual);

      await repo.setLocked(a.id!, true);

      await expectStoredSealed(a.id!);
      expect(repo.cached(a.id!), isNull);
    });

    test('unlocking decrypts back into the cache', () async {
      final a = await repo.save(note('t', locked: true));
      await repo.setLocked(a.id!, false);
      expect((await row(a.id!))['title'], 't');
      expect(repo.cached(a.id!)!.title, 't');
    });

    test('a locked vault refuses to read or lock', () async {
      final a = await repo.save(note('t', locked: true));
      final b = await repo.save(note('u'));
      vault.lock();
      expect(repo.lockedNotes(), throwsA(isA<VaultLockedException>()));
      expect(repo.setLocked(b.id!, true), throwsA(isA<VaultLockedException>()));
      expect(repo.find(a.id!), throwsA(isA<VaultLockedException>()));
    });

    test('duplicating a locked note gives a readable, sealed copy', () async {
      final a = await repo.save(note('pw', locked: true));
      final copy = (await repo.duplicate(a.id!, copyLabel: 'Copy'))!;
      await expectStoredSealed(copy.id!);
      expect((await repo.find(copy.id!))!.title, 'pw - Copy');
      expect(copy.uuid, isNot(a.uuid));
    });

    test('converting the type of a locked note keeps it sealed', () async {
      final a = await repo.save(note('t', locked: true));
      await repo.convertType(a.id!,
          content: 'code', noteType: 'code', isChecklist: false);
      await expectStoredSealed(a.id!);
    });

    test('side effects only ever see the sealed note', () async {
      await repo.save(note('secret title', locked: true));
      expect(effects.changed.single.title, isNot('secret title'));
    });

    test('legacy AES-CTR values migrate to GCM and still decrypt', () async {
      final a = await repo.save(note('t', locked: true));
      expect(await repo.migrateLegacyCiphertext(), 0, reason: 'none yet');

      // مفتاح الخزنة نفسه، وقيمة بالصيغة القديمة كما كتبتها الإصدارات السابقة
      await vault.setBiometricEnabled(true);
      final key = (await VaultKeyStore().biometricKey())!;
      final iv = legacy.IV.fromSecureRandom(16);
      final old = legacy.Encrypter(legacy.AES(legacy.Key(key)))
          .encrypt('old content', iv: iv);
      await db.update('notes', {'content': '${iv.base64}:${old.base64}'},
          where: 'id = ?', whereArgs: [a.id]);

      expect(await repo.migrateLegacyCiphertext(), 1);
      final stored = (await row(a.id!))['content'] as String;
      expect(stored, startsWith('g1:'));
      expect((await repo.find(a.id!))!.content, 'old content');
      await expectStoredSealed(a.id!);
    });

    test('resealAll re-encrypts every locked value in one transaction',
        () async {
      final a = await repo.save(note('t', locked: true));
      await vault.rotateKey('Fresh789!', (reseal) => repo.resealAll(reseal));
      expect((await repo.find(a.id!))!.title, 't');
      await expectStoredSealed(a.id!);
    });
  });
}
