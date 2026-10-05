import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/data/repositories/backup_repository.dart';
import 'package:sinan_note/data/repositories/categories_repository.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/data/repositories/vault_repository.dart';
import 'package:sinan_note/data/services/database/note_mapper.dart';
import 'package:sinan_note/data/services/database/notes_schema.dart';
import 'package:sinan_note/data/services/sync/tombstone_store.dart';
import 'package:sinan_note/data/services/vault/vault_key_store.dart';
import 'package:sinan_note/domain/errors.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_data_layer.dart';
import '../../test_setup.dart';

Future<Database> _openDb(String path) => databaseFactoryFfi.openDatabase(path,
    options: OpenDatabaseOptions(
      version: NotesSchema.version,
      onCreate: (db, _) => NotesSchema.create(db),
      singleInstance: false,
    ));

void main() {
  late Directory tmp;
  late Database db;
  late VaultRepository vault;
  late NotesRepository notes;
  late CategoriesRepository categories;
  late BackupRepository backups;
  final t0 = DateTime.utc(2026, 1, 1);

  setUpAll(initializeTestEnvironment);

  setUp(() async {
    await const FlutterSecureStorage().deleteAll();
    tmp = await Directory.systemTemp.createTemp('backup_repo_');
    db = await _openDb(inMemoryDatabasePath);
    vault = VaultRepository(store: VaultKeyStore());
    await vault.setUp('Pass123!');
    final store = MemoryStore();
    final tombstones = TombstoneStore(store);
    notes = NotesRepository(
        db: db,
        vault: vault,
        sideEffects: NoPlatformEffects(),
        deletionLog: tombstones);
    categories = CategoriesRepository(
        db: db, notes: notes, deletionLog: tombstones, store: store);
    await categories.load();
    backups = BackupRepository(db: db, notes: notes, categories: categories);
  });

  tearDown(() async {
    categories.dispose();
    notes.dispose();
    vault.dispose();
    await db.close();
    await tmp.delete(recursive: true);
  });

  Note note(String title, {DateTime? created, DateTime? updated}) => Note(
        title: title,
        content: 'content of $title',
        createdAt: created ?? t0,
        updatedAt: updated ?? created ?? t0,
      );

  /// ملف .db حقيقي بمخطط التطبيق.
  Future<String> dbFile(List<Note> rows,
      {Map<int, String> categories = const {}}) async {
    final path =
        '${tmp.path}/backup_${rows.length}_${DateTime.now().microsecondsSinceEpoch}.db';
    final backup = await _openDb(path);
    for (final MapEntry(:key, :value) in categories.entries) {
      await backup
          .insert('categories', {'id': key, 'name': value, 'sortOrder': 0});
    }
    for (final n in rows) {
      await backup.insert('notes', NoteMapper.toMap(n)..remove('id'));
    }
    await backup.close();
    return path;
  }

  /// نسخة .db فيها ملاحظة بنسختين سابقتين، ومقفلة بنسخة (من إصدار قديم).
  Future<String> dbWithHistory() async {
    final path = '${tmp.path}/history.db';
    final backup = await _openDb(path);
    final open = await backup.insert(
        'notes', NoteMapper.toMap(note('with history'))..remove('id'));
    final locked = await backup.insert(
        'notes',
        NoteMapper.toMap(note('locked').copyWith(isLocked: true))
          ..remove('id'));
    for (final (id, content, hour) in [
      (open, 'v1', 1),
      (open, 'v2', 2),
      (locked, 'plaintext leak', 3),
    ]) {
      await backup.insert('note_versions', {
        'noteId': id,
        'title': 't',
        'content': content,
        'timestamp': t0.add(Duration(hours: hour)).toIso8601String(),
        'action': 'manual_save',
        'noteType': 'simple',
      });
    }
    await backup.close();
    return path;
  }

  test('restoring a .db brings back version history, once', () async {
    final path = await dbWithHistory();
    await backups.merge(await backups.read(path));
    await backups.merge(await backups.read(path));

    final restored = notes.notes.singleWhere((n) => n.title == 'with history');
    expect((await notes.history(restored.id!)).map((v) => v.content),
        ['v2', 'v1']);
  });

  test('replace also restores history; locked notes never get versions',
      () async {
    await backups.replace(await backups.read(await dbWithHistory()));

    final restored = notes.notes.single;
    expect(await notes.history(restored.id!), hasLength(2));
    final versions = await db.query('note_versions');
    expect(
        versions.map((v) => v['content']), isNot(contains('plaintext leak')));
  });

  test('history follows a note that already exists locally', () async {
    final local = await notes.save(note('with history'));
    await backups.merge(await backups.read(await dbWithHistory()));
    expect(await notes.history(local.id!), hasLength(2),
        reason: 'matched by fingerprint, versions attached to the local note');
  });

  test('merge adds new notes and keeps local ones with colliding row ids',
      () async {
    await notes.save(note('local 1'));
    await notes.save(note('local 2'));
    final path = await dbFile([
      note('backup A', created: t0.add(const Duration(days: 1))),
      note('backup B', created: t0.add(const Duration(days: 2))),
    ]);

    expect(await backups.merge(await backups.read(path)), 2);
    expect(notes.notes.map((n) => n.title).toSet(),
        {'local 1', 'local 2', 'backup A', 'backup B'});
  });

  test(
      'the same note (uuid) keeps the newer version; merging twice adds '
      'nothing', () async {
    final local = await notes.save(note('original'));
    final path = await dbFile([
      local.copyWith(
          title: 'edited later', updatedAt: t0.add(const Duration(hours: 1))),
    ]);

    expect(await backups.merge(await backups.read(path)), 1);
    expect(await backups.merge(await backups.read(path)), 0);
    expect(notes.notes.single.title, 'edited later');
  });

  test('an old backup without uuid is not duplicated', () async {
    final local = await notes.save(note('same'));
    final path = '${tmp.path}/old.json';
    final legacyMap = NoteMapper.toMap(local)..remove('uuid');
    await File(path).writeAsString(jsonEncode([legacyMap]));

    expect(await backups.merge(await backups.read(path)), 0);
    expect(notes.notes.length, 1);
  });

  test('categories are matched by name', () async {
    final work =
        await db.insert('categories', {'name': 'Work', 'sortOrder': 0});
    final path = await dbFile([
      note('w').copyWith(categoryIds: [5])
    ], categories: {
      5: 'Work'
    });

    await backups.merge(await backups.read(path));

    expect(notes.notes.single.categoryIds, [work]);
    expect((await db.query('categories')).length, 1);
  });

  test('replace swaps unlocked notes and never touches the vault', () async {
    await notes.save(note('old unlocked'));
    final secret = await notes.save(note('secret').copyWith(isLocked: true));
    final path = await dbFile([note('from backup')]);

    await backups.replace(await backups.read(path));

    expect(notes.notes.map((n) => n.title), ['from backup']);
    expect((await notes.lockedNotes()).single.id, secret.id);
  });

  test(
      'a plaintext locked note in a file is sealed; with the vault locked '
      'nothing is written', () async {
    final path = '${tmp.path}/locked.json';
    await File(path).writeAsString(jsonEncode([
      NoteMapper.toMap(note('pw').copyWith(isLocked: true)),
    ]));
    final contents = await backups.read(path);

    vault.lock();
    await expectLater(
        backups.merge(contents), throwsA(isA<VaultLockedException>()));
    expect(await backups.localNotesCount(), 0);

    await vault.unlockWithPassword('Pass123!');
    await backups.merge(contents);
    final row = (await db.query('notes')).single;
    expect(row['title'], isNot('pw'));
    expect((await notes.lockedNotes()).single.title, 'pw');
  });

  test('an Isar-era .sinannote file is rejected without writing', () async {
    final path = '${tmp.path}/old.sinannote';
    await File(path).writeAsBytes(List.filled(4096, 0));
    expect(backups.read(path), throwsA(isA<ValidationException>()));
  });

  test('exportTo writes a readable snapshot', () async {
    await notes.save(note('kept'));
    final path = await backups.exportTo(tmp.path);
    expect(await BackupRepository.isSqliteFile(path), isTrue);
    expect((await backups.read(path)).notes.single.title, 'kept');
  });
}
