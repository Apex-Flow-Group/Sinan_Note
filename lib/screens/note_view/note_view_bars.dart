// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../models/note.dart';

class NoteViewBars {
  static Widget buildActionBar(
    BuildContext context,
    AppLocalizations l10n,
    Note note,
    VoidCallback onShare,
    VoidCallback onArchive,
    VoidCallback onDelete,
    VoidCallback onEdit,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomAppBarTheme.color ??
            Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: l10n.share,
                onPressed: onShare,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(note.isArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined),
                tooltip: note.isArchived ? l10n.unarchive : l10n.archive,
                onPressed: onArchive,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: l10n.delete,
                onPressed: onDelete,
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 20),
                  label: Text(
                    l10n.edit,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildRestoreBar(
    BuildContext context,
    AppLocalizations l10n,
    Note note,
    VoidCallback onRestore,
    VoidCallback onPermanentDelete,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        border: const Border(top: BorderSide(color: Colors.green, width: 2)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: Text(l10n.restore),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: onRestore,
            ),
            if (note.isTrashed)
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: Text(l10n.permanentDelete),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: onPermanentDelete,
              ),
          ],
        ),
      ),
    );
  }
}
