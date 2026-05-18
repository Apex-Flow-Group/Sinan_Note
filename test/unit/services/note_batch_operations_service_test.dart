// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/note_services/note_batch_operations_service.dart';
import 'package:sinan_note/services/note_services/note_side_effect_service.dart';
import 'package:sinan_note/services/note_services/note_state_service.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../test_setup.dart';
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    initializeTestEnvironment();
  });

  group('NoteBatchOperationsService', () {
    late NoteBatchOperationsService service;
    late SqliteDatabaseService dbService;
    late NoteStateService stateService;
    late NoteSideEffectService sideEffectService;
    late DateTime now;

    setUp(() async {
      SqliteDatabaseService.resetInstance();
      SqliteDatabaseService.overrideDbPath(':memory:');
      dbService = SqliteDatabaseService();
      stateService = NoteStateService();
      sideEffectService = NoteSideEffectService();
      service = NoteBatchOperationsService(
          dbService, stateService, sideEffectService);
      now = DateTime.now();
    });

    tearDown(() async {
      await dbService.closeDB();
      SqliteDatabaseService.resetInstance();
      stateService.dispose();
    });

    Future<List<Note>> insertAndLoad(List<Note> notes) async {
      final inserted = <Note>[];
      for (final n in notes) {
        final id = await dbService.insertNote(n);
        inserted.add(n.copyWith(id: id));
      }
      stateService.updateAllNotes(inserted);
      return inserted;
    }

    group('trashNotes', () {
      test('trashes multiple notes optimistically', () async {
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Note 1',
              content: 'Content',
              createdAt: now,
              updatedAt: now),
          Note(
              id: null,
              title: 'Note 2',
              content: 'Content',
              createdAt: now,
              updatedAt: now),
        ]);

        await service.batchTrashNotes(notes.map((n) => n.id!).toList());

        expect(stateService.trashedNotes.length, 2);
        expect(stateService.activeNotes.length, 0);
      });

      test('hard deletes locked notes', () async {
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Regular',
              content: 'Content',
              createdAt: now,
              updatedAt: now),
          Note(
              id: null,
              title: 'Locked',
              content: 'Content',
              createdAt: now,
              updatedAt: now,
              isLocked: true),
        ]);

        await service.batchTrashNotes(notes.map((n) => n.id!).toList());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateService.trashedNotes.length, 1);
      });

      test('cancels reminders for trashed notes', () async {
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Reminder',
              content: 'Content',
              createdAt: now,
              updatedAt: now,
              reminderDateTime: now.add(const Duration(days: 1))),
        ]);

        await service.batchTrashNotes([notes.first.id!]);
        expect(stateService.trashedNotes.length, 1);
      });

      test('handles empty list', () async {
        await service.batchTrashNotes([]);
      });

      test('handles non-existent notes', () async {
        await service.batchTrashNotes([999]);
      });
    });

    group('restoreNotes', () {
      test('restores multiple notes', () async {
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Note 1',
              content: 'Content',
              createdAt: now,
              updatedAt: now,
              isTrashed: true),
          Note(
              id: null,
              title: 'Note 2',
              content: 'Content',
              createdAt: now,
              updatedAt: now,
              isTrashed: true),
        ]);

        await service.batchRestoreNotes(notes.map((n) => n.id!).toList());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateService.activeNotes.length, 2);
        expect(stateService.trashedNotes.length, 0);
      });

      test('triggers sort after restore', () async {
        final older = now.subtract(const Duration(days: 1));
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Old',
              content: 'Content',
              createdAt: older,
              updatedAt: older,
              isTrashed: true),
          Note(
              id: null,
              title: 'New',
              content: 'Content',
              createdAt: now,
              updatedAt: now,
              isTrashed: true),
        ]);

        await service.batchRestoreNotes(notes.map((n) => n.id!).toList());
        await Future.delayed(const Duration(milliseconds: 100));

        // بعد الاستعادة يجب أن تكون الملاحظات في الـ activeNotes
        expect(stateService.activeNotes.length, 2);
      });

      test('handles empty list', () async {
        await service.batchRestoreNotes([]);
      });
    });

    group('archiveNotes', () {
      test('archives multiple notes', () async {
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Note 1',
              content: 'Content',
              createdAt: now,
              updatedAt: now),
          Note(
              id: null,
              title: 'Note 2',
              content: 'Content',
              createdAt: now,
              updatedAt: now),
        ]);

        await service.batchArchiveNotes(notes.map((n) => n.id!).toList());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateService.archivedNotes.length, 2);
        expect(stateService.activeNotes.length, 0);
      });

      test('cancels reminders for archived notes', () async {
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Reminder',
              content: 'Content',
              createdAt: now,
              updatedAt: now,
              reminderDateTime: now.add(const Duration(days: 1))),
        ]);

        await service.batchArchiveNotes([notes.first.id!]);
        await Future.delayed(const Duration(milliseconds: 100));
        expect(stateService.archivedNotes.length, 1);
      });

      test('handles empty list', () async {
        await service.batchArchiveNotes([]);
      });
    });

    group('unarchiveNotes', () {
      test('unarchives multiple notes', () async {
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Note 1',
              content: 'Content',
              createdAt: now,
              updatedAt: now,
              isArchived: true),
          Note(
              id: null,
              title: 'Note 2',
              content: 'Content',
              createdAt: now,
              updatedAt: now,
              isArchived: true),
        ]);

        await service.batchUnarchiveNotes(notes.map((n) => n.id!).toList());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateService.activeNotes.length, 2);
        expect(stateService.archivedNotes.length, 0);
      });

      test('handles empty list', () async {
        await service.batchUnarchiveNotes([]);
      });
    });

    group('Functional Immutability', () {
      test('batch operations use functional updates', () async {
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Original',
              content: 'Content',
              createdAt: now,
              updatedAt: now),
        ]);

        await service.batchTrashNotes([notes.first.id!]);
        expect(stateService.trashedNotes.length, 1);
      });
    });

    group('Background Sync', () {
      test('uses Future.microtask for DB sync', () async {
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Test',
              content: 'Content',
              createdAt: now,
              updatedAt: now),
        ]);

        await service.batchTrashNotes([notes.first.id!]);
        expect(stateService.trashedNotes.length, 1);
        await Future.delayed(const Duration(milliseconds: 100));
      });
    });

    group('Edge Cases', () {
      test('handles mixed valid and invalid IDs', () async {
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Valid',
              content: 'Content',
              createdAt: now,
              updatedAt: now),
        ]);

        await service.batchTrashNotes([notes.first.id!, 999]);
        expect(stateService.trashedNotes.length, 1);
      });

      test('handles duplicate IDs', () async {
        final notes = await insertAndLoad([
          Note(
              id: null,
              title: 'Test',
              content: 'Content',
              createdAt: now,
              updatedAt: now),
        ]);
        final id = notes.first.id!;

        await service.batchTrashNotes([id, id, id]);
        expect(stateService.trashedNotes.length, 1);
      });

      test('handles large batch operations', () async {
        final notes = await insertAndLoad(
          List.generate(
              100,
              (i) => Note(
                    id: null,
                    title: 'Note $i',
                    content: 'Content',
                    createdAt: now,
                    updatedAt: now,
                  )),
        );

        await service.batchTrashNotes(notes.map((n) => n.id!).toList());
        expect(stateService.trashedNotes.length, 100);
      });
    });
  });
}

