// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Dialog helpers for NoteEditor
class NoteEditorDialogs {
  /// Show delete confirmation dialog
  static Future<void> showDeleteDialog({
    required BuildContext context,
    required Color backgroundColor,
    required Color textColor,
    required int? noteId,
  }) async {
    HapticFeedback.heavyImpact();
    final l10n = AppLocalizations.of(context)!;

    if (noteId == null) {
      Navigator.pop(context);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(l10n.deleteNote, style: TextStyle(color: textColor)),
        content: Text(l10n.deleteConfirm, style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = Provider.of<NotesProvider>(context, listen: false);
      await provider.trashNote(noteId);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }
  }
}
