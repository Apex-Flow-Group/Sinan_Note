// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class EditorOptionsMenu {
  static Future<String?> show({
    required BuildContext context,
    required bool hasContent,
    bool showReminder = false,
    bool showLock = false,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (showReminder)
              ListTile(
                leading: Icon(
                  Icons.alarm_add_rounded,
                  color: hasContent ? Colors.orange : Colors.grey,
                ),
                title: Text(
                  l10n.reminder,
                  style: TextStyle(color: hasContent ? null : Colors.grey),
                ),
                enabled: hasContent,
                onTap: hasContent
                    ? () => Navigator.pop(ctx, 'reminder')
                    : null,
              ),
            if (showLock)
              ListTile(
                leading: Icon(
                  Icons.lock_outline,
                  color: hasContent ? Colors.blue : Colors.grey,
                ),
                title: Text(
                  l10n.lockNote,
                  style: TextStyle(color: hasContent ? null : Colors.grey),
                ),
                enabled: hasContent,
                onTap: hasContent ? () => Navigator.pop(ctx, 'lock') : null,
              ),
            ListTile(
              leading: Icon(
                Icons.share_rounded,
                color: hasContent ? Colors.blue : Colors.grey,
              ),
              title: Text(
                l10n.actionShare,
                style: TextStyle(color: hasContent ? null : Colors.grey),
              ),
              enabled: hasContent,
              onTap: hasContent ? () => Navigator.pop(ctx, 'share') : null,
            ),
            ListTile(
              leading: Icon(
                Icons.archive_rounded,
                color: hasContent ? Colors.green : Colors.grey,
              ),
              title: Text(
                l10n.actionArchive,
                style: TextStyle(color: hasContent ? null : Colors.grey),
              ),
              enabled: hasContent,
              onTap: hasContent ? () => Navigator.pop(ctx, 'archive') : null,
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.delete_rounded,
                color: hasContent ? Colors.red : Colors.grey,
              ),
              title: Text(
                l10n.actionDelete,
                style: TextStyle(color: hasContent ? Colors.red : Colors.grey),
              ),
              enabled: hasContent,
              onTap: hasContent ? () => Navigator.pop(ctx, 'delete') : null,
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
