// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
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
    final scheme = context.scheme;
    final colors = context.colors;
    final disabled = colors.muted;

    Widget tile(IconData icon, Color color, String label, String value) =>
        ListTile(
          leading: Icon(icon, color: hasContent ? color : disabled),
          title: Text(label,
              style: TextStyle(color: hasContent ? null : disabled)),
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
              tile(Icons.alarm_add_rounded, colors.warning, l10n.reminder, 'reminder'),
            if (showConvertToSimple)
              tile(Icons.note_rounded, scheme.tertiary, l10n.simpleNotes, 'convertToSimple'),
            if (showConvertToRich)
              tile(Icons.text_fields_rounded, scheme.tertiary, l10n.richText, 'convertToRich'),
            if (showConvertToCode)
              tile(Icons.code_rounded, scheme.tertiary, l10n.professionalNotes, 'convertToCode'),
            if (showConvertToChecklist)
              tile(Icons.checklist_rounded, scheme.tertiary, l10n.checklist, 'convertToChecklist'),
            if (showLock)
              tile(Icons.lock_outline, scheme.primary, l10n.lockNote, 'lock'),
            tile(Icons.share_rounded, scheme.primary, l10n.actionShare, 'share'),
            tile(Icons.archive_rounded, colors.success, l10n.actionArchive, 'archive'),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_rounded,
                  color: hasContent ? colors.danger : disabled),
              title: Text(l10n.actionDelete,
                  style: TextStyle(
                      color: hasContent ? colors.danger : disabled)),
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

