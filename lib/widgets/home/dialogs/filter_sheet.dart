// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/widgets/common/app_bottom_sheet.dart';
import 'package:flutter/material.dart';

/// Bottom sheet موحد لاختيار الفلتر في الشاشة الرئيسية
class FilterSheet {
  static void show(
    BuildContext context, {
    required ValueNotifier<String?> activeFilterNotifier,
  }) {
    final l10n = AppLocalizations.of(context)!;

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
              child: Text(l10n.noteType,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),
            ListTile(
              leading: const Icon(Icons.note, color: Colors.blue),
              title: Text(l10n.simpleNotes),
              onTap: () {
                Navigator.pop(context);
                activeFilterNotifier.value = 'type:simple';
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist, color: Colors.green),
              title: Text(l10n.checklists),
              onTap: () {
                Navigator.pop(context);
                activeFilterNotifier.value = 'type:checklist';
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(l10n.noteStatus,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),
            ListTile(
              leading: const Icon(Icons.push_pin, color: Colors.red),
              title: Text(l10n.pinnedOnly),
              onTap: () {
                Navigator.pop(context);
                activeFilterNotifier.value = 'pinned:true';
              },
            ),
            ListTile(
              leading: const Icon(Icons.label_off_outlined, color: Colors.grey),
              title: Text(l10n.noCategory),
              onTap: () {
                Navigator.pop(context);
                activeFilterNotifier.value = 'category:none';
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.clear_all, color: Colors.red),
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
