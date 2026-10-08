// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sinan_note/ui/features/editor/widgets/tear/tear_painters.dart';

/// عدسة فوق سطر المؤشر: صورة حية للسطر نفسه (لا لمكان الإصبع) بذيل يشير
/// إلى المؤشر. تستعملها دمعة المؤشر ومقبضا التحديد.
class TearMagnifier extends StatelessWidget {
  const TearMagnifier({
    super.key,
    required this.line,
    required this.bgColor,
    this.area,
  });

  /// سطر المؤشر (عرض صفري عند المؤشر)، بإحداثيات الـ Stack الأب.
  final Rect line;

  /// حيث يجوز أن تقع العدسة، بالإحداثيات نفسها؛ بدونه: الشاشة دون أشرطة
  /// النظام (الأب يملأ الشاشة).
  final Rect? area;

  /// لون الملاحظة: إطار العدسة يطابق الصورة الحية.
  final Color bgColor;

  static const double kMw = 160.0;
  static const double kMh = 44.0;
  static const double kMTear = 8.0;

  /// المسافة بين ذيل العدسة وأعلى السطر.
  static const double kGap = 14.0;

  Rect _area(BuildContext context) {
    final given = area;
    if (given != null) return given;
    final screen = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding;
    return Rect.fromLTRB(8, pad.top + 4, screen.width - 8, screen.height - 8);
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _area(context);
    final x = line.center.dx;

    final left = (x - kMw / 2)
        .clamp(bounds.left, math.max(bounds.left, bounds.right - kMw))
        .toDouble();
    final top = (line.top - kMh - kMTear - kGap)
        .clamp(bounds.top, math.max(bounds.top, bounds.bottom - kMh - kMTear))
        .toDouble();

    final tearX = (x - left).clamp(12.0, kMw - 12.0);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: SizedBox(
          width: kMw,
          height: kMh + kMTear,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // الإطار + الذيل (نفس لون النوت ليتطابق مع الصورة الحية)
              Positioned.fill(
                child: CustomPaint(
                  painter: MagBgPainter(
                    w: kMw,
                    h: kMh,
                    tearH: kMTear,
                    tearX: tearX,
                    color: bgColor,
                  ),
                ),
              ),
              // الصورة الحية للسطر
              Positioned(
                top: 0,
                left: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: RawMagnifier(
                    clipBehavior: Clip.hardEdge,
                    decoration: const MagnifierDecoration(
                      shape: RoundedRectangleBorder(),
                      shadows: [],
                    ),
                    size: const Size(kMw, kMh),
                    focalPointOffset: Offset(
                      x - (left + kMw / 2),
                      line.center.dy - (top + kMh / 2),
                    ),
                    magnificationScale: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `QuillEditorConfig.quillMagnifierBuilder`: عدسة الدمعة لسحب التحديد، داخل
/// حدود المحرر.
Widget tearMagnifierBuilder(Rect line, Color bgColor) => Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          clipBehavior: Clip.none,
          children: [
            TearMagnifier(
              line: line,
              area: Offset.zero & constraints.biggest,
              bgColor: bgColor,
            ),
          ],
        ),
      ),
    );
