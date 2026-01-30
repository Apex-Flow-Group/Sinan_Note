// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';
import 'package:apex_note/services/note_services/note_crud_service.dart';
import 'package:apex_note/services/note_services/note_security_service.dart';
import 'package:apex_note/services/database_service.dart';
import 'package:apex_note/controllers/editor/text_direction_controller.dart';
import 'package:apex_note/controllers/editor/editor_state_manager.dart';
import 'package:flutter/material.dart';

// Mock Database Service for testing
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
  Future<List<Note>> getLockedNotes() async =>
      _notes.values.where((n) => n.isLocked).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final faker = Faker();

  group('Property Tests', () {
    group('Property 1: State Filtering', () {
      test('For any list of notes, filtered views contain only matching notes',
          () {
        final service = NoteStateService();
        final now = DateTime.now();

        // Generate random notes with various states
        for (int i = 0; i < 50; i++) {
          final notes = List.generate(20, (index) {
            final isArchived = faker.randomGenerator.boolean();
            final isTrashed = faker.randomGenerator.boolean();
            final isLocked = faker.randomGenerator.boolean();

            return Note(
              id: index,
              title: faker.lorem.sentence(),
              content: faker.lorem.words(10).join(' '),
              createdAt: now,
              updatedAt: now,
              isArchived: isArchived,
              isTrashed: isTrashed,
              isLocked: isLocked,
            );
          });

          service.updateAllNotes(notes);

          // Property: Active notes should not be archived, trashed, or locked
          for (final note in service.activeNotes) {
            expect(note.isArchived, false);
            expect(note.isTrashed, false);
            expect(note.isLocked, false);
          }

          // Property: Archived notes should be archived but not trashed or locked
          for (final note in service.archivedNotes) {
            expect(note.isArchived, true);
            expect(note.isTrashed, false);
            expect(note.isLocked, false);
          }

          // Property: Trashed notes should be trashed but not locked
          for (final note in service.trashedNotes) {
            expect(note.isTrashed, true);
            expect(note.isLocked, false);
          }

          // Property: Locked notes should be locked
          for (final note in service.lockedNotes) {
            expect(note.isLocked, true);
          }
        }

        service.dispose();
      });
    });

    group('Property 2: CRUD Consistency', () {
      test('For any note, adding then retrieving returns equivalent note', () async {
        final dbService = MockDatabaseService();
        final stateService = NoteStateService();
        final crudService = NoteCRUDService(dbService, stateService);
        final now = DateTime.now();

        for (int i = 0; i < 30; i++) {
          final originalNote = Note(
            title: faker.lorem.sentence(),
            content: faker.lorem.words(20).join(' '),
            createdAt: now,
            updatedAt: now,
            colorIndex: faker.randomGenerator.integer(10),
            isPinned: faker.randomGenerator.boolean(),
          );

          // Add note
          final id = await crudService.addNote(originalNote);

          // Retrieve note
          final retrievedNote = await crudService.getNoteById(id);

          // Property: Retrieved note should match original (except ID)
          expect(retrievedNote, isNotNull);
          expect(retrievedNote!.title, originalNote.title);
          expect(retrievedNote.content, originalNote.content);
          expect(retrievedNote.colorIndex, originalNote.colorIndex);
          expect(retrievedNote.isPinned, originalNote.isPinned);
        }

        stateService.dispose();
      });
    });

    group('Property 3: Text Direction Detection', () {
      test('For any text, direction detection is consistent', () {
        final controller = TextDirectionController();

        // Test Arabic text
        for (int i = 0; i < 20; i++) {
          final arabicText = 'مرحبا بك في التطبيق ${faker.randomGenerator.integer(100)}';
          final direction = controller.detectParagraphDirection(arabicText);
          expect(direction, TextDirection.rtl);
        }

        // Test English text
        for (int i = 0; i < 20; i++) {
          final englishText = faker.lorem.sentence();
          final direction = controller.detectParagraphDirection(englishText);
          expect(direction, TextDirection.ltr);
        }

        // Property: Empty text always returns LTR
        expect(controller.detectParagraphDirection(''), TextDirection.ltr);
        expect(controller.detectParagraphDirection('   '), TextDirection.ltr);
      });

      test('Multi-paragraph detection maintains per-paragraph accuracy', () {
        final controller = TextDirectionController();

        for (int i = 0; i < 20; i++) {
          final paragraphs = [
            'مرحبا بك',
            faker.lorem.sentence(),
            'هذا نص عربي',
            faker.lorem.sentence(),
          ];

          final content = paragraphs.join('\n');
          final directions = controller.getParagraphDirections(content);

          // Property: Number of directions matches number of paragraphs
          expect(directions.length, paragraphs.length);

          // Property: Each direction matches its paragraph
          expect(directions[0].direction, TextDirection.rtl);
          expect(directions[1].direction, TextDirection.ltr);
          expect(directions[2].direction, TextDirection.rtl);
          expect(directions[3].direction, TextDirection.ltr);
        }
      });
    });

    group('Property 4: Smart Dirty Checking', () {
      test('For any state change, hasChanges detects modifications correctly',
          () {
        final manager = EditorStateManager();
        final now = DateTime.now();

        for (int i = 0; i < 30; i++) {
          final originalContent = faker.lorem.words(15).join(' ');
          final originalTitle = faker.lorem.sentence();
          final originalColor = faker.randomGenerator.integer(10);

          manager.loadFromNote(
            noteContent: originalContent,
            noteTitle: originalTitle,
            noteColorIndex: originalColor,
          );

          // Property: No changes initially
          expect(manager.hasChanges(), false);

          // Modify content
          manager.content = faker.lorem.words(15).join(' ');
          expect(manager.hasChanges(), true);

          // Reset
          manager.loadFromNote(
            noteContent: originalContent,
            noteTitle: originalTitle,
            noteColorIndex: originalColor,
          );
          expect(manager.hasChanges(), false);

          // Modify title
          manager.customTitle = faker.lorem.sentence();
          expect(manager.hasChanges(), true);

          // Reset
          manager.loadFromNote(
            noteContent: originalContent,
            noteTitle: originalTitle,
            noteColorIndex: originalColor,
          );

          // Modify color
          manager.colorIndex = faker.randomGenerator.integer(10);
          if (manager.colorIndex != originalColor) {
            expect(manager.hasChanges(), true);
          }
        }
      });
    });

    group('Property 5: Cursor Position Stability', () {
      test('Cursor position remains stable across direction changes', () {
        final controller = TextDirectionController();

        for (int i = 0; i < 20; i++) {
          const content = 'مرحبا\nHello\nمرحبا مرة أخرى';
          final directions = controller.getParagraphDirections(content);

          // Property: Offsets are sequential and non-overlapping
          for (int j = 0; j < directions.length - 1; j++) {
            expect(
              directions[j].endOffset,
              lessThanOrEqualTo(directions[j + 1].startOffset),
            );
          }

          // Property: Last offset matches content length
          expect(directions.last.endOffset, content.length);
        }
      });
    });

    group('Property 6: Encryption Round-Trip', () {
      test('Locked notes maintain data integrity through encryption', () async {
        final dbService = MockDatabaseService();
        final securityService = NoteSecurityService();
        final now = DateTime.now();

        for (int i = 0; i < 20; i++) {
          final originalTitle = faker.lorem.sentence();
          final originalContent = faker.lorem.words(20).join(' ');

          final note = Note(
            id: i,
            title: originalTitle,
            content: originalContent,
            createdAt: now,
            updatedAt: now,
            isLocked: false,
          );

          dbService._notes[i] = note;

          // Lock (encrypt)
          await securityService.toggleLockStatus(i, true, dbService);

          final encryptedNote = await dbService.getNoteById(i);
          expect(encryptedNote?.isLocked, true);

          // Unlock (decrypt)
          await securityService.toggleLockStatus(i, false, dbService);

          final decryptedNote = await dbService.getNoteById(i);

          // Property: Decrypted content matches original
          expect(decryptedNote?.title, originalTitle);
          expect(decryptedNote?.content, originalContent);
        }
      });

      test('Checklists are never encrypted', () async {
        final dbService = MockDatabaseService();
        final securityService = NoteSecurityService();
        final now = DateTime.now();

        for (int i = 0; i < 10; i++) {
          const checklistContent = '[]Item 1\n[x]Item 2';

          final note = Note(
            id: i,
            title: 'Checklist',
            content: checklistContent,
            createdAt: now,
            updatedAt: now,
            isLocked: false,
            isChecklist: true,
          );

          dbService._notes[i] = note;

          // Lock
          await securityService.toggleLockStatus(i, true, dbService);

          final lockedNote = await dbService.getNoteById(i);

          // Property: Checklist content remains plain text
          expect(lockedNote?.content, checklistContent);
          expect(lockedNote?.title, 'Checklist');
        }
      });
    });

    group('Property 7: Search Consistency', () {
      test('Search results always match query criteria', () {
        final service = NoteStateService();
        final now = DateTime.now();

        for (int i = 0; i < 20; i++) {
          final notes = List.generate(30, (index) {
            return Note(
              id: index,
              title: faker.lorem.sentence(),
              content: faker.lorem.words(10).join(' '),
              createdAt: now,
              updatedAt: now,
            );
          });

          service.updateAllNotes(notes);

          // Random search query
          final query = faker.lorem.word();
          final results = service.searchNotes(query);

          // Property: All results contain query (case-insensitive)
          for (final note in results) {
            final matchesTitle =
                note.title.toLowerCase().contains(query.toLowerCase());
            final matchesContent =
                note.content.toLowerCase().contains(query.toLowerCase());
            expect(matchesTitle || matchesContent, true);
          }

          // Property: No locked notes in results
          for (final note in results) {
            expect(note.isLocked, false);
          }
        }

        service.dispose();
      });
    });

    group('Property 8: Sort Stability', () {
      test('Pinned notes always appear first after sort', () {
        final service = NoteStateService();
        final now = DateTime.now();

        for (int i = 0; i < 20; i++) {
          final notes = List.generate(20, (index) {
            return Note(
              id: index,
              title: faker.lorem.sentence(),
              content: faker.lorem.words(10).join(' '),
              createdAt: now,
              updatedAt: now.subtract(Duration(minutes: index)),
              isPinned: faker.randomGenerator.boolean(),
            );
          });

          service.updateAllNotes(notes);

          final activeNotes = service.activeNotes;
          final pinnedCount = activeNotes.where((n) => n.isPinned).length;

          if (pinnedCount > 0) {
            // Property: First N notes are pinned
            for (int j = 0; j < pinnedCount; j++) {
              expect(activeNotes[j].isPinned, true);
            }

            // Property: Remaining notes are not pinned
            for (int j = pinnedCount; j < activeNotes.length; j++) {
              expect(activeNotes[j].isPinned, false);
            }
          }
        }

        service.dispose();
      });
    });

    group('Property 9: Batch Operation Atomicity', () {
      test('Batch operations maintain consistency', () {
        final service = NoteStateService();
        final now = DateTime.now();

        for (int i = 0; i < 10; i++) {
          final notes = List.generate(20, (index) {
            return Note(
              id: index,
              title: faker.lorem.sentence(),
              content: faker.lorem.words(10).join(' '),
              createdAt: now,
              updatedAt: now,
            );
          });

          service.updateAllNotes(notes);

          // Batch trash
          final idsToTrash = [0, 1, 2, 3, 4];
          service.batchUpdateNotes(
            idsToTrash,
            (note) => note.copyWith(isTrashed: true),
          );

          // Property: All specified notes are trashed
          for (final id in idsToTrash) {
            final note = service.trashedNotes.firstWhere(
              (n) => n.id == id,
              orElse: () => notes[id],
            );
            expect(note.isTrashed, true);
          }

          // Property: Other notes remain active
          expect(service.activeNotes.length, notes.length - idsToTrash.length);
        }

        service.dispose();
      });
    });

    group('Property 10: Memory Safety', () {
      test('Locked notes are cleared from memory on vault lock', () {
        final stateService = NoteStateService();
        final securityService = NoteSecurityService();
        final now = DateTime.now();

        for (int i = 0; i < 10; i++) {
          final lockedNotes = List.generate(5, (index) {
            return Note(
              id: index,
              title: faker.lorem.sentence(),
              content: faker.lorem.words(10).join(' '),
              createdAt: now,
              updatedAt: now,
              isLocked: true,
            );
          });

          stateService.updateLockedNotes(lockedNotes);
          expect(stateService.lockedNotes.length, 5);

          // Lock vault and clear session
          securityService.lockVault();
          securityService.clearLockedSession(stateService);

          // Property: Locked notes are wiped from memory
          expect(stateService.lockedNotes.length, 0);
        }

        stateService.dispose();
      });
    });
  });
}
