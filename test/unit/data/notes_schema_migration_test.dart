import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/data/services/database/notes_schema.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../test_setup.dart';

/// مخطط v5 كما في الإصدارات المنشورة قبل uuid.
const _v5Notes = '''
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL DEFAULT '', content TEXT NOT NULL DEFAULT '',
  normalizedTitle TEXT NOT NULL DEFAULT '', normalizedContent TEXT NOT NULL DEFAULT '',
  createdAt TEXT NOT NULL, updatedAt TEXT NOT NULL,
  colorIndex INTEGER NOT NULL DEFAULT 0, isArchived INTEGER NOT NULL DEFAULT 0,
  isTrashed INTEGER NOT NULL DEFAULT 0, reminderDateTime TEXT,
  isLocked INTEGER NOT NULL DEFAULT 0, noteType TEXT NOT NULL DEFAULT 'simple',
  recurrenceRule TEXT, isCompleted INTEGER NOT NULL DEFAULT 0,
  isProfessional INTEGER NOT NULL DEFAULT 0, isPinned INTEGER NOT NULL DEFAULT 0,
  isChecklist INTEGER NOT NULL DEFAULT 0, categoryIds TEXT NOT NULL DEFAULT '',
  isHiddenFromHome INTEGER NOT NULL DEFAULT 0
)''';

void main() {
  late Directory tmp;

  setUpAll(initializeTestEnvironment);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('schema_migration_');
  });

  tearDown(() async {
    await SqliteDatabaseService().closeDB();
    SqliteDatabaseService.resetInstance();
    await tmp.delete(recursive: true);
  });

  test(
      'v5 database upgrades to v6: every note keeps its data and gets a '
      'unique uuid', () async {
    final path = '${tmp.path}/v5.db';
    final old = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, _) async {
            await db.execute(_v5Notes);
            await db.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY '
                'AUTOINCREMENT, name TEXT NOT NULL, sortOrder INTEGER NOT NULL '
                'DEFAULT 0)');
          },
        ));
    for (var i = 0; i < 3; i++) {
      await old.insert('notes', {
        'title': 'note $i',
        'content': 'content $i',
        'createdAt': '2026-01-0${i + 1}T00:00:00.000Z',
        'updatedAt': '2026-01-0${i + 1}T00:00:00.000Z',
      });
    }
    await old.close();

    SqliteDatabaseService.resetInstance();
    SqliteDatabaseService.overrideDbPath(path);
    final notes = await SqliteDatabaseService().getAllNotes();

    expect(notes.map((n) => n.title).toSet(), {'note 0', 'note 1', 'note 2'});
    expect(notes.map((n) => n.uuid).toSet().length, 3);
    expect(notes.every((n) => n.uuid.length == 36), isTrue);

    final db = await SqliteDatabaseService().database;
    expect(await db.getVersion(), NotesSchema.version);
    final indexes = await db.rawQuery("PRAGMA index_list('notes')");
    expect(
        indexes.any((i) => i['name'] == 'idx_notes_uuid' && i['unique'] == 1),
        isTrue);
  });

  test('a fresh database has the uuid column and unique index', () async {
    SqliteDatabaseService.resetInstance();
    SqliteDatabaseService.overrideDbPath('${tmp.path}/fresh.db');
    final db = await SqliteDatabaseService().database;
    final cols = await db.rawQuery('PRAGMA table_info(notes)');
    expect(cols.any((c) => c['name'] == 'uuid'), isTrue);
    final indexes = await db.rawQuery("PRAGMA index_list('notes')");
    expect(indexes.any((i) => i['name'] == 'idx_notes_uuid'), isTrue);
  });
}
