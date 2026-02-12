// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../models/note.dart';
import '../../core/utils/checklist_formatter.dart';
import '../../screens/shared/note_editor.dart';
import '../../controllers/settings/settings_provider.dart';
import '../effects/premium_card_effect.dart';

class NotesGrid extends StatelessWidget {
  final List<Note> notes;
  final Function() onRefresh;
  final Function(Note) onDelete;
  final bool showArchiveOption;
  final bool showRestoreOption;

  const NotesGrid({
    super.key,
    required this.notes,
    required this.onRefresh,
    required this.onDelete,
    this.showArchiveOption = false,
    this.showRestoreOption = false,
  });

  Widget _buildChecklistPreview(Note note, Color textColor) {
    try {
      final items = (jsonDecode(note.content) as List)
          .map((e) => ChecklistItem.fromJson(e))
          .take(3)
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                          item.isDone
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 16,
                          color: textColor.withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(item.text,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: textColor.withValues(alpha: 0.8),
                                  decoration: item.isDone
                                      ? TextDecoration.lineThrough
                                      : null),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ))
            .toList(),
      );
    } catch (e) {
      return Text(note.content,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: textColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);

    if (notes.isEmpty) {
      return Center(child: Text(l10n.noNotes));
    }

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(8),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final bool isLightColor =
            Color(note.colorIndex).computeLuminance() > 0.5;
        final Color textColor = isLightColor ? Colors.black87 : Colors.white;
        final Color contentColor =
            isLightColor ? Colors.grey[700]! : Colors.grey[300]!;

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditorImmersive(note: note),
              ),
            );
            onRefresh();
          },
          child: PremiumCardEffect(
            baseColor: Color(note.colorIndex),
            enableMotion: settings.cardMotionEnabled,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor),
                        ),
                      ),
                      if (note.isLocked)
                        Icon(Icons.lock, size: 20, color: textColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // SECURITY: Never render body for locked notes
                  note.isLocked
                      ? Text(
                          'Protected Content',
                          style: TextStyle(
                            fontSize: 14,
                            color: contentColor.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : note.noteType == 'checklist'
                          ? _buildChecklistPreview(note, textColor)
                          : Text(
                              note.content,
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(fontSize: 14, color: contentColor),
                            ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
