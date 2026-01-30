// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class SpringDragWidget extends StatefulWidget {
  final Widget child;
  final double resistance;

  const SpringDragWidget({
    super.key,
    required this.child,
    this.resistance = 3.5,
  });

  @override
  State<SpringDragWidget> createState() => _SpringDragWidgetState();
}

class _SpringDragWidgetState extends State<SpringDragWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _offsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      final distance = _offsetY.abs();
      final resistanceFactor = 1.0 / (1.0 + distance / 100);
      _offsetY += details.delta.dy * resistanceFactor / widget.resistance;
    });
  }

  void _runSpringBack(DragEndDetails details) {
    final startOffset = _offsetY;
    _controller.reset();

    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    animation.addListener(() {
      setState(() {
        _offsetY = startOffset * (1.0 - animation.value);
      });
    });

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragDown: (_) => _controller.stop(),
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _runSpringBack,
      onVerticalDragCancel: () => _runSpringBack(DragEndDetails()),
      child: Transform.translate(
        offset: Offset(0, _offsetY),
        child: widget.child,
      ),
    );
  }
}
