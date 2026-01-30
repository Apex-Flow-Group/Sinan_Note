// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/notes_provider.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() {
    initializeTestEnvironment();
  });
  
  group('NotesProvider Integration', () {
    late NotesProvider provider;
    late DateTime now;

    setUp(() {
      provider = NotesProvider();
      now = DateTime.now();
    });

    tearDown(() {
      provider.dispose();
    });

    group('Service Delegation', () {
      test('delegates to NoteStateService for getters', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        await provider.addNote(note);

        expect(provider.activeNotes.length, 1);
        expect(provider.archivedNotes.length, 0);
        expect(provider.trashedNotes.length, 0);
      });

      test('delegates to NoteCRUDService for operations', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await provider.addNote(note);
        expect(id, greaterThan(0));

        final updatedNote = note.copyWith(id: id, title: 'Updated');
        await provider.updateNote(updatedNote);
        expect(provider.activeNotes.first.title, 'Updated');

        await provider.deleteNote(id);
        expect(provider.activeNotes.length, 0);
      });

      test('delegates to NoteSecurityService', () {
        expect(provider.isVaultUnlocked, false);

        provider.unlockVault();
        expect(provider.isVaultUnlocked, true);

        provider.lockVault();
        expect(provider.isVaultUnlocked, false);
      });

      test('delegates to NoteBatchOperationsService', () async {
        final notes = [
          Note(
            title: 'Note 1',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
          Note(
            title: 'Note 2',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        final id1 = await provider.addNote(notes[0]);
        final id2 = await provider.addNote(notes[1]);

        await provider.trashNotes([id1, id2]);

        expect(provider.trashedNotes.length, 2);
      });
    });

    group('NotifyListeners', () {
      test('notifies on state changes', () async {
        int count = 0;
        provider.addListener(() => count++);

        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        await provider.addNote(note);

        expect(count, greaterThan(0));
      });
    });

    group('Backward Compatibility', () {
      test('maintains public method signatures', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await provider.addNote(note);
        await provider.updateNote(note.copyWith(id: id));
        await provider.deleteNote(id);
        await provider.refreshAllNotes();

        final searched = provider.searchNotes('Test');
        expect(searched, isA<List<Note>>());
      });

      test('maintains getter compatibility', () {
        expect(provider.activeNotes, isA<List<Note>>());
        expect(provider.archivedNotes, isA<List<Note>>());
        expect(provider.trashedNotes, isA<List<Note>>());
        expect(provider.lockedNotes, isA<List<Note>>());
        expect(provider.reminderNotes, isA<List<Note>>());
        expect(provider.isVaultUnlocked, isA<bool>());
        expect(provider.isInitialDataLoaded, isA<bool>());
      });
    });

    group('Complex Workflows', () {
      test('handles complete lifecycle', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final id = await provider.addNote(note);
        expect(provider.activeNotes.length, 1);

        await provider.updateNote(note.copyWith(id: id, title: 'Updated'));
        expect(provider.activeNotes.first.title, 'Updated');

        await provider.archiveNotes([id]);
        await Future.delayed(const Duration(milliseconds: 100));
        expect(provider.archivedNotes.length, 1);

        await provider.unarchiveNotes([id]);
        await Future.delayed(const Duration(milliseconds: 100));
        expect(provider.activeNotes.length, 1);

        await provider.trashNotes([id]);
        expect(provider.trashedNotes.length, 1);

        await provider.restoreNotes([id]);
        await Future.delayed(const Duration(milliseconds: 100));
        expect(provider.activeNotes.length, 1);

        await provider.deleteNote(id);
        expect(provider.activeNotes.length, 0);
      });
    });
  });
}
