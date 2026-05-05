// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/app_bottom_sheet.dart';
import 'package:flutter/material.dart';

class VaultDialogs {
  static void showSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    AppBottomSheet.show(
      context,
      isScrollControlled: true,
      child: AppBottomSheet(
        title: l10n.settings,
        titleIcon: Icons.settings,
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: Text(l10n.createPassword),
              subtitle: const Text('Change vault password'),
              onTap: () {
                Navigator.pop(context);
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
                    Navigator.pop(context);
                    UnifiedNotificationService().show(
                      context: context,
                      message:
                          val ? 'Biometric enabled ✅' : 'Biometric disabled ❌',
                      type: NotificationType.success,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
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
    bool isLoading = false;

    AppBottomSheet.show(
      context,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AppBottomSheet(
            title: l10n.createPassword,
            titleIcon: Icons.vpn_key,
            scrollable: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _passwordField(
                    controller: oldCtrl,
                    label: l10n.oldPassword,
                    obscure: obscureOld,
                    onToggle: () =>
                        setModalState(() => obscureOld = !obscureOld),
                    onChanged: () => setModalState(() => errorText = null),
                  ),
                  const SizedBox(height: 12),
                  _passwordField(
                    controller: newCtrl,
                    label: l10n.newPassword,
                    obscure: obscureNew,
                    onToggle: () =>
                        setModalState(() => obscureNew = !obscureNew),
                    onChanged: () => setModalState(() => errorText = null),
                  ),
                  const SizedBox(height: 12),
                  _passwordField(
                    controller: confirmCtrl,
                    label: l10n.confirmPassword,
                    obscure: obscureConfirm,
                    onToggle: () =>
                        setModalState(() => obscureConfirm = !obscureConfirm),
                    onChanged: () => setModalState(() => errorText = null),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(errorText!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: l10n.cancel,
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final old = oldCtrl.text;
                                final newP = newCtrl.text;
                                final confirm = confirmCtrl.text;
                                if (old.isEmpty ||
                                    newP.isEmpty ||
                                    confirm.isEmpty) {
                                  setModalState(
                                      () => errorText = l10n.fillAllFields);
                                  return;
                                }
                                if (newP.length < 8) {
                                  setModalState(
                                      () => errorText = 'Minimum 8 characters');
                                  return;
                                }
                                if (!RegExp(r'[0-9]').hasMatch(newP)) {
                                  setModalState(() => errorText =
                                      'Must contain at least one number');
                                  return;
                                }
                                if (!RegExp(
                                        r'[!@#$%^&*()\-_=+\[\]{};:,.<>/?\\|`~"]')
                                    .hasMatch(newP)) {
                                  setModalState(() => errorText =
                                      'Must contain at least one symbol');
                                  return;
                                }
                                if (newP != confirm) {
                                  setModalState(
                                      () => errorText = l10n.passwordMismatch);
                                  return;
                                }
                                setModalState(() => isLoading = true);
                                final success =
                                    await VaultService.changePassword(
                                        old, newP);
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  UnifiedNotificationService().show(
                                    context: context,
                                    message: 'Password changed successfully',
                                    type: NotificationType.success,
                                  );
                                } else {
                                  setModalState(() {
                                    isLoading = false;
                                    errorText = l10n.incorrectPassword;
                                  });
                                }
                              },
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded),
                        tooltip: l10n.save,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
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
