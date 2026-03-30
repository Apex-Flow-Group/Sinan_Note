// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/feature_info.dart';
import 'package:apex_note/screens/auth/vault_intro_pages.dart';
import 'package:apex_note/screens/mobile/locked_notes_screen.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const double _kMaxContentWidth = 600.0;

class LockedNotesIntroScreen extends StatefulWidget {
  const LockedNotesIntroScreen({super.key});

  @override
  State<LockedNotesIntroScreen> createState() => _LockedNotesIntroScreenState();
}

class _LockedNotesIntroScreenState extends State<LockedNotesIntroScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorText;
  String? _recoveryCode;
  bool _codeSaved = false;
  bool _hasBackupInDrive = false;
  bool _hasBiometrics = false;

  int get _totalPages => 4;

  @override
  void initState() {
    super.initState();
    _checkForDriveBackup();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final hasBio = await BiometricService.hasBiometrics();
    if (mounted) setState(() => _hasBiometrics = hasBio);
  }

  Future<void> _checkForDriveBackup() async {
    if (GoogleDriveService.isSignedIn) {
      final hasBackup = await GoogleDriveService.hasBackupInDrive();
      if (mounted) setState(() => _hasBackupInDrive = hasBackup);
    }
  }

  List<FeatureInfo> _getFeatures(AppLocalizations l10n) => [
        FeatureInfo(
            icon: Icons.lock_outline,
            title: l10n.secureVault,
            description: l10n.vaultFullyEncrypted,
            color: Colors.orange),
        FeatureInfo(
            icon: Icons.file_download_outlined,
            title: l10n.importFromInside,
            description: l10n.noLockButtonsOutside,
            color: Colors.blue),
        FeatureInfo(
            icon: Icons.security,
            title: l10n.sessionProtection,
            description: l10n.dataEncryptedOnExit,
            color: Colors.green),
      ];

  Future<void> _handleNext() async {
    final l10n = AppLocalizations.of(context)!;

    if (_currentPage == 1) {
      final password = _passwordController.text;
      final confirm = _confirmController.text;
      if (password.length < 6) {
        setState(() => _errorText = l10n.passwordMinLength);
        return;
      }
      if (password != confirm) {
        setState(() => _errorText = l10n.passwordMismatch);
        return;
      }
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final code = await VaultService.setupVault(password);
        if (!mounted) return;
        Navigator.pop(context);
        setState(() {
          _recoveryCode = code;
          _errorText = null;
        });
        _nextPage();
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        setState(() => _errorText = 'Setup failed');
      }
      return;
    }

    if (_currentPage == 2) {
      if (!_codeSaved) {
        setState(() => _errorText = l10n.mustSaveCode);
        return;
      }
      if (!_hasBiometrics) {
        await _finishSetup(enableBiometric: false);
        return;
      }
      _nextPage();
      return;
    }

    if (_currentPage == _totalPages - 1) {
      await _finishSetup(enableBiometric: true);
      return;
    }

    _nextPage();
  }

  Future<void> _finishSetup({bool enableBiometric = false}) async {
    await VaultService.setBiometricEnabled(enableBiometric);
    if (!mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.setLockedIntroSeen(true);
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const LockedNotesScreen()));
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _restoreVaultFromDrive() async {
    if (mounted) {
      UnifiedNotificationService().show(
        context: context,
        message:
            '⚠️ استعادة الخزنة من Drive قريباً...\nحالياً: استخدم Recovery Code',
        type: NotificationType.info,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final pageCount = _hasBiometrics ? _totalPages : _totalPages - 1;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: _currentPage == 1 || _currentPage == 2
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      onPageChanged: (index) {
                        FocusScope.of(context).unfocus();
                        setState(() => _currentPage = index);
                      },
                      itemCount: pageCount,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return VaultFeaturesPage(
                              isDark: isDark, features: _getFeatures(l10n));
                        }
                        if (index == 1) {
                          return VaultPasswordPage(
                            isDark: isDark,
                            passwordController: _passwordController,
                            confirmController: _confirmController,
                            obscurePassword: _obscurePassword,
                            obscureConfirm: _obscureConfirm,
                            errorText: _errorText,
                            onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            onToggleConfirm: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            onChanged: () => setState(() => _errorText = null),
                          );
                        }
                        if (index == 2) {
                          return VaultRecoveryPage(
                            isDark: isDark,
                            recoveryCode: _recoveryCode,
                            codeSaved: _codeSaved,
                            hasBackupInDrive: _hasBackupInDrive,
                            errorText: _errorText,
                            onCodeSavedChanged: (val) =>
                                setState(() => _codeSaved = val ?? false),
                            onRestoreFromDrive: _restoreVaultFromDrive,
                          );
                        }
                        if (index == 3) {
                          return VaultBiometricPage(isDark: isDark);
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  _buildIndicators(pageCount),
                  _buildBottomButton(isDark, pageCount, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicators(int pageCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          pageCount,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index ? Colors.orange : Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(bool isDark, int pageCount, AppLocalizations l10n) {
    final isLastPage = _currentPage == pageCount - 1;
    final isButtonEnabled = _currentPage == 1
        ? _passwordController.text.length >= 6 &&
            _confirmController.text.length >= 6
        : _currentPage == 2
            ? _codeSaved && _recoveryCode != null
            : true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLastPage && _hasBiometrics)
            TextButton(
              onPressed: () async {
                await VaultService.setBiometricEnabled(false);
                if (mounted) await _finishSetup(enableBiometric: false);
              },
              child: Text(l10n.skipBiometric),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isButtonEnabled
                  ? (isLastPage
                      ? () => _finishSetup(enableBiometric: true)
                      : _handleNext)
                  : null,
              icon: Icon(isLastPage ? Icons.fingerprint : Icons.arrow_forward),
              label: Text(
                isLastPage
                    ? l10n.enableBiometricAccess
                    : (_currentPage == 2 ? l10n.continueAction : l10n.next),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
