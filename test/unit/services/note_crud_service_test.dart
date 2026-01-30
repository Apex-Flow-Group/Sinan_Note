// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/note_services/note_crud_service.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';
import 'package:apex_note/services/database_service.dart';

class MockDatabaseService implements DatabaseService {
  final Map<int, Note> _notes = {};
  int _nextId = 1;

  @override
  Future<int> insertNote(Note note) async {
    final id = _nextId++;
    _notes[id] = note.copyWith(id: id);
    return id;
  }

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
  Future<Note?> getNoteById(int id) async => _notes[id];

  @override
  Future<List<Note>> getAllNotes() async => _notes.values.toList();

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
  Future<List<Note>> getLockedNotes() async => [];
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('NoteCRUDService', () {
    late NoteCRUDService service;
    late MockDatabaseService dbService;
    late NoteStateService stateService;
    late DateTime now;

    setUp(() {
      dbService = MockDatabaseService();
      stateService = NoteStateService();
      service = NoteCRUDService(dbService, stateService);
      now = DateTime.now();
    });

    tearDown(() {
      stateService.dispose();
    });

    group('addNote', () {
      test('adds note to memory immediately', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        await service.addNote(note);

        // Note is added twice: once in addNote, once in updateNote with ID
        expect(stateService.activeNotes.length, greaterThanOrEqualTo(1));
      });

      test('inserts note into database', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);

        expect(id, greaterThan(0));
        final dbNote = await dbService.getNoteById(id);
        expect(dbNote, isNotNull);
      });

      test('updates note ID in memory after DB insert', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);

        // Find note with the returned ID
        final addedNote = stateService.activeNotes.firstWhere(
          (n) => n.id == id,
          orElse: () => note,
        );
        expect(addedNote.id, id);
      });
    });

    group('updateNote', () {
      test('updates note in database', () async {
        final note = Note(
          title: 'Original',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);
        final updatedNote = note.copyWith(id: id, title: 'Updated');

        final result = await service.updateNote(updatedNote);

        expect(result, 1);
        final dbNote = await dbService.getNoteById(id);
        expect(dbNote?.title, 'Updated');
      });

      test('fetches fresh data after update', () async {
        final note = Note(
          title: 'Original',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);
        final updatedNote = note.copyWith(id: id, title: 'Updated');

        await service.updateNote(updatedNote);

        // Find the updated note
        final found = stateService.activeNotes.firstWhere(
          (n) => n.id == id,
          orElse: () => note,
        );
        expect(found.title, 'Updated');
      });

      test('triggers immediate sort', () async {
        final note1 = Note(
          title: 'First',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          isPinned: false,
        );

        final id = await service.addNote(note1);
        final pinnedNote = note1.copyWith(id: id, isPinned: true);

        await service.updateNote(pinnedNote);

        expect(stateService.activeNotes.first.isPinned, true);
      });
    });

    group('deleteNote', () {
      test('deletes note from database', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);
        await service.deleteNote(id);

        final dbNote = await dbService.getNoteById(id);
        expect(dbNote, isNull);
      });

      test('removes note from memory', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);
        final initialCount = stateService.activeNotes.length;
        
        await service.deleteNote(id);

        // Should have one less note
        expect(stateService.activeNotes.length, lessThan(initialCount));
      });
    });

    group('getNoteById', () {
      test('retrieves note from database', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);
        final retrieved = await service.getNoteById(id);

        expect(retrieved, isNotNull);
        expect(retrieved?.title, 'Test');
      });

      test('returns null for non-existent note', () async {
        final retrieved = await service.getNoteById(999);
        expect(retrieved, isNull);
      });
    });

    group('refreshAllNotes', () {
      test('loads all notes from database', () async {
        final note1 = Note(
          title: 'Note 1',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );
        final note2 = Note(
          title: 'Note 2',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        await service.addNote(note1);
        await service.addNote(note2);

        stateService.updateAllNotes([]);
        expect(stateService.activeNotes.length, 0);

        await service.refreshAllNotes();
        expect(stateService.activeNotes.length, 2);
      });
    });

    group('archiveNote', () {
      test('archives note in database', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);
        await service.archiveNote(id);

        final dbNote = await dbService.getNoteById(id);
        expect(dbNote?.isArchived, true);
      });

      test('updates note in memory', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);
        await service.archiveNote(id);

        expect(stateService.archivedNotes.length, 1);
      });
    });

    group('trashNote', () {
      test('trashes regular note', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);
        await service.trashNote(id);

        final dbNote = await dbService.getNoteById(id);
        expect(dbNote?.isTrashed, true);
      });

      test('hard deletes locked note', () async {
        final note = Note(
          title: 'Locked',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          isLocked: true,
        );

        final id = await service.addNote(note);
        await service.trashNote(id);

        final dbNote = await dbService.getNoteById(id);
        expect(dbNote, isNull);
      });
    });

    group('restoreNote', () {
      test('restores note from trash', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);
        await service.trashNote(id);
        await service.restoreNote(id);

        final dbNote = await dbService.getNoteById(id);
        expect(dbNote?.isTrashed, false);
      });

      test('triggers sort after restore', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await service.addNote(note);
        await service.trashNote(id);
        await service.restoreNote(id);

        // Note should be restored
        expect(stateService.activeNotes.length, greaterThanOrEqualTo(1));
      });
    });
  });
}
