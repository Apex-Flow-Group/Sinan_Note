// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/settings/backup_restore_flow.dart';
import 'package:sinan_note/services/storage/storage_service.dart';
import 'package:sinan_note/ui/features/backup/view_models/backup_view_model.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';

class SettingsBackupHandlers {
  static void showBackupDialog(
      BuildContext context, String lang, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exportBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionButton(
              icon: Icons.save_alt,
              label: l10n.saveToFolder,
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.getDirectoryPath();
                if (result == null) {
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: l10n.noFileSelected,
                      type: NotificationType.warning);
                  return;
                }
                if (!context.mounted) return;
                try {
                  final outputPath = await context
                      .read<BackupViewModel>()
                      .exportTo(result);
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                    context: context,
                    message: '${l10n.backupSaved}\n$outputPath',
                    type: NotificationType.success,
                    duration: const Duration(seconds: 4),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: e.toString().replaceAll('Exception:', ''),
                      type: NotificationType.error);
                }
              },
            ),
            const SizedBox(height: 10),
            _actionButton(
              icon: Icons.share,
              label: l10n.share,
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await context.read<BackupViewModel>().share(
                      subject: l10n.exportBackup, text: l10n.backupSaved);
                } catch (e) {
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: e.toString().replaceAll('Exception:', ''),
                      type: NotificationType.error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showExportDialog(
      BuildContext context, String lang, AppLocalizations l10n) {
    final isArabic = lang == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exportJson),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── تصدير عادي ──
            Text(
              isArabic
                  ? 'تصدير عادي (بدون مشفرة)'
                  : 'Normal export (no encrypted)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _actionButton(
              icon: Icons.save_alt,
              label: l10n.saveToFolder,
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.getDirectoryPath();
                if (result == null) return;
                try {
                  final msg = await StorageService().exportNotesToPath(result);
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: msg,
                      type: NotificationType.success,
                      duration: const Duration(seconds: 4));
                } catch (e) {
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: e.toString().replaceAll('Exception:', ''),
                      type: NotificationType.error);
                }
              },
            ),
            const SizedBox(height: 6),
            _actionButton(
              icon: Icons.share,
              label: l10n.share,
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await StorageService().shareNotesFile();
                } catch (e) {
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: e.toString().replaceAll('Exception:', ''),
                      type: NotificationType.error);
                }
              },
            ),
            const Divider(height: 24),
            // ── تصدير كامل ──
            Text(
              isArabic
                  ? 'تصدير كامل (مع المشفرة)'
                  : 'Full export (with encrypted)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Container(
              margin: const EdgeInsets.only(top: 6, bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isArabic
                    ? 'الملاحظات المشفرة ستُصدَّر كـ ciphertext — تحتاج مفتاح الخزنة للاستعادة'
                    : 'Encrypted notes exported as ciphertext — vault key needed to restore',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
            _actionButton(
              icon: Icons.save_alt,
              label: l10n.saveToFolder,
              onPressed: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.getDirectoryPath();
                if (result == null) return;
                try {
                  final msg = await StorageService()
                      .exportNotesToPath(result, includeVault: true);
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: msg,
                      type: NotificationType.success,
                      duration: const Duration(seconds: 4));
                } catch (e) {
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: e.toString().replaceAll('Exception:', ''),
                      type: NotificationType.error);
                }
              },
            ),
            const SizedBox(height: 6),
            _actionButton(
              icon: Icons.share,
              label: l10n.share,
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await StorageService().shareNotesFile(includeVault: true);
                } catch (e) {
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: e.toString().replaceAll('Exception:', ''),
                      type: NotificationType.error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// استيراد/استعادة نسخة من أي صيغة (.db أو JSON): دمج أو استبدال.
  static Future<void> handleImportJSON(
          BuildContext context, AppLocalizations l10n) =>
      BackupRestoreFlow.pickAndRun(context);

  static Future<void> handleSmartImport(
          BuildContext context, String lang, AppLocalizations l10n) =>
      BackupRestoreFlow.pickAndRun(context);

  static Future<void> handleSmartRestore(
          BuildContext context, String lang, AppLocalizations l10n) =>
      BackupRestoreFlow.pickAndRun(context);

  static Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50)),
      onPressed: onPressed,
    );
  }
}
