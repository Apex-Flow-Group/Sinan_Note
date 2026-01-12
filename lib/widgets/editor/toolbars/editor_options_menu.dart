// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

class EditorOptionsMenu {
  static Future<String?> show({
    required BuildContext context,
    required RelativeRect position,
    required bool hasContent,
    bool showReminder = false,
    bool showLock = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      elevation: 8,
      items: [
        if (showReminder)
          PopupMenuItem(
            value: 'reminder',
            enabled: hasContent,
            child: Row(
              children: [
                Icon(Icons.alarm,
                    size: 20, color: hasContent ? null : Colors.grey),
                const SizedBox(width: 12),
                Text(l10n.reminder,
                    style: TextStyle(color: hasContent ? null : Colors.grey)),
              ],
            ),
          ),
        if (showLock)
          PopupMenuItem(
            value: 'lock',
            enabled: hasContent,
            child: Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 20, color: hasContent ? null : Colors.grey),
                const SizedBox(width: 12),
                Text(l10n.lockNote,
                    style: TextStyle(color: hasContent ? null : Colors.grey)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'share',
          enabled: hasContent,
          child: Row(
            children: [
              Icon(Icons.share_outlined,
                  size: 20, color: hasContent ? null : Colors.grey),
              const SizedBox(width: 12),
              Text(l10n.actionShare,
                  style: TextStyle(color: hasContent ? null : Colors.grey)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          enabled: hasContent,
          child: Row(
            children: [
              Icon(Icons.archive_outlined,
                  size: 20, color: hasContent ? null : Colors.grey),
              const SizedBox(width: 12),
              Text(l10n.actionArchive,
                  style: TextStyle(color: hasContent ? null : Colors.grey)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          enabled: hasContent,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  color: hasContent ? Colors.red : Colors.grey, size: 20),
              const SizedBox(width: 12),
              Text(l10n.actionDelete,
                  style: TextStyle(
                      color: hasContent ? Colors.red : Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
