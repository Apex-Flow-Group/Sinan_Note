// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/features/diagnostics/view_models/diagnostics.dart';

/// يُبلغ المستخدم بخطأ غير متوقع، مع زر لإرسال السجل.
void showUnexpectedError(BuildContext context, String operation) {
  final l10n = AppLocalizations.of(context)!;
  final scheme = Theme.of(context).colorScheme;
  final diagnostics = context.read<Diagnostics>();
  final message = switch (operation) {
    _ when operation.startsWith('DB::') => l10n.databaseError,
    _ when operation.startsWith('VAULT::') => l10n.vaultError,
    _ when operation.startsWith('SYNC::') => l10n.googleDriveSyncFailed,
    _ => l10n.unexpectedError,
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: scheme.error,
      duration: const Duration(seconds: 6),
      action: SnackBarAction(
        label: l10n.errorReportAction,
        textColor: scheme.onError,
        onPressed: diagnostics.shareErrorLog,
      ),
    ),
  );
}
