// Copyright © 2025 Apex Flow Group. All rights reserved.

// سحب مقبضي التحديد يتبع الإصبع: أفقياً يبقى على سطره ويتحرك في اتجاه
// الإصبع بلا قفزات (يميناً في سطر عربي يرجع في النص)، وعمودياً ينتقل سطراً
// بسطر. الإصبع على المقبض تحت السطر، لا على السطر التالي.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/ui/core/direction/text_direction.dart';

const _arabic = [
  'السطر الأول فيه كلمات كثيرة للتحديد',
  'السطر الثاني فيه كلمات أخرى هنا',
  'السطر الثالث والأخير في الملاحظة',
];
const _english = [
  'the first line has many words to select',
  'the second line has other words here',
  'the third and last line of the note',
];

void main() {
  late List<String> lines;

  /// ما تلقّاه منشئ العدسة أثناء السحب (سطر المؤشر بإحداثيات المحرر).
  late List<Rect> magnified;

  int lineOf(int offset) {
    var end = 0;
    for (var i = 0; i < lines.length; i++) {
      end += lines[i].length + 1;
      if (offset < end) return i;
    }
    return lines.length;
  }

  /// يحدد كلمة في منتصف السطر الأول بضغطة طويلة (كما في أندرويد).
  Future<QuillController> select(WidgetTester tester, List<String> text) async {
    lines = text;
    magnified = [];
    final controller = QuillController(
      document: Document.fromDelta(Delta()..insert('${text.join('\n')}\n')),
      selection: const TextSelection.collapsed(offset: 0),
    );
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: QuillEditor(
              controller: controller,
              focusNode: focus,
              scrollController: ScrollController(),
              config: QuillEditorConfig(
                textDirectionResolver: strongDirectionOf,
                quillMagnifierBuilder: (line) {
                  magnified.add(line);
                  return const SizedBox.shrink(key: ValueKey('magnifier'));
                },
              ),
            ),
          ),
        ),
      ),
    ));
    focus.requestFocus();
    await tester.pumpAndSettle();

    final editor = tester.getRect(find.byType(QuillEditor));
    await tester.longPressAt(Offset(editor.center.dx, editor.top + 10));
    await tester.pumpAndSettle();
    expect(controller.selection.isCollapsed, isFalse);
    expect(lineOf(controller.selection.start), 0);
    return controller;
  }

  /// المقبضان: الأول للبداية، والثاني للنهاية.
  Finder handle({required bool end}) {
    final all = find.descendant(
      of: find.byType(CompositedTransformFollower),
      matching: find.byType(GestureDetector),
    );
    return end ? all.last : all.first;
  }

  /// يسحب المقبض خطوات أفقية ويُرجع موضع طرفه بعد كل خطوة (بعد عتبة السحب).
  Future<List<int>> dragSideways(WidgetTester tester, QuillController c,
      {required bool end, required double step, int steps = 5}) async {
    final gesture =
        await tester.startGesture(tester.getCenter(handle(end: end)));
    // عتبة السحب: حركة صغيرة لا تُحسب
    await gesture.moveBy(Offset(step.sign * 20, 0));
    await tester.pump();
    final offsets = <int>[];
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(step, 0));
      await tester.pump();
      final at = end ? c.selection.end : c.selection.start;
      expect(lineOf(at), 0, reason: 'sideways never leaves the line');
      offsets.add(at);
    }
    await gesture.up();
    await tester.pumpAndSettle();
    return offsets;
  }

  void expectMonotonic(List<int> offsets, {required bool increasing}) {
    for (var i = 1; i < offsets.length; i++) {
      increasing
          ? expect(offsets[i], greaterThanOrEqualTo(offsets[i - 1]),
              reason: 'no jump back: $offsets')
          : expect(offsets[i], lessThanOrEqualTo(offsets[i - 1]),
              reason: 'no jump back: $offsets');
    }
    expect(offsets.first, isNot(offsets.last), reason: 'it moved: $offsets');
  }

  Future<void> android(Future<void> Function() body) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  group('arabic line', () {
    testWidgets('end handle: left extends, right shrinks', (tester) async {
      await android(() async {
        final c = await select(tester, _arabic);
        expectMonotonic(await dragSideways(tester, c, end: true, step: -10),
            increasing: true);
        expectMonotonic(
            await dragSideways(tester, c, end: true, step: 10, steps: 3),
            increasing: false);
      });
    });

    testWidgets('start handle: right extends back in the text', (tester) async {
      await android(() async {
        final c = await select(tester, _arabic);
        expectMonotonic(await dragSideways(tester, c, end: false, step: 10),
            increasing: false);
      });
    });
  });

  group('english line', () {
    testWidgets('end handle: right extends, left shrinks', (tester) async {
      await android(() async {
        final c = await select(tester, _english);
        expectMonotonic(await dragSideways(tester, c, end: true, step: 10),
            increasing: true);
        expectMonotonic(
            await dragSideways(tester, c, end: true, step: -10, steps: 3),
            increasing: false);
      });
    });
  });

  testWidgets('dragging the end handle down moves line by line',
      (tester) async {
    await android(() async {
      final c = await select(tester, _arabic);
      final gesture =
          await tester.startGesture(tester.getCenter(handle(end: true)));
      await gesture.moveBy(const Offset(0, 20)); // عتبة السحب
      await tester.pump();
      final visited = <int>[lineOf(c.selection.end)];
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(0, 4));
        await tester.pump();
        visited.add(lineOf(c.selection.end));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(visited.first, 0, reason: 'starts on its line: $visited');
      for (var i = 1; i < visited.length; i++) {
        expect(visited[i] - visited[i - 1], inInclusiveRange(0, 1),
            reason: 'one line at a time, never back: $visited');
      }
      expect(visited, contains(1), reason: 'reaches the next line: $visited');
    });
  });

  group('feedback while dragging a handle', () {
    testWidgets('a strong tick on grab, then one light tick per new position',
        (tester) async {
      await android(() async {
        final c = await select(tester, _arabic);
        final ticks = <String>[];
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            ticks.add(call.arguments as String);
          }
          return null;
        });
        addTearDown(() => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null));

        final positions = <int>{c.selection.end};
        final gesture =
            await tester.startGesture(tester.getCenter(handle(end: true)));
        for (var i = 0; i < 8; i++) {
          await gesture.moveBy(const Offset(-10, 0));
          await tester.pump();
          positions.add(c.selection.end);
        }
        await gesture.up();
        await tester.pumpAndSettle();

        expect(ticks.first, 'HapticFeedbackType.mediumImpact');
        final clicks =
            ticks.where((t) => t == 'HapticFeedbackType.selectionClick');
        expect(clicks.length, positions.length - 1,
            reason: 'one tick per new position: $positions, $ticks');
        expect(clicks, isNotEmpty);
      });
    });

    testWidgets('the magnifier shows the edge\'s text line, not the finger',
        (tester) async {
      await android(() async {
        await select(tester, _arabic);
        magnified.clear();
        final grab = tester.getCenter(handle(end: true));
        final gesture = await tester.startGesture(grab);
        for (var i = 0; i < 4; i++) {
          await gesture.moveBy(const Offset(-10, 0));
          await tester.pump();
        }
        await tester.pump(); // العدسة تتحدث بعد الإطار
        expect(find.byKey(const ValueKey('magnifier')), findsOneWidget);
        final line = magnified.last;
        expect(line.height, greaterThan(10),
            reason: 'a text line, not the finger\'s point: $line');
        // الإصبع على المقبض تحت السطر؛ العدسة على السطر الأول نفسه
        final editorTop = tester.getRect(find.byType(QuillEditor)).top;
        expect(line.center.dy, lessThan(line.height),
            reason: 'first line of the editor: $line');
        expect(grab.dy - editorTop, greaterThan(line.bottom),
            reason: 'the finger is below the line it magnifies');

        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('magnifier')), findsNothing);
      });
    });
  });
}
