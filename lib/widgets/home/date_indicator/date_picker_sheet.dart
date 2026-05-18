// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';

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

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return AppBottomSheet.show<DateTime>(
      context,
      child: AppBottomSheet(
        title: isAr ? 'انتقل إلى تاريخ' : 'Jump to date',
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
                  _formatDate(date, isAr),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color:
                        isSelected ? Theme.of(ctx).colorScheme.primary : null,
                  ),
                ),
                trailing: Text('$count',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                onTap: () => Navigator.pop(ctx, date),
              );
            },
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date, bool isAr) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return isAr ? 'اليوم' : 'Today';
    if (date == yesterday) return isAr ? 'أمس' : 'Yesterday';
    return DateFormat(isAr ? 'd MMMM yyyy' : 'MMMM d, yyyy', isAr ? 'ar' : 'en')
        .format(date);
  }
}

