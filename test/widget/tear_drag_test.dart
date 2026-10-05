// Copyright © 2025 Apex Flow Group. All rights reserved.

// سحب الدمعة يحرّك المؤشر وحده: الصفحة تحتها لا تتمرر، أينما بدأت اللمسة
// في مربع اللمس، والمؤشر يتبع حركة الإصبع بالمقدار نفسه بلا قفزة.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/ui/features/editor/widgets/tear/tear.dart';

final _lines = List.generate(80, (i) => 'line $i').join('\n');

/// السطر الذي فيه [offset].
int _lineOf(int offset) => '\n'.allMatches(_lines.substring(0, offset)).length;

void main() {
  /// يفتح ملاحظة طويلة والمؤشر في السطر العاشر والدمعة ظاهرة، ثم يسحب من
  /// [grabAt] (موضع داخل الدمعة المرسومة) بمقدار [by].
  Future<({double scrolled, int line})> drag(WidgetTester tester,
      {required Offset Function(Rect tear) grabAt, required Offset by}) async {
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

    await tester.timedDragFrom(
        grabAt(tester.getRect(drawn)), by, const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    tear.dispose(); // يلغي مؤقت الإخفاء قبل نهاية الاختبار

    return (
      scrolled: scroll.offset,
      line: _lineOf(controller.selection.baseOffset),
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
    'above the tear': (t) => Offset(t.center.dx, t.top - 6),
  };
  for (final MapEntry(key: where, value: grabAt) in grabs.entries) {
    testWidgets('three lines up from the $where lands three lines up',
        (tester) async {
      final r =
          await drag(tester, grabAt: grabAt, by: const Offset(0, -3 * line));
      expect(r.line, 7);
    });
  }
}
