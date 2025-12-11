// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class PremiumCardEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final bool enableMotion;

  const PremiumCardEffect({
    super.key,
    required this.child,
    required this.baseColor,
    this.enableMotion = false,
  });

  @override
  State<PremiumCardEffect> createState() => _PremiumCardEffectState();
}

class _PremiumCardEffectState extends State<PremiumCardEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.enableMotion && mounted) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PremiumCardEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableMotion != oldWidget.enableMotion) {
      if (widget.enableMotion && mounted) {
        _controller.repeat(reverse: true);
      } else if (mounted) {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    if (!widget.enableMotion) {
      return Container(
        decoration: BoxDecoration(
          color: widget.baseColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      );
    }

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Layer 1: Animated Gradient Border (Bottom)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white
                              .withValues(alpha: _opacityAnimation.value),
                          Colors.transparent,
                          Colors.white
                              .withValues(alpha: _opacityAnimation.value * 0.5),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Layer 2: Content Container (Top)
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.baseColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
