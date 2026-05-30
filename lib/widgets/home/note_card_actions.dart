// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/notification_service.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';
import 'package:sinan_note/widgets/common/custom_share_sheet.dart';
import 'package:sinan_note/widgets/editor/category_picker_sheet.dart';
import 'package:sinan_note/widgets/editor/reminder_picker_sheet.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';
import 'package:sinan_note/widgets/home/swipe_custom_sheet.dart';

class NoteCardActions {
  static Widget buildLockedNoteMenu(BuildContext context, Note note,
      Color titleColor, VoidCallback onNoteChanged) {
    final l10n = AppLocalizations.of(context)!;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20, color: titleColor),
      onSelected: (value) async {
        if (value == 'unlock') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.unlockNote),
              content: Text(l10n.unlockNoteConfirmation),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.unlock),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            await notesProvider.toggleLockStatus(note.id!, false);
            onNoteChanged();
            if (!context.mounted) return;
            UnifiedNotificationService().show(
              context: context,
              message: l10n.noteUnlocked,
              type: NotificationType.success,
            );
          }
        } else if (value == 'delete') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.permanentDelete),
              content: Text(l10n.confirmPermanentDelete),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            HapticFeedback.mediumImpact();
            final noteId = note.id!;
            await notesProvider.trashNote(noteId);
            onNoteChanged();
            if (!context.mounted) return;
            UnifiedNotificationService().show(
              context: context,
              message: l10n.noteDeleted,
              type: NotificationType.info,
            );
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'unlock',
          child: Row(
            children: [
              const Icon(Icons.lock_open, size: 18),
              const SizedBox(width: 8),
              Text(l10n.unlock),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 18, color: Colors.red),
              const SizedBox(width: 8),
              Text(l10n.delete, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildCustomSlidableAction({
    required String action,
    required BuildContext context,
    required BorderRadius borderRadius,
    required Note note,
    required VoidCallback onNoteChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    IconData icon;
    Color color;
    VoidCallback onTap;

    switch (action) {
      case 'delete':
        icon = Icons.delete_outline;
        color = Colors.red.shade600;
        onTap = () async {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          final noteId = note.id!;
          final noteTitle = note.title;

          await notesProvider.trashNote(noteId);
          onNoteChanged();

          if (!context.mounted) return;

          UnifiedNotificationService().showWithUndo(
            context: context,
            message: '${l10n.movedTo} "$noteTitle" ${l10n.toTrash}',
            actionKey: 'swipe_delete_$noteId',
            type: NotificationType.info,
            onExecute: () {},
            onUndo: () async {
              await notesProvider.restoreNote(noteId);
              onNoteChanged();
            },
            undoLabel: l10n.undo,
          );
        };
        break;
      case 'archive':
        icon = Icons.archive_outlined;
        color = Colors.green.shade600;
        onTap = () async {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          final noteId = note.id!;
          final noteTitle = note.title;

          await notesProvider.archiveNote(noteId);
          onNoteChanged();

          if (!context.mounted) return;

          UnifiedNotificationService().showWithUndo(
            context: context,
            message: '${l10n.movedTo} "$noteTitle" ${l10n.toArchive}',
            actionKey: 'swipe_archive_$noteId',
            type: NotificationType.success,
            onExecute: () {},
            onUndo: () async {
              await notesProvider.unarchiveNote(noteId);
              onNoteChanged();
            },
            undoLabel: l10n.undo,
          );
        };
        break;
      case 'share':
        icon = Icons.share_outlined;
        color = Colors.blue.shade600;
        onTap = () {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          final plainContent = NoteCardUtils.fixNoteContent(note.content, maxChars: null);
          CustomShareSheet.show(
            context,
            '${note.title}\n\n$plainContent',
            subject: note.title,
            note: note,
            onNoteCopied: () async {
              await notesProvider.duplicateNote(note.id!,
                  copyLabel: l10n.noteCopy);
              onNoteChanged();
              if (!context.mounted) return;
              UnifiedNotificationService().show(
                context: context,
                message: l10n.copyCreated,
                type: NotificationType.success,
              );
            },
          );
        };
        break;
      case 'reminder':
        icon = Icons.alarm_rounded;
        color = Colors.orange.shade600;
        onTap = () async {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          await Future.delayed(const Duration(milliseconds: 200));
          if (!context.mounted) return;
          final result = await ReminderPickerSheet.show(
            context,
            note.reminderDateTime,
            note.recurrenceRule,
            Theme.of(context).colorScheme.surface,
          );
          if (!context.mounted || result == null) return;
          if (result['remove'] == true) {
            await NotificationService().cancelNotification(note.id!);
            final updated =
                note.copyWith(reminderDateTime: null, recurrenceRule: null);
            await notesProvider.updateNote(updated);
          } else {
            final updated = note.copyWith(
              reminderDateTime: result['dateTime'] as DateTime,
              recurrenceRule: result['recurrence'] == 'none'
                  ? null
                  : result['recurrence'] as String,
            );
            await notesProvider.updateNote(updated);
            await NotificationService().scheduleNotification(
              id: note.id!,
              title: note.title,
              body: NoteCardUtils.fixNoteContent(note.content, maxChars: 100),
              scheduledTime: result['dateTime'] as DateTime,
              recurrenceRule: result['recurrence'] == 'none'
                  ? null
                  : result['recurrence'] as String,
            );
          }
          onNoteChanged();
        };
        break;
      case 'category':
        icon = Icons.label_outlined;
        color = Colors.teal.shade600;
        onTap = () async {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          await Future.delayed(const Duration(milliseconds: 200));
          if (!context.mounted) return;
          final result = await CategoryPickerSheet.show(
            context,
            note.categoryIds,
            isHiddenFromHome: note.isHiddenFromHome,
          );
          if (!context.mounted || result == null) return;
          final updated = note.copyWith(
            categoryIds: (result['categoryIds'] as List).cast<int>(),
            isHiddenFromHome: result['isHiddenFromHome'] as bool,
          );
          await notesProvider.updateNote(updated);
          onNoteChanged();
        };
        break;
      case 'duplicate':
        icon = Icons.copy_all_rounded;
        color = Colors.purple.shade600;
        onTap = () async {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          await notesProvider.duplicateNote(note.id!, copyLabel: l10n.noteCopy);
          onNoteChanged();
          if (!context.mounted) return;
          UnifiedNotificationService().show(
            context: context,
            message: l10n.copyCreated,
            type: NotificationType.success,
          );
        };
        break;
      case 'custom':
        icon = Icons.bolt_rounded;
        color = Colors.indigo.shade600;
        onTap = () {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          final settings =
              Provider.of<SettingsProvider>(context, listen: false);
          SwipeCustomSheet.show(
            context,
            note: note,
            actions: settings.swipeCustomActions,
            onNoteChanged: onNoteChanged,
          );
        };
        break;
      case 'restore':
        icon = Icons.restore;
        color = Colors.green.shade600;
        onTap = () async {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          await notesProvider.restoreNote(note.id!);
          onNoteChanged();
          if (!context.mounted) return;
          UnifiedNotificationService().showWithUndo(
            context: context,
            message: l10n.restoredToHome,
            actionKey: 'swipe_restore_${note.id}',
            type: NotificationType.success,
            onExecute: () {},
            onUndo: () async {
              await notesProvider.trashNote(note.id!);
              onNoteChanged();
            },
            undoLabel: l10n.undo,
          );
        };
        break;
      case 'permanent_delete':
        icon = Icons.delete_forever;
        color = Colors.red.shade700;
        onTap = () async {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          final confirm = await AppBottomSheet.show<bool>(
            context,
            child: _PermanentDeleteSheet(note: note),
          );
          if (confirm == true) {
            await notesProvider.deleteNote(note.id!);
            onNoteChanged();
          }
        };
        break;
      case 'unarchive':
        icon = Icons.unarchive_outlined;
        color = Colors.green.shade600;
        onTap = () async {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          await notesProvider.unarchiveNote(note.id!);
          onNoteChanged();
          if (!context.mounted) return;
          UnifiedNotificationService().showWithUndo(
            context: context,
            message: l10n.restoredToHome,
            actionKey: 'swipe_unarchive_${note.id}',
            type: NotificationType.success,
            onExecute: () {},
            onUndo: () async {
              await notesProvider.archiveNote(note.id!);
              onNoteChanged();
            },
            undoLabel: l10n.undo,
          );
        };
        break;
      case 'trash_from_archive':
        icon = Icons.delete_outline;
        color = Colors.red.shade600;
        onTap = () async {
          HapticFeedback.mediumImpact();
          Slidable.of(context)?.close();
          final noteId = note.id!;
          await notesProvider.trashNote(noteId);
          onNoteChanged();
          if (!context.mounted) return;
          UnifiedNotificationService().showWithUndo(
            context: context,
            message: '${l10n.movedTo} "${note.title}" ${l10n.toTrash}',
            actionKey: 'swipe_trash_archive_$noteId',
            type: NotificationType.info,
            onExecute: () {},
            onUndo: () async {
              await notesProvider.restoreNote(noteId);
              await notesProvider.archiveNote(noteId);
              onNoteChanged();
            },
            undoLabel: l10n.undo,
          );
        };
        break;
      default:
        return const SizedBox.shrink();
    }

    return CustomSlidableAction(
      onPressed: (_) => onTap(),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      borderRadius: borderRadius,
      child: Align(
        alignment: borderRadius ==
                const BorderRadius.horizontal(right: Radius.circular(16))
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Padding(
          padding: borderRadius ==
                  const BorderRadius.horizontal(right: Radius.circular(16))
              ? const EdgeInsets.only(right: 8)
              : const EdgeInsets.only(left: 8),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: Colors.white),
          ),
        ),
      ),
    );
  }
}


class _PermanentDeleteSheet extends StatelessWidget {
  final Note note;
  const _PermanentDeleteSheet({required this.note});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AppBottomSheet(
      scrollable: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  size: 36, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.permanentDelete,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.confirmPermanentDelete,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
