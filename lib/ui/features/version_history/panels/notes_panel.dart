// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/text/checklist.dart';
import 'package:sinan_note/domain/text/note_text.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/theme/note_palette.dart';
import 'package:sinan_note/ui/core/widgets/effects/premium_card_effect.dart';
import 'package:sinan_note/ui/features/home/home_screen.dart' show ViewType;
import 'package:sinan_note/ui/features/home/widgets/note_card_utils.dart';

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
            Icon(Icons.history_rounded,
                size: 56, color: context.colors.muted.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty ? l10n.noHistoryYet : l10n.noResults,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: context.colors.muted),
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
    final noteColor =
        AppColorPalette.palette[note.colorIndex].getColor(brightness);
    final isLight = noteColor.computeLuminance() > 0.5;
    // حبر Material فوق لون الملاحظة: داكن فوق الفاتح، وفاتح فوق الداكن.
    final ink =
        isLight ? Typography.blackMountainView : Typography.whiteMountainView;
    final titleColor = ink.titleMedium!.color!;
    final contentColor = ink.bodySmall!.color!;
    final displayTitle = NoteCardUtils.getDisplayTitle(note);
    final displayContent = NoteText.toDisplayText(note.content, maxChars: 200);
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
                        style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: titleColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<int>(
                      future: getVersionCount(note.id!),
                      builder: (_, snap) => snap.hasData
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.80),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history,
                                      size: 12,
                                      color: context.scheme.onPrimary),
                                  const SizedBox(width: 3),
                                  Text('${snap.data}',
                                      style: context.text.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.scheme.onPrimary)),
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
                      ? NoteCardUtils.buildChecklistPreview(
                          note.content, titleColor)
                      : Text(displayContent,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodyMedium
                              ?.copyWith(color: contentColor)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
