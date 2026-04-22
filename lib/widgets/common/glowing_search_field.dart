// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:math';

import 'package:apex_note/core/theme/app_theme.dart';

import 'package:flutter/material.dart';

class GlowingSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final VoidCallback? onMenuTap;
  final VoidCallback? onViewToggle;
  final VoidCallback? onFilterTap;
  final ValueNotifier<String> viewTypeNotifier;
  final ValueNotifier<double>? scrollFadeNotifier;

  const GlowingSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    this.onMenuTap,
    this.onViewToggle,
    this.onFilterTap,
    required this.viewTypeNotifier,
    this.scrollFadeNotifier,
  });

  @override
  State<GlowingSearchField> createState() => _GlowingSearchFieldState();
}

class _GlowingSearchFieldState extends State<GlowingSearchField>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();

    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _focusNode.addListener(() {
      if (!mounted) return;
      setState(() {});
      if (_focusNode.hasFocus) {
        _waveController.repeat();
      } else {
        _waveController.stop();
        _waveController.animateTo(0,
            duration: const Duration(milliseconds: 500));
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // كل شيء داخل AnimatedBuilder لضمان قراءة الثيم الصحيح في كل frame
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, if (widget.scrollFadeNotifier != null) widget.scrollFadeNotifier!]),
      builder: (context, _) {
        final iconOpacity = widget.scrollFadeNotifier?.value ?? 1.0;
        final cs = Theme.of(context).colorScheme;
        final barColor = AppTheme.bg(cs);
        final contentColor = cs.onSurface;

        return Container(
          padding: EdgeInsets.all(_focusNode.hasFocus ? 1.5 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: _focusNode.hasFocus
                ? LinearGradient(
                    colors: [
                      barColor,
                      const Color(0xFF00D4FF).withValues(alpha: 0.5),
                      const Color(0xFF7B2FFF).withValues(alpha: 0.5),
                      barColor,
                    ],
                    stops: const [0.0, 0.4, 0.6, 1.0],
                    transform:
                        GradientRotation(_waveController.value * 2 * pi),
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(28.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Opacity(
                      opacity: iconOpacity,
                      child: Icon(Icons.search,
                          color: contentColor.withValues(alpha: 0.6), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(color: contentColor, fontSize: 14),
                        cursorColor: const Color(0xFF00D4FF),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                              color: contentColor.withValues(alpha: 0.5),
                              fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(bottom: 2),
                          isDense: true,
                        ),
                      ),
                    ),
                    if (widget.onViewToggle != null || widget.onFilterTap != null)
                      Opacity(
                        opacity: iconOpacity,
                        child: ClipRect(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            child: SizedBox(
                              width: _focusNode.hasFocus ? 0 : null,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.onViewToggle != null)
                                      ValueListenableBuilder<String>(
                                        valueListenable: widget.viewTypeNotifier,
                                        builder: (context, viewType, _) {
                                          return IconButton(
                                            icon: Icon(
                                              viewType == 'listExpanded'
                                                  ? Icons.view_headline
                                                  : viewType == 'listCompact'
                                                      ? Icons.grid_view
                                                      : Icons.view_day,
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
                        ),
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
