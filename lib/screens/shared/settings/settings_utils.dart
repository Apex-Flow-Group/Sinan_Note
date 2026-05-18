// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/services/diagnostics/apex_diagnostics_engine.dart';
import 'package:sinan_note/services/unified_notification_service.dart';

class SettingsUtils {
  static String getLanguageText(String code, AppLocalizations l10n) {
    switch (code) {
      case 'ar':
        return l10n.arabic;
      case 'en':
        return l10n.english;
      default:
        return l10n.system;
    }
  }

  static String getThemeText(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.systemTheme;
      case ThemeMode.light:
        return l10n.lightTheme;
      case ThemeMode.dark:
        return l10n.darkTheme;
    }
  }

  static String getSwipeActionText(String action, AppLocalizations l10n) {
    switch (action) {
      case 'delete':    return l10n.delete;
      case 'archive':   return l10n.actionArchive;
      case 'share':     return l10n.share;
      case 'reminder':  return l10n.reminder;
      case 'category':  return l10n.categories;
      case 'duplicate': return l10n.noteCopy;
      case 'custom':    return l10n.custom;
      default:          return l10n.delete;
    }
  }

  static IconData getSwipeActionIcon(String action) {
    switch (action) {
      case 'delete':    return Icons.delete_outline_rounded;
      case 'archive':   return Icons.archive_outlined;
      case 'share':     return Icons.share_outlined;
      case 'reminder':  return Icons.alarm_rounded;
      case 'category':  return Icons.label_outlined;
      case 'duplicate': return Icons.copy_all_rounded;
      case 'custom':    return Icons.bolt_rounded;
      default:          return Icons.delete_outline_rounded;
    }
  }

  static String getLockDelayText(int seconds, AppLocalizations l10n) {
    switch (seconds) {
      case 30:
        return l10n.seconds30;
      case 120:
        return l10n.minutes2;
      case 180:
        return l10n.minutes3;
      case 300:
        return l10n.minutes5;
      default:
        return '$seconds ${l10n.seconds30.split(' ')[1]}';
    }
  }

  static void showDiagnostics(
      BuildContext context, AppLocalizations l10n, String lang) async {
    final log = await ApexDiagnosticsEngine().getErrorLog();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.errorLog),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(log,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApexDiagnosticsEngine().clearLog();
              if (!context.mounted) return;
              Navigator.pop(ctx);
              UnifiedNotificationService().show(
                context: context,
                message: l10n.cleared,
                type: NotificationType.success,
              );
            },
            child: Text(l10n.clear),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  static Widget buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

