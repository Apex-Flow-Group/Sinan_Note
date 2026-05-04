// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// شكل الدمعة أسفل المؤشر
class TearPainter extends CustomPainter {
  const TearPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final r = w * 0.42;
    final cy = h - r;

    final path = Path()
      ..moveTo(cx, 0)
      ..cubicTo(cx + w * 0.04, h * 0.20, cx + r, cy - r * 0.55, cx + r, cy)
      ..arcToPoint(Offset(cx - r, cy),
          radius: Radius.circular(r), clockwise: true)
      ..cubicTo(cx - r, cy - r * 0.55, cx - w * 0.04, h * 0.20, cx, 0)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
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

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.45), 16, true);
    canvas.drawPath(path, Paint()..color = color);

    // حد سفلي داكن يعطي إحساس العمق
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(MagBgPainter old) =>
      old.tearX != tearX || old.color != color;
}
