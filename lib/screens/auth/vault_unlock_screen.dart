// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sinan_note/core/utils/vault_navigator.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/auth/vault_intro_pages.dart';
import 'package:sinan_note/services/security/biometric_service.dart';
import 'package:sinan_note/services/security/unified_lock_service.dart';
import 'package:sinan_note/services/security/vault_service.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';
import 'package:sinan_note/widgets/layout/vault_desktop_wrapper.dart';

final _passwordFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[a-zA-Z0-9!@#$%^&*()\-_=+\[\]{};:,.<>/?\\|`~"]'),
);

// Password validation is handled by validateVaultPassword() from vault_intro_pages.dart
// which delegates to VaultService.validatePasswordStrength() — single source of truth.

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
  bool _loading = false;
  String? _errorText;

  // نُحمّل حالة البصمة مرة واحدة في initState بدلاً من FutureBuilder
  // الذي يُعيد الاستدعاء مع كل setState
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
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

  Future<void> _loadBiometricState() async {
    final visible = await VaultService.isBiometricButtonVisible();
    final hasBio = await BiometricService.hasBiometrics();
    if (mounted) {
      setState(() => _showBiometricButton = visible && hasBio);
    }
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
    if (!mounted || _loading) return;
    final password = _passwordController.text;
    final l10n = AppLocalizations.of(context)!;

    if (password.isEmpty) {
      setState(() => _errorText = l10n.enterPassword);
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });
    final success = await VaultService.unlockWithPassword(password);
    if (!mounted) return;

    if (success) {
      _navigateToVault();
    } else {
      setState(() {
        _errorText = l10n.wrongPassword;
        _loading = false;
      });
    }
  }

  Future<void> _handleBiometricUnlock() async {
    if (!mounted || _loading) return;
    final l10n = AppLocalizations.of(context)!;

    final authenticated = await UnifiedLockService().runVaultOperation(
      () => BiometricService.authenticate(),
    );
    if (!mounted) return;

    if (authenticated) {
      try {
        await VaultService.getMasterKey();
        if (!mounted) return;
        _navigateToVault();
      } catch (_) {
        if (!mounted) return;
        setState(() => _errorText = l10n.enterPassword);
      }
    } else {
      setState(() => _errorText = l10n.authenticationFailed);
    }
  }

  Future<void> _handleRecoveryRestore() async {
    if (!mounted || _loading) return;
    final recoveryCode = _recoveryController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (recoveryCode.isEmpty) {
      setState(() => _errorText = l10n.enterRecoveryCode);
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final success = await VaultService.recoverWithCode(recoveryCode);
    if (!mounted) return;

    if (success) {
      setState(() {
        _showRecoveryMode = false;
        _showNewPasswordMode = true;
        _errorText = null;
        _loading = false;
      });
    } else {
      setState(() {
        _errorText = l10n.invalidRecoveryCode;
        _loading = false;
      });
    }
  }

  Future<void> _handleSetNewPassword() async {
    if (!mounted || _loading) return;
    final newPassword = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    final l10n = AppLocalizations.of(context)!;

    final validationError = validateVaultPassword(newPassword);
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }
    if (newPassword != confirm) {
      setState(() => _errorText = l10n.passwordMismatch);
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });
    final success = await VaultService.setPasswordAfterRecovery(newPassword);
    if (!mounted) return;

    if (success) {
      _navigateToVault();
    } else {
      setState(() {
        _errorText = AppLocalizations.of(context)!.decryptionFailed;
        _loading = false;
      });
    }
  }

  void _navigateToVault() async {
    setState(() => _unlocked = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    VaultNavigator.toLockedNotes(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.locked),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor:
              isDark ? const Color(0xFF1E1E1E) : Colors.white,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
      ),
      body: VaultDesktopWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_showNewPasswordMode) const SizedBox(height: 20),
                if (!_showRecoveryMode && !_showNewPasswordMode)
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
                if (!_showNewPasswordMode) const SizedBox(height: 32),
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
      ),
    );
  }

  Widget _buildPasswordMode(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.enterVaultPassword,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // حقل كلمة المرور
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          inputFormatters: [_passwordFormatter],
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.enterPassword,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onChanged: (_) => setState(() => _errorText = null),
          onSubmitted: (_) => _handlePasswordUnlock(),
        ),
        const SizedBox(height: 16),

        // زر الفتح
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _handlePasswordUnlock,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_open),
                    const SizedBox(width: 8),
                    Text(l10n.unlock,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ]),
          ),
        ),

        // زر البصمة — يظهر إذا كان الجهاز يدعم البيومتري ومفعّلة بالخزنة
        // _showBiometricButton يُحمَّل مرة واحدة في initState (بدلاً من FutureBuilder)
        if (_showBiometricButton)
          Column(
            children: [
              const SizedBox(height: 20),
              // فاصل
              Row(
                children: [
                  Expanded(
                      child:
                          Divider(color: Colors.grey.withValues(alpha: 0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.orText,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ),
                  Expanded(
                      child:
                          Divider(color: Colors.grey.withValues(alpha: 0.3))),
                ],
              ),
              const SizedBox(height: 16),
              // زر البصمة الواضح
              InkWell(
                onTap: _loading ? null : _handleBiometricUnlock,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.orange.withValues(alpha: 0.06),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          size: 30,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.authenticateWithBiometric,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.biometricLoginHint,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.orange.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleRecoveryRestore(),
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
          child: ElevatedButton(
            onPressed: _loading ? null : _handleRecoveryRestore,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restore),
                      const SizedBox(width: 8),
                      Text(l10n.restore,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VaultPasswordPage(
          isDark: isDark,
          passwordController: _newPasswordController,
          confirmController: _confirmPasswordController,
          obscurePassword: _obscureNew,
          obscureConfirm: _obscureConfirm,
          errorText: _errorText,
          headerIcon: Icons.check_circle,
          headerColor: Colors.green,
          headerTitle: l10n.vaultRecovered,
          onTogglePassword: () => setState(() => _obscureNew = !_obscureNew),
          onToggleConfirm: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          onChanged: () => setState(() => _errorText = null),
          onSubmit: _handleSetNewPassword,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleSetNewPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check),
                      const SizedBox(width: 8),
                      Text(l10n.save,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                    ]),
            ),
          ),
        ),
      ],
    );
  }
}
