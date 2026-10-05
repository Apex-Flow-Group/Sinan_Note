// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';

class BackupDialogs {
  /// اختيار دمج / استبدال / إلغاء عند الاستعادة فوق ملاحظات موجودة.
  /// يُرجع 'merge' أو 'replace' أو 'cancel' (أو null عند الإغلاق).
  static Future<String?> showActionDialog(
    BuildContext context,
    AppLocalizations l10n,
    int localCount,
  ) {
    final scheme = context.scheme;
    final warning = context.colors.warning;
    return AppBottomSheet.show<String>(
      context,
      child: AppBottomSheet(
        title: l10n.restoreDataTitle,
        titleIcon: Icons.restore_rounded,
        scrollable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: warning, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.currentNotesCount(localCount),
                          style: context.text.bodyMedium),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, 'merge'),
                  icon: const Icon(Icons.merge_rounded),
                  label: Text(l10n.merge),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'replace'),
                  icon: Icon(Icons.swap_horiz_rounded, color: scheme.error),
                  label:
                      Text(l10n.replace, style: TextStyle(color: scheme.error)),
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  child: Text(l10n.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool?> showReplaceConfirmation(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showDialog<bool>(
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
  }

  static Future<void> showSuccessDialog(
    BuildContext context,
    AppLocalizations l10n,
    String message,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary, size: 50),
        title: Text(l10n.restoreSuccessful, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok))
        ],
      ),
    );
  }
}

