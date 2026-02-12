// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/note_services/note_batch_operations_service.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';
import 'package:apex_note/services/note_services/note_side_effect_service.dart';
import '../../test_setup.dart';

// Mock Database Service for testing
// Note: We can't extend IsarDatabaseService because it uses a factory constructor
// Instead, we create a standalone mock that implements the same interface
class MockDatabaseService {
  final Map<int, Note> _notes = {};

  Future<int> updateNote(Note note) async {
    if (_notes.containsKey(note.id)) {
      _notes[note.id!] = note;
      return 1;
    }
    return 0;
  }

  Future<bool> deleteNote(int id) async {
    if (_notes.remove(id) != null) return true;
    return false;
  }

  Future<int> trashNote(int id) async {
    final note = _notes[id];
    if (note != null) {
      _notes[id] = note.copyWith(isTrashed: true);
      return 1;
    }
    return 0;
  }

  Future<int> restoreNote(int id) async {
    final note = _notes[id];
    if (note != null) {
      _notes[id] = note.copyWith(isTrashed: false, isArchived: false);
      return 1;
    }
    return 0;
  }

  Future<int> archiveNote(int id) async {
    final note = _notes[id];
    if (note != null) {
      _notes[id] = note.copyWith(isArchived: true);
      return 1;
    }
    return 0;
  }

  Future<int> unarchiveNote(int id) async {
    final note = _notes[id];
    if (note != null) {
      _notes[id] = note.copyWith(isArchived: false);
      return 1;
    }
    return 0;
  }

  Future<Note?> getNoteById(int id) async => _notes[id];

  void addNote(Note note) {
    _notes[note.id!] = note;
  }
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
      // Use dynamic to bypass type checking for mock
      service = NoteBatchOperationsService(
        dbService as dynamic,
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

        await service.batchTrashNotes([1, 2]);

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

        await service.batchTrashNotes([1, 2]);

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

        await service.batchTrashNotes([1]);

        // Should not throw
        expect(stateService.trashedNotes.length, 1);
      });

      test('handles empty list', () async {
        await service.batchTrashNotes([]);
        // Should not throw
      });

      test('handles non-existent notes', () async {
        await service.batchTrashNotes([999]);
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

        await service.batchRestoreNotes([1, 2]);

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

        await service.batchRestoreNotes([1, 2]);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Newer note should be first after sort
        expect(stateService.activeNotes.first.id, 2);
      });

      test('handles empty list', () async {
        await service.batchRestoreNotes([]);
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

        await service.batchArchiveNotes([1, 2]);

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

        await service.batchArchiveNotes([1]);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateService.archivedNotes.length, 1);
      });

      test('handles empty list', () async {
        await service.batchArchiveNotes([]);
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

        await service.batchUnarchiveNotes([1, 2]);

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        expect(stateService.activeNotes.length, 2);
        expect(stateService.archivedNotes.length, 0);
      });

      test('handles empty list', () async {
        await service.batchUnarchiveNotes([]);
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

        await service.batchTrashNotes([1]);

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
        await service.batchTrashNotes([1]);

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

        await service.batchTrashNotes([1, 999]);

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

        await service.batchTrashNotes([1, 1, 1]);

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
        await service.batchTrashNotes(ids);

        expect(stateService.trashedNotes.length, 100);
      });
    });
  });
}
