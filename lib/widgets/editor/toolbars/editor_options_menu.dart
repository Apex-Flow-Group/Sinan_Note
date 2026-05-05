// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/widgets/common/app_bottom_sheet.dart';
import 'package:flutter/material.dart';

class EditorOptionsMenu {
  static Future<String?> show({
    required BuildContext context,
    required bool hasContent,
    bool showReminder = false,
    bool showLock = false,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet.show<String>(
      context,
      child: AppBottomSheet(
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showReminder)
              ListTile(
                leading: Icon(Icons.alarm_add_rounded,
                    color: hasContent ? Colors.orange : Colors.grey),
                title: Text(l10n.reminder,
                    style: TextStyle(color: hasContent ? null : Colors.grey)),
                enabled: hasContent,
                onTap: hasContent
                    ? () => Navigator.pop(context, 'reminder')
                    : null,
              ),
            if (showLock)
              ListTile(
                leading: Icon(Icons.lock_outline,
                    color: hasContent ? Colors.blue : Colors.grey),
                title: Text(l10n.lockNote,
                    style: TextStyle(color: hasContent ? null : Colors.grey)),
                enabled: hasContent,
                onTap: hasContent ? () => Navigator.pop(context, 'lock') : null,
              ),
            ListTile(
              leading: Icon(Icons.share_rounded,
                  color: hasContent ? Colors.blue : Colors.grey),
              title: Text(l10n.actionShare,
                  style: TextStyle(color: hasContent ? null : Colors.grey)),
              enabled: hasContent,
              onTap: hasContent ? () => Navigator.pop(context, 'share') : null,
            ),
            ListTile(
              leading: Icon(Icons.archive_rounded,
                  color: hasContent ? Colors.green : Colors.grey),
              title: Text(l10n.actionArchive,
                  style: TextStyle(color: hasContent ? null : Colors.grey)),
              enabled: hasContent,
              onTap:
                  hasContent ? () => Navigator.pop(context, 'archive') : null,
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_rounded,
                  color: hasContent ? Colors.red : Colors.grey),
              title: Text(l10n.actionDelete,
                  style:
                      TextStyle(color: hasContent ? Colors.red : Colors.grey)),
              enabled: hasContent,
              onTap: hasContent ? () => Navigator.pop(context, 'delete') : null,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
