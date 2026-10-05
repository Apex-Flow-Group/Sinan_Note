// R2.6 — الثابت: صف مقفل في notes عنوانه ومحتواه (غير الفارغين) مشفّران،
// ولا توجد له نسخ في note_versions، أياً كانت عملية الكتابة.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_version.dart';
import 'package:sinan_note/services/security/vault_service.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';

import '../../test_setup.dart';

void main() {
  late NotesProvider provider;
  late SqliteDatabaseService db;

  setUpAll(() async {
    initializeTestEnvironment();
    await VaultService.setupVault('TestPass123!');
  });

  setUp(() {
    SqliteDatabaseService.resetInstance();
    SqliteDatabaseService.overrideDbPath(':memory:');
    db = SqliteDatabaseService();
    provider = NotesProvider(dbService: db);
  });

  tearDown(() async {
    provider.dispose();
    await db.closeDB();
    SqliteDatabaseService.resetInstance();
  });

  Note locked({String title = 'secret title', String content = 'secret'}) =>
      Note(
        title: title,
        content: content,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        isLocked: true,
      );

  Future<void> expectInvariant(int id) async {
    final row = (await db.getNoteById(id))!;
    expect(row.isLocked, isTrue, reason: 'still locked');
    if (row.title.isNotEmpty) {
      expect(VaultService.isEncrypted(row.title), isTrue, reason: 'title');
    }
    if (row.content.isNotEmpty) {
      expect(VaultService.isEncrypted(row.content), isTrue, reason: 'content');
    }
    expect(await db.getNoteHistory(id), isEmpty, reason: 'no versions');
  }

  test('add: title is encrypted even when content is empty', () async {
    final id = await provider.addNote(locked(content: ''));
    await expectInvariant(id);
  });

  test('update with plaintext re-encrypts; encrypted input is not doubled',
      () async {
    final id = await provider.addNote(locked());
    final stored = (await db.getNoteById(id))!;

    await provider.updateNote(stored.copyWith(content: 'edited'));
    await expectInvariant(id);
    expect(
        await VaultService.decryptWithMasterKey(
            (await db.getNoteById(id))!.content),
        'edited');

    final again = (await db.getNoteById(id))!;
    await provider.updateNote(again);
    expect(
        await VaultService.decryptWithMasterKey(
            (await db.getNoteById(id))!.content),
        'edited');
  });

  test('metadata updates keep the note locked and encrypted', () async {
    final id = await provider.addNote(locked());
    await provider.updateNoteMeta(id, colorIndex: 5);
    await provider.updateNoteMeta(id,
        reminderDateTime: DateTime.now().add(const Duration(days: 1)));
    await provider.togglePinned(id);
    await expectInvariant(id);
    final row = (await db.getNoteById(id))!;
    expect(row.colorIndex, 5);
    expect(row.isPinned, isTrue);
  });

  test('duplicate of a locked note decrypts to readable text', () async {
    final id = await provider.addNote(locked(title: 'pw'));
    final copyId = await provider.duplicateNote(id);
    await expectInvariant(copyId);
    final copy = (await db.getNoteById(copyId))!;
    expect(await VaultService.decryptWithMasterKey(copy.title), 'pw - Copy');
    expect(await VaultService.decryptWithMasterKey(copy.content), 'secret');
  });

  test('converting the type of a locked note keeps it encrypted', () async {
    final id = await provider.addNote(locked());
    await provider.convertNoteType(id,
        newContent: 'converted plain', newNoteType: 'code', isChecklist: false);
    await expectInvariant(id);
  });

  test('versions are never logged for a locked note', () async {
    final id = await provider.addNote(locked());
    await db.logNoteVersion(NoteVersion.create(
      noteId: id,
      title: 'plain',
      content: 'plain',
      timestamp: DateTime.now(),
      action: 'manual_save',
    ));
    await expectInvariant(id);
  });

  test('locking deletes the plaintext history of the note', () async {
    final id = await provider.addNote(locked()..isLocked = false);
    await db.logNoteVersion(NoteVersion.create(
      noteId: id,
      title: 'before lock',
      content: 'before lock',
      timestamp: DateTime.now(),
      action: 'manual_save',
    ));
    expect(await db.getNoteHistory(id), isNotEmpty);

    expect(await provider.toggleLockStatus(id, true), isTrue);
    await expectInvariant(id);
  });

  test('unlock that cannot decrypt keeps the note locked', () async {
    final id = await provider.addNote(locked());
    final row = (await db.getNoteById(id))!;
    // نص مشفّر بمفتاح آخر: صيغة صحيحة لكن فك التشفير يفشل
    const foreign = 'AAAAAAAAAAAAAAAAAAAAAA==:BBBBBBBBBBBBBBBB';
    await db.updateNote(row.copyWith(content: foreign));

    expect(await provider.toggleLockStatus(id, false), isFalse);
    final after = (await db.getNoteById(id))!;
    expect(after.isLocked, isTrue);
    expect(after.content, foreign);
  });
}
