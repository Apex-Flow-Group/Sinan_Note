// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../models/note.dart';
import '../../services/database_service.dart';
import '../../screens/note_editor.dart';
import '../apex_snackbar.dart';
import '../custom_share_sheet.dart';

class NoteOptionsSheet {
  static void show(
    BuildContext context,
    Note note,
    VoidCallback onNoteChanged,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final dbService = DatabaseService();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: 80 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.edit),
              onTap: () async {
                Navigator.pop(ctx);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteEditorImmersive(note: note),
                  ),
                );
                onNoteChanged();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l10n.copy),
              onTap: () async {
                Navigator.pop(ctx);
                final newNote = Note(
                  title: '${note.title} - ${l10n.noteCopy}',
                  content: note.content,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  colorIndex: note.colorIndex,
                );

                final newId = await dbService.insertNote(newNote);
                onNoteChanged();
                ApexSnackBar.show(
                  context,
                  l10n.copyCreated,
                  type: SnackBarType.success,
                  actionLabel: l10n.undo,
                  onAction: () async {
                    await dbService.deleteNote(newId);
                    onNoteChanged();
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(l10n.share),
              onTap: () {
                Navigator.pop(ctx);
                CustomShareSheet.show(context, '${note.title}\n\n${note.content}',
                    subject: note.title);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: Text(l10n.saveAsFile),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final result = await FilePicker.platform.getDirectoryPath();
                  if (result != null) {
                    final file = File('$result/${note.title}.txt');
                    await file
                        .writeAsString('${note.title}\n\n${note.content}');
                    ApexSnackBar.show(context, l10n.savedSuccessfully,
                        type: SnackBarType.success);
                  }
                } catch (e) {
                  ApexSnackBar.show(context, l10n.saveFailed,
                      type: SnackBarType.error);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: Text(l10n.archive),
              onTap: () async {
                Navigator.pop(ctx);
                await dbService.archiveNote(note.id!);
                onNoteChanged();
                ApexSnackBar.show(
                  context,
                  l10n.movedToArchive,
                  type: SnackBarType.success,
                  actionLabel: l10n.undo,
                  onAction: () async {
                    await dbService.unarchiveNote(note.id!);
                    onNoteChanged();
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.info),
              onTap: () async {
                Navigator.pop(ctx);
                final history = await dbService.getNoteHistory(note.id!);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.noteHistory),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: history.isEmpty
                          ? Text(l10n.noHistory)
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: history.length,
                              itemBuilder: (ctx, i) {
                                final version = history[i];
                                return ListTile(
                                  leading: const Icon(Icons.history, size: 20),
                                  title: Text(version.action),
                                  subtitle: Text(version.timestamp.toString()),
                                );
                              },
                            ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.close),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await dbService.trashNote(note.id!);
                  onNoteChanged();
                  if (context.mounted) {
                    ApexSnackBar.show(
                      context,
                      l10n.movedToTrash,
                      type: SnackBarType.success,
                      actionLabel: l10n.undo,
                      onAction: () async {
                        await dbService.restoreNote(note.id!);
                        onNoteChanged();
                      },
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ApexSnackBar.show(context, l10n.deleteFailed,
                        type: SnackBarType.error);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
