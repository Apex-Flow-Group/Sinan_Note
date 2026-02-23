// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/shared/settings/recovery_code_dialog.dart';
import 'package:apex_note/screens/sync/google_drive/google_drive_vault_warning_dialog.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:flutter/material.dart';

class GoogleDriveHandlers {
  static Future<void> handleSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await GoogleDriveService.signOut();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.signOutSuccess), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${l10n.signOutFailed} $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  static Future<void> handleSync(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (!GoogleDriveService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.pleaseSignIn), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final success = await GoogleDriveService.uploadDatabase(null);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.syncSuccess : l10n.syncFailed),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${l10n.syncFailed} $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  static Future<void> handleUpload(BuildContext context,
      {bool uploadMasterKey = false, bool uploadVault = false}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!GoogleDriveService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.pleaseSignIn), backgroundColor: Colors.orange),
      );
      return;
    }

    // Check if there are locked notes
    try {
      final dbService = IsarDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();

      if (lockedNotes.isNotEmpty) {
        // Show vault warning if needed
        final shouldShowWarning =
            await GoogleDriveVaultWarningDialog.shouldShow();

        if (shouldShowWarning && context.mounted) {
          final agreed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const GoogleDriveVaultWarningDialog(),
          );

          if (agreed != true) return;
        }
      }
    } catch (e) {
      // Continue even if check fails
    }

    try {
      final success = await GoogleDriveService.uploadDatabase(null,
          uploadMasterKey: uploadMasterKey, uploadVault: uploadVault);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.uploadSuccess : l10n.uploadFailed),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${l10n.uploadFailed} $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  static Future<void> handleDownload(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (!GoogleDriveService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.pleaseSignIn), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDownload),
        content: Text(l10n.confirmDownloadMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.download)),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Check if downloaded backup contains vault_data
      final hasVaultData = await GoogleDriveService.checkForVaultData();

      if (hasVaultData && context.mounted) {
        // Show recovery code dialog
        final recovered = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const RecoveryCodeDialog(),
        );

        if (recovered != true) {
          if (!context.mounted) return;
          final lang = Localizations.localeOf(context).languageCode;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  lang == 'ar' ? 'تم إلغاء التنزيل' : 'Download cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      final success = await GoogleDriveService.downloadDatabase(null);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.downloadSuccess : l10n.downloadFailed),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${l10n.downloadFailed} $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  static String formatDateTime(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context)!.justNow;
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
