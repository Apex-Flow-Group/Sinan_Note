// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncVaultWarningWidget extends StatefulWidget {
  const SyncVaultWarningWidget({super.key});

  @override
  State<SyncVaultWarningWidget> createState() => _SyncVaultWarningWidgetState();
}

class _SyncVaultWarningWidgetState extends State<SyncVaultWarningWidget> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة التحذير
            Icon(
              Icons.info_outline,
              size: 64,
              color: theme.colorScheme.tertiary,
            ),

            const SizedBox(height: 24),

            // العنوان
            Text(
              l10n.disclaimer,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // رسالة التحذير
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Text(
                l10n.googleDriveVaultWarning,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Checkbox: لا تذكرني مرة أخرى
            CheckboxListTile(
              value: _dontShowAgain,
              onChanged: (val) => setState(() => _dontShowAgain = val ?? false),
              title: Text(
                l10n.dontShowAgain,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 24),

            // الأزرار
            Row(
              children: [
                // زر الإلغاء
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),

                const SizedBox(width: 12),

                // زر المتابعة
                Expanded(
                  child: FilledButton(
                    onPressed: _handleContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text(l10n.continueAction),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    // حفظ الإعداد إذا اختار المستخدم "لا تذكرني"
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_drive_vault_warning_shown', true);
    }

    // ⚠️ DEPRECATED: هذا الويدجت معطل - الخزنة لا تُزامن
    // الكود محفوظ للمستقبل
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
