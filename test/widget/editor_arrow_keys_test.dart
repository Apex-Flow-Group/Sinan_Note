// Copyright © 2025 Apex Flow Group. All rights reserved.

// السهمان يمين/يسار بصريان (كما في أندرويد): في سطر عربي "يمين" يرجع في
// ترتيب النص. هكذا تحرّك لوحة المفاتيح المؤشر بالسحب على زر المسافة.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/ui/core/direction/text_direction.dart';

void main() {
  Future<QuillController> editor(
      WidgetTester tester, String text, int caret) async {
    final controller = QuillController(
      document: Document.fromDelta(Delta()..insert('$text\n')),
      selection: TextSelection.collapsed(offset: caret),
    );
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: QuillEditor(
            controller: controller,
            focusNode: focus,
            scrollController: ScrollController(),
            config: const QuillEditorConfig(
              textDirectionResolver: strongDirectionOf,
            ),
          ),
        ),
      ),
    ));
    focus.requestFocus();
    await tester.pumpAndSettle();
    return controller;
  }

  Future<int> press(
      WidgetTester tester, QuillController c, LogicalKeyboardKey key,
      {bool shift = false}) async {
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    return c.selection.extentOffset;
  }

  testWidgets('arabic line: right goes back in the text, left goes on',
      (tester) async {
    final c = await editor(tester, 'مرحبا', 2);
    expect(await press(tester, c, LogicalKeyboardKey.arrowRight), 1);
    expect(await press(tester, c, LogicalKeyboardKey.arrowLeft), 2);
    expect(await press(tester, c, LogicalKeyboardKey.arrowLeft), 3);
  });

  testWidgets('english line, even in an arabic app: right goes on',
      (tester) async {
    final c = await editor(tester, 'hello', 2);
    expect(await press(tester, c, LogicalKeyboardKey.arrowRight), 3);
    expect(await press(tester, c, LogicalKeyboardKey.arrowLeft), 2);
  });

  testWidgets('each line follows its own direction', (tester) async {
    // سطر عربي ثم سطر إنجليزي: المؤشر في الثاني
    final c = await editor(tester, 'مرحبا\nhello', 8);
    expect(await press(tester, c, LogicalKeyboardKey.arrowRight), 9);
    c.updateSelection(
        const TextSelection.collapsed(offset: 3), ChangeSource.local);
    await tester.pump();
    expect(await press(tester, c, LogicalKeyboardKey.arrowRight), 2);
  });

  testWidgets('shift extends the selection the way it looks', (tester) async {
    final c = await editor(tester, 'مرحبا', 2);
    await press(tester, c, LogicalKeyboardKey.arrowLeft, shift: true);
    expect(c.selection, const TextSelection(baseOffset: 2, extentOffset: 3));
  });
}
