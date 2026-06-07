// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui' show lerpDouble;import 'package:flutter/material.dart';import 'package:provider/provider.dart'; import 'package:sinan_note/controllers/settings/settings_provider.dart';
class PremiumCardEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final bool enableMotion;
  final bool isSelected;
  final String? heroTag;

  const PremiumCardEffect({
    super.key,
    required this.child,
    required this.baseColor,
    this.enableMotion = false,
    this.isSelected = false,
    this.heroTag,
  });

  @override
  State<PremiumCardEffect> createState() => _PremiumCardEffectState();
}

class _PremiumCardEffectState extends State<PremiumCardEffect>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _glowAnimation;

  void _startMotion() {
    if (_controller != null) return;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOutSine),
    );
    _controller!.repeat(reverse: true);
  }

  void _stopMotion() {
    _controller?.dispose();
    _controller = null;
    _glowAnimation = null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.enableMotion) _startMotion();
  }

  @override
  void didUpdateWidget(PremiumCardEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableMotion != oldWidget.enableMotion) {
      widget.enableMotion ? _startMotion() : _stopMotion();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final borderRadius = BorderRadius.circular(16);

    // الحسبة الذكية للون الحافة الأساسي (أغمق أو أفتح حسب الوضع)
    final Color baseBorderColor = brightness == Brightness.light
        ? Color.lerp(widget.baseColor, Colors.black, 0.15)!
        : Color.lerp(widget.baseColor, Colors.white, 0.25)!;

    final Color effectiveBorderColor = widget.isSelected
        ? Theme.of(context).colorScheme.secondary
        : baseBorderColor;

    if (!widget.enableMotion) {
      final container = Container(
        decoration: BoxDecoration(
          color: widget.baseColor,
          borderRadius: borderRadius,
          border: widget.isSelected
              ? Border.all(color: effectiveBorderColor, width: 0.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: brightness == Brightness.light ? 0.10 : 0.28),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: widget.child,
      );
      if (widget.heroTag != null) {
        final heroEnabled =
            Provider.of<SettingsProvider>(context, listen: false)
                .heroAnimationEnabled;
        if (!heroEnabled) return container;
        return Hero(
          tag: widget.heroTag!,
          transitionOnUserGestures: false,
          createRectTween: (begin, end) =>
              MaterialRectArcTween(begin: begin, end: end),
          placeholderBuilder: (context, heroSize, child) => SizedBox(
            width: heroSize.width,
            height: heroSize.height,
          ),
          flightShuttleBuilder:
              (flightContext, animation, direction, fromCtx, toCtx) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return AnimatedBuilder(
              animation: curved,
              builder: (context, _) {
                final radius = BorderRadius.circular(
                  direction == HeroFlightDirection.push
                      ? lerpDouble(16, 0, curved.value)!
                      : lerpDouble(0, 16, curved.value)!,
                );
                return Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: radius,
                    child: container,
                  ),
                );
              },
            );
          },
          child: container,
        );
      }
      return container;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation!,
        builder: (context, child) {
          final br = Theme.of(context).brightness;
          return Container(
            decoration: BoxDecoration(
              color: widget.baseColor,
              borderRadius: borderRadius,
              border: widget.isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 0.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: br == Brightness.light ? 0.10 : 0.28),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: widget.child,
          );
        },
      ),
    );
  }
}

