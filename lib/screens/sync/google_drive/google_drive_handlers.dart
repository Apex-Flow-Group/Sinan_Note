// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/services/sync/cloud_sync_gateway.dart';
import 'package:sinan_note/services/unified_notification_service.dart';

class GoogleDriveHandlers {
  static Future<void> handleSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await CloudSyncGateway.signOut();
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
    if (!CloudSyncGateway.isSignedIn) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.pleaseSignIn,
        type: NotificationType.warning,
      );
      return;
    }

    try {
      await CloudSyncGateway.smartSync();
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
    if (!CloudSyncGateway.isSignedIn) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.pleaseSignIn,
        type: NotificationType.warning,
      );
      return;
    }

    try {
      final success = await CloudSyncGateway.upload();
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
    if (!CloudSyncGateway.isSignedIn) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.pleaseSignIn,
        type: NotificationType.warning,
      );
      return;
    }
    try {
      await CloudSyncGateway.silentMerge();
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
    if (!CloudSyncGateway.isSignedIn) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.pleaseSignIn,
        type: NotificationType.warning,
      );
      return;
    }

    try {
      final success = await CloudSyncGateway.download();
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context)!.justNow;
    } else if (difference.inHours < 1) {
      final m = difference.inMinutes;
      return isAr ? 'منذ $m دقيقة' : '${m}m ago';
    } else if (difference.inDays < 1) {
      final h = difference.inHours;
      return isAr ? 'منذ $h ساعة' : '${h}h ago';
    } else if (difference.inDays < 7) {
      final d = difference.inDays;
      return isAr ? 'منذ $d يوم' : '${d}d ago';
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

