// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/unified_notification_service.dart';

class DesktopSelectionActions extends StatelessWidget {
  final Set<int> selectedIds;
  final VoidCallback onClearSelection;

  const DesktopSelectionActions({
    super.key,
    required this.selectedIds,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.push_pin),
          onPressed: () => _handlePin(context, notesProvider, l10n),
        ),
        IconButton(
          icon: const Icon(Icons.archive),
          tooltip: l10n.archive,
          onPressed: () => _handleArchive(context, notesProvider, l10n),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: l10n.delete,
          onPressed: () => _handleDelete(context, notesProvider, l10n),
        ),
      ],
    );
  }

  Future<void> _handlePin(BuildContext context, NotesProvider notesProvider,
      AppLocalizations l10n) async {
    final ids = List<int>.from(selectedIds);
    final notesToRestore = <Note>[];

    for (final id in ids) {
      final note = notesProvider.notes.firstWhere((n) => n.id == id);
      notesToRestore.add(note);
      await notesProvider.updateNote(note.copyWith(
        isPinned: !note.isPinned,
        updatedAt: DateTime.now(),
      ));
    }

    onClearSelection();
    if (context.mounted) {
      UnifiedNotificationService().showWithUndo(
        context: context,
        message: '${ids.length} ${l10n.notesPinned}',
        actionKey: 'bulk_pin',
        type: NotificationType.success,
        onExecute: () {},
        onUndo: () async {
          for (final note in notesToRestore) {
            await notesProvider.updateNote(note);
          }
        },
        undoLabel: l10n.undo,
      );
    }
  }

  Future<void> _handleArchive(BuildContext context, NotesProvider notesProvider,
      AppLocalizations l10n) async {
    final ids = List<int>.from(selectedIds);
    await notesProvider.archiveNotes(ids);
    onClearSelection();
    if (context.mounted) {
      UnifiedNotificationService().showWithUndo(
        context: context,
        message: '${ids.length} ${l10n.notesArchived}',
        actionKey: 'bulk_archive',
        type: NotificationType.success,
        onExecute: () {},
        onUndo: () async => await notesProvider.unarchiveNotes(ids),
        undoLabel: l10n.undo,
      );
    }
  }

  Future<void> _handleDelete(BuildContext context, NotesProvider notesProvider,
      AppLocalizations l10n) async {
    final ids = List<int>.from(selectedIds);
    await notesProvider.trashNotes(ids);
    onClearSelection();
    if (context.mounted) {
      UnifiedNotificationService().showWithUndo(
        context: context,
        message: '${ids.length} ${l10n.notesDeleted}',
        actionKey: 'bulk_delete',
        type: NotificationType.info,
        onExecute: () {},
        onUndo: () async => await notesProvider.restoreNotes(ids),
        undoLabel: l10n.undo,
      );
    }
  }
}

