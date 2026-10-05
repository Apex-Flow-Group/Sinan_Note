// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/widgets/app_bottom_sheet.dart';

/// Bottom sheet موحد لاختيار الفلتر في الشاشة الرئيسية
class FilterSheet {
  static void show(
    BuildContext context, {
    required ValueNotifier<String?> activeFilterNotifier,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final scheme = context.scheme;
    final sectionStyle = context.text.labelMedium
        ?.copyWith(fontWeight: FontWeight.bold, color: colors.muted);

    AppBottomSheet.show(
      context,
      child: AppBottomSheet(
        title: l10n.filter,
        titleIcon: Icons.filter_list_rounded,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(l10n.noteType, style: sectionStyle),
            ),
            ListTile(
              leading: Icon(Icons.note, color: scheme.primary),
              title: Text(l10n.simpleNotes),
              onTap: () {
                Navigator.pop(context);
                activeFilterNotifier.value = 'type:simple';
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.format_paint_rounded, color: scheme.secondary),
              title: Text(l10n.richNoteMenu),
              onTap: () {
                Navigator.pop(context);
                activeFilterNotifier.value = 'type:rich';
              },
            ),
            ListTile(
              leading: Icon(Icons.checklist, color: colors.success),
              title: Text(l10n.checklists),
              onTap: () {
                Navigator.pop(context);
                activeFilterNotifier.value = 'type:checklist';
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(l10n.noteStatus, style: sectionStyle),
            ),
            ListTile(
              leading: Icon(Icons.push_pin, color: colors.gold),
              title: Text(l10n.pinnedOnly),
              onTap: () {
                Navigator.pop(context);
                activeFilterNotifier.value = 'pinned:true';
              },
            ),
            ListTile(
              leading: Icon(Icons.label_off_outlined, color: colors.muted),
              title: Text(l10n.noCategory),
              onTap: () {
                Navigator.pop(context);
                activeFilterNotifier.value = 'category:none';
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.clear_all, color: colors.danger),
              title: Text(l10n.clearFilter),
              onTap: () {
                Navigator.pop(context);
                activeFilterNotifier.value = null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
