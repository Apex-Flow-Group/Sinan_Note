// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NoteConversionSheet {
  static void show(BuildContext context, Note note, VoidCallback onConverted) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currentType = note.noteType;

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
            const SizedBox(height: 16),
            Text(
              l10n.convertTo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (currentType != 'simple')
              _buildOption(ctx, Icons.note, l10n.simpleNotes, 'simple', note,
                  onConverted),
            if (currentType != 'code' &&
                currentType != 'pro' &&
                !note.isProfessional)
              _buildOption(ctx, Icons.code, l10n.professionalNotes, 'code',
                  note, onConverted),
            if (currentType != 'rich')
              _buildOption(ctx, Icons.text_fields, l10n.richText, 'rich', note,
                  onConverted),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  static Widget _buildOption(
    BuildContext ctx,
    IconData icon,
    String title,
    String targetType,
    Note note,
    VoidCallback onConverted,
  ) {
    final theme = Theme.of(ctx);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          Navigator.pop(ctx);
          await _convertNote(ctx, note, targetType, onConverted);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _convertNote(
    BuildContext context,
    Note note,
    String targetType,
    VoidCallback onConverted,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<NotesProvider>(context, listen: false);

    String newContent = note.content;

    // Code → Rich: wrap in markdown code block
    if ((note.noteType == 'code' || note.isProfessional) &&
        targetType == 'rich') {
      newContent = '```\n${note.content}\n```';
    }

    // Checklist → Rich: convert to markdown checklist
    if (note.isChecklist && targetType == 'rich') {
      newContent = note.content; // Already in markdown format
    }

    final updatedNote = note.copyWith(
      noteType: targetType,
      isProfessional: targetType == 'code',
      isChecklist: false,
      content: newContent,
      updatedAt: DateTime.now(),
    );

    await provider.updateNote(updatedNote);
    onConverted();

    if (context.mounted) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.noteConverted,
        type: NotificationType.success,
      );
    }
  }
}
