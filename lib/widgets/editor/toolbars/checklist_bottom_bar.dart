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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
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
                  tooltip: 'Background Color',
                ),
                IconButton(
                  icon: Icon(Icons.undo_rounded,
                      color: onUndo != null ? textColor : Colors.grey),
                  onPressed: onUndo,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: Icon(Icons.redo_rounded,
                      color: onRedo != null ? textColor : Colors.grey),
                  onPressed: onRedo,
                  tooltip: 'Redo',
                ),
              ],
            ),
            Flexible(
              child: Builder(
                builder: (ctx) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      EditorOptionsMenu.show(
                        context: context,
                        hasContent: hasContent,
                        showReminder: true,
                      ).then((value) {
                        if (value == 'reminder') {
                          onReminderTap?.call();
                        } else if (value == 'share') {
                          onShareTap();
                        } else if (value == 'archive') {
                          onArchiveTap();
                        } else if (value == 'delete') {
                          onDeleteTap();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
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
            ),
          ],
        ),
      ),
    );
  }
}
