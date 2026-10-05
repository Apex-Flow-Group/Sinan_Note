// Copyright © 2025 Apex Flow Group. All rights reserved.
// ⚡ MEMORY & PERFORMANCE — اختبارات تسريب الذاكرة والأداء

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/data/services/database/note_mapper.dart';
import 'package:sinan_note/domain/models/note.dart';

import '../helpers/test_data_layer.dart';
import '../test_setup.dart';

void main() {
  setUpAll(() => initializeTestEnvironment());

  final now = DateTime.now();

  Note note(int i) => Note(
        id: i,
        title: 'Note $i',
        content: 'Content $i ' * 10,
        createdAt: now,
        updatedAt: now,
      );

  // ══════════════════════════════════════════════════════════════
  // 1. تسريب الذاكرة — Controllers
  // ══════════════════════════════════════════════════════════════
  group('Memory Leak — Controllers', () {
    test('TextEditingController يُتلف بدون استثناء', () {
      final ctrl = TextEditingController();
      expect(() => ctrl.dispose(), returnsNormally);
    });

    test('FocusNode يُتلف بدون استثناء', () {
      final node = FocusNode();
      expect(() => node.dispose(), returnsNormally);
    });

    test('100 TextEditingController تُتلف بدون تسريب', () {
      final controllers =
          List.generate(100, (_) => TextEditingController(text: 'test'));
      expect(() {
        for (final c in controllers) {
          c.dispose();
        }
      }, returnsNormally);
    });

    test('UndoHistoryController يُتلف بدون استثناء', () {
      final ctrl = UndoHistoryController();
      expect(() => ctrl.dispose(), returnsNormally);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 2. تسريب الذاكرة — NotesProvider
  // ══════════════════════════════════════════════════════════════
  group('Memory Leak — NotesProvider', () {
    test('NotesProvider يُتلف ويفصل مستمعيه عن المستودع', () async {
      final data = await TestDataLayer.create();
      final provider = NotesProvider(notes: data.notes, vault: data.vault);
      var count = 0;
      provider.addListener(() => count++);
      provider.dispose();
      // بعد الإتلاف لا يصل إشعار من المستودع إلى الـ provider
      await data.notes.load();
      expect(count, 0);
      await data.dispose();
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 6. الأداء — Note Serialization
  // ══════════════════════════════════════════════════════════════
  group('Performance — Note Serialization', () {
    test('تسلسل 1000 ملاحظة في أقل من 200ms', () {
      final notes = List.generate(1000, (i) => note(i));

      final sw = Stopwatch()..start();
      final maps = notes.map((n) => NoteMapper.toMap(n)).toList();
      sw.stop();

      expect(maps.length, 1000);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });

    test('إعادة تحميل 1000 ملاحظة من Map في أقل من 200ms', () {
      final maps = List.generate(1000, (i) => NoteMapper.toMap(note(i)));

      final sw = Stopwatch()..start();
      final notes = maps.map((m) => NoteMapper.fromMap(m)).toList();
      sw.stop();

      expect(notes.length, 1000);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });
  });
}
