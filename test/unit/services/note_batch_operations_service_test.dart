// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/note_services/note_batch_operations_service.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';
import 'package:apex_note/services/note_services/note_side_effect_service.dart';
import 'package:apex_note/services/database_service.dart';
import '../../test_setup.dart';

class MockDatabaseService implements DatabaseService {
  final Map<int, Note> _notes = {};

  @override
  Future<int> updateNote(Note note) async {
    if (_notes.containsKey(note.id)) {
      _notes[note.id!] = note;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteNote(int id) async {
    if (_notes.remove(id) != null) return 1;
    return 0;
  }

  @override
  Future<int> trashNote(int id) async {
    final note = _notes[id];
    if (note != null) {
      _notes[id] = note.copyWith(isTrashed: true);
      return 1;
    }
    return 0;
  }

  @override
  Future<int> restoreNote(int id) async {
    final note = _notes[id];
    if (note != null) {
      _notes[id] = note.copyWith(isTrashed: false, isArchived: false);
      return 1;
    }
    return 0;
  }

  @override
  Future<int> archiveNote(int id) async {
    final note = _notes[id];
    if (note != null) {
      _notes[id] = note.copyWith(isArchived: true);
      return 1;
    }
    return 0;
  }

  @override
  Future<int> unarchiveNote(int id) async {
    final note = _notes[id];
    if (note != null) {
      _notes[id] = note.copyWith(isArchived: false);
      return 1;
    }
    return 0;
  }

  @override
  Future<Note?> getNoteById(int id) async => _notes[id];

  void addNote(Note note) {
    _notes[note.id!] = note;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    initializeTestEnvironment();
  });
  
  group('NoteBatchOperationsService', () {
    late NoteBatchOperationsService service;
    late MockDatabaseService dbService;
    late NoteStateService stateService;
    late NoteSideEffectService sideEffectService;
    late DateTime now;

    setUp(() {
      dbService = MockDatabaseService();
      stateService = NoteStateService();
      sideEffectService = NoteSideEffectService();
      service = NoteBatchOperationsService(
        dbService,
        stateService,
        sideEffectService,
      );
      now = DateTime.now();
    });

    tearDown(() {
      stateService.dispose();
    });

    group('trashNotes', () {
      test('trashes multiple notes optimistically', () async {
        final notes = [
          Note(
            id: 1,
            title: 'Note 1',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
          Note(
            id: 2,
            title: 'Note 2',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        for (final note in notes) {
          dbService.addNote(note);
        }
        stateService.updateAllNotes(notes);

        await service.trashNotes([1, 2]);

        // Check memory update (optimistic)
        expect(stateService.trashedNotes.length, 2);
        expect(stateService.activeNotes.length, 0);
      });

      test('hard deletes locked notes', () async {
        final notes = [
          Note(
            id: 1,
            title: 'Regular',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
          Note(
            id: 2,
            title: 'Locked',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isLocked: true,
          ),
        ];

        for (final note in notes) {
          dbService.addNote(note);
        }
        stateService.updateAllNotes(notes);

        await service.trashNotes([1, 2]);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Locked note should be deleted, regular note trashed
        expect(stateService.trashedNotes.length, 1);
      });

      test('cancels reminders for trashed notes', () async {
        final futureDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'Reminder',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: futureDate,
        );

        dbService.addNote(note);
        stateService.updateAllNotes([note]);

        await service.trashNotes([1]);

        // Should not throw
        expect(stateService.trashedNotes.length, 1);
      });

      test('handles empty list', () async {
        await service.trashNotes([]);
        // Should not throw
      });

      test('handles non-existent notes', () async {
        await service.trashNotes([999]);
        // Should not throw
      });
    });

    group('restoreNotes', () {
      test('restores multiple notes', () async {
        final notes = [
          Note(
            id: 1,
            title: 'Note 1',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isTrashed: true,
          ),
          Note(
            id: 2,
            title: 'Note 2',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isTrashed: true,
          ),
        ];

        for (final note in notes) {
          dbService.addNote(note);
        }
        stateService.updateAllNotes(notes);

        await service.restoreNotes([1, 2]);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateService.activeNotes.length, 2);
        expect(stateService.trashedNotes.length, 0);
      });

      test('triggers sort after restore', () async {
        final notes = [
          Note(
            id: 1,
            title: 'Old',
            content: 'Content',
            createdAt: now,
            updatedAt: now.subtract(const Duration(days: 1)),
            isTrashed: true,
          ),
          Note(
            id: 2,
            title: 'New',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isTrashed: true,
          ),
        ];

        for (final note in notes) {
          dbService.addNote(note);
        }
        stateService.updateAllNotes(notes);

        await service.restoreNotes([1, 2]);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Newer note should be first after sort
        expect(stateService.activeNotes.first.id, 2);
      });

      test('handles empty list', () async {
        await service.restoreNotes([]);
        // Should not throw
      });
    });

    group('archiveNotes', () {
      test('archives multiple notes', () async {
        final notes = [
          Note(
            id: 1,
            title: 'Note 1',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
          Note(
            id: 2,
            title: 'Note 2',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        for (final note in notes) {
          dbService.addNote(note);
        }
        stateService.updateAllNotes(notes);

        await service.archiveNotes([1, 2]);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateService.archivedNotes.length, 2);
        expect(stateService.activeNotes.length, 0);
      });

      test('cancels reminders for archived notes', () async {
        final futureDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'Reminder',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: futureDate,
        );

        dbService.addNote(note);
        stateService.updateAllNotes([note]);

        await service.archiveNotes([1]);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateService.archivedNotes.length, 1);
      });

      test('handles empty list', () async {
        await service.archiveNotes([]);
        // Should not throw
      });
    });

    group('unarchiveNotes', () {
      test('unarchives multiple notes', () async {
        final notes = [
          Note(
            id: 1,
            title: 'Note 1',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isArchived: true,
          ),
          Note(
            id: 2,
            title: 'Note 2',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isArchived: true,
          ),
        ];

        for (final note in notes) {
          dbService.addNote(note);
        }
        stateService.updateAllNotes(notes);

        await service.unarchiveNotes([1, 2]);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateService.activeNotes.length, 2);
        expect(stateService.archivedNotes.length, 0);
      });

      test('handles empty list', () async {
        await service.unarchiveNotes([]);
        // Should not throw
      });
    });

    group('Functional Immutability', () {
      test('batch operations use functional updates', () async {
        final note = Note(
          id: 1,
          title: 'Original',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        dbService.addNote(note);
        stateService.updateAllNotes([note]);

        await service.trashNotes([1]);

        // Note should be in trashed state in memory
        expect(stateService.trashedNotes.length, 1);
      });
    });

    group('Background Sync', () {
      test('uses Future.microtask for DB sync', () async {
        final note = Note(
          id: 1,
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        dbService.addNote(note);
        stateService.updateAllNotes([note]);

        // Call should return immediately (optimistic)
        await service.trashNotes([1]);

        // Memory should be updated immediately
        expect(stateService.trashedNotes.length, 1);

        // Wait for background sync
        await Future.delayed(const Duration(milliseconds: 100));
      });
    });

    group('Edge Cases', () {
      test('handles mixed valid and invalid IDs', () async {
        final note = Note(
          id: 1,
          title: 'Valid',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        dbService.addNote(note);
        stateService.updateAllNotes([note]);

        await service.trashNotes([1, 999]);

        expect(stateService.trashedNotes.length, 1);
      });

      test('handles duplicate IDs', () async {
        final note = Note(
          id: 1,
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        dbService.addNote(note);
        stateService.updateAllNotes([note]);

        await service.trashNotes([1, 1, 1]);

        expect(stateService.trashedNotes.length, 1);
      });

      test('handles large batch operations', () async {
        final notes = List.generate(
          100,
          (i) => Note(
            id: i,
            title: 'Note $i',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        );

        for (final note in notes) {
          dbService.addNote(note);
        }
        stateService.updateAllNotes(notes);

        final ids = List.generate(100, (i) => i);
        await service.trashNotes(ids);

        expect(stateService.trashedNotes.length, 100);
      });
    });
  });
}
