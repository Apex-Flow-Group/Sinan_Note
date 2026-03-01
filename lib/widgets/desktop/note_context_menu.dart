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

  static void show(BuildContext context, Note note, VoidCallback onNoteChanged) {
    final l10n = AppLocalizations.of(context)!;
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final selectedNoteProvider = Provider.of<SelectedNoteProvider>(context, listen: false);

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(
        overlay.size.width / 2,
        overlay.size.height / 2,
        0,
        0,
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(value: 'open', child: _item(Icons.open_in_new, l10n.open)),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'pin',
          child: _item(
            note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            note.isPinned ? l10n.unpin : l10n.pin,
          ),
        ),
        PopupMenuItem(value: 'archive', child: _item(Icons.archive_rounded, l10n.archive)),
        PopupMenuItem(value: 'share', child: _item(Icons.share_rounded, l10n.share)),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: _item(Icons.delete_rounded, l10n.delete, color: Colors.red),
        ),
      ],
    ).then((value) async {
      if (value == null) return;
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
    });
  }

  static Widget _item(IconData icon, String label, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final position = RelativeRect.fromRect(
          details.globalPosition & Size.zero,
          Offset.zero & overlay.size,
        );
        final l10n = AppLocalizations.of(context)!;
        final notesProvider = Provider.of<NotesProvider>(context, listen: false);
        final selectedNoteProvider = Provider.of<SelectedNoteProvider>(context, listen: false);

        showMenu<String>(
          context: context,
          position: position,
          items: [
            PopupMenuItem(value: 'open', child: _item(Icons.open_in_new, l10n.open)),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'pin',
              child: _item(
                note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                note.isPinned ? l10n.unpin : l10n.pin,
              ),
            ),
            PopupMenuItem(value: 'archive', child: _item(Icons.archive_rounded, l10n.archive)),
            PopupMenuItem(value: 'share', child: _item(Icons.share_rounded, l10n.share)),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: _item(Icons.delete_rounded, l10n.delete, color: Colors.red),
            ),
          ],
        ).then((value) async {
          if (value == null) return;
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
        });
      },
      child: child,
    );
  }
}
