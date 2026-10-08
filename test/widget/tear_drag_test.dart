// Copyright © 2025 Apex Flow Group. All rights reserved.

// الدمعة تحت المؤشر:
// - سحبها يحرّك المؤشر وحده: الصفحة لا تتمرر، والمؤشر يتبع حركة الإصبع
//   بالمقدار نفسه بلا قفزة.
// - منطقة لمسها تبدأ من أسفل السطر: لا تغطي النص، فالضغط المزدوج على الكلمة
//   يحددها والدمعة ظاهرة.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/ui/features/editor/widgets/tear/tear.dart';

final _lines = List.generate(80, (i) => 'line $i').join('\n');

/// السطر الذي فيه [offset].
int _lineOf(int offset) => '\n'.allMatches(_lines.substring(0, offset)).length;

typedef _Opened = ({
  QuillController controller,
  ScrollController scroll,
  TearController tear,
  Finder drawn,
});

void main() {
  /// ملاحظة طويلة، المؤشر في السطر العاشر، والدمعة ظاهرة.
  Future<_Opened> open(WidgetTester tester) async {
    final caret = _lines.indexOf('line 10') + 2;
    final controller = QuillController(
      document: Document.fromDelta(Delta()..insert('$_lines\n')),
      selection: TextSelection.collapsed(offset: caret),
    );
    final editorKey = GlobalKey<EditorState>();
    final scroll = ScrollController();
    final tear = TearController(
      quillController: controller,
      getBgColor: () => Colors.white,
    );

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SizedBox(
          height: 400,
          child: QuillEditor(
            controller: controller,
            focusNode: FocusNode(),
            scrollController: scroll,
            config: QuillEditorConfig(
              editorKey: editorKey,
              scrollable: true,
              expands: true,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    tear.showOnTap(editorKey: editorKey);
    // الدمعة تظهر بعد الإطار التالي
    tester.binding.scheduleFrame();
    await tester.pumpAndSettle();
    final drawn = find
        .byWidgetPredicate((w) => w is CustomPaint && w.painter is TearPainter);
    expect(drawn, findsOneWidget);
    return (controller: controller, scroll: scroll, tear: tear, drawn: drawn);
  }

  /// يسحب من [grabAt] (موضع بالنسبة للدمعة المرسومة) بمقدار [by].
  Future<({double scrolled, int line})> drag(WidgetTester tester,
      {required Offset Function(Rect tear) grabAt, required Offset by}) async {
    final o = await open(tester);
    await tester.timedDragFrom(
        grabAt(tester.getRect(o.drawn)), by, const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    o.tear.dispose(); // يلغي مؤقت الإخفاء قبل نهاية الاختبار
    return (
      scrolled: o.scroll.offset,
      line: _lineOf(o.controller.selection.baseOffset),
    );
  }

  // ارتفاع السطر في المحرر بالخط الافتراضي
  const line = 18.0;

  testWidgets('a touch just below the drawn tear does not scroll the page',
      (tester) async {
    // الإصبع يصعد: لو استلمت الصفحة اللمسة لتمررت
    final r = await drag(tester,
        grabAt: (t) => Offset(t.center.dx, t.bottom + 6),
        by: const Offset(0, -5 * line));
    expect(r.scrolled, 0);
    expect(r.line, lessThan(10));
  });

  // المؤشر يتحرك بمقدار حركة الإصبع أينما أُمسك مربع الدمعة، بلا قفزة
  final grabs = <String, Offset Function(Rect)>{
    'tear centre': (t) => t.center,
    'below the tear': (t) => Offset(t.center.dx, t.bottom + 6),
  };
  for (final MapEntry(key: where, value: grabAt) in grabs.entries) {
    testWidgets('three lines up from the $where lands three lines up',
        (tester) async {
      final r =
          await drag(tester, grabAt: grabAt, by: const Offset(0, -3 * line));
      expect(r.line, 7);
    });
  }

  testWidgets('a double tap on the word above the tear selects it',
      (tester) async {
    final o = await open(tester);
    // أسفل سطر النص مباشرة فوق رأس الدمعة: نص، لا دمعة
    final tip = tester.getRect(o.drawn).topCenter;
    final onText = tip.translate(0, -4);
    await tester.tapAt(onText);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(onText);
    await tester.pumpAndSettle();

    expect(o.controller.selection.isCollapsed, isFalse,
        reason: 'the double tap reached the text and selected the word');
    expect(_lineOf(o.controller.selection.start), 10);
    o.tear.dispose();
  });
}
