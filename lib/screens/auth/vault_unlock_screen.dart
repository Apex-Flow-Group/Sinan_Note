// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/mobile/locked_notes_screen.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final _passwordFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[a-zA-Z0-9!@#$%^&*()\-_=+\[\]{};:,.<>/?\\|`~"]'),
);

String? _validatePassword(String password) {
  if (password.length < 8) return 'Minimum 8 characters';
  if (!RegExp(r'[0-9]').hasMatch(password)) return 'Must contain at least one number';
  if (!RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.<>/?\\|`~"]').hasMatch(password)) {
    return 'Must contain at least one symbol (!@#\$...)';
  }
  return null;
}

class VaultUnlockScreen extends StatefulWidget {
  final bool biometricFailed;

  const VaultUnlockScreen({
    super.key,
    this.biometricFailed = false,
  });

  @override
  State<VaultUnlockScreen> createState() => _VaultUnlockScreenState();
}

class _VaultUnlockScreenState extends State<VaultUnlockScreen> {
  final _passwordController = TextEditingController();
  final _recoveryController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _showRecoveryMode = false;
  bool _showNewPasswordMode = false;
  bool _unlocked = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.biometricFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          UnifiedNotificationService().show(
            context: context,
            message: l10n.authenticationFailed,
            type: NotificationType.error,
          );
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _recoveryController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordUnlock() async {
    if (!mounted) return;
    final password = _passwordController.text;
    final l10n = AppLocalizations.of(context)!;

    if (password.isEmpty) {
      setState(() => _errorText = l10n.enterPassword);
      return;
    }

    final success = await VaultService.unlockWithPassword(password);
    if (!mounted) return;

    if (success) {
      _navigateToVault();
    } else {
      setState(() => _errorText = l10n.wrongPassword);
    }
  }

  Future<void> _handleBiometricUnlock() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final authenticated = await BiometricService.authenticate();
    if (!mounted) return;

    if (authenticated) {
      _navigateToVault();
    } else {
      setState(() => _errorText = l10n.authenticationFailed);
    }
  }

  Future<void> _handleRecoveryRestore() async {
    if (!mounted) return;
    final recoveryCode = _recoveryController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (recoveryCode.isEmpty) {
      setState(() => _errorText = l10n.enterRecoveryCode);
      return;
    }

    final success = await VaultService.recoverWithCode(recoveryCode);
    if (!mounted) return;

    if (success) {
      setState(() {
        _showRecoveryMode = false;
        _showNewPasswordMode = true;
        _errorText = null;
      });
    } else {
      setState(() => _errorText = l10n.invalidRecoveryCode);
    }
  }

  Future<void> _handleSetNewPassword() async {
    if (!mounted) return;
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    final l10n = AppLocalizations.of(context)!;

    final validationError = _validatePassword(newPassword);
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    if (newPassword != confirm) {
      setState(() => _errorText = l10n.passwordMismatch);
      return;
    }

    final success = await VaultService.changePassword('', newPassword);
    if (!mounted) return;

    if (success) {
      _navigateToVault();
    } else {
      setState(() => _errorText = 'Failed to set new password');
    }
  }

  void _navigateToVault() async {
    setState(() => _unlocked = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LockedNotesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.locked),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _unlocked
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _unlocked ? Icons.lock_open : Icons.lock_outline,
                    key: ValueKey(_unlocked),
                    size: 50,
                    color: _unlocked ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (!_showRecoveryMode && !_showNewPasswordMode)
                _buildPasswordMode(l10n)
              else if (_showRecoveryMode)
                _buildRecoveryMode(l10n)
              else
                _buildNewPasswordMode(l10n),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordMode(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.enterVaultPassword,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [_passwordFormatter],
          decoration: InputDecoration(
            labelText: l10n.enterPassword,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onChanged: (_) => setState(() => _errorText = null),
          onSubmitted: (_) => _handlePasswordUnlock(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _handlePasswordUnlock,
            icon: const Icon(Icons.lock_open),
            label: Text(l10n.unlock,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<bool>(
          future: BiometricService.hasBiometrics(),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return OutlinedButton.icon(
                onPressed: _handleBiometricUnlock,
                icon: const Icon(Icons.fingerprint),
                label: Text(l10n.authenticateWithBiometric),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _showRecoveryMode = true;
            _errorText = null;
          }),
          child: Text(l10n.forgotPassword),
        ),
      ],
    );
  }

  Widget _buildRecoveryMode(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.recoverVault,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(l10n.enterRecoveryCode,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        TextField(
          controller: _recoveryController,
          decoration: InputDecoration(
            labelText: l10n.recoveryCode,
            hintText: 'SN-XXXX-XXXX-XXXX',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.vpn_key),
          ),
          onChanged: (_) => setState(() => _errorText = null),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _handleRecoveryRestore,
            icon: const Icon(Icons.restore),
            label: Text(l10n.restore,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _showRecoveryMode = false;
            _errorText = null;
          }),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }

  Widget _buildNewPasswordMode(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 60, color: Colors.green),
        const SizedBox(height: 16),
        Text(l10n.vaultRecovered,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(l10n.setNewPassword,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '• Min 8 characters\n• At least one number (0-9)\n• At least one symbol (!@#\$...)\n• English letters only',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [_passwordFormatter],
          decoration: InputDecoration(
            labelText: l10n.enterPassword,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          onChanged: (_) => setState(() => _errorText = null),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [_passwordFormatter],
          decoration: InputDecoration(
            labelText: l10n.confirmPassword,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          onChanged: (_) => setState(() => _errorText = null),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _handleSetNewPassword,
            icon: const Icon(Icons.check),
            label: Text(l10n.save,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}
