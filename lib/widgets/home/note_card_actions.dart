// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../models/note.dart';
import '../../controllers/notes/notes_provider.dart';
import '../../services/toast_service.dart';
import '../common/custom_share_sheet.dart';

class NoteCardActions {
  static Widget buildLockedNoteMenu(BuildContext context, Note note, Color titleColor, VoidCallback onNoteChanged) {
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

          if (confirmed == true) {
            await notesProvider.toggleLockStatus(note.id!, false);
            onNoteChanged();
            ToastService().showToast(
              context: context,
              message: l10n.noteUnlocked,
              type: ToastType.success,
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

          if (confirmed == true) {
            HapticFeedback.mediumImpact();
            final noteId = note.id!;
            await notesProvider.trashNote(noteId);
            onNoteChanged();
            ToastService().showToast(
              context: context,
              message: l10n.noteDeleted,
              type: ToastType.info,
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
          
          ToastService().showUndoToast(
            context: context,
            message: '${l10n.movedTo} "$noteTitle" ${l10n.toTrash}',
            actionKey: 'swipe_delete_$noteId',
            type: ToastType.info,
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
          
          ToastService().showUndoToast(
            context: context,
            message: '${l10n.movedTo} "$noteTitle" ${l10n.toArchive}',
            actionKey: 'swipe_archive_$noteId',
            type: ToastType.success,
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
          CustomShareSheet.show(context, '${note.title}\n\n${note.content}',
              subject: note.title);
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