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
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // حركة هادئة جداً للنبض (3 ثواني)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // حركة من 0 إلى 1 لدمج الألوان بنعومة
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
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
    } else if (widget.baseColor != oldWidget.baseColor && mounted) {
      // Hot reload: حافظ على الأنيميشن بدون إعادة تشغيل
      if (widget.enableMotion && !_controller.isAnimating) {
        _controller.repeat(reverse: true);
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

    if (!widget.enableMotion) {
      // الحالة الثابتة (سريعة جداً بدون أنيميشن)
      return Container(
        decoration: BoxDecoration(
          color: widget.baseColor,
          borderRadius: borderRadius,
          border: Border.all(color: baseBorderColor, width: 0.8), // الحافة الرفيعة
        ),
        clipBehavior: Clip.hardEdge,
        child: widget.child,
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: widget.baseColor,
              borderRadius: borderRadius,
              // السحر هنا: دمج لون الحافة الأساسي مع لون مضيء بنسبة متغيرة
              border: Border.all(
                color: Color.lerp(baseBorderColor, glowColor, _glowAnimation.value * 0.4)!,
                width: 0.8, // نحافظ على السماكة الرفيعة والأنيقة
              ),
              boxShadow: [
                // ظل خفيف جداً يظهر ويختفي مع نبض الحافة
                BoxShadow(
                  color: glowColor.withValues(alpha: _glowAnimation.value * 0.15),
                  blurRadius: 6 * _glowAnimation.value,
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