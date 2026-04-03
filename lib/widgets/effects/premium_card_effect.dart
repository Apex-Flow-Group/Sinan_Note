// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class PremiumCardEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final bool enableMotion;
  final bool isSelected;

  const PremiumCardEffect({
    super.key,
    required this.child,
    required this.baseColor,
    this.enableMotion = false,
    this.isSelected = false,
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

    // لون الإضاءة الذي سيندمج مع الحافة أثناء الحركة
    final Color glowColor = brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.5);

    final Color effectiveBorderColor = widget.isSelected
        ? Theme.of(context).colorScheme.secondary
        : baseBorderColor;

    if (!widget.enableMotion) {
      return Container(
        decoration: BoxDecoration(
          color: widget.baseColor,
          borderRadius: borderRadius,
          border: Border.all(color: effectiveBorderColor, width: widget.isSelected ? 2.0 : 0.8),
        ),
        clipBehavior: Clip.hardEdge,
        child: widget.child,
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation!,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: widget.baseColor,
              borderRadius: borderRadius,
              // السحر هنا: دمج لون الحافة الأساسي مع لون مضيء بنسبة متغيرة
              border: Border.all(
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Color.lerp(baseBorderColor, glowColor, _glowAnimation!.value * 0.4)!,
                width: widget.isSelected ? 2.0 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: _glowAnimation!.value * 0.15),
                  blurRadius: 6 * _glowAnimation!.value,
                  spreadRadius: 0,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: widget.child, // المحتوى بدون أي Padding يكسر التصميم
          );
        },
      ),
    );
  }
}
