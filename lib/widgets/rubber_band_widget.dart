// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class RubberBandWidget extends StatefulWidget {
  final Widget child;
  final double resistance;
  final double limit;

  const RubberBandWidget({
    super.key,
    required this.child,
    this.resistance = 0.5,
    this.limit = 100.0,
  });

  @override
  State<RubberBandWidget> createState() => _RubberBandWidgetState();
}

class _RubberBandWidgetState extends State<RubberBandWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
    _controller.addListener(() {
      setState(() {
        _dragOffset = _controller.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSpringAnimation(double start, double end, double velocity) {
    const spring = SpringDescription(
      mass: 1.0,
      stiffness: 100.0,
      damping: 10.0,
    );

    final simulation = SpringSimulation(spring, start, end, velocity);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        double delta = details.primaryDelta!;
        double progress = (_dragOffset.abs() / widget.limit).clamp(0.0, 1.0);
        double resistanceFactor = (1.0 - progress) * widget.resistance;

        setState(() {
          _dragOffset += delta * resistanceFactor;
        });
      },
      onHorizontalDragEnd: (details) {
        _runSpringAnimation(_dragOffset, 0.0, details.primaryVelocity ?? 0.0);
      },
      child: Transform.translate(
        offset: Offset(_dragOffset, 0),
        child: widget.child,
      ),
    );
  }
}
