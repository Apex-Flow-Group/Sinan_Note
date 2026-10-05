import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/models/note_category.dart';
import 'package:sinan_note/services/storage/backup_service.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';

import '../../test_setup.dart';

Note _note(int id, String title, DateTime created, {DateTime? updated}) => Note(
      id: id,
      title: title,
      content: 'content of $title',
      createdAt: created,
      updatedAt: updated ?? created,
    );

/// يبني ملف نسخة احتياطية (.db) حقيقياً بنفس مخطط التطبيق.
Future<String> _buildBackup(
  Directory dir,
  List<Note> notes, {
  List<NoteCategory> categories = const [],
}) async {
  final path = '${dir.path}/backup.db';
  SqliteDatabaseService.resetInstance();
  SqliteDatabaseService.overrideDbPath(path);
  final db = SqliteDatabaseService();
  for (final c in categories) {
    await db.insertCategory(c);
  }
  for (final n in notes) {
    await db.upsertNote(n);
  }
  await db.closeDB();
  SqliteDatabaseService.resetInstance();
  SqliteDatabaseService.overrideDbPath(':memory:');
  return path;
}

void main() {
  late Directory tmp;
  final t0 = DateTime.utc(2026, 1, 1);

  setUpAll(initializeTestEnvironment);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('backup_merge_');
    SqliteDatabaseService.resetInstance();
    SqliteDatabaseService.overrideDbPath(':memory:');
  });

  tearDown(() async {
    await SqliteDatabaseService().closeDB();
    SqliteDatabaseService.resetInstance();
    await tmp.delete(recursive: true);
  });

  test('merging a .db backup keeps local notes whose ids collide', () async {
    final backup = await _buildBackup(tmp, [
      _note(1, 'from backup A', t0.add(const Duration(days: 1))),
      _note(2, 'from backup B', t0.add(const Duration(days: 2))),
    ]);
    final db = SqliteDatabaseService();
    await db.upsertNote(_note(1, 'local 1', t0));
    await db.upsertNote(_note(2, 'local 2', t0));

    final count = await BackupService().mergeDatabaseFile(backup);

    final titles = (await db.getAllNotes()).map((n) => n.title).toSet();
    expect(count, 2);
    expect(titles, {'local 1', 'local 2', 'from backup A', 'from backup B'});
  });

  test('the same note (same uuid) keeps the newer version', () async {
    final original = _note(1, 'original', t0);
    final newestLocal =
        _note(2, 'newest local', t0, updated: t0.add(const Duration(hours: 3)));
    final backup = await _buildBackup(tmp, [
      original.copyWith(
          title: 'edited later', updatedAt: t0.add(const Duration(hours: 5))),
      newestLocal.copyWith(
          title: 'older edit', updatedAt: t0.add(const Duration(hours: 1))),
    ]);
    final db = SqliteDatabaseService();
    await db.upsertNote(original);
    await db.upsertNote(newestLocal);

    await BackupService().mergeDatabaseFile(backup);

    final notes = await db.getAllNotes();
    expect(notes.length, 2);
    expect(notes.map((n) => n.title).toSet(), {'edited later', 'newest local'});
  });

  test('merging the same backup twice adds nothing the second time', () async {
    final backup = await _buildBackup(tmp, [
      _note(7, 'only in backup', t0),
    ]);
    final db = SqliteDatabaseService();
    await db
        .upsertNote(_note(7, 'local seven', t0.add(const Duration(days: 9))));

    await BackupService().mergeDatabaseFile(backup);
    final second = await BackupService().mergeDatabaseFile(backup);

    expect(second, 0);
    expect((await db.getAllNotes()).length, 2);
  });

  test(
      'a newer copy updates a note that got a new local id in an earlier merge',
      () async {
    final db = SqliteDatabaseService();
    await db.upsertNote(_note(1, 'local 1', t0));
    final imported = _note(1, 'imported', t0.add(const Duration(days: 1)));
    final first = await _buildBackup(tmp, [imported]);
    await BackupService().mergeDatabaseFile(first);

    final recolored = imported.copyWith(
        colorIndex: 4,
        updatedAt: t0.add(const Duration(days: 1, milliseconds: 1)));
    await File(first).delete();
    final second = await _buildBackup(tmp, [recolored]);
    await BackupService().mergeDatabaseFile(second);

    final notes = await db.getAllNotes();
    expect(notes.length, 2);
    expect(notes.firstWhere((n) => n.title == 'imported').colorIndex, 4);
    expect(notes.firstWhere((n) => n.title == 'local 1').colorIndex, 0);
  });

  test('a note from an old backup without uuid is not duplicated', () async {
    final db = SqliteDatabaseService();
    final local = _note(1, 'same note', t0);
    await db.upsertNote(local);
    // نسخة قديمة: نفس الملاحظة بهوية مختلفة (الملفات القديمة بلا uuid)
    final backup =
        await _buildBackup(tmp, [local.asNew(at: t0).copyWith(id: 9)]);

    expect(await BackupService().mergeDatabaseFile(backup), 0);
    expect((await db.getAllNotes()).length, 1);
  });

  test('categories are matched by name', () async {
    final backup = await _buildBackup(
      tmp,
      [
        _note(1, 'work note', t0).copyWith(categoryIds: [5]),
      ],
      categories: [const NoteCategory(id: 5, name: 'Work')],
    );
    final db = SqliteDatabaseService();
    final localWork = await db.insertCategory(const NoteCategory(name: 'Work'));

    await BackupService().mergeDatabaseFile(backup);

    final merged =
        (await db.getAllNotes()).firstWhere((n) => n.title == 'work note');
    expect(merged.categoryIds, [localWork]);
    expect((await db.getAllCategories()).length, 1);
  });

  test('a non-SQLite file is rejected and never touches local notes', () async {
    final isarLike = File('${tmp.path}/old.sinannote')
      ..writeAsBytesSync(List.filled(4096, 0));
    final db = SqliteDatabaseService();
    await db.upsertNote(_note(1, 'keep me', t0));

    expect(await BackupService.isSqliteFile(isarLike.path), isFalse);
    await expectLater(
        BackupService().mergeDatabaseFile(isarLike.path), throwsA(anything));
    expect((await db.getAllNotes()).single.title, 'keep me');
  });
}
