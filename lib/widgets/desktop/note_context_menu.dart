// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NoteContextMenu extends StatelessWidget {
  final Note note;
  final Widget child;
  final VoidCallback onNoteChanged;

  const NoteContextMenu({
    super.key,
    required this.note,
    required this.child,
    required this.onNoteChanged,
  });

  static Future<void> show(BuildContext context, Note note, VoidCallback onNoteChanged) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _ContextSheet(note: note),
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
    final selectedNoteProvider = Provider.of<SelectedNoteProvider>(context, listen: false);

    switch (value) {
      case 'open':
        selectedNoteProvider.selectNote(note);
      case 'pin':
        await notesProvider.updateNote(note.copyWith(isPinned: !note.isPinned));
        onNoteChanged();
      case 'archive':
        if (note.id != null) {
          await notesProvider.archiveNote(note.id!);
          if (selectedNoteProvider.selectedNote?.id == note.id) {
            selectedNoteProvider.clearSelection();
          }
        }
      case 'share':
        if (context.mounted) {
          CustomShareSheet.show(
            context,
            '${note.title}\n\n${note.content}',
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
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (_) => show(context, note, onNoteChanged),
      child: child,
    );
  }
}

class _ContextSheet extends StatelessWidget {
  final Note note;
  const _ContextSheet({required this.note});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(l10n.open),
            onTap: () => Navigator.pop(context, 'open'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
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
