// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReminderPickerSheet extends StatefulWidget {
  final DateTime? initialDateTime;
  final String? initialRecurrence;
  final Color backgroundColor;

  const ReminderPickerSheet({
    super.key,
    this.initialDateTime,
    this.initialRecurrence,
    required this.backgroundColor,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    DateTime? initialDateTime,
    String? initialRecurrence,
    Color backgroundColor,
  ) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReminderPickerSheet(
        initialDateTime: initialDateTime,
        initialRecurrence: initialRecurrence,
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  State<ReminderPickerSheet> createState() => _ReminderPickerSheetState();
}

class _ReminderPickerSheetState extends State<ReminderPickerSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _recurrence = 'none';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = widget.initialDateTime ?? now.add(const Duration(hours: 1));
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    _recurrence = widget.initialRecurrence ?? 'none';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900]! : theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: textColor.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Cancel',
                  ),
                  if (widget.initialDateTime != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => Navigator.pop(context, {'remove': true}),
                      tooltip: 'Remove',
                    ),
                  const Spacer(),
                  Text(
                    'Reminder',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.check_rounded, color: primaryColor),
                    onPressed: () {
                      final result = {
                        'dateTime': DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        ),
                        'recurrence': _recurrence,
                      };
                      Navigator.pop(context, result);
                    },
                    tooltip: 'Save',
                  ),
                ],
              ),
            ),
            // Quick Date Selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuickDateChip('Today', DateTime.now(), textColor),
                      const SizedBox(width: 8),
                      _buildQuickDateChip(
                          'Tomorrow',
                          DateTime.now().add(const Duration(days: 1)),
                          textColor),
                      const SizedBox(width: 8),
                      _buildQuickDateChip(
                          'Next Week',
                          DateTime.now().add(const Duration(days: 7)),
                          textColor),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: theme.copyWith(
                              colorScheme: theme.colorScheme.copyWith(
                                surface: bgColor,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                        DateFormat('EEE, MMM d, yyyy').format(_selectedDate)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(
                          color: primaryColor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Time Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: theme.copyWith(
                              colorScheme: theme.colorScheme.copyWith(
                                surface: bgColor,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(_selectedTime.format(context)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(
                          color: primaryColor.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Recurrence Options
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repeat',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRecurrenceChip(
                          'Does not repeat', 'none', textColor),
                      _buildRecurrenceChip('Daily', 'DAILY', textColor),
                      _buildRecurrenceChip('Weekly', 'WEEKLY', textColor),
                      _buildRecurrenceChip('Monthly', 'MONTHLY', textColor),
                      _buildRecurrenceChip('Yearly', 'YEARLY', textColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, DateTime date, Color textColor) {
    final isSelected = _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedDate = date);
        }
      },
      selectedColor: primaryColor,
      backgroundColor: textColor.withValues(alpha: 0.05),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : textColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      elevation: isSelected ? 2 : 0,
    );
  }

  Widget _buildRecurrenceChip(String label, String value, Color textColor) {
    final isSelected = _recurrence == value;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _recurrence = value);
        }
      },
      selectedColor: primaryColor,
      backgroundColor: textColor.withValues(alpha: 0.05),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : textColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      elevation: isSelected ? 2 : 0,
    );
  }
}
