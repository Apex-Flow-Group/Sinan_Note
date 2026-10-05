// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';

class GoogleDriveVaultWarningDialog extends StatefulWidget {
  const GoogleDriveVaultWarningDialog({super.key});

  @override
  State<GoogleDriveVaultWarningDialog> createState() =>
      _GoogleDriveVaultWarningDialogState();

  /// Check if warning should be shown
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('google_drive_vault_warning_shown') ?? false);
  }
}

class _GoogleDriveVaultWarningDialogState
    extends State<GoogleDriveVaultWarningDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vault = context.colors.vault;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: vault, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.disclaimer,
              style: context.text.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main warning message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: vault.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: vault, width: 2),
              ),
              child: Text(
                l10n.googleDriveVaultWarning,
                style: context.text.bodyMedium?.copyWith(height: 1.6),
              ),
            ),

            const SizedBox(height: 16),

            // Don't show again checkbox
            CheckboxListTile(
              value: _dontShowAgain,
              onChanged: (val) => setState(() => _dontShowAgain = val ?? false),
              title: Text(
                l10n.dontShowAgain,
                style: context.text.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_dontShowAgain) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('google_drive_vault_warning_shown', true);
            }
            if (context.mounted) {
              Navigator.pop(context, true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: vault,
            foregroundColor: context.colors.onVault,
          ),
          child: Text(l10n.continueAction),
        ),
      ],
    );
  }
}
