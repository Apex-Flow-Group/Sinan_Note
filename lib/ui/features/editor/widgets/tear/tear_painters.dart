// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sinan_note/ui/core/theme/editor_palette.dart';

/// الدمعة أسفل المؤشر بشكل أندرويد (Material): دائرة يخرج من أعلاها رأس
/// مدبّب يلامس أسفل المؤشر — ربع مربع على الدائرة مُدار 45°.
class TearPainter extends CustomPainter {
  const TearPainter({required this.color});
  final Color color;

  /// قطر الدائرة كما في مقبض أندرويد.
  static const diameter = 22.0;

  /// من الرأس إلى أسفل الدائرة: نصف القطر + نصف القطر × √2.
  static const size = Size(diameter, diameter / 2 * (1 + math.sqrt2));

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: r))
      ..addRect(Rect.fromLTWH(-r, -r, r, r));
    canvas
      ..save()
      ..translate(r, size.height - r)
      // زاوية المربع (−r, −r) تصير إلى الأعلى مباشرة
      ..rotate(math.pi / 4)
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..isAntiAlias = true,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(TearPainter old) => old.color != color;
}

/// خلفية المكبر مع الذيل
class MagBgPainter extends CustomPainter {
  const MagBgPainter({
    required this.w,
    required this.h,
    required this.tearH,
    required this.tearX,
    required this.color,
  });

  final double w, h, tearH, tearX;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(10),
      ))
      ..moveTo(tearX - 7, h)
      ..lineTo(tearX, h + tearH)
      ..lineTo(tearX + 7, h)
      ..close();

    canvas.drawShadow(
        path, EditorPalette.tintOnLight.withValues(alpha: 0.45), 16, true);
    canvas.drawPath(path, Paint()..color = color);

    // حد سفلي داكن يعطي إحساس العمق
    final borderPaint = Paint()
      ..color = EditorPalette.tintOnLight.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(MagBgPainter old) =>
      old.tearX != tearX || old.color != color;
}
