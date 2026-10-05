// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sinan_note/domain/vault_policy.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/widgets/copy_code_button.dart';
import 'package:sinan_note/ui/features/vault/feature_info.dart';

final _vaultPasswordFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[a-zA-Z0-9!@#$%^&*()\-_=+\[\]{};:\x27",./<>?\\|`~]'),
);

/// رسالة ما ينقص كلمة سر الخزنة، أو null إن كانت مقبولة ([VaultPolicy]).
String? validateVaultPassword(AppLocalizations l10n, String password) =>
    switch (VaultPolicy.check(password)) {
      null => null,
      PasswordIssue.tooShort => l10n.vaultPasswordTooShort,
      PasswordIssue.noDigit => l10n.vaultPasswordNeedsDigit,
      PasswordIssue.noSymbol => l10n.vaultPasswordNeedsSymbol,
      PasswordIssue.noLetter => l10n.vaultPasswordNeedsLetter,
    };

class VaultFeaturesPage extends StatelessWidget {
  final List<FeatureInfo> features;
  const VaultFeaturesPage({super.key, required this.features});

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
                child: _FeatureCard(feature: f),
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final FeatureInfo feature;
  const _FeatureCard({required this.feature});

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
                    style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.scheme.onSurface)),
                const SizedBox(height: 4),
                Text(feature.description,
                    style: context.text.bodySmall
                        ?.copyWith(color: context.colors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VaultPasswordPage extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final String? errorText;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final IconData headerIcon;

  /// لون أيقونة الرأس؛ الافتراضي `scheme.secondary`.
  final Color? headerColor;
  final String? headerTitle;

  const VaultPasswordPage({
    super.key,
    required this.passwordController,
    required this.confirmController,
    required this.obscurePassword,
    required this.obscureConfirm,
    this.errorText,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onChanged,
    required this.onSubmit,
    this.headerIcon = Icons.vpn_key,
    this.headerColor,
    this.headerTitle,
  });

  @override
  State<VaultPasswordPage> createState() => _VaultPasswordPageState();
}

class _VaultPasswordPageState extends State<VaultPasswordPage> {
  bool _hasLength = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;
  bool _passwordsMatch = false;
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _confirmFocus.dispose();
    super.dispose();
  }

  void _updateChecks() {
    final p = widget.passwordController.text;
    final c = widget.confirmController.text;
    setState(() {
      _hasLength = p.length >= 8;
      _hasNumber = RegExp(r'[0-9]').hasMatch(p);
      _hasSymbol =
          RegExp(r'[!@#$%^&*()\-_=+\[\]{};:\x27",./<>?\\|`~]').hasMatch(p);
      _passwordsMatch = p.isNotEmpty && p == c;
    });
    widget.onChanged();
  }

  Widget _req(String label, bool met) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              met ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: met
                  ? context.colors.success
                  : context.scheme.secondary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: context.text.labelMedium?.copyWith(
                    color: met
                        ? context.colors.success
                        : context.scheme.secondary.withValues(alpha: 0.8))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCompact = MediaQuery.of(context).size.height < 700;
    final headerColor = widget.headerColor ?? context.scheme.secondary;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(32, isCompact ? 12 : 32, 32, 32),
      child: Column(
        children: [
          SizedBox(height: isCompact ? 8 : 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.headerIcon, size: 50, color: headerColor),
          ),
          const SizedBox(height: 24),
          Text(widget.headerTitle ?? l10n.createPassword,
              style: context.text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: context.scheme.onSurface),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.scheme.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _req(l10n.passwordRuleMinLength, _hasLength),
                _req(l10n.passwordRuleNumber, _hasNumber),
                _req(l10n.passwordRuleSymbol, _hasSymbol),
                _req(l10n.passwordRuleMatch, _passwordsMatch),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.passwordController,
            obscureText: widget.obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [_vaultPasswordFormatter],
            textInputAction: TextInputAction.next,
            onChanged: (_) => _updateChecks(),
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_confirmFocus),
            decoration: InputDecoration(
              labelText: l10n.enterPassword,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(widget.obscurePassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: widget.onTogglePassword,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.confirmController,
            focusNode: _confirmFocus,
            obscureText: widget.obscureConfirm,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [_vaultPasswordFormatter],
            textInputAction: TextInputAction.send,
            onChanged: (_) => _updateChecks(),
            onSubmitted: (_) => widget.onSubmit(),
            decoration: InputDecoration(
              labelText: l10n.confirmPassword,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(widget.obscureConfirm
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: widget.onToggleConfirm,
              ),
            ),
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: 12),
            Text(widget.errorText!,
                style: context.text.bodyMedium
                    ?.copyWith(color: context.scheme.error)),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class VaultRecoveryPage extends StatelessWidget {
  final String? recoveryCode;
  final bool codeSaved;
  final String? errorText;
  final ValueChanged<bool?> onCodeSavedChanged;

  const VaultRecoveryPage({
    super.key,
    required this.recoveryCode,
    required this.codeSaved,
    this.errorText,
    required this.onCodeSavedChanged,
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.colors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield, size: 50, color: context.colors.danger),
          ),
          const SizedBox(height: 24),
          Text(l10n.recoveryCode,
              style: context.text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: context.scheme.onSurface),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.vault.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.vault, width: 2),
            ),
            child: Text(
              recoveryCode ?? '',
              style: context.text.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          CopyCodeButton(
            code: recoveryCode ?? '',
            label: l10n.copyCode,
          ),
          const SizedBox(height: 16),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: context.colors.info.withValues(alpha: 0.05),
              collapsedBackgroundColor:
                  context.colors.info.withValues(alpha: 0.05),
              leading: Icon(Icons.info_outline,
                  color: context.colors.info, size: 24),
              title: Text(l10n.importantInfo,
                  style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: context.colors.info)),
              children: [
                Text(l10n.recoveryCodeInfo,
                    style: context.text.bodySmall
                        ?.copyWith(color: context.colors.muted, height: 1.6),
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
                style: context.text.bodyMedium
                    ?.copyWith(color: context.scheme.error)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class VaultBiometricPage extends StatelessWidget {
  const VaultBiometricPage({super.key});

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
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: context.scheme.tertiary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.fingerprint,
                      size: 60, color: context.scheme.tertiary),
                ),
                const SizedBox(height: 40),
                Text(l10n.enableBiometric,
                    style: context.text.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.scheme.onSurface),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Text(l10n.biometricOptional,
                    style: context.text.bodyLarge?.copyWith(
                        height: 1.5, color: context.scheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
