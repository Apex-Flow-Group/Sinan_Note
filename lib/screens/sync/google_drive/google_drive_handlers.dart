// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../../services/cloud/google_drive_service.dart';
import '../../../services/storage/isar_database_service.dart';
import 'google_drive_vault_warning_dialog.dart';
import '../../shared/settings/recovery_code_dialog.dart';

class GoogleDriveHandlers {
  static Future<void> handleSignOut(BuildContext context) async {
    try {
      await GoogleDriveService.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.signOutSuccess), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.signOutFailed} $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> handleSync(BuildContext context) async {
    if (!GoogleDriveService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSignIn), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final success = await GoogleDriveService.uploadDatabase(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? AppLocalizations.of(context)!.syncSuccess : AppLocalizations.of(context)!.syncFailed),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.syncFailed} $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> handleUpload(BuildContext context, {bool uploadMasterKey = false, bool uploadVault = false}) async {
    if (!GoogleDriveService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSignIn), backgroundColor: Colors.orange),
      );
      return;
    }

    // Check if there are locked notes
    try {
      final dbService = IsarDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();
      
      if (lockedNotes.isNotEmpty) {
        // Show vault warning if needed
        final shouldShowWarning = await GoogleDriveVaultWarningDialog.shouldShow();
        
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
      final success = await GoogleDriveService.uploadDatabase(context, uploadMasterKey: uploadMasterKey, uploadVault: uploadVault);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? AppLocalizations.of(context)!.uploadSuccess : AppLocalizations.of(context)!.uploadFailed),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.uploadFailed} $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static Future<void> handleDownload(BuildContext context) async {
    if (!GoogleDriveService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSignIn), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDownload),
        content: Text(AppLocalizations.of(context)!.confirmDownloadMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.download)),
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
          if (context.mounted) {
            final lang = Localizations.localeOf(context).languageCode;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(lang == 'ar' ? 'تم إلغاء التنزيل' : 'Download cancelled'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }
      
      final success = await GoogleDriveService.downloadDatabase(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? AppLocalizations.of(context)!.downloadSuccess : AppLocalizations.of(context)!.downloadFailed),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.downloadFailed} $e'), backgroundColor: Colors.red),
        );
      }
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
