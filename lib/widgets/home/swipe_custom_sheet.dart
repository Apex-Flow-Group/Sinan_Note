// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/notification_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/app_bottom_sheet.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/editor/category_picker_sheet.dart';
import 'package:apex_note/widgets/editor/reminder_picker_sheet.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SwipeCustomSheet {
  static Future<void> show(
    BuildContext context, {
    required Note note,
    required List<String> actions,
    required VoidCallback onNoteChanged,
  }) {
    return AppBottomSheet.show(
      context,
      isScrollControlled: true,
      child: _SwipeCustomSheetContent(
        note: note,
        actions: actions,
        onNoteChanged: onNoteChanged,
      ),
    );
  }
}

class _SwipeCustomSheetContent extends StatefulWidget {
  final Note note;
  final List<String> actions;
  final VoidCallback onNoteChanged;

  const _SwipeCustomSheetContent({
    required this.note,
    required this.actions,
    required this.onNoteChanged,
  });

  @override
  State<_SwipeCustomSheetContent> createState() =>
      _SwipeCustomSheetContentState();
}

class _SwipeCustomSheetContentState extends State<_SwipeCustomSheetContent> {
  bool _hidden = false;

  Future<void> _withHide(Future<void> Function() fn) async {
    setState(() => _hidden = true);
    await fn();
    if (mounted) setState(() => _hidden = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Visibility(
      visible: !_hidden,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: AppBottomSheet(
        title: l10n.custom,
        titleIcon: Icons.bolt_rounded,
        scrollable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.actions.map((action) {
              final (icon, label, color) = _actionMeta(action, l10n, scheme);
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                title: Text(label),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () => _execute(context, action, l10n),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  (IconData, String, Color) _actionMeta(
      String action, AppLocalizations l10n, ColorScheme scheme) {
    return switch (action) {
      'delete' => (Icons.delete_outline_rounded, l10n.delete, Colors.red),
      'archive' => (Icons.archive_outlined, l10n.archive, Colors.green),
      'share' => (Icons.share_outlined, l10n.share, Colors.blue),
      'reminder' => (Icons.alarm_rounded, l10n.reminder, Colors.orange),
      'category' => (Icons.label_outlined, l10n.categories, scheme.primary),
      'duplicate' => (Icons.copy_all_rounded, l10n.noteCopy, Colors.purple),
      _ => (Icons.help_outline, action, scheme.onSurface),
    };
  }

  Future<void> _execute(
      BuildContext context, String action, AppLocalizations l10n) async {
    HapticFeedback.mediumImpact();
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    switch (action) {
      case 'delete':
        Navigator.pop(context);
        final delId = widget.note.id!;
        await notesProvider.trashNote(delId);
        widget.onNoteChanged();
        if (!context.mounted) return;
        UnifiedNotificationService().showWithUndo(
          context: context,
          message: '${l10n.movedTo} "${widget.note.title}" ${l10n.toTrash}',
          actionKey: 'custom_delete_$delId',
          type: NotificationType.info,
          onExecute: () {},
          onUndo: () async {
            await notesProvider.restoreNote(delId);
            widget.onNoteChanged();
          },
          undoLabel: l10n.undo,
        );

      case 'archive':
        Navigator.pop(context);
        final archId = widget.note.id!;
        await notesProvider.archiveNote(archId);
        widget.onNoteChanged();
        if (!context.mounted) return;
        UnifiedNotificationService().showWithUndo(
          context: context,
          message: '${l10n.movedTo} "${widget.note.title}" ${l10n.toArchive}',
          actionKey: 'custom_archive_$archId',
          type: NotificationType.success,
          onExecute: () {},
          onUndo: () async {
            await notesProvider.unarchiveNote(archId);
            widget.onNoteChanged();
          },
          undoLabel: l10n.undo,
        );

      case 'share':
        Navigator.pop(context);
        if (!context.mounted) return;
        CustomShareSheet.show(
          context,
          '${widget.note.title}\n\n${NoteCardUtils.fixNoteContent(widget.note.content)}',
          subject: widget.note.title,
          note: widget.note,
          onNoteCopied: () async {
            await notesProvider.duplicateNote(widget.note.id!,
                copyLabel: l10n.noteCopy);
            widget.onNoteChanged();
            if (!context.mounted) return;
            UnifiedNotificationService().show(
              context: context,
              message: l10n.copyCreated,
              type: NotificationType.success,
            );
          },
        );

      case 'duplicate':
        Navigator.pop(context);
        await notesProvider.duplicateNote(widget.note.id!,
            copyLabel: l10n.noteCopy);
        widget.onNoteChanged();
        if (!context.mounted) return;
        UnifiedNotificationService().show(
          context: context,
          message: l10n.copyCreated,
          type: NotificationType.success,
        );

      case 'reminder':
        await _withHide(() async {
          final result = await ReminderPickerSheet.show(
            context,
            widget.note.reminderDateTime,
            widget.note.recurrenceRule,
            Theme.of(context).colorScheme.surface,
          );
          if (!context.mounted) return;
          Navigator.pop(context);
          if (result == null) return;
          if (result['remove'] == true) {
            await NotificationService().cancelNotification(widget.note.id!);
            await notesProvider.updateNote(widget.note
                .copyWith(reminderDateTime: null, recurrenceRule: null));
          } else {
            final dt = result['dateTime'] as DateTime;
            final rec = result['recurrence'] == 'none'
                ? null
                : result['recurrence'] as String;
            await notesProvider.updateNote(widget.note
                .copyWith(reminderDateTime: dt, recurrenceRule: rec));
            await NotificationService().scheduleNotification(
              id: widget.note.id!,
              title: widget.note.title,
              body: NoteCardUtils.fixNoteContent(widget.note.content,
                  maxChars: 100),
              scheduledTime: dt,
              recurrenceRule: rec,
            );
          }
          widget.onNoteChanged();
        });

      case 'category':
        await _withHide(() async {
          final result = await CategoryPickerSheet.show(
            context,
            widget.note.categoryIds,
            isHiddenFromHome: widget.note.isHiddenFromHome,
          );
          if (!context.mounted) return;
          Navigator.pop(context);
          if (result == null) return;
          await notesProvider.updateNote(widget.note.copyWith(
            categoryIds: (result['categoryIds'] as List).cast<int>(),
            isHiddenFromHome: result['isHiddenFromHome'] as bool,
          ));
          widget.onNoteChanged();
        });
    }
  }
}
