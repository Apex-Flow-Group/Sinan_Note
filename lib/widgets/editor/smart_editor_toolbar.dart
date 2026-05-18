// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/widgets/editor/toolbars/editor_options_menu.dart';

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
  final VoidCallback onUnderline;
  final VoidCallback onStrikethrough;
  final VoidCallback onList;
  final VoidCallback onOrderedList;
  final VoidCallback onBlockquote;
  final VoidCallback onH1;
  final VoidCallback onH2;
  final VoidCallback onChecklist;
  final bool showChecklist;

  // Format Active States
  final bool isBoldActive;
  final bool isItalicActive;
  final bool isUnderlineActive;
  final bool isStrikethroughActive;
  final bool isH1Active;
  final bool isH2Active;
  final bool isListActive;
  final bool isOrderedListActive;
  final bool isBlockquoteActive;
  final bool isChecklistActive;

  // Style Callbacks
  final VoidCallback onColorTap;
  final VoidCallback? onBackgroundColorTap;

  // Convert Callbacks (rich → simple + code + checklist)
  final VoidCallback? onConvertToSimple;
  final VoidCallback? onConvertToCode;
  final VoidCallback? onConvertToChecklist;

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
    required this.onUnderline,
    required this.onStrikethrough,
    required this.onList,
    required this.onOrderedList,
    required this.onBlockquote,
    required this.onH1,
    required this.onH2,
    required this.onChecklist,
    this.showChecklist = true,
    required this.onColorTap,
    this.onBackgroundColorTap,
    this.mode = ToolbarMode.main,
    this.hasReminder = false,
    this.hasContent = false,
    this.isBoldActive = false,
    this.isItalicActive = false,
    this.isUnderlineActive = false,
    this.isStrikethroughActive = false,
    this.isH1Active = false,
    this.isH2Active = false,
    this.isListActive = false,
    this.isOrderedListActive = false,
    this.isBlockquoteActive = false,
    this.isChecklistActive = false,
    this.onConvertToSimple,
    this.onConvertToCode,
    this.onConvertToChecklist,
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
              padding: const EdgeInsets.all(8),
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
      showConvertToSimple: widget.onConvertToSimple != null,
      showConvertToCode: widget.onConvertToCode != null,
      showConvertToChecklist: widget.onConvertToChecklist != null,
    ).then((value) {
      if (value == 'reminder') {
        widget.onReminderTap();
      } else if (value == 'share') {
        widget.onShareTap();
      } else if (value == 'archive') {
        widget.onArchiveTap();
      } else if (value == 'delete') {
        widget.onDeleteTap();
      } else if (value == 'convertToSimple') {
        widget.onConvertToSimple?.call();
      } else if (value == 'convertToCode') {
        widget.onConvertToCode?.call();
      } else if (value == 'convertToChecklist') {
        widget.onConvertToChecklist?.call();
      }
    });
  }

  Widget _buildFormatBar() {
    return Row(
      key: const ValueKey('format'),
      children: [
        _buildCloseBtn(),
        Container(
            height: 24,
            width: 1,
            color: widget.textColor.withValues(alpha: 0.2)),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildIconBtn(Icons.format_bold_rounded, widget.onBold,
                    isActive: widget.isBoldActive),
                _buildIconBtn(Icons.format_italic_rounded, widget.onItalic,
                    isActive: widget.isItalicActive),
                _buildIconBtn(Icons.format_underlined_rounded, widget.onUnderline,
                    isActive: widget.isUnderlineActive),
                _buildIconBtn(Icons.strikethrough_s_rounded, widget.onStrikethrough,
                    isActive: widget.isStrikethroughActive),
                _buildIconBtn(Icons.title_rounded, widget.onH1,
                    isActive: widget.isH1Active),
                _buildIconBtn(Icons.format_size_rounded, widget.onH2,
                    isActive: widget.isH2Active),
                _buildIconBtn(Icons.format_list_bulleted_rounded, widget.onList,
                    isActive: widget.isListActive),
                _buildIconBtn(Icons.format_list_numbered_rounded, widget.onOrderedList,
                    isActive: widget.isOrderedListActive),
                _buildIconBtn(Icons.format_quote_rounded, widget.onBlockquote,
                    isActive: widget.isBlockquoteActive),
                if (widget.showChecklist)
                  _buildIconBtn(Icons.checklist_rounded, widget.onChecklist,
                      isActive: widget.isChecklistActive),
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
        Container(
            height: 24,
            width: 1,
            color: widget.textColor.withValues(alpha: 0.2)),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (widget.onBackgroundColorTap != null)
                  _buildIconBtn(Icons.color_lens, widget.onBackgroundColorTap),
                _buildIconBtn(
                    Icons.format_color_text_rounded, widget.onColorTap),
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
      {Color? color, bool isEnabled = true, bool isActive = false}) {
    final effectiveColor =
        onTap == null ? Colors.grey : (color ?? widget.textColor);
    final activeColor = widget.textColor;

    return IconButton(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 28,
        height: 28,
        decoration: isActive
            ? BoxDecoration(
                color: activeColor.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
              )
            : const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
        child: Icon(icon, color: effectiveColor, size: 22),
      ),
      onPressed: onTap,
      splashRadius: 24,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

