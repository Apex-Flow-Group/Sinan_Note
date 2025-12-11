// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

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
  final bool hasReminder;
  final bool hasContent;

  // Format Callbacks
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onList;
  final VoidCallback onH1;
  final VoidCallback onH2;
  final VoidCallback onChecklist;

  // Style Callbacks
  final VoidCallback onColorTap;
  final VoidCallback onAlignLeft;
  final VoidCallback onAlignCenter;
  final VoidCallback onAlignRight;
  final VoidCallback onDirectionToggle;
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
    required this.onBold,
    required this.onItalic,
    required this.onList,
    required this.onH1,
    required this.onH2,
    required this.onChecklist,
    required this.onColorTap,
    required this.onAlignLeft,
    required this.onAlignCenter,
    required this.onAlignRight,
    required this.onDirectionToggle,
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
        border: Border(
          top: BorderSide(
            color: widget.textColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
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
    final l10n = AppLocalizations.of(context)!;

    return Row(
      key: const ValueKey('main'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildIconBtn(Icons.calculate_outlined, widget.onCalculate),
            _buildIconBtn(Icons.text_fields_rounded,
                () => setState(() => _currentMode = ToolbarMode.format)),
            _buildIconBtn(Icons.palette_outlined,
                () => setState(() => _currentMode = ToolbarMode.style)),
            _buildIconBtn(Icons.undo_rounded, widget.onUndo, isEnabled: true),
            _buildIconBtn(Icons.redo_rounded, widget.onRedo, isEnabled: true),
          ],
        ),
        Builder(
          builder: (ctx) => Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final RenderBox button = ctx.findRenderObject() as RenderBox;
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    button.localToGlobal(Offset.zero, ancestor: overlay),
                    button.localToGlobal(button.size.bottomRight(Offset.zero),
                        ancestor: overlay),
                  ),
                  Offset.zero & overlay.size,
                );
                showMenu(
                  context: context,
                  position: position,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2D2D2D)
                      : Colors.white,
                  elevation: 8,
                  items: [
                    PopupMenuItem(
                      value: 'reminder',
                      child: Row(
                        children: [
                          Icon(
                            widget.hasReminder
                                ? Icons.alarm_on_rounded
                                : Icons.alarm_add_rounded,
                            size: 20,
                            color: widget.hasReminder ? Colors.orange : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.hasReminder
                                ? 'Edit Reminder'
                                : 'Add Reminder',
                            style: TextStyle(
                              color: widget.hasReminder ? Colors.orange : null,
                              fontWeight: widget.hasReminder
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      enabled: widget.hasContent,
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined,
                              size: 20,
                              color: widget.hasContent ? null : Colors.grey),
                          const SizedBox(width: 12),
                          Text(l10n.actionShare,
                              style: TextStyle(
                                  color:
                                      widget.hasContent ? null : Colors.grey)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      enabled: widget.hasContent,
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined,
                              size: 20,
                              color: widget.hasContent ? null : Colors.grey),
                          const SizedBox(width: 12),
                          Text(l10n.actionArchive,
                              style: TextStyle(
                                  color:
                                      widget.hasContent ? null : Colors.grey)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: widget.hasContent,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              color:
                                  widget.hasContent ? Colors.red : Colors.grey,
                              size: 20),
                          const SizedBox(width: 12),
                          Text(l10n.actionDelete,
                              style: TextStyle(
                                  color: widget.hasContent
                                      ? Colors.red
                                      : Colors.grey)),
                        ],
                      ),
                    ),
                  ],
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
              },
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
        ),
      ],
    );
  }

  Widget _buildFormatBar() {
    return Row(
      key: const ValueKey('format'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCloseBtn(),
        Container(
            height: 24,
            width: 1,
            color: widget.textColor.withValues(alpha: 0.2)),
        _buildIconBtn(Icons.format_bold_rounded, widget.onBold),
        _buildIconBtn(Icons.format_italic_rounded, widget.onItalic),
        _buildIconBtn(Icons.title_rounded, widget.onH1),
        _buildIconBtn(Icons.format_size_rounded, widget.onH2),
        _buildIconBtn(Icons.format_list_bulleted_rounded, widget.onList),
        _buildIconBtn(Icons.checklist_rounded, widget.onChecklist),
      ],
    );
  }

  Widget _buildStyleBar() {
    return Row(
      key: const ValueKey('style'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCloseBtn(),
        Container(
            height: 24,
            width: 1,
            color: widget.textColor.withValues(alpha: 0.2)),
        if (widget.onBackgroundColorTap != null)
          _buildIconBtn(Icons.color_lens, widget.onBackgroundColorTap),
        const SizedBox(width: 10),
        _buildIconBtn(Icons.format_align_right_rounded, widget.onAlignRight),
        _buildIconBtn(Icons.format_align_center_rounded, widget.onAlignCenter),
        _buildIconBtn(Icons.format_align_left_rounded, widget.onAlignLeft),
        const SizedBox(width: 10),
        _buildIconBtn(Icons.format_textdirection_r_to_l_rounded,
            widget.onDirectionToggle),
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
