// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/widgets/app_bottom_sheet.dart';
import 'package:sinan_note/ui/features/notes/view_models/notes_provider.dart';

class TrashEmptySheet extends StatelessWidget {
  final List<Note> trashedNotes;
  final NotesProvider notesProvider;

  const TrashEmptySheet({
    super.key,
    required this.trashedNotes,
    required this.notesProvider,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Note> trashedNotes,
    required NotesProvider notesProvider,
  }) {
    return AppBottomSheet.show(
      context,
      child: TrashEmptySheet(
        trashedNotes: trashedNotes,
        notesProvider: notesProvider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AppBottomSheet(
      scrollable: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_forever_rounded,
                  size: 36, color: context.colors.danger),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.permanentDelete,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.confirmDeleteAll,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.notesCount(trashedNotes.length),
              style: context.text.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.danger,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      for (final note in trashedNotes) {
                        await notesProvider.deleteNote(note.id!);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
