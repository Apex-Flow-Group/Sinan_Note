// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/note_mode.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

// Global notifier for menu state
final ValueNotifier<bool> isMenuOpenNotifier = ValueNotifier<bool>(false);

class AddMenuWidget extends StatefulWidget {
  final bool showMenu;
  final VoidCallback onToggle;
  final Function(NoteMode) onModeSelected;

  const AddMenuWidget({
    super.key,
    required this.showMenu,
    required this.onToggle,
    required this.onModeSelected,
  });

  @override
  State<AddMenuWidget> createState() => _AddMenuWidgetState();
}

class _AddMenuWidgetState extends State<AddMenuWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed ||
          status == AnimationStatus.completed) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(AddMenuWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showMenu && !oldWidget.showMenu) {
      _controller.forward();
    } else if (!widget.showMenu && oldWidget.showMenu) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isVisible = widget.showMenu || _controller.isAnimating;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Background Blur - Excludes bottom navigation bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: GestureDetector(
              onTap: widget.onToggle,
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10.0 * _controller.value,
                        sigmaY: 10.0 * _controller.value,
                      ),
                      child: Container(
                        color: isVisible
                            ? (isDark
                                ? Colors.black.withValues(alpha: 0.2 * _controller.value)
                                : Colors.black.withValues(alpha: 0.05 * _controller.value))
                            : Colors.transparent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Menu items without SafeArea
        if (isVisible)
          Stack(children: _buildAnimatedMenuItems(context)),
        // FAB outside SafeArea - dynamic position
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: null,
              onPressed: widget.onToggle,
              backgroundColor: Colors.blue,
              elevation: 0,
              child: AnimatedRotation(
                turns: widget.showMenu ? 0.125 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.add, size: 32),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAnimatedMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      {
        'icon': Icons.checklist_rounded,
        'color': colorScheme.tertiary,
        'title': l10n.checklistMenu,
        'mode': NoteMode.checklist
      },
      {
        'icon': Icons.code_rounded,
        'color': colorScheme.secondary,
        'title': l10n.codeEditorMenu,
        'mode': NoteMode.code
      },
      {
        'icon': Icons.format_paint_rounded,
        'color': colorScheme.primary,
        'title': l10n.richNoteMenu,
        'mode': NoteMode.rich
      },
      {
        'icon': Icons.note_outlined,
        'color': colorScheme.outline,
        'title': l10n.simpleNoteMenu,
        'mode': NoteMode.simple
      },
    ];

    final double fabBottom = MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 16;
    const double fabSize = 56.0;
    const double itemSpacing = 8.0;
    final double baseBottom = fabBottom + fabSize + itemSpacing;

    return List.generate(items.length, (index) {
      final item = items[index];

      final double start = index * 0.2;
      final double end = (start + 0.6).clamp(0.0, 1.0);

      final Animation<double> itemAnimation = CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutBack),
        reverseCurve: Interval(start, end, curve: Curves.easeIn),
      );

      return Positioned(
        bottom: baseBottom + (index * 70),
        right: 16,
        child: _AnimatedMenuItem(
          icon: item['icon'] as IconData,
          color: item['color'] as Color,
          title: item['title'] as String,
          animation: itemAnimation,
          onTap: () {
            widget.onToggle();
            widget.onModeSelected(item['mode'] as NoteMode);
          },
        ),
      );
    });
  }
}

class _AnimatedMenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  final Animation<double> animation;

  const _AnimatedMenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      alignment: Alignment.bottomRight,
      child: FadeTransition(
        opacity: animation,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final double width = 56.0 + (144.0 * animation.value);

              return Container(
                width: width,
                height: 56,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon,
                            color: color,
                            size: 24),
                      ),
                    ),
                    if (animation.value > 0.3)
                      Positioned(
                        left: 60,
                        right: 12,
                        top: 0,
                        bottom: 0,
                        child: Opacity(
                          opacity:
                              ((animation.value - 0.5).clamp(0.0, 1.0) * 2.0)
                                  .clamp(0.0, 1.0),
                          child: Center(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
