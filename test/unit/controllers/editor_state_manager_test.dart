// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/controllers/editor/editor_state_manager.dart';
import 'package:sinan_note/models/note.dart';

void main() {
  group('EditorStateManager', () {
    late EditorStateManager manager;
    late DateTime now;

    setUp(() {
      manager = EditorStateManager();
      now = DateTime.now();
    });

    group('Initialization', () {
      test('initializes with default values', () {
        expect(manager.content, '');
        expect(manager.customTitle, null);
        expect(manager.checklistTitle, null);
        expect(manager.colorIndex, 0);
        expect(manager.isAuthenticated, false);
        expect(manager.isSaving, false);
        expect(manager.isDirty, false);
        expect(manager.hasContent, false);
        expect(manager.canUndo, false);
        expect(manager.canRedo, false);
        expect(manager.reminderDateTime, null);
        expect(manager.recurrenceRule, null);
      });
    });

    group('loadFromNote', () {
      test('loads simple note correctly', () {
        final note = Note(
          id: 1,
          title: 'Test Title',
          content: 'Test Content',
          createdAt: now,
          updatedAt: now,
          colorIndex: 2,
          noteType: 'simple',
        );

        manager.loadFromNote(
          noteContent: note.content,
          noteTitle: note.title,
          noteColorIndex: note.colorIndex,
        );

        expect(manager.content, 'Test Content');
        expect(manager.customTitle, 'Test Title');
        expect(manager.colorIndex, 2);
        expect(manager.hasContent, true);
      });

      test('loads checklist note correctly', () {
        final note = Note(
          id: 1,
          title: 'Checklist Title',
          content: '[]Item 1\n[x]Item 2',
          createdAt: now,
          updatedAt: now,
          noteType: 'checklist',
          isChecklist: true,
        );

        manager.loadFromNote(
          noteContent: note.content,
          noteTitle: note.title,
          isChecklist: true,
        );

        expect(manager.content, '[]Item 1\n[x]Item 2');
        expect(manager.checklistTitle, 'Checklist Title');
        expect(manager.hasContent, true);
      });

      test('loads note with reminder correctly', () {
        final reminderDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'Reminder Note',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: reminderDate,
          recurrenceRule: 'FREQ=DAILY',
        );

        manager.loadFromNote(
          noteContent: note.content,
          noteTitle: note.title,
          noteReminderDateTime: note.reminderDateTime,
          noteRecurrenceRule: note.recurrenceRule,
        );

        expect(manager.reminderDateTime, reminderDate);
        expect(manager.recurrenceRule, 'FREQ=DAILY');
      });

      test('updates snapshot after loading', () {
        final note = Note(
          id: 1,
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        manager.loadFromNote(
          noteContent: note.content,
          noteTitle: note.title,
        );

        expect(manager.hasChanges(), false);
      });
    });

    group('hasChanges', () {
      test('returns false when no changes', () {
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
        );

        expect(manager.hasChanges(), false);
      });

      test('detects content changes', () {
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
        );

        manager.updateContent('Modified');

        expect(manager.hasChanges(), true);
      });

      test('detects title changes', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteTitle: 'Original Title',
        );

        manager.customTitle = 'Modified Title';

        expect(manager.hasChanges(), true);
      });

      test('detects color changes', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteColorIndex: 0,
        );

        manager.colorIndex = 1;

        expect(manager.hasChanges(), true);
      });

      test('detects reminder changes', () {
        final originalDate = now.add(const Duration(days: 1));
        manager.loadFromNote(
          noteContent: 'Content',
          noteReminderDateTime: originalDate,
        );

        manager.reminderDateTime = now.add(const Duration(days: 2));

        expect(manager.hasChanges(), true);
      });

      test('detects recurrence rule changes', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteRecurrenceRule: 'FREQ=DAILY',
        );

        manager.recurrenceRule = 'FREQ=WEEKLY';

        expect(manager.hasChanges(), true);
      });

      test('detects reminder removal', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteReminderDateTime: now.add(const Duration(days: 1)),
        );

        manager.reminderDateTime = null;

        expect(manager.hasChanges(), true);
      });

      test('handles null title correctly', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteTitle: null,
        );

        expect(manager.hasChanges(), false);

        manager.customTitle = 'New Title';
        expect(manager.hasChanges(), true);
      });
    });

    group('updateSnapshot', () {
      test('updates snapshot to current state', () {
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
        );

        manager.updateContent('Modified');
        expect(manager.hasChanges(), true);

        manager.updateSnapshot();
        expect(manager.hasChanges(), false);
      });

      test('updates all snapshot fields', () {
        manager.updateContent('New Content');
        manager.updateTitle('New Title');
        manager.colorIndex = 3;
        manager.reminderDateTime = now.add(const Duration(days: 1));
        manager.recurrenceRule = 'FREQ=DAILY';

        manager.updateSnapshot();
        expect(manager.hasChanges(), false);

        manager.updateContent('Different');
        expect(manager.hasChanges(), true);
      });
    });

    group('State Management', () {
      test('tracks content state correctly', () {
        expect(manager.hasContent, false);

        manager.content = 'Some content';
        manager.hasContent = true;

        expect(manager.hasContent, true);
      });

      test('tracks UI state correctly', () {
        expect(manager.isAuthenticated, false);
        expect(manager.isSaving, false);
        expect(manager.isDirty, false);

        manager.isAuthenticated = true;
        manager.isSaving = true;
        manager.isDirty = true;

        expect(manager.isAuthenticated, true);
        expect(manager.isSaving, true);
        expect(manager.isDirty, true);
      });

      test('tracks undo/redo state correctly', () {
        expect(manager.canUndo, false);
        expect(manager.canRedo, false);

        manager.canUndo = true;
        manager.canRedo = true;

        expect(manager.canUndo, true);
        expect(manager.canRedo, true);
      });
    });

    group('Edge Cases', () {
      test('handles empty content', () {
        manager.loadFromNote(
          noteContent: '',
          noteTitle: '',
        );

        expect(manager.hasChanges(), false);

        manager.updateContent('New');
        expect(manager.hasChanges(), true);
      });

      test('handles very long content', () {
        final longContent = 'A' * 10000;
        manager.loadFromNote(
          noteContent: longContent,
        );

        expect(manager.content, longContent);
        expect(manager.hasChanges(), false);
      });

      test('handles special characters in content', () {
        const specialContent = 'مرحبا\n\t\r\n😀🎉';
        manager.loadFromNote(
          noteContent: specialContent,
        );

        expect(manager.content, specialContent);
        expect(manager.hasChanges(), false);
      });

      test('handles null values correctly', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteTitle: null,
          noteReminderDateTime: null,
          noteRecurrenceRule: null,
        );

        expect(manager.customTitle, null);
        expect(manager.reminderDateTime, null);
        expect(manager.recurrenceRule, null);
        expect(manager.hasChanges(), false);
      });

      test('handles DateTime comparison correctly', () {
        final date1 = DateTime(2025, 1, 1, 12, 0, 0);
        final date2 = DateTime(2025, 1, 1, 12, 0, 0);

        manager.loadFromNote(
          noteContent: 'Content',
          noteReminderDateTime: date1,
        );

        manager.reminderDateTime = date2;

        // Same date/time should not trigger changes
        expect(manager.hasChanges(), false);
      });
    });

    group('Complex Scenarios', () {
      test('handles multiple changes and snapshot updates', () {
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
          noteColorIndex: 0,
        );
        expect(manager.hasChanges(), false);

        manager.updateContent('Modified 1');
        expect(manager.hasChanges(), true);

        manager.updateSnapshot();
        expect(manager.hasChanges(), false);

        manager.updateTitle('New Title');
        expect(manager.hasChanges(), true);

        manager.updateSnapshot();
        expect(manager.hasChanges(), false);
      });

      test('handles reverting changes', () {
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
        );

        // Make changes
        manager.content = 'Modified';
        manager.customTitle = 'New Title';
        expect(manager.hasChanges(), true);

        // Revert by reloading
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
        );
        expect(manager.hasChanges(), false);
      });

      test('handles switching between note types', () {
        // Load as simple note
        manager.loadFromNote(
          noteContent: 'Simple content',
          noteTitle: 'Simple Title',
        );

        // Switch to checklist
        manager.content = '[]Item 1';
        manager.checklistTitle = 'Checklist Title';
        manager.customTitle = null;

        expect(manager.hasChanges(), true);
      });
    });

    group('Performance', () {
      test('hasChanges is fast for large content', () {
        final largeContent = 'A' * 100000;
        manager.loadFromNote(
          noteContent: largeContent,
        );

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          manager.hasChanges();
        }
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('updateSnapshot is fast', () {
        manager.content = 'Content' * 1000;
        manager.customTitle = 'Title';
        manager.colorIndex = 5;

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          manager.updateSnapshot();
        }
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}

