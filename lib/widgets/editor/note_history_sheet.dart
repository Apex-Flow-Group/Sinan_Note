// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import '../../services/unified_notification_service.dart';
import 'package:flutter/services.dart';
import '../../models/note_version.dart';
import '../../services/storage/isar_database_service.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../core/utils/checklist_formatter.dart';

class NoteHistorySheet extends StatelessWidget {
  final int noteId;

  const NoteHistorySheet({super.key, required this.noteId});

  static void show(BuildContext context, int noteId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NoteHistorySheet(noteId: noteId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.history_edu, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.noteHistory,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<NoteVersion>>(
                  future: IsarDatabaseService().getNoteHistory(noteId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final history = snapshot.data!;

                    if (history.isEmpty) {
                      return Center(
                          child:
                              Text(AppLocalizations.of(context)!.noHistoryYet));
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final date = item.timestamp;
                        final isCreate = item.action == 'create';
                        final contentPreview =
                            item.content.replaceAll('\n', ' ');

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                isCreate ? Colors.green[100] : Colors.blue[100],
                            child: Icon(
                              isCreate ? Icons.add_circle_outline : Icons.edit,
                              color: isCreate ? Colors.green : Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            isCreate
                                ? AppLocalizations.of(context)!.created
                                : AppLocalizations.of(context)!.edit,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${date.year}-${date.month}-${date.day}  ${date.hour}:${date.minute}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                contentPreview,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              String textToCopy;
                              if (ChecklistFormatter.isValidChecklist(item.content)) {
                                textToCopy = ChecklistFormatter.formatForSharing('', item.content);
                              } else {
                                textToCopy = item.content;
                              }
                              Clipboard.setData(ClipboardData(text: textToCopy));
                              Navigator.pop(context);
                              UnifiedNotificationService().show(
                                context: context,
                                message: AppLocalizations.of(context)!.copiedOldVersion,
                                type: NotificationType.success,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
