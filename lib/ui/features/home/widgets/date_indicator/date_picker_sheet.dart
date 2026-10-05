// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/widgets/app_bottom_sheet.dart';

class DatePickerSheet {
  static Future<DateTime?> show(
    BuildContext context, {
    required List<Note> notes,
    required DateTime? currentDate,
  }) {
    final uniqueDates = notes
        .map((n) =>
            DateTime(n.updatedAt.year, n.updatedAt.month, n.updatedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet.show<DateTime>(
      context,
      child: AppBottomSheet(
        title: l10n.jumpToDate,
        titleIcon: Icons.calendar_month_outlined,
        scrollable: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: uniqueDates.length,
            itemBuilder: (ctx, i) {
              final date = uniqueDates[i];
              final isSelected = date == currentDate;
              final count = notes
                  .where((n) =>
                      n.updatedAt.year == date.year &&
                      n.updatedAt.month == date.month &&
                      n.updatedAt.day == date.day)
                  .length;
              return ListTile(
                leading: Icon(Icons.circle,
                    size: 10,
                    color: isSelected
                        ? Theme.of(ctx).colorScheme.primary
                        : Colors.transparent),
                title: Text(
                  _formatDate(date, l10n),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color:
                        isSelected ? Theme.of(ctx).colorScheme.primary : null,
                  ),
                ),
                trailing: Text('$count',
                    style: ctx.text.bodySmall?.copyWith(color: ctx.colors.muted)),
                onTap: () => Navigator.pop(ctx, date),
              );
            },
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return l10n.today;
    if (date == yesterday) return l10n.yesterday;
    return DateFormat.yMMMMd(l10n.localeName).format(date);
  }
}

