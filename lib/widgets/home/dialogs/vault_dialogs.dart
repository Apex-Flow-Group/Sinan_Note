// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';

class VaultDialogs {
  static void showSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // عنوان
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.settings, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.settings,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Divider(height: 16),
              // تغيير كلمة المرور
              ListTile(
                leading: const Icon(Icons.vpn_key),
                title: Text(l10n.createPassword),
                subtitle: const Text('Change vault password'),
                onTap: () {
                  Navigator.pop(ctx);
                  showChangePassword(context);
                },
              ),
              // البيومتري
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
              const SizedBox(height: 8),
            ],
          ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // عنوان
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.vpn_key, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.createPassword,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  // الحقول
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _passwordField(
                          controller: oldCtrl,
                          label: l10n.oldPassword,
                          obscure: obscureOld,
                          onToggle: () => setModalState(() => obscureOld = !obscureOld),
                          onChanged: () => setModalState(() => errorText = null),
                        ),
                        const SizedBox(height: 12),
                        _passwordField(
                          controller: newCtrl,
                          label: l10n.newPassword,
                          obscure: obscureNew,
                          onToggle: () => setModalState(() => obscureNew = !obscureNew),
                          onChanged: () => setModalState(() => errorText = null),
                        ),
                        const SizedBox(height: 12),
                        _passwordField(
                          controller: confirmCtrl,
                          label: l10n.confirmPassword,
                          obscure: obscureConfirm,
                          onToggle: () => setModalState(() => obscureConfirm = !obscureConfirm),
                          onChanged: () => setModalState(() => errorText = null),
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 10),
                          Text(errorText!,
                              style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: l10n.cancel,
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: isLoading ? null : () async {
                                final old = oldCtrl.text;
                                final newP = newCtrl.text;
                                final confirm = confirmCtrl.text;
                                if (old.isEmpty || newP.isEmpty || confirm.isEmpty) {
                                  setModalState(() => errorText = l10n.fillAllFields);
                                  return;
                                }
                                if (newP.length < 8) {
                                  setModalState(() => errorText = 'Minimum 8 characters');
                                  return;
                                }
                                if (!RegExp(r'[0-9]').hasMatch(newP)) {
                                  setModalState(() => errorText = 'Must contain at least one number');
                                  return;
                                }
                                if (!RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.<>/?\\|`~"]').hasMatch(newP)) {
                                  setModalState(() => errorText = 'Must contain at least one symbol');
                                  return;
                                }
                                if (newP != confirm) {
                                  setModalState(() => errorText = l10n.passwordMismatch);
                                  return;
                                }
                                setModalState(() => isLoading = true);
                                final success = await VaultService.changePassword(old, newP);
                                if (success && context.mounted) {
                                  Navigator.pop(ctx);
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
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.check_rounded),
                              tooltip: l10n.save,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
