// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/widgets/editor/tear/tear_painters.dart';
import 'package:flutter/material.dart';

class TearMagnifier extends StatelessWidget {
  const TearMagnifier({
    super.key,
    required this.pos,
    required this.lineTop,
    required this.lineBottom,
    required this.bgColor,
  });

  final Offset pos;
  final double lineTop;
  final double lineBottom;
  final Color bgColor;

  static const double kMw = 160.0;
  static const double kMh = 44.0;
  static const double kMTear = 8.0;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding;
    final lineMid = (lineTop + lineBottom) / 2;

    double left = pos.dx - kMw / 2;
    double top = lineTop - kMh - kMTear - 14;
    left = left.clamp(8.0, screen.width - kMw - 8.0);
    top = top.clamp(pad.top + 4.0, screen.height - kMh - kMTear - 8.0);

    final tearX = (pos.dx - left).clamp(12.0, kMw - 12.0);

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
              // الصورة الحية للنص
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
                      pos.dx - (left + kMw / 2),
                      lineMid - (top + kMh / 2),
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
