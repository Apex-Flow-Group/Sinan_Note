// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/models/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Note Model', () {
    late DateTime now;
    setUp(() => now = DateTime.now());

    group('normalize()', () {
      test('removes Arabic diacritics', () {
        expect(Note.normalize('مَرْحَباً'), 'مرحبا');
      });
      test('normalizes alef variants', () {
        expect(Note.normalize('أإآ'), 'ااا');
      });
      test('normalizes taa marbuta', () {
        expect(Note.normalize('مدرسة'), 'مدرسه');
      });
      test('normalizes alef maksura', () {
        expect(Note.normalize('يحيى'), 'يحيي');
      });
      test('lowercases English', () {
        expect(Note.normalize('Hello World'), 'hello world');
      });
      test('handles empty string', () {
        expect(Note.normalize(''), '');
      });
    });

    group('isEncrypted', () {
      test('returns true for encrypted content', () {
        final note = Note(
          content: 'iv1234567890123456:encrypteddata',
          title: '', createdAt: now, updatedAt: now,
        );
        expect(note.isEncrypted, true);
      });
      test('returns false for plain content', () {
        final note = Note(title: '', content: 'plain text', createdAt: now, updatedAt: now);
        expect(note.isEncrypted, false);
      });
      test('returns false for empty content', () {
        final note = Note(title: '', content: '', createdAt: now, updatedAt: now);
        expect(note.isEncrypted, false);
      });
    });

    group('copyWith()', () {
      test('copies and overrides fields', () {
        final original = Note(
          id: 1, title: 'Original', content: 'Content',
          createdAt: now, updatedAt: now, colorIndex: 3, isPinned: true,
        );
        final copy = original.copyWith(title: 'Modified');
        expect(copy.title, 'Modified');
        expect(copy.content, 'Content');
        expect(copy.colorIndex, 3);
        expect(copy.isPinned, true);
      });
      test('can clear reminderDateTime with null', () {
        final note = Note(
          title: '', content: '', createdAt: now, updatedAt: now,
          reminderDateTime: now.add(const Duration(days: 1)),
        );
        expect(note.copyWith(reminderDateTime: null).reminderDateTime, isNull);
      });
      test('auto-updates normalizedTitle', () {
        final note = Note(title: 'أَهْلاً', content: '', createdAt: now, updatedAt: now);
        final copy = note.copyWith(title: 'مَرْحَباً');
        expect(copy.normalizedTitle, Note.normalize('مَرْحَباً'));
      });
    });

    group('toMap() / fromMap()', () {
      test('round-trip preserves all fields', () {
        final original = Note(
          id: 42, title: 'Test', content: 'Content',
          createdAt: now, updatedAt: now,
          colorIndex: 5, isArchived: true, isPinned: true,
          noteType: 'code', categoryIds: [1, 2, 3],
        );
        final restored = Note.fromMap(original.toMap());
        expect(restored.id, 42);
        expect(restored.title, 'Test');
        expect(restored.colorIndex, 5);
        expect(restored.isArchived, true);
        expect(restored.isPinned, true);
        expect(restored.noteType, 'code');
        expect(restored.categoryIds, [1, 2, 3]);
      });

      test('fromMap: noteType "pro" → "code"', () {
        final map = _baseMap(now)..['noteType'] = 'pro';
        expect(Note.fromMap(map).noteType, 'code');
      });

      test('fromMap: noteType "professional" → "code"', () {
        final map = _baseMap(now)..['noteType'] = 'professional';
        expect(Note.fromMap(map).noteType, 'code');
      });

      test('fromMap: empty categoryIds → []', () {
        final map = _baseMap(now)..['categoryIds'] = '';
        expect(Note.fromMap(map).categoryIds, isEmpty);
      });

      test('fromMap: null reminderDateTime → null', () {
        final map = _baseMap(now)..['reminderDateTime'] = null;
        expect(Note.fromMap(map).reminderDateTime, isNull);
      });

      test('fromMap: colorIndex out of range → 0', () {
        final map = _baseMap(now)..['colorIndex'] = 999;
        expect(Note.fromMap(map).colorIndex, 0);
      });

      test('1000 notes round-trip without data loss', () {
        for (int i = 0; i < 1000; i++) {
          final note = Note(
            id: i, title: 'Note $i', content: 'Content $i',
            createdAt: now, updatedAt: now,
            colorIndex: i % 12, noteType: ['simple', 'code', 'checklist'][i % 3],
          );
          final restored = Note.fromMap(note.toMap());
          expect(restored.title, note.title);
          expect(restored.colorIndex, note.colorIndex);
          expect(restored.noteType, note.noteType);
        }
      });
    });
  });
}

Map<String, dynamic> _baseMap(DateTime now) => {
  'id': 1, 'title': 'T', 'content': 'C',
  'createdAt': now.toIso8601String(), 'updatedAt': now.toIso8601String(),
  'noteType': 'simple', 'colorIndex': 0,
  'isArchived': 0, 'isTrashed': 0, 'isLocked': 0,
  'isCompleted': 0, 'isProfessional': 0, 'isPinned': 0, 'isChecklist': 0,
};
