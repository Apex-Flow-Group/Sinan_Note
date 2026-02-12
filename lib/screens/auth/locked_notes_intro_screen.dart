// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../controllers/settings/settings_provider.dart';
import '../../services/security/vault_service.dart';
import '../../services/security/biometric_service.dart';
import '../../services/cloud/google_drive_service.dart';
import '../mobile/locked_notes_screen.dart';
import '../../services/unified_notification_service.dart';

class LockedNotesIntroScreen extends StatefulWidget {
  const LockedNotesIntroScreen({super.key});

  @override
  State<LockedNotesIntroScreen> createState() => _LockedNotesIntroScreenState();
}

class _LockedNotesIntroScreenState extends State<LockedNotesIntroScreen> {
  final PageController _pageController = PageController();
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

  @override
  void initState() {
    super.initState();
    _checkForDriveBackup();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final hasBio = await BiometricService.hasBiometrics();
    if (mounted) {
      setState(() => _hasBiometrics = hasBio);
    }
  }

  Future<void> _checkForDriveBackup() async {
    if (GoogleDriveService.isSignedIn) {
      final hasBackup = await GoogleDriveService.hasBackupInDrive();
      if (mounted) {
        setState(() => _hasBackupInDrive = hasBackup);
      }
    }
  }

  int get _totalPages => 4;

  List<_FeatureInfo> _getFeatures(AppLocalizations l10n) => [
        _FeatureInfo(
          icon: Icons.lock_outline,
          title: l10n.secureVault,
          description: l10n.vaultFullyEncrypted,
          color: Colors.orange,
        ),
        _FeatureInfo(
          icon: Icons.file_download_outlined,
          title: l10n.importFromInside,
          description: l10n.noLockButtonsOutside,
          color: Colors.blue,
        ),
        _FeatureInfo(
          icon: Icons.security,
          title: l10n.sessionProtection,
          description: l10n.dataEncryptedOnExit,
          color: Colors.green,
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Password page (index 1)
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
      
      // Show loading
      if (!mounted) return;
      
      // Hide keyboard first
      FocusScope.of(context).unfocus();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      // Setup vault
      try {
        final code = await VaultService.setupVault(password);
        if (mounted) Navigator.pop(context); // Close loading
        setState(() {
          _recoveryCode = code;
          _errorText = null;
        });
        _nextPage();
      } catch (e) {
        if (mounted) Navigator.pop(context); // Close loading
        setState(() => _errorText = 'Setup failed');
      }
      return;
    }
    
    // Recovery code page (index 2)
    if (_currentPage == 2) {
      if (!_codeSaved) {
        setState(() => _errorText = l10n.mustSaveCode);
        return;
      }
      // Skip biometric page if device doesn't support it
      if (!_hasBiometrics) {
        await _finishSetup(enableBiometric: false);
        return;
      }
      _nextPage();
      return;
    }
    
    // Biometric page (index 3 - last)
    if (_currentPage == _totalPages - 1) {
      await _finishSetup(enableBiometric: true);
      return;
    }
    
    _nextPage();
  }
  
  Future<void> _finishSetup({bool enableBiometric = false}) async {
    // Always save biometric preference (true or false)
    await VaultService.setBiometricEnabled(enableBiometric);
    
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.setLockedIntroSeen(true);
    
    if (mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LockedNotesScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _restoreVaultFromDrive() async {
    if (mounted) {
      UnifiedNotificationService().show(
        context: context,
        message: '⚠️ استعادة الخزنة من Drive قريباً...\nحالياً: استخدم Recovery Code',
        type: NotificationType.info,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
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
                  itemCount: _hasBiometrics ? _totalPages : _totalPages - 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildFeaturesPage(isDark);
                    if (index == 1) return _buildPasswordPage(isDark);
                    if (index == 2) return _buildRecoveryPage(isDark);
                    if (index == 3) return _buildBiometricPage(isDark);
                    return const SizedBox();
                  },
                ),
              ),
              _buildIndicators(),
              _buildBottomButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesPage(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final features = _getFeatures(l10n);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildFeatureCard(
              icon: feature.icon,
              title: feature.title,
              description: feature.description,
              color: feature.color,
              isDark: isDark,
            ),
          )),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _hasBiometrics ? _totalPages : _totalPages - 1,
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

  Widget _buildBottomButton(bool isDark) {
    final totalPages = _hasBiometrics ? _totalPages : _totalPages - 1;
    final isLastPage = _currentPage == totalPages - 1;
    final l10n = AppLocalizations.of(context)!;
    
    // تحديد حالة الزر
    bool isButtonEnabled = true;
    
    // صفحة كلمة المرور (1)
    if (_currentPage == 1) {
      isButtonEnabled = _passwordController.text.length >= 6 && 
                       _confirmController.text.length >= 6;
    }
    
    // صفحة كود الاستعادة (2)
    if (_currentPage == 2) {
      isButtonEnabled = _codeSaved && _recoveryCode != null;
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Skip button for biometric page
          if (isLastPage && _hasBiometrics)
            TextButton(
              onPressed: () async {
                await VaultService.setBiometricEnabled(false);
                final check = await VaultService.isBiometricEnabled();
                if (mounted) await _finishSetup(enableBiometric: false);
              },
              child: Text(l10n.skipBiometric),
            ),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: isButtonEnabled ? (isLastPage ? () => _finishSetup(enableBiometric: true) : _handleNext) : null,
              icon: Icon(isLastPage ? Icons.fingerprint : Icons.arrow_forward),
              label: Text(
                isLastPage ? l10n.enableBiometricAccess : (_currentPage == 2 ? l10n.continueAction : l10n.next),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPasswordPage(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vpn_key, size: 50, color: Colors.purple),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.createPassword,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
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
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
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
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(_errorText!, style: const TextStyle(color: Colors.red, fontSize: 14)),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }
  
  Widget _buildRecoveryPage(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, size: 50, color: Colors.red),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.recoveryCode,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _recoveryCode ?? ''));
                UnifiedNotificationService().show(
                  context: context,
                  message: l10n.codeCopied,
                  type: NotificationType.success,
                );
              },
              child: Text(
                _recoveryCode ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _recoveryCode ?? ''));
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
            ],
          ),
          if (_hasBackupInDrive) ...[
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
                        child: Text(
                          l10n.vaultFoundInDrive,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _restoreVaultFromDrive,
                      icon: const Icon(Icons.download),
                      label: Text(l10n.restoreVaultFromDrive),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
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
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.blue.withValues(alpha: 0.05),
              collapsedBackgroundColor: Colors.blue.withValues(alpha: 0.05),
              leading: const Icon(Icons.info_outline, color: Colors.blue, size: 24),
              title: Text(
                l10n.importantInfo,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blue),
              ),
              children: [
                Text(
                  l10n.recoveryCodeInfo,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[700], height: 1.6),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _codeSaved,
            onChanged: (val) => setState(() => _codeSaved = val ?? false),
            title: Text(l10n.iHaveSavedCode),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_errorText != null)
            Text(_errorText!, style: const TextStyle(color: Colors.red, fontSize: 14)),
        ],
      ),
    );
  }
  
  Widget _buildBiometricPage(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fingerprint, size: 60, color: Colors.teal),
          ),
          const SizedBox(height: 40),
          Text(
            l10n.enableBiometric,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.biometricOptional,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeatureInfo {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _FeatureInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
