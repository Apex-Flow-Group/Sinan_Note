// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/core/utils/vault_navigator.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/services/security/unified_lock_service.dart';
import 'package:sinan_note/ui/features/vault/view_models/vault_view_model.dart';
import 'package:sinan_note/widgets/layout/vault_desktop_wrapper.dart';

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
    final vault = context.read<VaultViewModel>();
    if (!await vault.isSetUp()) {
      if (mounted) VaultNavigator.toIntro(context);
      return;
    }
    // بلا فتح سريع (أو جهاز بلا بصمة): كلمة سر الخزنة
    if (!await vault.canUseBiometrics()) {
      if (mounted) VaultNavigator.toUnlock(context);
      return;
    }
    if (!mounted) return;

    if (await UnifiedLockService().getLockType() == LockType.pin) {
      final hasPinAlready = await UnifiedLockService().hasPinSet();
      if (!mounted) return;
      // toPinLock يستبدل هذه الشاشة، فالـ Navigator يُحفظ قبلها
      final navigator = Navigator.of(context);
      VaultNavigator.toPinLock(
        context,
        isSetup: !hasPinAlready,
        onSuccess: () async {
          if (await vault.unlockAfterDeviceAuth()) {
            VaultNavigator.replaceWithLockedNotes(navigator);
          } else {
            VaultNavigator.replaceWithUnlock(navigator);
          }
        },
      );
      return;
    }

    final opened = await vault.unlockWithBiometrics();
    if (!mounted) return;
    if (opened) {
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
      body: VaultDesktopWrapper(
        child: Center(
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
      ),
    );
  }
}
