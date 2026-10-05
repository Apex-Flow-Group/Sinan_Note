// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/theme/app_theme.dart';
import 'package:sinan_note/ui/core/theme/common_palette.dart';

class GlowingSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final VoidCallback? onMenuTap;
  final VoidCallback? onViewToggle;
  final VoidCallback? onFilterTap;
  final ValueNotifier<String> viewTypeNotifier;

  const GlowingSearchField({
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

    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
    if (_focusNode.hasFocus) {
      _waveController.repeat();
    } else {
      _waveController.stop();
      _waveController.animateTo(0, duration: const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    // FocusNode الممرَّر من الأب يعيش بعدنا: يُزال مستمعنا منه
    _focusNode.removeListener(_onFocusChanged);
    _waveController.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final barColor = AppTheme.scaffoldBackground(cs);
    final contentColor = cs.onSurface;
    final shadow = context.colors.shadow.withValues(alpha: 0.05);

    // الحركة تدير إطار التوهج وحده؛ الحقل يُبنى مرة ويُمرَّر child
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _waveController,
        child: _field(context, barColor, contentColor),
        builder: (context, field) => Container(
          padding: EdgeInsets.all(_focusNode.hasFocus ? 1.5 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: _focusNode.hasFocus
                ? LinearGradient(
                    colors: [
                      barColor,
                      CommonPalette.searchGlowStart.withValues(alpha: 0.5),
                      CommonPalette.searchGlowEnd.withValues(alpha: 0.5),
                      barColor,
                    ],
                    stops: const [0.0, 0.4, 0.6, 1.0],
                    transform: GradientRotation(_waveController.value * 2 * pi),
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: field,
        ),
      ),
    );
  }

  Widget _field(BuildContext context, Color barColor, Color contentColor) {
    return Container(
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
              Icon(Icons.search,
                  color: contentColor.withValues(alpha: 0.6), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  textAlignVertical: TextAlignVertical.center,
                  style: context.text.bodyMedium?.copyWith(color: contentColor),
                  cursorColor: CommonPalette.searchGlowStart,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: context.text.bodyMedium
                        ?.copyWith(color: contentColor.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(bottom: 2),
                    isDense: true,
                  ),
                ),
              ),
              if (widget.onViewToggle != null || widget.onFilterTap != null)
                ClipRect(
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
                                      viewType == 'listCompact'
                                          ? Icons.view_day
                                          : viewType == 'listExpanded'
                                              ? Icons.grid_view
                                              : Icons.view_headline,
                                      color:
                                          contentColor.withValues(alpha: 0.7),
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
            ],
          ),
        ),
      ),
    );
  }
}
