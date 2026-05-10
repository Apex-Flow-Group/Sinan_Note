// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/auth/pin_lock_screen.dart';
import 'package:apex_note/screens/shared/settings/settings_dialogs.dart';
import 'package:apex_note/screens/shared/settings/settings_utils.dart';
import 'package:apex_note/screens/shared/settings/widgets/settings_section_card.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/services/security/unified_lock_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();

    return SettingsSectionCard(
      title: l10n.security,
      icon: Icons.shield_rounded,
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.lock),
          title: Text(l10n.appLock),
          subtitle: Text(settings.isAppLockEnabled ? l10n.enabled : l10n.disabled),
          value: settings.isAppLockEnabled,
          onChanged: (val) async {
            if (val) {
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PinLockScreen(
                    isSetup: true,
                    onSuccess: () async {
                      Navigator.of(context).pop();
                      await settings.setAppLockEnabled(true);
                      await settings.setCustomPinEnabled(true);
                    },
                  ),
                ),
              );
            } else {
              final lockType = await UnifiedLockService().getLockType();
              if (lockType == LockType.pin) {
                if (!context.mounted) return;
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PinLockScreen(
                      isSetup: false,
                      onSuccess: () async {
                        Navigator.of(context).pop();
                        await settings.setAppLockEnabled(false);
                        await settings.setCustomPinEnabled(false);
                        await settings.setBiometricLockEnabled(false);
                      },
                    ),
                  ),
                );
              } else {
                final authenticated = await UnifiedLockService().authenticate(context: 'app_lock');
                UnifiedLockService().resetSession();
                if (authenticated) {
                  await settings.setAppLockEnabled(false);
                  await settings.setBiometricLockEnabled(false);
                }
              }
            }
          },
        ),
        // خيار البصمة — يظهر فقط إذا كان القفل مفعّلاً والجهاز يدعم البيومتري
        if (settings.isAppLockEnabled)
          FutureBuilder<bool>(
            future: BiometricService.hasBiometrics(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return SwitchListTile(
                contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 16),
                secondary: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fingerprint, color: Colors.teal, size: 24),
                ),
                title: Text(l10n.unlockWithBiometric),
                subtitle: Text(l10n.unlockWithBiometricDesc),
                value: settings.biometricLockEnabled,
                onChanged: (val) async {
                  if (val) {
                    final ok = await UnifiedLockService().authenticate(context: 'app_lock');
                    if (ok) await settings.setBiometricLockEnabled(true);
                  } else {
                    final ok = await UnifiedLockService().authenticate(context: 'app_lock');
                    if (ok) await settings.setBiometricLockEnabled(false);
                  }
                },
              );
            },
          ),
        if (settings.isAppLockEnabled)
          SwitchListTile(
            contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 16),
            secondary: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_outlined, color: Colors.orange, size: 24),
            ),
            title: Text(l10n.lockDelay),
            subtitle: Text(settings.lockDelayEnabled
                ? SettingsUtils.getLockDelayText(settings.lockDelaySeconds, l10n)
                : l10n.immediate),
            value: settings.lockDelayEnabled,
            onChanged: (val) async {
              if (val) {
                await SettingsDialogs.showLockDelayDialog(context, settings, l10n);
              } else {
                await settings.setLockDelayEnabled(false);
              }
            },
          ),
        SwitchListTile(
          secondary: const Icon(Icons.visibility_off),
          title: Text(l10n.hideContentInBackground),
          subtitle: Text(l10n.applyBlurEffect),
          value: settings.hideContentInBackground,
          onChanged: settings.setHideContentInBackground,
        ),
      ],
    );
  }
}
