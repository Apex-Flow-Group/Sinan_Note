// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';

class EditorOptionsMenu {
  static Future<String?> show({
    required BuildContext context,
    required bool hasContent,
    bool showReminder = false,
    bool showLock = false,
    // تحويلات متاحة
    bool showConvertToSimple = false,
    bool showConvertToRich = false,
    bool showConvertToCode = false,
    bool showConvertToChecklist = false,
  }) {
    final l10n = AppLocalizations.of(context)!;

    Widget tile(IconData icon, Color color, String label, String value) =>
        ListTile(
          leading: Icon(icon, color: hasContent ? color : Colors.grey),
          title: Text(label,
              style: TextStyle(color: hasContent ? null : Colors.grey)),
          enabled: hasContent,
          onTap: hasContent ? () => Navigator.pop(context, value) : null,
        );

    return AppBottomSheet.show<String>(
      context,
      child: AppBottomSheet(
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showReminder)
              tile(Icons.alarm_add_rounded, Colors.orange, l10n.reminder, 'reminder'),
            if (showConvertToSimple)
              tile(Icons.note_rounded, Colors.teal, l10n.simpleNotes, 'convertToSimple'),
            if (showConvertToRich)
              tile(Icons.text_fields_rounded, Colors.teal, l10n.richText, 'convertToRich'),
            if (showConvertToCode)
              tile(Icons.code_rounded, Colors.teal, l10n.professionalNotes, 'convertToCode'),
            if (showConvertToChecklist)
              tile(Icons.checklist_rounded, Colors.teal, l10n.checklist, 'convertToChecklist'),
            if (showLock)
              tile(Icons.lock_outline, Colors.blue, l10n.lockNote, 'lock'),
            tile(Icons.share_rounded, Colors.blue, l10n.actionShare, 'share'),
            tile(Icons.archive_rounded, Colors.green, l10n.actionArchive, 'archive'),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_rounded,
                  color: hasContent ? Colors.red : Colors.grey),
              title: Text(l10n.actionDelete,
                  style: TextStyle(
                      color: hasContent ? Colors.red : Colors.grey)),
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

