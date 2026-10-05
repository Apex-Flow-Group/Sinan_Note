import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/ui/core/direction/text_direction.dart';

/// اتجاه كل سطر في المحرر يُحسب من نصه — حتى داخل تطبيق RTL.
void main() {
  Future<Map<String, TextDirection>> render(
      WidgetTester tester, Delta delta) async {
    final controller = QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: QuillEditor(
            controller: controller,
            focusNode: FocusNode(),
            scrollController: ScrollController(),
            config: const QuillEditorConfig(
              textDirectionResolver: strongDirectionOf,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final directions = <String, TextDirection>{};
    for (final element in find.byType(RichText).evaluate()) {
      final widget = element.widget as RichText;
      final text = widget.text.toPlainText().trim();
      if (text.isNotEmpty) {
        directions[text] = widget.textDirection ?? Directionality.of(element);
      }
    }
    return directions;
  }

  testWidgets('each line takes the direction of its own text', (tester) async {
    final directions = await render(
      tester,
      Delta()..insert('Hello\nمرحبا\n١٢٣\n123\nHello مرحبا\nمرحبا hello\n'),
    );
    expect(directions['Hello'], TextDirection.ltr);
    expect(directions['مرحبا'], TextDirection.rtl);
    expect(directions['١٢٣'], TextDirection.rtl);
    expect(directions['123'], TextDirection.ltr);
    expect(directions['Hello مرحبا'], TextDirection.ltr);
    expect(directions['مرحبا hello'], TextDirection.rtl);
  });

  testWidgets('a list takes the direction of its first item', (tester) async {
    final directions = await render(
      tester,
      Delta()
        ..insert('first item')
        ..insert('\n', {'list': 'bullet'})
        ..insert('بند ثانٍ')
        ..insert('\n', {'list': 'bullet'}),
    );
    expect(directions['first item'], TextDirection.ltr);
    expect(directions['بند ثانٍ'], TextDirection.ltr);
  });
}
