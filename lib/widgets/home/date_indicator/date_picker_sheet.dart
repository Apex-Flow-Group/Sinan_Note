// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/models/note.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerSheet {
  static Future<DateTime?> show(
    BuildContext context, {
    required List<Note> notes,
    required DateTime? currentDate,
  }) {
    final uniqueDates = notes
        .map((n) => DateTime(n.updatedAt.year, n.updatedAt.month, n.updatedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return showModalBottomSheet<DateTime>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [
              const Icon(Icons.calendar_month_outlined, size: 20),
              const SizedBox(width: 8),
              Text(isAr ? 'انتقل إلى تاريخ' : 'Jump to date',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.4),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: uniqueDates.length,
              itemBuilder: (ctx, i) {
                final date = uniqueDates[i];
                final isSelected = date == currentDate;
                final count = notes.where((n) =>
                    n.updatedAt.year == date.year &&
                    n.updatedAt.month == date.month &&
                    n.updatedAt.day == date.day).length;
                return ListTile(
                  leading: Icon(Icons.circle, size: 10,
                      color: isSelected ? Theme.of(ctx).colorScheme.primary : Colors.transparent),
                  title: Text(
                    _formatDate(date, isAr),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(ctx).colorScheme.primary : null,
                    ),
                  ),
                  trailing: Text('$count', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  onTap: () => Navigator.pop(ctx, date),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date, bool isAr) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return isAr ? 'اليوم' : 'Today';
    if (date == yesterday) return isAr ? 'أمس' : 'Yesterday';
    return DateFormat(isAr ? 'd MMMM yyyy' : 'MMMM d, yyyy', isAr ? 'ar' : 'en').format(date);
  }
}
