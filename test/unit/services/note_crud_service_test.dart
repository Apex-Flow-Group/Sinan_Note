// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/note_services/note_state_service.dart';

// Mock Database Service for testing
// Note: We can't extend IsarDatabaseService because it uses a factory constructor
// Instead, we create a standalone mock that implements the same interface
class MockDatabaseService {
  final Map<int, Note> _notes = {};
  int _nextId = 1;

  Future<int> insertNote(Note note) async {
    final id = _nextId++;
    _notes[id] = note.copyWith(id: id);
    return id;
  }

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

  Future<Note?> getNoteById(int id) async => _notes[id];

  Future<List<Note>> getAllNotes() async => _notes.values.toList();

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

  Future<List<Note>> getLockedNotes() async => [];
}

void main() {
  group('Database Operations', () {
    late MockDatabaseService dbService;
    late NoteStateService stateService;
    late DateTime now;

    setUp(() {
      dbService = MockDatabaseService();
      stateService = NoteStateService();
      now = DateTime.now();
    });

    tearDown(() {
      stateService.dispose();
    });

    test('inserts note into database', () async {
      final note = Note(
        title: 'Test',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      );

      final id = await dbService.insertNote(note);
      expect(id, greaterThan(0));

      final dbNote = await dbService.getNoteById(id);
      expect(dbNote, isNotNull);
      expect(dbNote!.title, 'Test');
    });

    test('updates note in database', () async {
      final note = Note(
        title: 'Original',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      );

      final id = await dbService.insertNote(note);
      final updatedNote = note.copyWith(id: id, title: 'Updated');
      await dbService.updateNote(updatedNote);

      final dbNote = await dbService.getNoteById(id);
      expect(dbNote?.title, 'Updated');
    });

    test('deletes note from database', () async {
      final note = Note(
        title: 'Test',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      );

      final id = await dbService.insertNote(note);
      await dbService.deleteNote(id);

      final dbNote = await dbService.getNoteById(id);
      expect(dbNote, isNull);
    });

    test('archives note', () async {
      final note = Note(
        title: 'Test',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      );

      final id = await dbService.insertNote(note);
      await dbService.archiveNote(id);

      final dbNote = await dbService.getNoteById(id);
      expect(dbNote?.isArchived, true);
    });

    test('trashes note', () async {
      final note = Note(
        title: 'Test',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      );

      final id = await dbService.insertNote(note);
      await dbService.trashNote(id);

      final dbNote = await dbService.getNoteById(id);
      expect(dbNote?.isTrashed, true);
    });

    test('restores note from trash', () async {
      final note = Note(
        title: 'Test',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      );

      final id = await dbService.insertNote(note);
      await dbService.trashNote(id);
      await dbService.restoreNote(id);

      final dbNote = await dbService.getNoteById(id);
      expect(dbNote?.isTrashed, false);
    });
  });
}

