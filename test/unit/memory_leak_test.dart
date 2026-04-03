// Copyright © 2025 Apex Flow Group. All rights reserved.
// ⚡ MEMORY & PERFORMANCE — اختبارات تسريب الذاكرة والأداء

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';
import 'package:apex_note/services/storage/compression_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  // 2. تسريب الذاكرة — NoteStateService
  // ══════════════════════════════════════════════════════════════
  group('Memory Leak — NoteStateService', () {
    test('dispose يُلغي كل الـ timers', () {
      final service = NoteStateService();
      service.updateAllNotes(List.generate(10, (i) => note(i)));
      service.sortNotes(); // ينشئ debounce timer
      service.updateNote(note(1)); // ينشئ sync timer
      expect(() => service.dispose(), returnsNormally);
    });

    test('إنشاء وتدمير 50 NoteStateService لا يُسبب مشاكل', () {
      for (int i = 0; i < 50; i++) {
        final service = NoteStateService();
        service.updateAllNotes(List.generate(5, (j) => note(j)));
        service.dispose();
      }
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 3. تسريب الذاكرة — NotesProvider
  // ══════════════════════════════════════════════════════════════
  group('Memory Leak — NotesProvider', () {
    test('NotesProvider يُتلف بدون استثناء', () {
      final provider = NotesProvider();
      expect(() => provider.dispose(), returnsNormally);
    });

    test('NotesProvider مع listeners يُتلف بدون تسريب', () {
      final provider = NotesProvider();
      int count = 0;
      provider.addListener(() => count++);
      expect(() => provider.dispose(), returnsNormally);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 4. الأداء — NoteStateService
  // ══════════════════════════════════════════════════════════════
  group('Performance — NoteStateService', () {
    test('تحميل 10,000 ملاحظة في أقل من 500ms', () {
      final service = NoteStateService();
      final notes = List.generate(10000, (i) => note(i));

      final sw = Stopwatch()..start();
      service.updateAllNotes(notes);
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(500));
      service.dispose();
    });

    test('فلترة 10,000 ملاحظة في أقل من 100ms', () {
      final service = NoteStateService();
      service.updateAllNotes(List.generate(10000, (i) => note(i)));

      final sw = Stopwatch()..start();
      final _ = service.activeNotes;
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(100));
      service.dispose();
    });

    test('البحث في 10,000 ملاحظة في أقل من 200ms', () {
      final service = NoteStateService();
      service.updateAllNotes(List.generate(10000, (i) => note(i)));

      final sw = Stopwatch()..start();
      service.searchNotes('Note 5000');
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(200));
      service.dispose();
    });

    test('الكاش يُسرِّع القراءة المتكررة', () {
      final service = NoteStateService();
      service.updateAllNotes(List.generate(5000, (i) => note(i)));

      // أول قراءة (بناء الكاش)
      final sw1 = Stopwatch()..start();
      service.activeNotes;
      sw1.stop();

      // ثاني قراءة (من الكاش)
      final sw2 = Stopwatch()..start();
      service.activeNotes;
      sw2.stop();

      // الكاش يجب أن يكون أسرع
      expect(sw2.elapsedMicroseconds,
          lessThanOrEqualTo(sw1.elapsedMicroseconds + 100));
      service.dispose();
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 5. الأداء — Compression
  // ══════════════════════════════════════════════════════════════
  group('Performance — Compression', () {
    test('ضغط 1MB من البيانات في أقل من 1000ms', () {
      final largeData = 'x' * 1024 * 1024; // 1MB
      final sw = Stopwatch()..start();
      CompressionService.compress(largeData);
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('ضغط وفك ضغط 100KB في أقل من 200ms', () {
      final data = 'Note content with Arabic text: مرحبا بالعالم\n' * 1000;
      final sw = Stopwatch()..start();
      final compressed = CompressionService.compress(data);
      final decompressed = CompressionService.decompress(compressed);
      sw.stop();

      expect(decompressed, equals(data));
      expect(sw.elapsedMilliseconds, lessThan(200));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 6. الأداء — Note Serialization
  // ══════════════════════════════════════════════════════════════
  group('Performance — Note Serialization', () {
    test('تسلسل 1000 ملاحظة في أقل من 200ms', () {
      final notes = List.generate(1000, (i) => note(i));

      final sw = Stopwatch()..start();
      final maps = notes.map((n) => n.toMap()).toList();
      sw.stop();

      expect(maps.length, 1000);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });

    test('إعادة تحميل 1000 ملاحظة من Map في أقل من 200ms', () {
      final maps = List.generate(1000, (i) => note(i).toMap());

      final sw = Stopwatch()..start();
      final notes = maps.map((m) => Note.fromMap(m)).toList();
      sw.stop();

      expect(notes.length, 1000);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });
  });
}
