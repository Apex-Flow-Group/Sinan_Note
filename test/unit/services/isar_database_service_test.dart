// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:apex_note/models/note.dart';
import '../../test_setup.dart';

void main() {
  setUpAll(() {
    initializeTestEnvironment();
  });

  group('IsarDatabaseService', () {
    late IsarDatabaseService db;

    setUp(() {
      db = IsarDatabaseService();
    });

    tearDown(() async {
      await db.closeDB();
    });

    group('CRUD Operations', () {
      test('inserts note and returns ID', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await db.insertNote(note);
        expect(id, greaterThan(0));
      });

      test('gets note by ID', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await db.insertNote(note);
        final retrieved = await db.getNoteById(id);

        expect(retrieved, isNotNull);
        expect(retrieved!.title, 'Test');
        expect(retrieved.content, 'Content');
      });

      test('updates note', () async {
        final note = Note(
          title: 'Original',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await db.insertNote(note);
        final updated = note.copyWith(id: id, title: 'Updated');
        
        await db.updateNote(updated);
        final retrieved = await db.getNoteById(id);

        expect(retrieved!.title, 'Updated');
      });

      test('deletes note', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await db.insertNote(note);
        final deleted = await db.deleteNote(id);

        expect(deleted, true);
        expect(await db.getNoteById(id), isNull);
      });
    });

    group('Filtering', () {
      test('gets active notes only', () async {
        await db.insertNote(Note(
          title: 'Active',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        await db.insertNote(Note(
          title: 'Archived',
          content: 'Content',
          isArchived: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final notes = await db.getNotes();
        expect(notes.length, 1);
        expect(notes.first.title, 'Active');
      });

      test('gets archived notes', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await db.insertNote(note);
        await db.archiveNote(id);

        final archived = await db.getArchivedNotes();
        expect(archived.length, 1);
        expect(archived.first.isArchived, true);
      });

      test('gets trashed notes', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await db.insertNote(note);
        await db.trashNote(id);

        final trashed = await db.getTrashedNotes();
        expect(trashed.length, 1);
        expect(trashed.first.isTrashed, true);
      });

      test('gets locked notes', () async {
        final note = Note(
          title: 'Locked',
          content: 'Secret',
          isLocked: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await db.insertNote(note);
        final locked = await db.getLockedNotes();

        expect(locked.length, 1);
        expect(locked.first.isLocked, true);
      });
    });

    group('Search', () {
      test('searches by title', () async {
        await db.insertNote(Note(
          title: 'Flutter Tutorial',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        await db.insertNote(Note(
          title: 'Dart Guide',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final results = await db.searchNotes('Flutter');
        expect(results.length, 1);
        expect(results.first.title, 'Flutter Tutorial');
      });

      test('searches by content', () async {
        await db.insertNote(Note(
          title: 'Note',
          content: 'This is about Flutter',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final results = await db.searchNotes('Flutter');
        expect(results.length, 1);
      });

      test('search is case insensitive', () async {
        await db.insertNote(Note(
          title: 'Flutter',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final results = await db.searchNotes('flutter');
        expect(results.length, 1);
      });
    });

    group('Reminders', () {
      test('gets upcoming reminders', () async {
        final future = DateTime.now().add(const Duration(hours: 1));
        
        await db.insertNote(Note(
          title: 'Reminder',
          content: 'Content',
          reminderDateTime: future,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final reminders = await db.getUpcomingReminders();
        expect(reminders.length, 1);
      });

      test('excludes past reminders from upcoming', () async {
        final past = DateTime.now().subtract(const Duration(hours: 1));
        
        await db.insertNote(Note(
          title: 'Past',
          content: 'Content',
          reminderDateTime: past,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final reminders = await db.getUpcomingReminders();
        expect(reminders.length, 0);
      });

      test('gets expired reminders', () async {
        final past = DateTime.now().subtract(const Duration(hours: 1));
        
        await db.insertNote(Note(
          title: 'Expired',
          content: 'Content',
          reminderDateTime: past,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final expired = await db.getExpiredReminders();
        expect(expired.length, 1);
      });
    });

    group('Version Control', () {
      test('logs note version on insert', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await db.insertNote(note);
        final history = await db.getNoteHistory(id);

        expect(history.length, 1);
        expect(history.first.action, 'created');
      });

      test('logs note version on update', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await db.insertNote(note);
        await db.updateNote(note.copyWith(id: id, title: 'Updated'));
        
        final history = await db.getNoteHistory(id);
        expect(history.length, 2);
        expect(history.first.action, 'updated');
      });

      test('keeps max versions limit', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await db.insertNote(note);
        
        // Create 60 versions
        for (int i = 0; i < 60; i++) {
          await db.updateNote(note.copyWith(id: id, title: 'Update $i'));
        }

        final history = await db.getNoteHistory(id);
        expect(history.length, lessThanOrEqualTo(50));
      });
    });

    group('State Management', () {
      test('archives and unarchives note', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await db.insertNote(note);
        await db.archiveNote(id);
        
        var retrieved = await db.getNoteById(id);
        expect(retrieved!.isArchived, true);

        await db.unarchiveNote(id);
        retrieved = await db.getNoteById(id);
        expect(retrieved!.isArchived, false);
      });

      test('trashes and restores note', () async {
        final note = Note(
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final id = await db.insertNote(note);
        await db.trashNote(id);
        
        var retrieved = await db.getNoteById(id);
        expect(retrieved!.isTrashed, true);

        await db.restoreNote(id);
        retrieved = await db.getNoteById(id);
        expect(retrieved!.isTrashed, false);
      });
    });
  });
}
