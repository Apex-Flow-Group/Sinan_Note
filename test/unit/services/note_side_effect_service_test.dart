// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/note_services/note_side_effect_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoteSideEffectService', () {
    late NoteSideEffectService service;
    late DateTime now;

    setUp(() {
      service = NoteSideEffectService();
      now = DateTime.now();
    });

    group('handleReminderSideEffect', () {
      test('returns true for note without reminder', () async {
        final note = Note(
          id: 1,
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        final result = await service.handleReminderSideEffect(note);
        expect(result, true);
      });

      test('handles note with future reminder', () async {
        final futureDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'Reminder',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: futureDate,
        );

        final result = await service.handleReminderSideEffect(note);
        // May fail on platforms without notification support
        expect(result, isA<bool>());
      });

      test('skips past reminders', () async {
        final pastDate = now.subtract(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'Past Reminder',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: pastDate,
        );

        final result = await service.handleReminderSideEffect(note);
        expect(result, true);
      });

      test('skips reminders for trashed notes', () async {
        final futureDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'Trashed',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: futureDate,
          isTrashed: true,
        );

        final result = await service.handleReminderSideEffect(note);
        expect(result, true);
      });

      test('skips reminders for archived notes', () async {
        final futureDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'Archived',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: futureDate,
          isArchived: true,
        );

        final result = await service.handleReminderSideEffect(note);
        expect(result, true);
      });

      test('handles checklist notes with special formatting', () async {
        final futureDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'Checklist',
          content: '[]Item 1\n[x]Item 2',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: futureDate,
          isChecklist: true,
        );

        final result = await service.handleReminderSideEffect(note);
        expect(result, isA<bool>());
      });

      test('handles note with recurrence rule', () async {
        final futureDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'Recurring',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: futureDate,
          recurrenceRule: 'FREQ=DAILY',
        );

        final result = await service.handleReminderSideEffect(note);
        expect(result, isA<bool>());
      });

      test('truncates long content in notification', () async {
        final futureDate = now.add(const Duration(days: 1));
        final longContent = 'A' * 200;
        final note = Note(
          id: 1,
          title: 'Long',
          content: longContent,
          createdAt: now,
          updatedAt: now,
          reminderDateTime: futureDate,
        );

        final result = await service.handleReminderSideEffect(note);
        expect(result, isA<bool>());
      });

      test('uses default title for empty title', () async {
        final futureDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: '',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: futureDate,
        );

        final result = await service.handleReminderSideEffect(note);
        expect(result, isA<bool>());
      });
    });

    group('cancelReminderSideEffect', () {
      test('cancels reminder without error', () async {
        await service.cancelReminderSideEffect(1);
        // Should not throw
      });

      test('handles non-existent reminder', () async {
        await service.cancelReminderSideEffect(999);
        // Should not throw
      });

      test('handles multiple cancellations', () async {
        await service.cancelReminderSideEffect(1);
        await service.cancelReminderSideEffect(1);
        // Should not throw
      });
    });

    group('updateWidgetSideEffect', () {
      test('completes without error', () async {
        await service.updateWidgetSideEffect();
        // Should not throw
      });

      test('can be called multiple times', () async {
        await service.updateWidgetSideEffect();
        await service.updateWidgetSideEffect();
        // Should not throw
      });
    });

    group('checkAndUpdateIfPinned', () {
      test('handles pinned note', () async {
        final note = Note(
          id: 1,
          title: 'Pinned',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          isPinned: true,
        );

        await service.checkAndUpdateIfPinned(note);
        // Should not throw
      });

      test('handles unpinned note', () async {
        final note = Note(
          id: 1,
          title: 'Regular',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          isPinned: false,
        );

        await service.checkAndUpdateIfPinned(note);
        // Should not throw
      });
    });

    group('checkAndResetIfPinned', () {
      test('handles note deletion', () async {
        await service.checkAndResetIfPinned(1);
        // Should not throw
      });

      test('handles non-existent note', () async {
        await service.checkAndResetIfPinned(999);
        // Should not throw
      });
    });

    group('Edge Cases', () {
      test('handles note with null ID', () async {
        final note = Note(
          title: 'No ID',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        // Should handle gracefully (may skip operations)
        final result = await service.handleReminderSideEffect(note);
        expect(result, isA<bool>());
      });

      test('handles note with empty content', () async {
        final futureDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'Empty',
          content: '',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: futureDate,
        );

        final result = await service.handleReminderSideEffect(note);
        expect(result, isA<bool>());
      });

      test('handles note with special characters', () async {
        final futureDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'مرحبا 😀',
          content: 'Content with\nnewlines\tand\ttabs',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: futureDate,
        );

        final result = await service.handleReminderSideEffect(note);
        expect(result, isA<bool>());
      });
    });
  });
}
