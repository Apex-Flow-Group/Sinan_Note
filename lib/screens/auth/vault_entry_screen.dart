// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/core/utils/vault_navigator.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/features/auth/view_models/app_lock.dart';
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
  late final AppLock _lock = context.read<AppLock>();

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

    if (await _lock.getLockType() == LockType.pin) {
      final hasPinAlready = await _lock.hasPinSet();
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
    return Scaffold(
      backgroundColor: context.scheme.surface,
      body: VaultDesktopWrapper(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: context.colors.vault.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 50,
                  color: context.colors.vault,
                ),
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(color: context.colors.vault),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.verifyingIdentity,
                style: context.text.bodyLarge
                    ?.copyWith(color: context.scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
