// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';

class BackupDialogs {
  static Future<bool?> showEncryptionAgreement(
    BuildContext context,
    AppLocalizations l10n,
    String lang,
    int lockedCount,
  ) {
    bool agreed = false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 22),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(l10n.disclaimer,
                      style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang == 'ar'
                    ? 'لديك $lockedCount ملاحظة مقفلة.\n\nيرجى الاحتفاظ بالمفتاح الأساسي (Recovery Code)، ستحتاجه لفتح الملاحظات المقفلة.'
                    : 'You have $lockedCount locked notes.\n\nPlease keep your Master Key (Recovery Code), you will need it to unlock your notes.',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: agreed,
                onChanged: (val) => setDialogState(() => agreed = val ?? false),
                title: Text(
                  lang == 'ar' ? 'موافق' : 'I Agree',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: agreed ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: agreed ? Colors.orange : Colors.grey),
              child: Text(l10n.continueAction),
            ),
          ],
        ),
      ),
    );
  }

  /// اختيار دمج / استبدال / إلغاء عند الاستعادة فوق ملاحظات موجودة.
  /// يُرجع 'merge' أو 'replace' أو 'cancel' (أو null عند الإغلاق).
  static Future<String?> showActionDialog(
    BuildContext context,
    AppLocalizations l10n,
    String lang,
    int localCount,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AppBottomSheet.show<String>(
      context,
      child: AppBottomSheet(
        title: lang == 'ar' ? 'استعادة البيانات' : 'Restore Data',
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
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lang == 'ar'
                            ? 'لديك $localCount ملاحظة حالياً'
                            : 'You have $localCount notes currently',
                        style: const TextStyle(fontSize: 14),
                      ),
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

