// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/domain/errors.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/widgets/app_bottom_sheet.dart';
import 'package:sinan_note/ui/core/widgets/unified_notification_service.dart';
import 'package:sinan_note/ui/features/backup/view_models/backup_view_model.dart';
import 'package:sinan_note/ui/features/settings/backup_dialogs.dart';

/// استعادة نسخة احتياطية من أي صيغة (.db أو JSON): قراءة، ثم دمج أو
/// استبدال حسب اختيار المستخدم، ثم ملخص.
abstract final class BackupRestoreFlow {
  static Future<void> pickAndRun(BuildContext context) async {
    final path = await context.read<BackupViewModel>().pickFile();
    if (path == null || !context.mounted) return;
    await run(context, path);
  }

  static Future<void> run(BuildContext context, String path) async {
    final backups = context.read<BackupViewModel>();
    final l10n = AppLocalizations.of(context)!;

    final BackupContents contents;
    try {
      contents = await backups.read(path);
    } on ValidationException {
      if (context.mounted) _error(context, l10n.unsupportedBackupFile);
      return;
    }
    if (!context.mounted) return;
    if (contents.notes.isEmpty) {
      _error(context, l10n.noNotesInFile);
      return;
    }

    // بلا ملاحظات محلية لا داعي للسؤال: الدمج يضيف كل شيء
    final localCount = await backups.localNotesCount();
    if (!context.mounted) return;
    final action = localCount == 0
        ? 'merge'
        : await BackupDialogs.showActionDialog(context, l10n, localCount);
    if (action != 'merge' && action != 'replace') return;
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final String message;
      if (action == 'merge') {
        message = l10n.restoreMergedCount(await backups.merge(contents));
      } else {
        await backups.replace(contents);
        message = l10n.restoreReplacedCount(contents.notes.length);
      }
      navigator.pop();
      if (context.mounted) _success(context, l10n, message);
    } on VaultLockedException {
      navigator.pop();
      if (context.mounted) _error(context, l10n.openVaultToImportLocked);
    } on Object {
      navigator.pop();
      if (context.mounted) _error(context, l10n.failed);
    }
  }

  static void _error(BuildContext context, String message) =>
      UnifiedNotificationService().show(
          context: context, message: message, type: NotificationType.error);

  static void _success(
      BuildContext context, AppLocalizations l10n, String message) {
    AppBottomSheet.show(
      context,
      child: AppBottomSheet(
        scrollable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: context.scheme.primary, size: 56),
              const SizedBox(height: 16),
              Text(l10n.restoreSuccessful,
                  style: context.text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.scheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
