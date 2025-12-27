// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'dart:math';

enum AnimationType { pulse, wave, glow, shimmer, breathe }

class BreathingSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final VoidCallback? onMenuTap;
  final VoidCallback? onViewToggle;
  final VoidCallback? onFilterTap;
  final ValueNotifier<String> viewTypeNotifier;

  const BreathingSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    this.onMenuTap,
    this.onViewToggle,
    this.onFilterTap,
    required this.viewTypeNotifier,
  });

  @override
  State<BreathingSearchField> createState() => _BreathingSearchFieldState();
}

class _BreathingSearchFieldState extends State<BreathingSearchField>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _focusController;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late AnimationType _animationType;
  bool _hasTriggered = false;
  late FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _animationType =
        AnimationType.values[Random().nextInt(AnimationType.values.length)];

    final duration = _getRandomDuration();
    _controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    _focusController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.white.withValues(alpha: 0.1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: _getRandomCurve(),
    ));

    (widget.focusNode ?? _focusNode).addListener(() {
      if (!mounted) return;
      if ((widget.focusNode ?? _focusNode).hasFocus) {
        if (mounted) _focusController.forward();
      } else {
        if (mounted) _focusController.reverse();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: Random().nextInt(3) + 1), () {
        if (mounted && !_hasTriggered) {
          _triggerAnimation();
        }
      });
    });
  }

  Duration _getRandomDuration() {
    switch (_animationType) {
      case AnimationType.pulse:
        return const Duration(milliseconds: 800);
      case AnimationType.wave:
        return const Duration(milliseconds: 2000);
      case AnimationType.glow:
        return const Duration(milliseconds: 1200);
      case AnimationType.shimmer:
        return const Duration(milliseconds: 1500);
      case AnimationType.breathe:
        return const Duration(milliseconds: 2500);
    }
  }

  Curve _getRandomCurve() {
    final curves = [
      Curves.easeInOut,
      Curves.easeInOutCubic,
      Curves.easeInOutSine,
      Curves.elasticInOut,
      Curves.bounceInOut,
    ];
    return curves[Random().nextInt(curves.length)];
  }

  void _triggerAnimation() async {
    if (!mounted) return;
    _hasTriggered = true;

    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      await _controller.forward();
      if (!mounted) return;
      await _controller.reverse();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (mounted) {
      _controller.stop();
      _controller.value = 0;
    }
  }



  @override
  void dispose() {
    _controller.dispose();
    _focusController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final Color searchBarColor = brightness == Brightness.light
        ? colorScheme.surfaceContainer
        : colorScheme.surfaceBright;
    final Color contentColor = colorScheme.onSurface;
    final Color primaryColor = colorScheme.primary;

    return AnimatedBuilder(
      animation:
          Listenable.merge([_colorAnimation, _scaleAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: searchBarColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                if (_controller.value > 0)
                  BoxShadow(
                    color: primaryColor.withValues(
                        alpha: (0.3 * _controller.value).clamp(0.0, 1.0)),
                    blurRadius: 30 * _controller.value,
                    spreadRadius: 2 * _controller.value,
                  ),
                if (_glowAnimation.value > 0)
                  BoxShadow(
                    color: primaryColor.withValues(
                        alpha: (0.15 * _glowAnimation.value).clamp(0.0, 1.0)),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: -2,
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        color: contentColor.withValues(alpha: 0.6),
                        size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode ?? _focusNode,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(color: contentColor, fontSize: 14),
                        cursorColor: contentColor,
                        enableInteractiveSelection: true,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                              color: contentColor.withValues(alpha: 0.5),
                              fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (widget.onViewToggle != null)
                      ValueListenableBuilder<String>(
                        valueListenable: widget.viewTypeNotifier,
                        builder: (context, viewType, child) {
                          return IconButton(
                            icon: Icon(
                              viewType == 'listExpanded'
                                  ? Icons.view_compact
                                  : viewType == 'listCompact'
                                      ? Icons.grid_view
                                      : Icons.view_agenda,
                              color: contentColor.withValues(alpha: 0.7),
                            ),
                            onPressed: widget.onViewToggle,
                            splashRadius: 24,
                          );
                        },
                      ),
                    if (widget.onFilterTap != null)
                      IconButton(
                        icon: Icon(Icons.filter_list_rounded,
                            color: contentColor.withValues(alpha: 0.7)),
                        onPressed: widget.onFilterTap,
                        splashRadius: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
