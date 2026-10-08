// Copyright © 2025 Apex Flow Group. All rights reserved.

// عدسة الدمعة: فوق السطر الذي تكبّره ومتمركزة على المؤشر، وتبقى داخل
// المنطقة المسموحة قرب الحواف.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/ui/features/editor/widgets/tear/tear_magnifier.dart';

void main() {
  const area = Rect.fromLTWH(0, 0, 400, 300);

  Future<Rect> place(WidgetTester tester, Rect line) async {
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: area.width,
          height: area.height,
          child: Stack(children: [
            TearMagnifier(line: line, area: area, bgColor: Colors.white),
          ]),
        ),
      ),
    ));
    final stack = tester.getTopLeft(find.byType(Stack).first);
    return tester.getRect(find.byType(RawMagnifier)).shift(-stack);
  }

  testWidgets('above the line, centred on the caret', (tester) async {
    const line = Rect.fromLTRB(200, 100, 200, 120);
    final lens = await place(tester, line);
    expect(lens.center.dx, closeTo(200, 0.5));
    expect(lens.bottom + TearMagnifier.kMTear, lessThanOrEqualTo(line.top),
        reason: 'the lens and its tail sit above the line: $lens');
  });

  testWidgets('stays inside the area near its edges', (tester) async {
    for (final line in const [
      Rect.fromLTRB(5, 10, 5, 30), // أعلى اليسار
      Rect.fromLTRB(395, 10, 395, 30), // أعلى اليمين
    ]) {
      final lens = await place(tester, line);
      expect(lens.left, greaterThanOrEqualTo(area.left), reason: '$line');
      expect(lens.right, lessThanOrEqualTo(area.right), reason: '$line');
      expect(lens.top, greaterThanOrEqualTo(area.top), reason: '$line');
    }
  });
}
