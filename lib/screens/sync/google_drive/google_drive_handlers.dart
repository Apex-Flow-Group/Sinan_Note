// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';

class GoogleDriveHandlers {
  static Future<void> handleSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await GoogleDriveService.signOut();
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: l10n.signOutSuccess,
        type: NotificationType.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: '${l10n.signOutFailed} $e',
        type: NotificationType.error,
      );
    }
  }

  static Future<void> handleSync(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!GoogleDriveService.isSignedIn) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.pleaseSignIn,
        type: NotificationType.warning,
      );
      return;
    }

    try {
      await GoogleDriveService.smartSyncOnStartup();
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: isArabic ? 'تمت المزامنة بنجاح' : l10n.syncSuccess,
        type: NotificationType.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: '${l10n.syncFailed} $e',
        type: NotificationType.error,
      );
    }
  }

  static Future<void> handleUpload(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!GoogleDriveService.isSignedIn) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.pleaseSignIn,
        type: NotificationType.warning,
      );
      return;
    }

    try {
      final success = await GoogleDriveService.uploadDatabase(null);
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: success
            ? l10n.uploadSuccess
            : isArabic
                ? 'انتظر 30 ثانية بين كل رفع'
                : 'Wait 30s between uploads',
        type: success ? NotificationType.success : NotificationType.warning,
      );
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: '${l10n.uploadFailed} $e',
        type: NotificationType.error,
      );
    }
  }

  static Future<void> handleMerge(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (!GoogleDriveService.isSignedIn) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.pleaseSignIn,
        type: NotificationType.warning,
      );
      return;
    }
    try {
      await GoogleDriveService.silentMerge();
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: isArabic ? 'تم الدمج بنجاح' : 'Merge completed successfully',
        type: NotificationType.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: '${l10n.syncFailed} $e',
        type: NotificationType.error,
      );
    }
  }

  static Future<void> handleDownload(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (!GoogleDriveService.isSignedIn) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.pleaseSignIn,
        type: NotificationType.warning,
      );
      return;
    }

    try {
      final success = await GoogleDriveService.downloadDatabase(null);
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: success ? l10n.downloadSuccess : l10n.downloadFailed,
        type: success ? NotificationType.success : NotificationType.error,
      );
    } catch (e) {
      if (!context.mounted) return;
      if (e.toString().contains('UPDATE_REQUIRED')) {
        _showUpdateRequiredDialog(context);
        return;
      }
      UnifiedNotificationService().show(
        context: context,
        message: '${l10n.downloadFailed} $e',
        type: NotificationType.error,
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

  static void _showUpdateRequiredDialog(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.system_update, color: Colors.orange, size: 48),
        title: Text(isArabic ? 'تحديث مطلوب' : 'Update Required'),
        content: Text(
          isArabic
              ? 'بياناتك على Drive تم تحديثها بإصدار أحدث من التطبيق.\n\nحدّث التطبيق من Google Play للاستمرار في المزامنة.'
              : 'Your Drive data was updated by a newer version of the app.\n\nPlease update the app from Google Play to continue syncing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'لاحقاً' : 'Later'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(isArabic ? 'تحديث الآن' : 'Update Now'),
            onPressed: () {
              Navigator.pop(ctx);
              // رابط Google Play
              
            },
          ),
        ],
      ),
    );
  }
}
