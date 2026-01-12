// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import '../../models/note_mode.dart';

class ApexEditorToolbar extends StatelessWidget {
  final Color backgroundColor;
  final double iconSize;
  final bool hasNote;
  final NoteMode mode;
  final String reminderTooltip;
  final String colorTooltip;
  final String renameTooltip;
  final VoidCallback onShareTap;
  final VoidCallback onReminderTap;
  final VoidCallback onColorTap;
  final VoidCallback onRenameTap;
  final VoidCallback onDeleteTap;

  const ApexEditorToolbar({
    super.key,
    required this.backgroundColor,
    required this.iconSize,
    required this.hasNote,
    required this.mode,
    required this.reminderTooltip,
    required this.colorTooltip,
    required this.renameTooltip,
    required this.onShareTap,
    required this.onReminderTap,
    required this.onColorTap,
    required this.onRenameTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.share_outlined, size: iconSize),
              onPressed: onShareTap,
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.alarm, size: iconSize),
                  tooltip: reminderTooltip,
                  onPressed: onReminderTap,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: Icon(Icons.palette_outlined, size: iconSize),
                  tooltip: colorTooltip,
                  onPressed: onColorTap,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: Icon(Icons.edit_note, size: iconSize),
                  tooltip: renameTooltip,
                  onPressed: onRenameTap,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
            if (hasNote)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red, size: iconSize),
                onPressed: onDeleteTap,
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
