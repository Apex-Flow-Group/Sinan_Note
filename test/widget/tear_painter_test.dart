// Copyright © 2025 Apex Flow Group. All rights reserved.

// الدمعة بشكل أندرويد: رأس مدبّب في أعلى الوسط يلامس المؤشر، ودائرة
// كاملة تحته، والزوايا العلوية فارغة.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/ui/features/editor/widgets/tear/tear_painters.dart';

void main() {
  testWidgets('android handle shape', (tester) async {
    const scale = 4.0;
    final size = TearPainter.size * scale;
    late ByteData bytes;
    late int width;
    late int height;

    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(scale);
      const TearPainter(color: Color(0xFF8AB4F8))
          .paint(canvas, TearPainter.size);
      final image = await recorder
          .endRecording()
          .toImage(size.width.ceil(), size.height.ceil());
      width = image.width;
      height = image.height;
      bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });

    bool filled(double fx, double fy) {
      final x = (fx * (width - 1)).round();
      final y = (fy * (height - 1)).round();
      return bytes.getUint8((y * width + x) * 4 + 3) > 128;
    }

    // الرأس: أعلى الوسط، ولا شيء على جانبيه
    expect(filled(0.5, 0.04), isTrue, reason: 'tip');
    expect(filled(0.2, 0.04), isFalse);
    expect(filled(0.8, 0.04), isFalse);
    // الدائرة: مركزها وأسفلها وجانباها
    final cy = 1 - (TearPainter.diameter / 2) / TearPainter.size.height;
    expect(filled(0.5, cy), isTrue, reason: 'center');
    expect(filled(0.5, 0.98), isTrue, reason: 'bottom');
    expect(filled(0.03, cy), isTrue, reason: 'left');
    expect(filled(0.97, cy), isTrue, reason: 'right');
    // الزوايا السفلية خارج الدائرة
    expect(filled(0.03, 0.98), isFalse);
    expect(filled(0.97, 0.98), isFalse);
  });
}
