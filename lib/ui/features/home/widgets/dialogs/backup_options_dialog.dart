// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/widgets/custom_share_sheet.dart';
import 'package:sinan_note/ui/core/widgets/unified_notification_service.dart';
import 'package:sinan_note/ui/features/notes/view_models/notes_provider.dart';

class BackupOptionsDialog {
  static void show(BuildContext context, Map<String, String> strings) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.5,
              child: Stack(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(l10n.googleDrive),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: ctx.scheme.surfaceContainerHighest,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: Text(l10n.googleDrive),
                          content: Text(l10n.googleDriveComingSoon),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: Text(l10n.ok),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ctx.scheme.tertiary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.soon,
                        style: ctx.text.labelSmall?.copyWith(
                            color: ctx.scheme.onTertiary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: Text(l10n.share),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final allNotes = context.read<NotesProvider>().activeNotes;
                  final backup = allNotes
                      .map((n) => '${n.title}\n${n.plainText}\n---')
                      .join('\n\n');
                  CustomShareSheet.show(context, backup,
                      subject: l10n.notesBackupShareSubject(allNotes.length));
                } catch (e) {
                  if (!context.mounted) return;
                  UnifiedNotificationService.of(context).show(
                    context: context,
                    message: '${l10n.shareFailed}: $e',
                    type: NotificationType.error,
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: Text(l10n.backupServices),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: Text(l10n.backupServices),
                    content: Text(l10n.backupServicesComingSoon),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
