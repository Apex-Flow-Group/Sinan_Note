import 'dart:convert';

// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/data/services/database/note_mapper.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/text/text_normalizer.dart';

void main() {
  group('Note Model', () {
    late DateTime now;
    setUp(() => now = DateTime.now());

    group('normalize()', () {
      test('removes Arabic diacritics', () {
        expect(TextNormalizer.normalize('مَرْحَباً'), 'مرحبا');
      });
      test('normalizes alef variants', () {
        expect(TextNormalizer.normalize('أإآ'), 'ااا');
      });
      test('normalizes taa marbuta', () {
        expect(TextNormalizer.normalize('مدرسة'), 'مدرسه');
      });
      test('normalizes alef maksura', () {
        expect(TextNormalizer.normalize('يحيى'), 'يحيي');
      });
      test('lowercases English', () {
        expect(TextNormalizer.normalize('Hello World'), 'hello world');
      });
      test('handles empty string', () {
        expect(TextNormalizer.normalize(''), '');
      });
    });

    group('matches()', () {
      test('finds the note by its readable text, not raw Delta JSON', () {
        final note = Note(
          title: 'Groceries',
          content: jsonEncode([
            {'insert': 'milk and bread\n'}
          ]),
          createdAt: now,
          updatedAt: now,
        );
        expect(note.matches('bread'), isTrue);
        expect(note.matches('insert'), isFalse);
      });
      test('ignores Arabic diacritics and alef forms', () {
        final note = Note(
            title: 'أَهْلاً بكم', content: '', createdAt: now, updatedAt: now);
        expect(note.matches('اهلا'), isTrue);
      });
      test('typo tolerance is opt-in', () {
        final note = Note(
            title: 'meeting notes',
            content: '',
            createdAt: now,
            updatedAt: now);
        expect(note.matches('meetimg'), isFalse);
        expect(note.matches('meetimg', typoTolerant: true), isTrue);
      });
    });

    group('identity', () {
      test('a new note gets a uuid; copies keep it; asNew replaces it', () {
        final note =
            Note(title: '', content: '', createdAt: now, updatedAt: now);
        expect(note.uuid, isNotEmpty);
        expect(note.copyWith(title: 'x').uuid, note.uuid);
        expect(note.asNew().uuid, isNot(note.uuid));
      });
      test('copyWith can clear the local id', () {
        final note =
            Note(id: 5, title: '', content: '', createdAt: now, updatedAt: now);
        expect(note.copyWith(id: null).id, isNull);
      });
    });

    group('copyWith()', () {
      test('copies and overrides fields', () {
        final original = Note(
          id: 1,
          title: 'Original',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          colorIndex: 3,
          isPinned: true,
        );
        final copy = original.copyWith(title: 'Modified');
        expect(copy.title, 'Modified');
        expect(copy.content, 'Content');
        expect(copy.colorIndex, 3);
        expect(copy.isPinned, true);
      });
      test('can clear reminderDateTime with null', () {
        final note = Note(
          title: '',
          content: '',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: now.add(const Duration(days: 1)),
        );
        expect(note.copyWith(reminderDateTime: null).reminderDateTime, isNull);
      });
    });

    group('toMap() / fromMap()', () {
      test('round-trip preserves all fields', () {
        final original = Note(
          id: 42,
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          colorIndex: 5,
          isArchived: true,
          isPinned: true,
          noteType: 'code',
          categoryIds: [1, 2, 3],
        );
        final restored = NoteMapper.fromMap(NoteMapper.toMap(original));
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
        expect(NoteMapper.fromMap(map).noteType, 'code');
      });

      test('fromMap: noteType "professional" → "code"', () {
        final map = _baseMap(now)..['noteType'] = 'professional';
        expect(NoteMapper.fromMap(map).noteType, 'code');
      });

      test('fromMap: empty categoryIds → []', () {
        final map = _baseMap(now)..['categoryIds'] = '';
        expect(NoteMapper.fromMap(map).categoryIds, isEmpty);
      });

      test('fromMap: null reminderDateTime → null', () {
        final map = _baseMap(now)..['reminderDateTime'] = null;
        expect(NoteMapper.fromMap(map).reminderDateTime, isNull);
      });

      test('fromMap: colorIndex out of range → 0', () {
        final map = _baseMap(now)..['colorIndex'] = 999;
        expect(NoteMapper.fromMap(map).colorIndex, 0);
      });

      test('1000 notes round-trip without data loss', () {
        for (int i = 0; i < 1000; i++) {
          final note = Note(
            id: i,
            title: 'Note $i',
            content: 'Content $i',
            createdAt: now,
            updatedAt: now,
            colorIndex: i % 12,
            noteType: ['simple', 'code', 'checklist'][i % 3],
          );
          final restored = NoteMapper.fromMap(NoteMapper.toMap(note));
          expect(restored.title, note.title);
          expect(restored.colorIndex, note.colorIndex);
          expect(restored.noteType, note.noteType);
        }
      });
    });
  });
}

Map<String, dynamic> _baseMap(DateTime now) => {
      'id': 1,
      'title': 'T',
      'content': 'C',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'noteType': 'simple',
      'colorIndex': 0,
      'isArchived': 0,
      'isTrashed': 0,
      'isLocked': 0,
      'isCompleted': 0,
      'isProfessional': 0,
      'isPinned': 0,
      'isChecklist': 0,
    };
