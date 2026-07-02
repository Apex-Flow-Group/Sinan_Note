// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/services/notification_service.dart';
import 'package:sinan_note/services/unified_notification_service.dart';

class ReminderPickerSheet extends StatefulWidget {
  final DateTime? initialDateTime;
  final String? initialRecurrence;

  const ReminderPickerSheet({
    super.key,
    this.initialDateTime,
    this.initialRecurrence,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    DateTime? initialDateTime,
    String? initialRecurrence,
    Color backgroundColor, // kept for API compatibility
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final notificationService = NotificationService();
    final permissions = await notificationService.checkAllPermissions();

    if (!context.mounted) return null;

    if (!permissions['notifications']! || !permissions['exactAlarm']!) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(l10n.permissionsRequired),
          content: Text(l10n.reminderPermissionsDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.grantPermissions),
            ),
          ],
        ),
      );

      if (!context.mounted) return null;

      if (shouldRequest == true) {
        await notificationService.requestNotificationPermissions();
        if (!context.mounted) return null;

        final newPermissions = await notificationService.checkAllPermissions();
        if (!context.mounted) return null;

        if (!newPermissions['notifications']! ||
            !newPermissions['exactAlarm']!) {
          UnifiedNotificationService().show(
            context: context,
            message: l10n.permissionsDenied,
            type: NotificationType.error,
            duration: const Duration(seconds: 3),
          );
          return null;
        }
      } else {
        return null;
      }
    }

    if (!context.mounted) return null;

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReminderPickerSheet(
        initialDateTime: initialDateTime,
        initialRecurrence: initialRecurrence,
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
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerLow : scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    tooltip: l10n.cancel,
                  ),
                  if (widget.initialDateTime != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: scheme.error),
                      onPressed: () => Navigator.pop(context, {'remove': true}),
                      tooltip: l10n.removeReminder,
                    ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.alarm_rounded,
                              color: Colors.orange, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.reminder,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context, {
                      'dateTime': DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _selectedTime.hour,
                        _selectedTime.minute,
                      ),
                      'recurrence': _recurrence,
                    }),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n.save),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            const Divider(height: 16),

            // ── Body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Date card ──
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(
                              l10n.date, Icons.calendar_today_rounded),
                          const SizedBox(height: 12),
                          // Quick chips
                          Row(
                            children: [
                              _QuickChip(
                                label: l10n.today,
                                date: DateTime.now(),
                                selected:
                                    _isSameDay(_selectedDate, DateTime.now()),
                                onTap: () => setState(
                                    () => _selectedDate = DateTime.now()),
                              ),
                              const SizedBox(width: 8),
                              _QuickChip(
                                label: l10n.tomorrow,
                                date:
                                    DateTime.now().add(const Duration(days: 1)),
                                selected: _isSameDay(
                                    _selectedDate,
                                    DateTime.now()
                                        .add(const Duration(days: 1))),
                                onTap: () => setState(() => _selectedDate =
                                    DateTime.now()
                                        .add(const Duration(days: 1))),
                              ),
                              const SizedBox(width: 8),
                              _QuickChip(
                                label: l10n.nextWeek,
                                date:
                                    DateTime.now().add(const Duration(days: 7)),
                                selected: _isSameDay(
                                    _selectedDate,
                                    DateTime.now()
                                        .add(const Duration(days: 7))),
                                onTap: () => setState(() => _selectedDate =
                                    DateTime.now()
                                        .add(const Duration(days: 7))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Date picker button
                          _PickerButton(
                            icon: Icons.edit_calendar_rounded,
                            label: DateFormat('EEE, MMM d, yyyy')
                                .format(_selectedDate),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() => _selectedDate = date);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Time card ──
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(l10n.time, Icons.access_time_rounded),
                          const SizedBox(height: 12),
                          _PickerButton(
                            icon: Icons.schedule_rounded,
                            label: _selectedTime.format(context),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (time != null) {
                                setState(() => _selectedTime = time);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Recurrence card ──
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(l10n.repeat, Icons.repeat_rounded),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _RecurrenceChip(
                                  label: l10n.doesNotRepeat,
                                  value: 'none',
                                  selected: _recurrence == 'none',
                                  onTap: () =>
                                      setState(() => _recurrence = 'none')),
                              _RecurrenceChip(
                                  label: l10n.daily,
                                  value: 'DAILY',
                                  selected: _recurrence == 'DAILY',
                                  onTap: () =>
                                      setState(() => _recurrence = 'DAILY')),
                              _RecurrenceChip(
                                  label: l10n.weekly,
                                  value: 'WEEKLY',
                                  selected: _recurrence == 'WEEKLY',
                                  onTap: () =>
                                      setState(() => _recurrence = 'WEEKLY')),
                              _RecurrenceChip(
                                  label: l10n.monthly,
                                  value: 'MONTHLY',
                                  selected: _recurrence == 'MONTHLY',
                                  onTap: () =>
                                      setState(() => _recurrence = 'MONTHLY')),
                              _RecurrenceChip(
                                  label: l10n.yearly,
                                  value: 'YEARLY',
                                  selected: _recurrence == 'YEARLY',
                                  onTap: () =>
                                      setState(() => _recurrence = 'YEARLY')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Shared sub-widgets ────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickerButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;
  const _QuickChip(
      {required this.label,
      required this.date,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? Colors.orange : Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? Colors.orange : Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.orange,
          ),
        ),
      ),
    );
  }
}

class _RecurrenceChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _RecurrenceChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
