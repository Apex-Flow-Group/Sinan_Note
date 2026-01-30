// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';

void main() {
  group('NoteStateService', () {
    late NoteStateService service;
    late DateTime now;

    setUp(() {
      service = NoteStateService();
      now = DateTime.now();
    });

    tearDown(() {
      service.dispose();
    });

    group('Filtered Getters', () {
      test('activeNotes returns only active notes', () {
        final notes = [
          Note(
            id: 1,
            title: 'Active',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isArchived: false,
            isTrashed: false,
            isLocked: false,
          ),
          Note(
            id: 2,
            title: 'Archived',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isArchived: true,
            isTrashed: false,
            isLocked: false,
          ),
          Note(
            id: 3,
            title: 'Trashed',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isArchived: false,
            isTrashed: true,
            isLocked: false,
          ),
          Note(
            id: 4,
            title: 'Locked',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isArchived: false,
            isTrashed: false,
            isLocked: true,
          ),
        ];

        service.updateAllNotes(notes);

        expect(service.activeNotes.length, 1);
        expect(service.activeNotes.first.id, 1);
      });

      test('archivedNotes returns only archived notes', () {
        final notes = [
          Note(
            id: 1,
            title: 'Active',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isArchived: false,
          ),
          Note(
            id: 2,
            title: 'Archived',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isArchived: true,
          ),
          Note(
            id: 3,
            title: 'Archived and Trashed',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isArchived: true,
            isTrashed: true,
          ),
        ];

        service.updateAllNotes(notes);

        expect(service.archivedNotes.length, 1);
        expect(service.archivedNotes.first.id, 2);
      });

      test('trashedNotes returns only trashed notes', () {
        final notes = [
          Note(
            id: 1,
            title: 'Active',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
          Note(
            id: 2,
            title: 'Trashed',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isTrashed: true,
          ),
          Note(
            id: 3,
            title: 'Trashed and Locked',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isTrashed: true,
            isLocked: true,
          ),
        ];

        service.updateAllNotes(notes);

        expect(service.trashedNotes.length, 1);
        expect(service.trashedNotes.first.id, 2);
      });

      test('reminderNotes returns only notes with future reminders', () {
        final futureDate = now.add(const Duration(days: 1));
        final pastDate = now.subtract(const Duration(days: 1));

        final notes = [
          Note(
            id: 1,
            title: 'Future Reminder',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            reminderDateTime: futureDate,
          ),
          Note(
            id: 2,
            title: 'Past Reminder',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            reminderDateTime: pastDate,
          ),
          Note(
            id: 3,
            title: 'No Reminder',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        service.updateAllNotes(notes);

        expect(service.reminderNotes.length, 1);
        expect(service.reminderNotes.first.id, 1);
      });
    });

    group('State Management', () {
      test('updateAllNotes replaces entire list', () {
        final notes1 = [
          Note(
            id: 1,
            title: 'Note 1',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        service.updateAllNotes(notes1);
        expect(service.activeNotes.length, 1);

        final notes2 = [
          Note(
            id: 2,
            title: 'Note 2',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
          Note(
            id: 3,
            title: 'Note 3',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        service.updateAllNotes(notes2);
        expect(service.activeNotes.length, 2);
        expect(service.activeNotes.any((n) => n.id == 1), false);
      });

      test('updateNote updates existing note', () {
        final note = Note(
          id: 1,
          title: 'Original',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        service.updateAllNotes([note]);

        final updatedNote = note.copyWith(title: 'Updated');
        service.updateNote(updatedNote);

        expect(service.activeNotes.first.title, 'Updated');
      });

      test('updateNote adds note if not found', () {
        service.updateAllNotes([]);

        final note = Note(
          id: 1,
          title: 'New',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        service.updateNote(note);

        expect(service.activeNotes.length, 1);
        expect(service.activeNotes.first.id, 1);
      });

      test('addNote adds to beginning of list', () {
        final note1 = Note(
          id: 1,
          title: 'First',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        service.updateAllNotes([note1]);

        final note2 = Note(
          id: 2,
          title: 'Second',
          content: 'Content',
          createdAt: now,
          updatedAt: now.add(const Duration(seconds: 1)),
        );

        service.addNote(note2);

        // After sorting, note2 should be first (newer updatedAt)
        expect(service.activeNotes.first.id, 2);
      });

      test('removeNote removes from both lists', () {
        final activeNote = Note(
          id: 1,
          title: 'Active',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final lockedNote = Note(
          id: 2,
          title: 'Locked',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          isLocked: true,
        );

        service.updateAllNotes([activeNote]);
        service.updateLockedNotes([lockedNote]);

        service.removeNote(1);
        expect(service.activeNotes.length, 0);

        service.removeNote(2);
        expect(service.lockedNotes.length, 0);
      });
    });

    group('Search', () {
      test('searchNotes finds notes by title', () {
        final notes = [
          Note(
            id: 1,
            title: 'Flutter Development',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
          Note(
            id: 2,
            title: 'Dart Programming',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        service.updateAllNotes(notes);

        final results = service.searchNotes('Flutter');
        expect(results.length, 1);
        expect(results.first.id, 1);
      });

      test('searchNotes finds notes by content', () {
        final notes = [
          Note(
            id: 1,
            title: 'Note 1',
            content: 'Flutter is awesome',
            createdAt: now,
            updatedAt: now,
          ),
          Note(
            id: 2,
            title: 'Note 2',
            content: 'Dart is great',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        service.updateAllNotes(notes);

        final results = service.searchNotes('awesome');
        expect(results.length, 1);
        expect(results.first.id, 1);
      });

      test('searchNotes is case-insensitive', () {
        final notes = [
          Note(
            id: 1,
            title: 'Flutter Development',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        service.updateAllNotes(notes);

        final results = service.searchNotes('flutter');
        expect(results.length, 1);
      });

      test('searchNotes excludes locked notes', () {
        final notes = [
          Note(
            id: 1,
            title: 'Public Note',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
          Note(
            id: 2,
            title: 'Locked Note',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isLocked: true,
          ),
        ];

        service.updateAllNotes(notes);

        final results = service.searchNotes('Note');
        expect(results.length, 1);
        expect(results.first.id, 1);
      });

      test('searchNotes returns active notes for empty query', () {
        final notes = [
          Note(
            id: 1,
            title: 'Active',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
          Note(
            id: 2,
            title: 'Trashed',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isTrashed: true,
          ),
        ];

        service.updateAllNotes(notes);

        final results = service.searchNotes('');
        expect(results.length, 1);
        expect(results.first.id, 1);
      });
    });

    group('Sorting', () {
      test('sortNotes puts pinned notes first', () {
        final notes = [
          Note(
            id: 1,
            title: 'Regular',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isPinned: false,
          ),
          Note(
            id: 2,
            title: 'Pinned',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isPinned: true,
          ),
        ];

        service.updateAllNotes(notes);

        expect(service.activeNotes.first.id, 2);
      });

      test('sortNotes sorts by updatedAt (newest first)', () {
        final notes = [
          Note(
            id: 1,
            title: 'Old',
            content: 'Content',
            createdAt: now,
            updatedAt: now.subtract(const Duration(days: 1)),
          ),
          Note(
            id: 2,
            title: 'New',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        service.updateAllNotes(notes);

        expect(service.activeNotes.first.id, 2);
      });

      test('sortNotes with immediate flag sorts immediately', () {
        final notes = [
          Note(
            id: 1,
            title: 'Second',
            content: 'Content',
            createdAt: now,
            updatedAt: now.subtract(const Duration(seconds: 1)),
          ),
          Note(
            id: 2,
            title: 'First',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        service.updateAllNotes(notes);
        service.sortNotes(immediate: true);

        expect(service.activeNotes.first.id, 2);
      });
    });

    group('Batch Operations', () {
      test('batchUpdateNotes applies transformation to matching notes', () {
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
          Note(
            id: 3,
            title: 'Note 3',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        service.updateAllNotes(notes);

        service.batchUpdateNotes([1, 3], (note) => note.copyWith(isTrashed: true));

        expect(service.trashedNotes.length, 2);
        expect(service.activeNotes.length, 1);
        expect(service.activeNotes.first.id, 2);
      });

      test('batchUpdateNotes does not affect non-matching notes', () {
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

        service.updateAllNotes(notes);

        service.batchUpdateNotes([1], (note) => note.copyWith(title: 'Updated'));

        expect(service.activeNotes[0].title, 'Updated');
        expect(service.activeNotes[1].title, 'Note 2');
      });
    });

    group('Locked Notes', () {
      test('updateLockedNotes updates locked notes list', () {
        final lockedNotes = [
          Note(
            id: 1,
            title: 'Locked',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isLocked: true,
          ),
        ];

        service.updateLockedNotes(lockedNotes);

        expect(service.lockedNotes.length, 1);
        expect(service.lockedNotes.first.id, 1);
      });

      test('clearLockedNotes wipes locked notes from memory', () {
        final lockedNotes = [
          Note(
            id: 1,
            title: 'Locked',
            content: 'Content',
            createdAt: now,
            updatedAt: now,
            isLocked: true,
          ),
        ];

        service.updateLockedNotes(lockedNotes);
        expect(service.lockedNotes.length, 1);

        service.clearLockedNotes();
        expect(service.lockedNotes.length, 0);
      });

      test('addNote adds locked notes to separate list', () {
        final lockedNote = Note(
          id: 1,
          title: 'Locked',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          isLocked: true,
        );

        service.addNote(lockedNote);

        expect(service.lockedNotes.length, 1);
        expect(service.activeNotes.length, 0);
      });
    });

    group('Initial Data Loading', () {
      test('isInitialDataLoaded is false initially', () {
        expect(service.isInitialDataLoaded, false);
      });

      test('isInitialDataLoaded is true after updateAllNotes', () {
        service.updateAllNotes([]);
        expect(service.isInitialDataLoaded, true);
      });
    });
  });
}
