// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';


class ApexMagnifier extends StatelessWidget {
  const ApexMagnifier({required this.dragPosition, super.key});

  final Offset dragPosition;

  static const _w = 120.0;
  static const _h = 50.0;
  static const _tearH = 12.0;
  static const _r = 14.0;
  static const _aboveOffset = _h + _tearH + 20.0;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    double left = dragPosition.dx - _w / 2;
    double top = dragPosition.dy - _aboveOffset;

    left = left.clamp(8.0, screen.width - _w - 8.0);
    top = top.clamp(padding.top + 8.0, screen.height - _h - _tearH - 8.0);

    // نقطة الدمعة تشير لموضع الإصبع الفعلي
    final tearX = (dragPosition.dx - left).clamp(_r, _w - _r);

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? scheme.surfaceContainerHigh : Colors.white;
    final shadowColor = Colors.black.withValues(alpha: 0.25);

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: _w,
        height: _h + _tearH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── الدمعة (خلف المكبر) ──────────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _TeardropShadowPainter(
                  width: _w,
                  height: _h,
                  tearH: _tearH,
                  tearX: tearX,
                  radius: _r,
                  color: bgColor,
                  shadowColor: shadowColor,
                ),
              ),
            ),
            // ── المكبر (فوق الدمعة، مقصوص بشكل مستطيل مدوّر) ──
            Positioned(
              top: 0,
              left: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_r),
                child: RawMagnifier(
                  clipBehavior: Clip.hardEdge,
                  decoration: const MagnifierDecoration(
                    shape: RoundedRectangleBorder(),
                  ),
                  size: const Size(_w, _h),
                  focalPointOffset: Offset(
                    dragPosition.dx - (left + _w / 2),
                    dragPosition.dy - (top + _h / 2),
                  ),
                  magnificationScale: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeardropShadowPainter extends CustomPainter {
  const _TeardropShadowPainter({
    required this.width,
    required this.height,
    required this.tearH,
    required this.tearX,
    required this.radius,
    required this.color,
    required this.shadowColor,
  });

  final double width, height, tearH, tearX, radius;
  final Color color, shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath();

    // ظل
    canvas.drawShadow(path, shadowColor, 6, false);

    // خلفية
    canvas.drawPath(path, Paint()..color = color);

    // حدود خفيفة
    canvas.drawPath(
      path,
      Paint()
        ..color = color.computeLuminance() > 0.5
            ? Colors.black.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  Path _buildPath() {
    final path = Path();
    // المستطيل المدوّر
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(radius),
    ));
    // الدمعة — مثلث صغير في الأسفل يشير لموضع الإصبع
    final tx = tearX;
    path.moveTo(tx - 8, height);
    path.lineTo(tx, height + tearH);
    path.lineTo(tx + 8, height);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_TeardropShadowPainter old) =>
      old.tearX != tearX || old.color != color;
}

Widget apexMagnifierBuilder(Offset dragPosition) =>
    ApexMagnifier(dragPosition: dragPosition);

