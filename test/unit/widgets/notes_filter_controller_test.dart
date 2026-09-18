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

  group('search debounce', () {
    testWidgets('typing refilters once, and clearing responds immediately',
        (tester) async {
      controller.filterFor([
        note(id: 1, title: 'Release Roadmap'),
        note(id: 2, title: 'Vault'),
      ]);

      var rebuilds = 0;
      void count() => rebuilds++;
      controller.filteredNotesNotifier.addListener(count);
      addTearDown(
        () => controller.filteredNotesNotifier.removeListener(count),
      );

      for (final partial in ['r', 're', 'rel', 'rele', 'relea']) {
        search.text = partial;
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(rebuilds, 0,
          reason: 'fast typing must not refilter per keystroke');

      await tester.pump(const Duration(milliseconds: 150));
      expect(rebuilds, 1);
      expect(controller.filteredNotesNotifier.value.single.id, 1);

      search.text = '';
      expect(rebuilds, 2, reason: 'clearing the field is not debounced');
      expect(controller.filteredNotesNotifier.value.length, 2);
    });
  });

  group('provider updates', () {
    test('an edited note is swapped in place without refiltering', () {
      final before = [
        note(id: 1, title: 'One', content: 'a'),
        note(id: 2, title: 'Two', content: 'b'),
      ];
      controller.filterFor(before);

      final edited = Note(
        id: 2,
        title: 'Two',
        content: 'b',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 6, 1),
        colorIndex: 3,
      );
      controller.applyProviderNotes([before.first, edited]);

      final visible = controller.filteredNotesNotifier.value;
      expect(visible.map((n) => n.id), [1, 2]);
      expect(visible.last.colorIndex, 3);
    });

    test('a note missing from the provider is dropped', () {
      final before = [
        note(id: 1, title: 'One'),
        note(id: 2, title: 'Two'),
      ];
      controller.filterFor(before);

      controller.applyProviderNotes([before.first]);

      expect(controller.filteredNotesNotifier.value.map((n) => n.id), [1]);
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
