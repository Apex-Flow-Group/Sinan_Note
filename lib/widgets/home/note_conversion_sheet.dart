// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/core/utils/quill_migration.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NoteConversionSheet {
  static void show(BuildContext context, Note note, VoidCallback onConverted) {
    final l10n = AppLocalizations.of(context)!;
    final currentType = note.noteType;

    AppBottomSheet.show(
      context,
      child: AppBottomSheet(
        title: l10n.convertTo,
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentType != 'simple')
              _buildOption(context, Icons.note, l10n.simpleNotes, 'simple',
                  note, onConverted),
            if (currentType != 'code' &&
                currentType != 'pro' &&
                !note.isProfessional)
              _buildOption(context, Icons.code, l10n.professionalNotes, 'code',
                  note, onConverted),
            if (currentType != 'rich')
              _buildOption(context, Icons.text_fields, l10n.richText, 'rich',
                  note, onConverted),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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

    // أي تحويل من rich: استخرج النص العادي من Delta أولاً
    if (QuillMigration.isDelta(note.content)) {
      final ctrl = QuillMigration.controllerFromContent(note.content);
      newContent = QuillMigration.toPlainText(ctrl);
      ctrl.dispose();
    }

    // code → rich: النص كما هو بدون code block
    // (Quill يعرض code block بخلفية داكنة غير مرغوبة)

    final updatedNote = note.copyWith(
      noteType: targetType,
      isProfessional: targetType == 'code',
      isChecklist: false,
      content: newContent,
      updatedAt: DateTime.now(),
    );

    await provider.updateNote(updatedNote);
    await provider.loadNotes(force: true);
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
