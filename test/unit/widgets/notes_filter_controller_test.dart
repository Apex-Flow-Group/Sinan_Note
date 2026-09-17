// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/widgets/home/notes_grid/notes_filter_controller.dart';

void main() {
  late TextEditingController search;
  late ValueNotifier<String?> filter;
  late NotesFilterController controller;

  setUp(() {
    search = TextEditingController();
    filter = ValueNotifier<String?>(null);
    controller = NotesFilterController(
      searchController: search,
      activeFilterNotifier: filter,
    );
  });

  tearDown(() {
    controller.dispose();
    search.dispose();
    filter.dispose();
  });

  Note note({
    required int id,
    String title = '',
    String content = '',
    bool isPinned = false,
  }) {
    final now = DateTime(2026, 1, 1);
    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      isPinned: isPinned,
    );
  }

  List<int> matchIds(List<Note> source, String query) {
    search.text = query;
    controller.filterFor(source);
    return controller.filteredNotesNotifier.value
        .map((n) => n.id!)
        .toList(growable: false);
  }

  group('search matching', () {
    final notes = [
      note(id: 1, title: 'Release Roadmap', content: 'checklist for launch'),
      note(id: 2, title: 'مكانة الفيلم', content: 'إيرادات خلال العام'),
      note(id: 3, title: 'Vault', content: 'encryption keys'),
    ];

    test('matches a literal substring', () {
      expect(matchIds(notes, 'roadmap'), [1]);
    });

    test('normalizes Arabic before matching', () {
      expect(matchIds(notes, 'إيرادات'), [2]);
      expect(matchIds(notes, 'ايرادات'), [2]);
    });

    test('tolerates a single typo in a word', () {
      expect(matchIds(notes, 'roadmao'), [1]);
      expect(matchIds(notes, 'roadmp'), [1]);
      expect(matchIds(notes, 'rooadmap'), [1]);
    });

    test('rejects two or more typos', () {
      expect(matchIds(notes, 'rvadmxp'), isEmpty);
    });

    test('short queries match literally only', () {
      expect(matchIds(notes, 'vau'), [3]);
      expect(matchIds(notes, 'vxu'), isEmpty);
    });

    test('an empty query keeps every note', () {
      expect(matchIds(notes, ''), [1, 2, 3]);
    });
  });

  group('pinned filter', () {
    test('keeps only pinned notes', () {
      final notes = [
        note(id: 1, title: 'one', isPinned: true),
        note(id: 2, title: 'two'),
      ];
      filter.value = 'pinned:true';
      controller.filterFor(notes);
      expect(
        controller.filteredNotesNotifier.value.map((n) => n.id),
        [1],
      );
    });
  });
}
