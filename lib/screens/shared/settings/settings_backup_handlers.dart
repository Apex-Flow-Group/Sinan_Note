// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/shared/settings/backup_dialogs.dart';
import 'package:apex_note/screens/shared/settings/database_restore_handler.dart';
import 'package:apex_note/screens/shared/settings/json_import_handler.dart';
import 'package:apex_note/services/storage/backup_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:apex_note/services/storage/storage_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SettingsBackupHandlers {
  static void showBackupDialog(
      BuildContext context, String lang, AppLocalizations l10n) async {
    if (!await _checkLockedNotes(context, lang, l10n)) return;
    if (!context.mounted) return;

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
      BuildContext context, String lang, AppLocalizations l10n) async {
    if (!await _checkLockedNotes(context, lang, l10n)) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exportJson),
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
                  final message =
                      await StorageService().exportNotesToPath(result);
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: message,
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
            const SizedBox(height: 10),
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
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom, allowedExtensions: ['json', 'isar']);
      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final isDatabase = result.files.single.name.endsWith('.isar');

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
    if (!await _checkLockedNotes(context, lang, l10n)) return;

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

  // ── Helpers ──────────────────────────────────────────────────────────────

  static Future<bool> _checkLockedNotes(
      BuildContext context, String lang, AppLocalizations l10n) async {
    try {
      final lockedNotes = await IsarDatabaseService().getLockedNotes();
      if (lockedNotes.isNotEmpty) {
        if (!context.mounted) return false;
        final agreed = await BackupDialogs.showEncryptionAgreement(
            context, l10n, lang, lockedNotes.length);
        if (agreed != true) return false;
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        UnifiedNotificationService().show(
            context: context,
            message: l10n.databaseError,
            type: NotificationType.error);
      }
      return false;
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


