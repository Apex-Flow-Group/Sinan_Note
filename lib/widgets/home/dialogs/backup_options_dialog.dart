// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:flutter/material.dart';

class BackupOptionsDialog {
  static void show(BuildContext context, Map<String, String> strings) {
    final dbService = SqliteDatabaseService();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('النسخ الاحتياطي'),
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
                      backgroundColor: Colors.grey,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: Text(l10n.googleDrive),
                          content: const Text(
                              'خدمات Google Drive ستكون متاحة قريباً في التحديث القادم.'),
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
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'قريباً',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
                  final allNotes = await dbService.getNotes();
                  if (!context.mounted) return;
                  final backup = allNotes
                      .map((n) => '${n.title}\n${n.content}\n---')
                      .join('\n\n');
                  CustomShareSheet.show(context, backup,
                      subject: 'Sinan Note Backup - ${allNotes.length} ملاحظة');
                } catch (e) {
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
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
              label: const Text('خدمات النسخ الاحتياطي'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('خدمات النسخ الاحتياطي'),
                    content: const Text(
                        'خدمات النسخ الاحتياطي والاستعادة ستكون متاحة قريباً في التحديث القادم.'),
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
