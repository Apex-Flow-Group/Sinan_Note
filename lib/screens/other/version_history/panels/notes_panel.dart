// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/adaptive_color.dart';
import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/note_content_utils.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/screens/mobile/home_screen.dart' show ViewType;
import 'package:apex_note/widgets/effects/premium_card_effect.dart';
import 'package:apex_note/widgets/home/note_card_utils.dart';
import 'package:flutter/material.dart';

class NotesPanel extends StatelessWidget {
  final List<Note> notes;
  final Note? selectedNote;
  final ViewType viewType;
  final String searchQuery;
  final Future<int> Function(int) getVersionCount;
  final void Function(Note) onSelectNote;

  const NotesPanel({
    super.key,
    required this.notes,
    required this.selectedNote,
    required this.viewType,
    required this.searchQuery,
    required this.getVersionCount,
    required this.onSelectNote,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty ? l10n.noHistoryYet : l10n.noResults,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 80),
      itemCount: notes.length,
      itemBuilder: (_, i) => _NoteItem(
        note: notes[i],
        isSelected: selectedNote?.id == notes[i].id,
        viewType: viewType,
        getVersionCount: getVersionCount,
        onTap: () => onSelectNote(notes[i]),
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final ViewType viewType;
  final Future<int> Function(int) getVersionCount;
  final VoidCallback onTap;

  const _NoteItem({
    required this.note,
    required this.isSelected,
    required this.viewType,
    required this.getVersionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final noteColor = AppColorPalette.palette[note.colorIndex].getColor(brightness);
    final isLight = noteColor.computeLuminance() > 0.5;
    final titleColor = isLight ? Colors.black87 : Colors.white;
    final contentColor = isLight ? Colors.grey[700]! : Colors.grey[300]!;
    final displayTitle = NoteCardUtils.getDisplayTitle(note);
    final displayContent = NoteContentUtils.toDisplayText(note.content, maxChars: 200);
    final isChecklist = ChecklistFormatter.isValidChecklist(note.content);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: PremiumCardEffect(
          baseColor: noteColor,
          enableMotion: false,
          isSelected: isSelected,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        maxLines: viewType == ViewType.listCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: titleColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<int>(
                      future: getVersionCount(note.id!),
                      builder: (_, snap) => snap.hasData
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.blue.withValues(alpha: 0.80),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.history, size: 12, color: Colors.white),
                                  const SizedBox(width: 3),
                                  Text('${snap.data}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                if (viewType == ViewType.listExpanded) ...[
                  const SizedBox(height: 8),
                  isChecklist
                      ? NoteCardUtils.buildChecklistPreview(note.content, titleColor)
                      : Text(displayContent,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: contentColor)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
