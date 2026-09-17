// Copyright © 2025 Apex Flow Group. All rights reserved.
//
// قياس تكلفة الفلترة على خيط الواجهة. الغرض توثيق رقم يُبنى عليه القرار،
// لا حجز ميزانية أداء — لذلك لا يفشل الاختبار على البطء.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/widgets/home/notes_grid/notes_filter_controller.dart';

void main() {
  const paragraph =
      'البدء في التخطيط لبناء منصة متكاملة تعتمد على قواعد بيانات موزعة '
      'لتوفير استجابة سريعة جدا في المزايدات والمتابعة اللحظية للطلبات '
      'Release roadmap checklist verify sync stability encryption vault ';

  List<Note> buildNotes(int count) {
    final now = DateTime(2026, 1, 1);
    return List.generate(count, (i) {
      return Note(
        id: i,
        title: 'ملاحظة رقم $i — Release Roadmap ${i % 7}',
        content: paragraph * 3,
        createdAt: now,
        updatedAt: now,
      );
    });
  }

  double measure(NotesFilterController controller, List<Note> notes) {
    final watch = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      controller.filterFor(notes);
    }
    watch.stop();
    return watch.elapsedMicroseconds / 20 / 1000;
  }

  test('filtering stays well inside a frame budget', () {
    final search = TextEditingController();
    final filter = ValueNotifier<String?>(null);
    final controller = NotesFilterController(
      searchController: search,
      activeFilterNotifier: filter,
    );
    addTearDown(() {
      controller.dispose();
      search.dispose();
      filter.dispose();
    });

    for (final count in [500, 2000]) {
      final notes = buildNotes(count);

      search.text = 'roadmap';
      final literal = measure(controller, notes);

      // استعلام لا يُطابق حرفياً — يُجبر المسح الضبابي على كل كلمة
      search.text = 'roadmxp';
      final fuzzy = measure(controller, notes);

      debugPrint('$count notes: literal ${literal.toStringAsFixed(2)}ms, '
          'fuzzy ${fuzzy.toStringAsFixed(2)}ms');

      expect(literal, lessThan(120));
      expect(fuzzy, lessThan(120));
    }
  });
}
