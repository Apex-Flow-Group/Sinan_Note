// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/settings/database_restore_handler.dart';
import 'package:sinan_note/screens/shared/settings/json_import_handler.dart';
import 'package:sinan_note/services/storage/backup_service.dart';
import 'package:sinan_note/services/storage/storage_service.dart';
import 'package:sinan_note/services/unified_notification_service.dart';

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
                try {
                  final outputPath =
                      await BackupService().exportDatabaseToPath(result);
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
                  await BackupService().shareDatabase();
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
              isArabic ? 'تصدير عادي (بدون مشفرة)' : 'Normal export (no encrypted)',
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
                      context: context, message: msg, type: NotificationType.success,
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
              isArabic ? 'تصدير كامل (مع المشفرة)' : 'Full export (with encrypted)',
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
                      context: context, message: msg, type: NotificationType.success,
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

  static Future<void> handleImportJSON(
      BuildContext context, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.warning),
        content: Text(l10n.replaceAllNotes),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.replace,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;

    final lang = context.mounted
        ? Localizations.localeOf(context).languageCode
        : 'en';
    if (!context.mounted) return;
    await JsonImportHandler.handle(
        context, lang, l10n, result.files.single.path!);
  }

  static Future<void> handleSmartImport(
      BuildContext context, String lang, AppLocalizations l10n) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final name = result.files.single.name;
      final isDatabase = name.endsWith('.sinannote') || name.endsWith('.db');

      if (!context.mounted) return;
      if (isDatabase) {
        await DatabaseRestoreHandler.handle(context, lang, l10n, filePath);
      } else {
        await JsonImportHandler.handle(context, lang, l10n, filePath);
      }
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
          context: context,
          message: e.toString().replaceAll('Exception:', ''),
          type: NotificationType.error);
    }
  }

  static void handleSmartRestore(
      BuildContext context, String lang, AppLocalizations l10n) async {
    try {
      final backupPath = await BackupService().pickBackupFile();
      if (backupPath == null) return;
      if (!context.mounted) return;
      await DatabaseRestoreHandler.handle(context, lang, l10n, backupPath);
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
          context: context,
          message: e.toString().replaceAll('Exception:', ''),
          type: NotificationType.error);
    }
  }

  static Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style:
          ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
      onPressed: onPressed,
    );
  }
}

