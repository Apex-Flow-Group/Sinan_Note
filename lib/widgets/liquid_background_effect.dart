// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class LiquidBackgroundEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final bool enabled;

  const LiquidBackgroundEffect({
    super.key,
    required this.child,
    required this.baseColor,
    this.enabled = true,
  });

  @override
  State<LiquidBackgroundEffect> createState() => _LiquidBackgroundEffectState();
}

class _LiquidBackgroundEffectState extends State<LiquidBackgroundEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Blob> _blobs = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    for (int i = 0; i < 6; i++) {
      _blobs.add(_Blob.create(i, 6));
    }
  }

  @override
  void didUpdateWidget(LiquidBackgroundEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.baseColor != oldWidget.baseColor) {
      setState(() {});
    }
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: widget.baseColor),
        if (widget.enabled)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CalmLiquidPainter(
                    progress: _controller.value,
                    blobs: _blobs,
                    baseColor: widget.baseColor,
                  ),
                );
              },
            ),
          ),
        if (widget.enabled)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        if (widget.enabled)
          Container(
              color: widget.baseColor.withValues(alpha: 0.3.clamp(0.0, 1.0))),
        widget.child,
      ],
    );
  }
}

class _Blob {
  final double orbitRadiusX;
  final double orbitRadiusY;
  final double size;
  final double speedMultiplier;
  final double thetaOffset;
  final int colorShift;

  _Blob({
    required this.orbitRadiusX,
    required this.orbitRadiusY,
    required this.size,
    required this.speedMultiplier,
    required this.thetaOffset,
    required this.colorShift,
  });

  factory _Blob.create(int index, int total) {
    final random = math.Random(index);

    double speed = (index % 2 == 0) ? 1.0 : -1.0;
    if (index % 3 == 0) speed *= 2.0;

    return _Blob(
      orbitRadiusX: 0.3 + random.nextDouble() * 0.3,
      orbitRadiusY: 0.3 + random.nextDouble() * 0.3,
      size: 0.4 + random.nextDouble() * 0.4,
      speedMultiplier: speed,
      thetaOffset: random.nextDouble() * 2 * math.pi,
      colorShift: index % 2 == 0 ? 20 : -20,
    );
  }
}

class _CalmLiquidPainter extends CustomPainter {
  final double progress;
  final List<_Blob> blobs;
  final Color baseColor;

  _CalmLiquidPainter({
    required this.progress,
    required this.blobs,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxDim = math.max(size.width, size.height);

    for (var blob in blobs) {
      final hsl = HSLColor.fromColor(baseColor);
      final blobColor = hsl
          .withHue((hsl.hue + blob.colorShift) % 360)
          .withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0))
          .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0))
          .toColor()
          .withValues(alpha: 0.6);

      final paint = Paint()..color = blobColor;

      final theta =
          blob.thetaOffset + (progress * 2 * math.pi * blob.speedMultiplier);

      final x = center.dx + math.cos(theta) * (size.width * blob.orbitRadiusX);
      final y = center.dy + math.sin(theta) * (size.height * blob.orbitRadiusY);

      canvas.drawCircle(Offset(x, y), maxDim * blob.size * 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
