// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/feature_info.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final _vaultPasswordFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[a-zA-Z0-9!@#$%^&*()\-_=+\[\]{};:\x27",./<>?\\|`~]'),
);

String? validateVaultPassword(String password) {
  if (password.length < 8) return 'Minimum 8 characters';
  if (!RegExp(r'[0-9]').hasMatch(password)) return 'Must contain at least one number';
  if (!RegExp(r'[!@#$%^&*()\-_=+\[\]{};:\x27",./<>?\\|`~]').hasMatch(password)) {
    return 'Must contain at least one symbol';
  }
  return null;
}

class VaultFeaturesPage extends StatelessWidget {
  final bool isDark;
  final List<FeatureInfo> features;
  const VaultFeaturesPage({super.key, required this.isDark, required this.features});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _FeatureCard(feature: f, isDark: isDark),
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final FeatureInfo feature;
  final bool isDark;
  const _FeatureCard({required this.feature, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: feature.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: feature.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(feature.icon, color: feature.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(feature.description,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VaultPasswordPage extends StatelessWidget {
  final bool isDark;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final String? errorText;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onChanged;

  const VaultPasswordPage({
    super.key,
    required this.isDark,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    this.errorText,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vpn_key, size: 50, color: Colors.purple),
          ),
          const SizedBox(height: 24),
          Text(l10n.createPassword,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          // hint للمتطلبات
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '• Min 8 characters\n• At least one number (0-9)\n• At least one symbol (!@#\$...)\n• English letters only',
              style: TextStyle(fontSize: 12, color: Colors.purple),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [_vaultPasswordFormatter],
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: l10n.enterPassword,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: onTogglePassword,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmController,
            obscureText: obscureConfirm,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [_vaultPasswordFormatter],
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: l10n.confirmPassword,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                onPressed: onToggleConfirm,
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 14)),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class VaultRecoveryPage extends StatelessWidget {
  final bool isDark;
  final String? recoveryCode;
  final bool codeSaved;
  final bool hasBackupInDrive;
  final String? errorText;
  final ValueChanged<bool?> onCodeSavedChanged;
  final VoidCallback onRestoreFromDrive;

  const VaultRecoveryPage({
    super.key,
    required this.isDark,
    required this.recoveryCode,
    required this.codeSaved,
    required this.hasBackupInDrive,
    this.errorText,
    required this.onCodeSavedChanged,
    required this.onRestoreFromDrive,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, size: 50, color: Colors.red),
          ),
          const SizedBox(height: 24),
          Text(l10n.recoveryCode,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: recoveryCode ?? ''));
              UnifiedNotificationService().show(
                context: context,
                message: l10n.codeCopied,
                type: NotificationType.success,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Text(
                recoveryCode ?? '',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: recoveryCode ?? ''));
                UnifiedNotificationService().show(
                  context: context,
                  message: l10n.codeCopied,
                  type: NotificationType.success,
                );
              },
              icon: const Icon(Icons.copy),
              label: Text(l10n.copyCode),
            ),
          ),
          if (hasBackupInDrive) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_download, color: Colors.blue, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l10n.vaultFoundInDrive,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRestoreFromDrive,
                      icon: const Icon(Icons.download),
                      label: Text(l10n.restoreVaultFromDrive),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              collapsedShape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.blue.withValues(alpha: 0.05),
              collapsedBackgroundColor: Colors.blue.withValues(alpha: 0.05),
              leading: const Icon(Icons.info_outline, color: Colors.blue, size: 24),
              title: Text(l10n.importantInfo,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue)),
              children: [
                Text(l10n.recoveryCodeInfo,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        height: 1.6),
                    textAlign: TextAlign.start),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: codeSaved,
            onChanged: onCodeSavedChanged,
            title: Text(l10n.iHaveSavedCode),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (errorText != null)
            Text(errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 14)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class VaultBiometricPage extends StatelessWidget {
  final bool isDark;
  const VaultBiometricPage({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fingerprint, size: 60, color: Colors.teal),
                ),
                const SizedBox(height: 40),
                Text(l10n.enableBiometric,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Text(l10n.biometricOptional,
                    style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: isDark ? Colors.grey[300] : Colors.grey[700]),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
