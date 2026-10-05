// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/features/sync/view_models/sync_view_model.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';

/// أوامر شاشة Google Drive مع رسائلها.
abstract final class GoogleDriveHandlers {
  static Future<void> handleSignOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await _run(context, context.read<SyncViewModel>().signOut,
        success: l10n.signOutSuccess,
        failure: l10n.signOutFailed,
        needsAccount: false);
  }

  /// يدمج مع Drive إن تغيّر ثم يرفع.
  static Future<void> handleSync(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await _run(context, context.read<SyncViewModel>().sync,
        success: l10n.syncSuccess, failure: l10n.syncFailed);
  }

  /// "استخدم ما على الجهاز".
  static Future<void> handleUpload(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await _run(context, context.read<SyncViewModel>().overwriteRemote,
        success: l10n.uploadSuccess, failure: l10n.uploadFailed);
  }

  static Future<void> handleMerge(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await _run(context, context.read<SyncViewModel>().sync,
        success: l10n.mergedSuccessfully, failure: l10n.syncFailed);
  }

  /// "استخدم ما في Drive".
  static Future<void> handleDownload(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await _run(context, context.read<SyncViewModel>().replaceLocal,
        success: l10n.downloadSuccess, failure: l10n.downloadFailed);
  }

  static String formatDateTime(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return l10n.justNow;
    if (difference.inHours < 1) return l10n.minutesAgo(difference.inMinutes);
    if (difference.inDays < 1) return l10n.hoursAgo(difference.inHours);
    if (difference.inDays < 7) return l10n.daysAgo(difference.inDays);
    return DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
        .format(dateTime);
  }

  static Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    required String success,
    required String failure,
    bool needsAccount = true,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (needsAccount && !context.read<SyncViewModel>().isSignedIn) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.pleaseSignIn,
        type: NotificationType.warning,
      );
      return;
    }
    try {
      await action();
      if (!context.mounted) return;
      UnifiedNotificationService().show(
          context: context, message: success, type: NotificationType.success);
    } on Object catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: '$failure ${e is SyncException ? l10n.syncUnavailable : e}',
        type: NotificationType.error,
      );
    }
  }
}
