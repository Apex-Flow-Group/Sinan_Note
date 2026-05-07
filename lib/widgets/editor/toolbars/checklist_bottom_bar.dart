// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/widgets/editor/toolbars/editor_options_menu.dart';
import 'package:flutter/material.dart';

class ChecklistBottomBar extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final bool hasContent;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onBackgroundColorTap;
  final VoidCallback? onReminderTap;
  final VoidCallback onShareTap;
  final VoidCallback onArchiveTap;
  final VoidCallback onDeleteTap;
  final VoidCallback? onConvertToSimple;
  final VoidCallback? onConvertToRich;

  const ChecklistBottomBar({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.hasContent,
    this.onUndo,
    this.onRedo,
    required this.onBackgroundColorTap,
    this.onReminderTap,
    required this.onShareTap,
    required this.onArchiveTap,
    required this.onDeleteTap,
    this.onConvertToSimple,
    this.onConvertToRich,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(color: backgroundColor),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.palette_outlined, color: textColor),
                  onPressed: onBackgroundColorTap,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: Icon(Icons.undo_rounded,
                      color: onUndo != null ? textColor : Colors.grey),
                  onPressed: onUndo,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: Icon(Icons.redo_rounded,
                      color: onRedo != null ? textColor : Colors.grey),
                  onPressed: onRedo,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            Flexible(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    EditorOptionsMenu.show(
                      context: context,
                      hasContent: hasContent,
                      showReminder: true,
                      showConvertToSimple: onConvertToSimple != null,
                      showConvertToRich: onConvertToRich != null,
                    ).then((value) {
                      if (value == 'reminder') {
                        onReminderTap?.call();
                      } else if (value == 'share') {
                        onShareTap();
                      } else if (value == 'archive') {
                        onArchiveTap();
                      } else if (value == 'delete') {
                        onDeleteTap();
                      } else if (value == 'convertToSimple') {
                        onConvertToSimple?.call();
                      } else if (value == 'convertToRich') {
                        onConvertToRich?.call();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: textColor.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Icon(Icons.more_vert_rounded,
                        color: textColor, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
