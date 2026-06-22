// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/providers/selected_note_provider.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';
import 'package:sinan_note/widgets/common/color_picker_sheet.dart';
import 'package:sinan_note/widgets/common/custom_share_sheet.dart';
import 'package:sinan_note/widgets/common/permanent_delete_sheet.dart';
import 'package:sinan_note/widgets/home/note_card_utils.dart';

class NoteContextMenu extends StatelessWidget {
  final Note note;
  final Widget child;
  final VoidCallback onNoteChanged;
  final String source;

  const NoteContextMenu({
    super.key,
    required this.note,
    required this.child,
    required this.onNoteChanged,
    this.source = 'home',
  });

  static Future<void> show(
    BuildContext context,
    Note note,
    VoidCallback onNoteChanged, {
    String source = 'home',
  }) async {
    final result = await AppBottomSheet.show<String>(
      context,
      child: _ContextSheet(note: note, source: source),
    );
    if (result == null || !context.mounted) return;
    await _handleAction(context, result, note, onNoteChanged);
  }

  static Future<void> _handleAction(
    BuildContext context,
    String value,
    Note note,
    VoidCallback onNoteChanged,
  ) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final selectedNoteProvider =
        Provider.of<SelectedNoteProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    switch (value) {
      case 'color':
        if (context.mounted) {
          final index = await ColorPickerSheet.show(
            context,
            currentIndex: note.colorIndex,
          );
          if (index != null && context.mounted) {
            final notesProvider =
                Provider.of<NotesProvider>(context, listen: false);
            await notesProvider.updateNote(note.copyWith(colorIndex: index));
            onNoteChanged();
          }
        }
      case 'open':
        selectedNoteProvider.selectNote(note);
      case 'pin':
        final wasPinned = note.isPinned;
        await notesProvider.updateNote(note.copyWith(isPinned: !wasPinned));
        onNoteChanged();
        if (!context.mounted) return;
        UnifiedNotificationService().showWithUndo(
          context: context,
          message: wasPinned ? l10n.unpin : l10n.pin,
          actionKey: 'context_pin_${note.id}',
          type: NotificationType.success,
          onExecute: () {},
          onUndo: () async {
            await notesProvider.updateNote(note.copyWith(isPinned: wasPinned));
            onNoteChanged();
          },
          undoLabel: l10n.undo,
        );
      case 'archive':
        if (note.id != null) {
          await notesProvider.archiveNote(note.id!);
          if (selectedNoteProvider.selectedNote?.id == note.id) {
            selectedNoteProvider.clearSelection();
          }
          onNoteChanged();
          if (!context.mounted) return;
          UnifiedNotificationService().showWithUndo(
            context: context,
            message: l10n.movedToArchive,
            actionKey: 'context_archive_${note.id}',
            type: NotificationType.success,
            onExecute: () {},
            onUndo: () async {
              await notesProvider.unarchiveNote(note.id!);
              onNoteChanged();
            },
            undoLabel: l10n.undo,
          );
        }
      case 'unarchive':
        if (note.id != null) {
          await notesProvider.unarchiveNote(note.id!);
          if (selectedNoteProvider.selectedNote?.id == note.id) {
            selectedNoteProvider.clearSelection();
          }
          onNoteChanged();
          if (!context.mounted) return;
          UnifiedNotificationService().showWithUndo(
            context: context,
            message: l10n.restoredToHome,
            actionKey: 'context_unarchive_${note.id}',
            type: NotificationType.success,
            onExecute: () {},
            onUndo: () async {
              await notesProvider.archiveNote(note.id!);
              onNoteChanged();
            },
            undoLabel: l10n.undo,
          );
        }
      case 'share':
        if (context.mounted) {
          final plainContent =
              NoteCardUtils.fixNoteContent(note.content, maxChars: null);
          CustomShareSheet.show(
            context,
            '${note.title}\n\n$plainContent',
            subject: note.title,
            note: note,
            onNoteCopied: () async {
              final newNote = Note(
                title: '${note.title} (نسخة)',
                content: note.content,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                colorIndex: note.colorIndex,
                noteType: note.noteType,
                isProfessional: note.isProfessional,
                isChecklist: note.isChecklist,
              );
              await notesProvider.addOrUpdateNote(newNote);
            },
          );
        }
      case 'delete':
        if (note.id != null) {
          await notesProvider.trashNote(note.id!);
          if (selectedNoteProvider.selectedNote?.id == note.id) {
            selectedNoteProvider.clearSelection();
          }
          onNoteChanged();
          if (!context.mounted) return;
          UnifiedNotificationService().showWithUndo(
            context: context,
            message: l10n.movedToTrash,
            actionKey: 'context_delete_${note.id}',
            type: NotificationType.info,
            onExecute: () {},
            onUndo: () async {
              await notesProvider.restoreNote(note.id!);
              onNoteChanged();
            },
            undoLabel: l10n.undo,
          );
        }
      case 'restore':
        if (note.id != null) {
          await notesProvider.restoreNote(note.id!);
          if (selectedNoteProvider.selectedNote?.id == note.id) {
            selectedNoteProvider.clearSelection();
          }
          onNoteChanged();
          if (!context.mounted) return;
          UnifiedNotificationService().showWithUndo(
            context: context,
            message: l10n.restoredToHome,
            actionKey: 'context_restore_${note.id}',
            type: NotificationType.success,
            onExecute: () {},
            onUndo: () async {
              await notesProvider.trashNote(note.id!);
              onNoteChanged();
            },
            undoLabel: l10n.undo,
          );
        }
      case 'permanent_delete':
        if (note.id != null && context.mounted) {
          final confirm = await AppBottomSheet.show<bool>(
            context,
            child: PermanentDeleteSheet(note: note),
          );
          if (confirm == true) {
            await notesProvider.deleteNote(note.id!);
            if (selectedNoteProvider.selectedNote?.id == note.id) {
              selectedNoteProvider.clearSelection();
            }
            onNoteChanged();
            if (!context.mounted) return;
            UnifiedNotificationService().show(
              context: context,
              message: l10n.noteDeleted,
              type: NotificationType.info,
            );
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (_) =>
          show(context, note, onNoteChanged, source: source),
      child: child,
    );
  }
}

class _ContextSheet extends StatelessWidget {
  final Note note;
  final String source;
  const _ContextSheet({required this.note, required this.source});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // في السلة: استعادة + حذف نهائي
    if (source == 'trash') {
      return AppBottomSheet(
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.green),
              title: Text(l10n.restore,
                  style: const TextStyle(color: Colors.green)),
              onTap: () => Navigator.pop(context, 'restore'),
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.delete_forever_rounded, color: Colors.red),
              title: Text(l10n.permanentDelete,
                  style: const TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'permanent_delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    // في الأرشيف: بدون تثبيت، إلغاء أرشفة بدل أرشفة
    if (source == 'archive') {
      return AppBottomSheet(
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: Text(l10n.open),
              onTap: () => Navigator.pop(context, 'open'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(l10n.chooseColor),
              onTap: () => Navigator.pop(context, 'color'),
            ),
            ListTile(
              leading: const Icon(Icons.unarchive_outlined),
              title: Text(l10n.unarchive),
              onTap: () => Navigator.pop(context, 'unarchive'),
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: Text(l10n.share),
              onTap: () => Navigator.pop(context, 'share'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title:
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    // الشاشة الرئيسية: الإجراءات الافتراضية
    return AppBottomSheet(
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(l10n.open),
            onTap: () => Navigator.pop(context, 'open'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.chooseColor),
            onTap: () => Navigator.pop(context, 'color'),
          ),
          ListTile(
            leading:
                Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
            title: Text(note.isPinned ? l10n.unpin : l10n.pin),
            onTap: () => Navigator.pop(context, 'pin'),
          ),
          ListTile(
            leading: const Icon(Icons.archive_rounded),
            title: Text(l10n.archive),
            onTap: () => Navigator.pop(context, 'archive'),
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: Text(l10n.share),
            onTap: () => Navigator.pop(context, 'share'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: Colors.red),
            title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
