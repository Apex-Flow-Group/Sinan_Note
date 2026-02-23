// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/providers/selected_note_provider.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NoteContextMenu {
  static void show(
    BuildContext context,
    Note note,
    VoidCallback onNoteChanged,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final selectedNoteProvider = Provider.of<SelectedNoteProvider>(context, listen: false);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _buildMenuItem(ctx, Icons.visibility_rounded, l10n.viewNote, () {
              Navigator.pop(ctx);
              selectedNoteProvider.selectNote(note);
            }),
            Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            _buildMenuItem(
              ctx,
              note.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              note.isPinned ? 'Unpin' : 'Pin',
              () async {
                Navigator.pop(ctx);
                if (note.id != null) {
                  final updatedNote = note.copyWith(isPinned: !note.isPinned);
                  await notesProvider.updateNote(updatedNote);
                  onNoteChanged();
                }
              },
            ),
            _buildMenuItem(ctx, Icons.share_rounded, l10n.share, () {
              Navigator.pop(ctx);
              final shareText = '${note.title}\n\n${note.content}';
              CustomShareSheet.show(
                context,
                shareText,
                subject: note.title,
                note: note,
                onNoteCopied: () async {
                  if (note.id != null) {
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
                  }
                },
              );
            }),
            Divider(height: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            _buildMenuItem(ctx, Icons.archive_rounded, l10n.archive, () async {
              Navigator.pop(ctx);
              if (note.id != null) {
                await notesProvider.archiveNote(note.id!);
                if (selectedNoteProvider.selectedNote?.id == note.id) {
                  selectedNoteProvider.clearSelection();
                }
              }
            }),
            _buildMenuItem(
              ctx,
              Icons.delete_rounded,
              l10n.delete,
              () async {
                Navigator.pop(ctx);
                if (note.id != null) {
                  await notesProvider.trashNote(note.id!);
                  if (selectedNoteProvider.selectedNote?.id == note.id) {
                    selectedNoteProvider.clearSelection();
                  }
                }
              },
              isDestructive: true,
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  static Widget _buildMenuItem(
    BuildContext ctx,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(ctx);
    final color = isDestructive ? Colors.red : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
