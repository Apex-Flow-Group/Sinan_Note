// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/widgets/editor/toolbars/editor_options_menu.dart';
import 'package:flutter/material.dart';

enum ToolbarMode { main, format, style }

class SmartEditorToolbar extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final ToolbarMode mode;

  // Callbacks
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onReminderTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onShareTap;
  final VoidCallback onArchiveTap;
  final VoidCallback onCalculate;
  final VoidCallback? onPaste;
  final bool hasReminder;
  final bool hasContent;

  // Format Callbacks
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onList;
  final VoidCallback onH1;
  final VoidCallback onH2;
  final VoidCallback onChecklist;
  final bool showChecklist;

  // Style Callbacks
  final VoidCallback onColorTap;
  final VoidCallback? onBackgroundColorTap;

  const SmartEditorToolbar({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.onUndo,
    required this.onRedo,
    required this.onReminderTap,
    required this.onDeleteTap,
    required this.onShareTap,
    required this.onArchiveTap,
    required this.onCalculate,
    this.onPaste,
    required this.onBold,
    required this.onItalic,
    required this.onList,
    required this.onH1,
    required this.onH2,
    required this.onChecklist,
    this.showChecklist = true,
    required this.onColorTap,
    this.onBackgroundColorTap,
    this.mode = ToolbarMode.main,
    this.hasReminder = false,
    this.hasContent = false,
  });

  @override
  State<SmartEditorToolbar> createState() => _SmartEditorToolbarState();
}

class _SmartEditorToolbarState extends State<SmartEditorToolbar> {
  ToolbarMode _currentMode = ToolbarMode.main;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: _buildCurrentBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBar() {
    switch (_currentMode) {
      case ToolbarMode.main:
        return _buildMainBar();
      case ToolbarMode.format:
        return _buildFormatBar();
      case ToolbarMode.style:
        return _buildStyleBar();
    }
  }

  Widget _buildMainBar() {
    return Row(
      key: const ValueKey('main'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildIconBtn(Icons.calculate_outlined, widget.onCalculate),
                _buildIconBtn(Icons.content_paste_rounded, widget.onPaste),
                _buildIconBtn(Icons.text_fields_rounded,
                    () => setState(() => _currentMode = ToolbarMode.format)),
                _buildIconBtn(Icons.palette_outlined,
                    () => setState(() => _currentMode = ToolbarMode.style)),
                _buildIconBtn(Icons.undo_rounded, widget.onUndo,
                    isEnabled: true),
                _buildIconBtn(Icons.redo_rounded, widget.onRedo,
                    isEnabled: true),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showOptionsMenu(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.textColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.textColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(Icons.more_vert_rounded,
                  color: widget.textColor, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu() {
    EditorOptionsMenu.show(
      context: context,
      hasContent: widget.hasContent,
      showReminder: true,
    ).then((value) {
      if (value == 'reminder') {
        widget.onReminderTap();
      } else if (value == 'share') {
        widget.onShareTap();
      } else if (value == 'archive') {
        widget.onArchiveTap();
      } else if (value == 'delete') {
        widget.onDeleteTap();
      }
    });
  }

  Widget _buildFormatBar() {
    return Row(
      key: const ValueKey('format'),
      children: [
        _buildCloseBtn(),
        Container(height: 24, width: 1, color: widget.textColor.withValues(alpha: 0.2)),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildIconBtn(Icons.format_bold_rounded, widget.onBold),
                _buildIconBtn(Icons.format_italic_rounded, widget.onItalic),
                _buildIconBtn(Icons.title_rounded, widget.onH1),
                _buildIconBtn(Icons.format_size_rounded, widget.onH2),
                _buildIconBtn(Icons.format_list_bulleted_rounded, widget.onList),
                if (widget.showChecklist)
                  _buildIconBtn(Icons.checklist_rounded, widget.onChecklist),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyleBar() {
    return Row(
      key: const ValueKey('style'),
      children: [
        _buildCloseBtn(),
        Container(height: 24, width: 1, color: widget.textColor.withValues(alpha: 0.2)),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (widget.onBackgroundColorTap != null)
                  _buildIconBtn(Icons.color_lens, widget.onBackgroundColorTap),
                _buildIconBtn(Icons.format_color_text_rounded, widget.onColorTap),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseBtn() {
    return IconButton(
      icon: Icon(Icons.close_rounded, color: widget.textColor),
      onPressed: () => setState(() => _currentMode = ToolbarMode.main),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback? onTap,
      {Color? color, bool isEnabled = true}) {
    final effectiveColor =
        onTap == null ? Colors.grey : (color ?? widget.textColor);
    return IconButton(
      icon: Icon(icon, color: effectiveColor, size: 22),
      onPressed: onTap,
      splashRadius: 24,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
