// Copyright © 2025 Apex Flow Group. All rights reserved.

// التشكيل في المحرر نفسه، بإعداد الملاحظات الحقيقي:
// - الحذف من الطريقين (لوحة مفاتيح الهاتف ومفتاح الحذف): الحركة قبل حرفها،
//   ولا تبقى حركة بلا حرفها.
// - الكتابة: المؤشر لا يقف بين حرف وحركته، فالحرف الجديد لا يأخذ الحركة.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/ui/core/input/arabic_marks_editing.dart';

const _fatha = '\u064E';
const _shadda = '\u0651';

void main() {
  Future<QuillController> editor(
      WidgetTester tester, String text, int caret) async {
    final controller = QuillController(
      document: Document.fromDelta(Delta()..insert('$text\n')),
      selection: TextSelection.collapsed(offset: caret),
      config: noteControllerConfig,
    );
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      home: Scaffold(
        body: QuillEditor(
          controller: controller,
          focusNode: focus,
          scrollController: ScrollController(),
          config: const QuillEditorConfig(
            backspaceResolver: backspaceResolver,
          ),
        ),
      ),
    ));
    focus.requestFocus();
    await tester.pumpAndSettle();
    return controller;
  }

  /// ما ترسله لوحة الهاتف بعد الحذف: النص الجديد وموضع المؤشر.
  Future<void> keyboardSends(
      WidgetTester tester, String text, int caret) async {
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: '$text\n',
      selection: TextSelection.collapsed(offset: caret),
    ));
    await tester.pump();
  }

  String text(QuillController c) =>
      c.document.toPlainText().replaceAll('\n', '');

  group('phone keyboard', () {
    testWidgets('a keyboard that deletes the whole letter: only the mark goes',
        (tester) async {
      final c = await editor(tester, 'كب$_fatha', 3);
      await keyboardSends(tester, 'ك', 1);
      expect(text(c), 'كب');
      expect(c.selection.baseOffset, 2);
    });

    testWidgets('a keyboard that deletes the mark: kept as is', (tester) async {
      final c = await editor(tester, 'كب$_fatha', 3);
      await keyboardSends(tester, 'كب', 2);
      expect(text(c), 'كب');
    });

    testWidgets('caret between the letter and its mark: the letter stays',
        (tester) async {
      final c = await editor(tester, 'كب$_fatha', 2);
      await keyboardSends(tester, 'ك$_fatha', 1);
      expect(text(c), 'كب');
    });

    testWidgets('shadda and fatha go one at a time', (tester) async {
      final c = await editor(tester, 'كب$_shadda$_fatha', 4);
      await keyboardSends(tester, 'ك', 1);
      expect(text(c), 'كب$_shadda');
      await keyboardSends(tester, 'ك', 1);
      expect(text(c), 'كب');
      await keyboardSends(tester, 'ك', 1);
      expect(text(c), 'ك');
    });

    testWidgets('deleting a whole word is left to the keyboard',
        (tester) async {
      final c = await editor(tester, 'كتب كب$_fatha', 7);
      await keyboardSends(tester, 'كتب ', 4);
      expect(text(c), 'كتب ');
    });

    testWidgets('typing is untouched', (tester) async {
      final c = await editor(tester, 'كب', 2);
      await keyboardSends(tester, 'كب$_fatha', 3);
      expect(text(c), 'كب$_fatha');
    });
  });

  group('backspace key', () {
    testWidgets('marks first, then the letter', (tester) async {
      final c = await editor(tester, 'كب$_shadda$_fatha', 4);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(text(c), 'كب$_shadda');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(text(c), 'كب');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(text(c), 'ك');
    });

    testWidgets('an emoji is deleted whole', (tester) async {
      final c = await editor(tester, 'ك😀', 3);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(text(c), 'ك');
    });
  });

  group('typing', () {
    // كَتب: الكاف ثم فتحتها
    const word = 'ك$_fatha' 'تب';

    testWidgets('a caret placed between a letter and its mark moves past it',
        (tester) async {
      final c = await editor(tester, word, 0);
      c.updateSelection(
          const TextSelection.collapsed(offset: 1), ChangeSource.local);
      await tester.pump();
      expect(c.selection.baseOffset, 2);
      // ولوحة المفاتيح تعرف الموضع الجديد
      expect(tester.testTextInput.editingState?['selectionBase'], 2);
    });

    testWidgets('a letter typed there keeps the mark on the previous letter',
        (tester) async {
      final c = await editor(tester, word, 0);
      c.updateSelection(
          const TextSelection.collapsed(offset: 1), ChangeSource.local);
      await tester.pump();
      // لوحة المفاتيح تكتب حيث تعرف أن المؤشر
      final state = tester.testTextInput.editingState!;
      final known = (state['text'] as String).replaceAll('\n', '');
      final at = state['selectionBase'] as int;
      await keyboardSends(tester, known.replaceRange(at, at, 'ل'), at + 1);
      expect(text(c), 'ك$_fatha' 'لتب');
    });

    testWidgets('marks can still be added after a letter', (tester) async {
      final c = await editor(tester, 'كب', 2);
      await keyboardSends(tester, 'كب$_shadda', 3);
      await keyboardSends(tester, 'كب$_shadda$_fatha', 4);
      expect(text(c), 'كب$_shadda$_fatha');
      expect(c.selection.baseOffset, 4);
    });
  });
}
