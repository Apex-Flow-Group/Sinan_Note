// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/vault_navigator.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/services/security/unified_lock_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:flutter/material.dart';

/// نقطة الدخول الرئيسية للخزنة.
/// تتحقق من الحالة وتُفوّض التنقل لـ [VaultNavigator].
class VaultEntryScreen extends StatefulWidget {
  const VaultEntryScreen({super.key});

  @override
  State<VaultEntryScreen> createState() => _VaultEntryScreenState();
}

class _VaultEntryScreenState extends State<VaultEntryScreen> {
  @override
  void initState() {
    super.initState();
    _checkVaultStatus();
  }

  Future<void> _checkVaultStatus() async {
    final hasNewVault = await VaultService.isVaultSetup();
    if (!mounted) return;

    if (!hasNewVault) {
      VaultNavigator.toIntro(context);
      return;
    }

    final biometricEnabled = await VaultService.isBiometricEnabled();
    if (!mounted) return;

    if (biometricEnabled) {
      await _authenticateWithBiometric();
    } else {
      VaultNavigator.toUnlock(context);
    }
  }

  Future<void> _authenticateWithBiometric() async {
    // إذا تمت المصادقة مسبقاً عبر قفل التطبيق → دخول مباشر
    if (UnifiedLockService().isAuthenticatedThisSession) {
      if (!mounted) return;
      VaultNavigator.toLockedNotes(context);
      return;
    }

    final lockType = await UnifiedLockService().getLockType();
    if (!mounted) return;

    if (lockType == LockType.pin) {
      final hasPinAlready = await UnifiedLockService().hasPinSet();
      if (!mounted) return;
      VaultNavigator.toPinLock(
        context,
        isSetup: !hasPinAlready,
        onSuccess: () => VaultNavigator.toLockedNotes(context),
      );
      return;
    }

    final authenticated =
        await UnifiedLockService().authenticate(context: 'vault_entry');
    if (!mounted) return;

    if (authenticated) {
      VaultNavigator.toLockedNotes(context);
    } else {
      VaultNavigator.toUnlock(context, biometricFailed: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 50,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.verifyingIdentity,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
