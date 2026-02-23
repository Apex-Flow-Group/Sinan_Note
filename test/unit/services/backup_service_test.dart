// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/storage/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() {
    initializeTestEnvironment();
  });

  group('BackupService', () {
    late BackupService service;

    setUp(() {
      service = BackupService();
    });

    test('checks local notes count', () async {
      final count = await service.checkLocalNotesCount();
      expect(count, greaterThanOrEqualTo(0));
    });

    test('exports notes to JSON format', () {
      final notes = [
        Note(
          title: 'Test 1',
          content: 'Content 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Note(
          title: 'Test 2',
          content: 'Content 2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final json = jsonEncode(notes.map((n) => n.toMap()).toList());
      expect(json, isNotEmpty);
      expect(json, contains('Test 1'));
      expect(json, contains('Test 2'));
    });

    test('imports notes from JSON format', () {
      const json = '''
      [
        {
          "title": "Imported",
          "content": "Content",
          "createdAt": "2025-01-01T00:00:00.000",
          "updatedAt": "2025-01-01T00:00:00.000",
          "colorIndex": 0,
          "isLocked": false,
          "isArchived": false,
          "isTrashed": false,
          "isPinned": false,
          "isCompleted": false,
          "isProfessional": false,
          "isChecklist": false,
          "noteType": "simple"
        }
      ]
      ''';

      final List<dynamic> data = jsonDecode(json);
      final notes = data.map((m) => Note.fromMap(m)).toList();

      expect(notes.length, 1);
      expect(notes.first.title, 'Imported');
    });

    test('handles empty export', () {
      final json = jsonEncode([]);
      expect(json, '[]');
    });

    test('handles invalid JSON import', () {
      expect(() => jsonDecode('invalid'), throwsException);
    });

    test('preserves note properties', () {
      final original = Note(
        title: 'Test',
        content: 'Content',
        colorIndex: 5,
        isLocked: true,
        isPinned: true,
        noteType: 'code',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = jsonEncode([original.toMap()]);
      final List<dynamic> data = jsonDecode(json);
      final imported = data.map((m) => Note.fromMap(m)).toList();

      expect(imported.first.title, original.title);
      expect(imported.first.colorIndex, original.colorIndex);
      expect(imported.first.isLocked, original.isLocked);
      expect(imported.first.isPinned, original.isPinned);
    });
  });
}
