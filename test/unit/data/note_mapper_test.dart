import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/data/services/database/note_mapper.dart';
import 'package:sinan_note/domain/models/note.dart';

void main() {
  group('Note Serialization — Backup Data Integrity', () {
    test('toMap ثم fromMap يُرجع نفس البيانات', () {
      final now = DateTime.now();
      final original = Note(
        id: 42,
        title: 'عنوان الملاحظة',
        content: 'محتوى الملاحظة',
        createdAt: now,
        updatedAt: now,
        colorIndex: 3,
        isArchived: false,
        isTrashed: false,
        isLocked: false,
        noteType: 'simple',
        isPinned: true,
        isChecklist: false,
      );

      final map = NoteMapper.toMap(original);
      final restored = NoteMapper.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.colorIndex, original.colorIndex);
      expect(restored.isPinned, original.isPinned);
      expect(restored.noteType, original.noteType);
    });

    test('fromMap يتعامل مع noteType القديم "pro"', () {
      final map = {
        'id': 1,
        'title': 'Code Note',
        'content': 'print("hello")',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'noteType': 'pro',
        'colorIndex': 0,
        'isArchived': 0,
        'isTrashed': 0,
        'isLocked': 0,
        'isCompleted': 0,
        'isProfessional': 1,
        'isPinned': 0,
        'isChecklist': 0,
      };

      final note = NoteMapper.fromMap(map);
      expect(note.noteType, 'code');
    });

    test('fromMap يتعامل مع noteType القديم "professional"', () {
      final map = {
        'id': 1,
        'title': 'Code',
        'content': 'code',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'noteType': 'professional',
        'colorIndex': 0,
        'isArchived': 0,
        'isTrashed': 0,
        'isLocked': 0,
        'isCompleted': 0,
        'isProfessional': 1,
        'isPinned': 0,
        'isChecklist': 0,
      };

      final note = NoteMapper.fromMap(map);
      expect(note.noteType, 'code');
    });

    test('تسلسل 1000 ملاحظة وإعادة تحميلها بدون فقدان بيانات', () {
      final now = DateTime.now();
      final notes = List.generate(
          1000,
          (i) => Note(
                id: i + 1,
                title: 'ملاحظة $i',
                content: 'محتوى $i',
                createdAt: now,
                updatedAt: now,
                colorIndex: i % 12,
                noteType: ['simple', 'code', 'checklist', 'reminder'][i % 4],
              ));

      final json = jsonEncode(notes.map((n) => NoteMapper.toMap(n)).toList());
      final decoded = jsonDecode(json) as List;
      final restored = decoded.map((m) => NoteMapper.fromMap(m)).toList();

      expect(restored.length, 1000);
      for (int i = 0; i < 1000; i++) {
        expect(restored[i].title, notes[i].title);
        expect(restored[i].colorIndex, notes[i].colorIndex);
        expect(restored[i].noteType, notes[i].noteType);
      }
    });

    test('ملاحظة مع تذكير تُحفظ وتُستعاد بشكل صحيح', () {
      final reminder = DateTime(2025, 12, 31, 10, 30);
      final note = Note(
        id: 1,
        title: 'تذكير',
        content: 'محتوى',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reminderDateTime: reminder,
        recurrenceRule: 'daily',
      );

      final map = NoteMapper.toMap(note);
      final restored = NoteMapper.fromMap(map);

      expect(restored.reminderDateTime, isNotNull);
      expect(restored.recurrenceRule, 'daily');
    });

    test('ملاحظة مقفلة تُحفظ وتُستعاد بشكل صحيح', () {
      final note = Note(
        id: 1,
        title: 'iv1234567890123456:encryptedcontent',
        content: 'iv1234567890123456:encryptedcontent',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isLocked: true,
      );

      final map = NoteMapper.toMap(note);
      final restored = NoteMapper.fromMap(map);

      expect(restored.isLocked, isTrue);
      expect(restored.title, note.title);
    });
  });
}
