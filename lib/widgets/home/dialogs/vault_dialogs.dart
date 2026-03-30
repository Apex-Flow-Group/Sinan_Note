// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';

class VaultDialogs {
  static void showSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.settings, size: 24),
            const SizedBox(width: 12),
            Text(l10n.settings),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: Text(l10n.createPassword),
              subtitle: const Text('Change vault password'),
              onTap: () {
                Navigator.pop(ctx);
                showChangePassword(context);
              },
            ),
            FutureBuilder<bool>(
              future: VaultService.isBiometricEnabled(),
              builder: (context, snapshot) {
                final isEnabled = snapshot.data ?? false;
                return SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: Text(l10n.enableBiometric),
                  subtitle: Text(l10n.biometricOptional),
                  value: isEnabled,
                  onChanged: (val) async {
                    await VaultService.setBiometricEnabled(val);
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    UnifiedNotificationService().show(
                      context: context,
                      message: val ? 'Biometric enabled ✅' : 'Biometric disabled ❌',
                      type: NotificationType.success,
                    );
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.close)),
        ],
      ),
    );
  }

  static void showChangePassword(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld = true, obscureNew = true, obscureConfirm = true;
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.createPassword),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _passwordField(
                  controller: oldCtrl,
                  label: l10n.oldPassword,
                  obscure: obscureOld,
                  onToggle: () => setDialogState(() => obscureOld = !obscureOld),
                  onChanged: () => setDialogState(() => errorText = null),
                ),
                const SizedBox(height: 16),
                _passwordField(
                  controller: newCtrl,
                  label: l10n.newPassword,
                  obscure: obscureNew,
                  onToggle: () => setDialogState(() => obscureNew = !obscureNew),
                  onChanged: () => setDialogState(() => errorText = null),
                ),
                const SizedBox(height: 16),
                _passwordField(
                  controller: confirmCtrl,
                  label: l10n.confirmPassword,
                  obscure: obscureConfirm,
                  onToggle: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                  onChanged: () => setDialogState(() => errorText = null),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 14)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () async {
                final old = oldCtrl.text;
                final newP = newCtrl.text;
                final confirm = confirmCtrl.text;
                if (old.isEmpty || newP.isEmpty || confirm.isEmpty) {
                  setDialogState(() => errorText = l10n.fillAllFields);
                  return;
                }
                if (newP.length < 6) {
                  setDialogState(() => errorText = l10n.passwordMinLength);
                  return;
                }
                if (newP != confirm) {
                  setDialogState(() => errorText = l10n.passwordMismatch);
                  return;
                }
                final success = await VaultService.changePassword(old, newP);
                if (success && context.mounted) {
                  Navigator.pop(ctx);
                  UnifiedNotificationService().show(
                    context: context,
                    message: 'Password changed successfully',
                    type: NotificationType.success,
                  );
                } else {
                  setDialogState(() => errorText = l10n.incorrectPassword);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required VoidCallback onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
