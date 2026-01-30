// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';
import 'package:apex_note/controllers/editor/text_direction_controller.dart';

void main() {
  group('Performance Benchmarks', () {
    test('note list sorting < 50ms for 1000 notes', () {
      final service = NoteStateService();
      final now = DateTime.now();
      
      final notes = List.generate(1000, (i) => Note(
        id: i,
        title: 'Note $i',
        content: 'Content',
        createdAt: now.subtract(Duration(seconds: i)),
        updatedAt: now.subtract(Duration(seconds: i)),
        isPinned: i % 10 == 0,
      ));
      
      service.updateAllNotes(notes);
      
      final stopwatch = Stopwatch()..start();
      service.sortNotes(immediate: true);
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('in-memory filtering < 10ms for 1000 notes', () {
      final service = NoteStateService();
      final now = DateTime.now();
      
      final notes = List.generate(1000, (i) => Note(
        id: i,
        title: 'Note $i',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
        isArchived: i % 3 == 0,
        isTrashed: i % 5 == 0,
      ));
      
      service.updateAllNotes(notes);
      
      final stopwatch = Stopwatch()..start();
      final active = service.activeNotes;
      final archived = service.archivedNotes;
      final trashed = service.trashedNotes;
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      expect(active.length + archived.length + trashed.length, lessThanOrEqualTo(1000));
    });

    test('text direction detection < 5ms for 1000 chars', () {
      final controller = TextDirectionController();
      final text = 'Hello World مرحبا بك ' * 50;
      
      final stopwatch = Stopwatch()..start();
      controller.getParagraphDirections(text);
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(5));
    });

    test('search performance < 20ms for 1000 notes', () {
      final service = NoteStateService();
      final now = DateTime.now();
      
      final notes = List.generate(1000, (i) => Note(
        id: i,
        title: 'Note $i',
        content: 'Content with keyword ${i % 10}',
        createdAt: now,
        updatedAt: now,
      ));
      
      service.updateAllNotes(notes);
      
      final stopwatch = Stopwatch()..start();
      final results = service.searchNotes('keyword');
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(20));
      expect(results, isNotEmpty);
    });

    test('batch update performance < 100ms for 100 notes', () {
      final service = NoteStateService();
      final now = DateTime.now();
      
      final notes = List.generate(100, (i) => Note(
        id: i,
        title: 'Note $i',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      ));
      
      service.updateAllNotes(notes);
      
      final stopwatch = Stopwatch()..start();
      service.batchUpdateNotes(
        notes.map((n) => n.id!).toList(),
        (note) => note.copyWith(isPinned: true),
      );
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
