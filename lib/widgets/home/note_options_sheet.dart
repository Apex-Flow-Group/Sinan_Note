// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/unified_notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../models/note.dart';
import '../../services/storage/isar_database_service.dart';
import '../../screens/shared/note_editor.dart';
import '../common/custom_share_sheet.dart';

class NoteOptionsSheet {
  static void show(
    BuildContext context,
    Note note,
    VoidCallback onNoteChanged,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final dbService = IsarDatabaseService();

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
                
                if (context.mounted) {
                  UnifiedNotificationService().showWithUndo(
                    context: context,
                    message: l10n.copyCreated,
                    actionKey: 'copy_note_$newId',
                    type: NotificationType.success,
                    onExecute: () {},
                    onUndo: () async {
                      await dbService.deleteNote(newId);
                      onNoteChanged();
                    },
                    undoLabel: l10n.undo,
                  );
                }
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
                    if (context.mounted) {
                      UnifiedNotificationService().show(
                        context: context,
                        message: l10n.savedSuccessfully,
                        type: NotificationType.success,
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    UnifiedNotificationService().show(
                      context: context,
                      message: l10n.saveFailed,
                      type: NotificationType.error,
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: Text(l10n.archive),
              onTap: () async {
                Navigator.pop(ctx);
                
                // IMMEDIATE: Execute action first (Google Keep style)
                await dbService.archiveNote(note.id!);
                onNoteChanged();
                
                if (context.mounted) {
                  UnifiedNotificationService().showWithUndo(
                    context: context,
                    message: l10n.movedToArchive,
                    actionKey: 'archive_note_${note.id}',
                    type: NotificationType.success,
                    onExecute: () {},
                    onUndo: () async {
                      await dbService.unarchiveNote(note.id!);
                      onNoteChanged();
                    },
                    undoLabel: l10n.undo,
                  );
                }
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
                  // IMMEDIATE: Execute action first (Google Keep style)
                  await dbService.trashNote(note.id!);
                  onNoteChanged();
                  
                  if (context.mounted) {
                    UnifiedNotificationService().showWithUndo(
                      context: context,
                      message: l10n.movedToTrash,
                      actionKey: 'delete_note_${note.id}',
                      type: NotificationType.info,
                      onExecute: () {},
                      onUndo: () async {
                        await dbService.restoreNote(note.id!);
                        onNoteChanged();
                      },
                      undoLabel: l10n.undo,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    UnifiedNotificationService().show(
                      context: context,
                      message: l10n.deleteFailed,
                      type: NotificationType.error,
                    );
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
