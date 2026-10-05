// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/ui/core/direction/text_direction.dart';

import '../helpers/test_data_layer.dart';
import '../test_setup.dart';

void main() {
  setUpAll(initializeTestEnvironment);

  final now = DateTime.utc(2026);
  List<Note> notes(int count) => List.generate(
        count,
        (i) => Note(
          title: 'Note $i',
          content: 'Content with keyword ${i % 10} ملاحظة عربية',
          createdAt: now.subtract(Duration(minutes: i)),
          updatedAt: now.subtract(Duration(minutes: i)),
          isPinned: i % 10 == 0,
          isArchived: i % 3 == 0,
          isTrashed: i % 5 == 0,
        ),
      );

  group('Performance Benchmarks', () {
    test('search across 1,000 notes < 50ms (first search builds the index)',
        () {
      final all = notes(1000);
      final sw = Stopwatch()..start();
      final results = all.where((n) => n.matches('keyword 7')).toList();
      sw.stop();
      expect(results, isNotEmpty);
      expect(sw.elapsedMilliseconds, lessThan(50));
    });

    test('repeat search across 1,000 notes < 10ms', () {
      final all = notes(1000)..forEach((n) => n.matches('warm'));
      final sw = Stopwatch()..start();
      all.where((n) => n.matches('ملاحظه')).toList();
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(10));
    });

    test('direction of 1,000 lines < 10ms', () {
      final lines = List.generate(
          1000, (i) => i.isEven ? 'مرحبا hello $i' : 'Hello مرحبا $i');
      final sw = Stopwatch()..start();
      for (final line in lines) {
        directionOf(line);
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(10));
    });

    test('load 1,000 notes and derive home lists < 500ms', () async {
      final data = await TestDataLayer.create();
      await data.notes.merge(notes(1000));
      final provider = NotesProvider(notes: data.notes, vault: data.vault);

      final sw = Stopwatch()..start();
      await data.notes.load();
      final total = provider.activeNotes.length +
          provider.archivedNotes.length +
          provider.trashedNotes.length;
      sw.stop();

      expect(total, 1000);
      expect(sw.elapsedMilliseconds, lessThan(500));
      provider.dispose();
      await data.dispose();
    });
  });
}
