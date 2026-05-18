// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/screens/shared/settings/backup_messages.dart';
import 'package:sinan_note/screens/shared/settings/recovery_code_dialog.dart';
import 'package:sinan_note/services/unified_notification_service.dart';

class RecoveryDialogHandler {
  static Future<bool> handleRecoveryIfNeeded({
    required BuildContext context,
    required bool hasVaultData,
    required String lang,
    String operation = 'import',
  }) async {
    if (!hasVaultData) return true;

    if (!context.mounted) return false;

    final recovered = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const RecoveryCodeDialog(),
    );

    if (recovered != true) {
      if (!context.mounted) return false;
      UnifiedNotificationService().show(
        context: context,
        message: BackupMessages.getCancelMessage(lang, operation),
        type: NotificationType.warning,
      );
      return false;
    }

    return true;
  }
}

