// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/auth/pin_lock_screen.dart';
import 'package:sinan_note/screens/shared/settings/settings_dialogs.dart';
import 'package:sinan_note/screens/shared/settings/settings_utils.dart';
import 'package:sinan_note/screens/shared/settings/widgets/settings_section_card.dart';
import 'package:sinan_note/services/security/biometric_service.dart';
import 'package:sinan_note/services/security/unified_lock_service.dart';

class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SettingsSectionCard(
      title: l10n.security,
      icon: Icons.shield_rounded,
      children: [
        SwitchListTile(
          secondary: Icon(Icons.lock_rounded, color: primaryColor),
          title: Text(l10n.appLock),
          subtitle:
              Text(settings.isAppLockEnabled ? l10n.enabled : l10n.disabled),
          value: settings.isAppLockEnabled,
          onChanged: (val) async {
            if (val) {
              if (!context.mounted) return;
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => PinLockScreen(
                    isSetup: true,
                    onSuccess: () {
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                  ),
                ),
              );
              if (result == true) {
                await settings.setAppLockEnabled(true);
                await settings.setCustomPinEnabled(true);
              }
            } else {
              final lockType = await UnifiedLockService().getLockType();
              if (lockType == LockType.pin) {
                if (!context.mounted) return;
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => PinLockScreen(
                      isSetup: false,
                      isDisabling: true,
                      onSuccess: () {
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                    ),
                  ),
                );
                if (result == true) {
                  await settings.setAppLockEnabled(false);
                  await settings.setCustomPinEnabled(false);
                  await settings.setBiometricLockEnabled(false);
                }
              } else {
                final authenticated = await UnifiedLockService()
                    .authenticate(context: 'app_lock');
                UnifiedLockService().resetSession();
                if (authenticated) {
                  await settings.setAppLockEnabled(false);
                  await settings.setBiometricLockEnabled(false);
                }
              }
            }
          },
        ),
        const SizedBox(height: 8),
        // خيار البصمة — يظهر فقط إذا كان القفل مفعّلاً والجهاز يدعم البيومتري
        if (settings.isAppLockEnabled)
          FutureBuilder<bool>(
            future: BiometricService.hasBiometrics(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(Icons.fingerprint_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(l10n.unlockWithBiometric),
                    subtitle: Text(l10n.unlockWithBiometricDesc),
                    value: settings.biometricLockEnabled,
                    onChanged: (val) async {
                      if (val) {
                        final ok = await UnifiedLockService()
                            .authenticate(context: 'app_lock');
                        if (ok) await settings.setBiometricLockEnabled(true);
                      } else {
                        final ok = await UnifiedLockService()
                            .authenticate(context: 'app_lock');
                        if (ok) await settings.setBiometricLockEnabled(false);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        if (settings.isAppLockEnabled)
          Column(
            children: [
              ListTile(
                leading: Icon(Icons.timer_outlined, color: primaryColor),
                title: Text(l10n.lockDelay),
                subtitle: Text(
                  settings.lockDelayEnabled
                      ? SettingsUtils.getLockDelayText(
                          settings.lockDelaySeconds, l10n)
                      : l10n.immediate,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await SettingsDialogs.showLockDelayDialog(
                      context, settings, l10n);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        SwitchListTile(
          secondary: Icon(Icons.visibility_off_rounded, color: primaryColor),
          title: Text(l10n.hideContentInBackground),
          subtitle: Text(l10n.applyBlurEffect),
          value: settings.hideContentInBackground,
          onChanged: settings.setHideContentInBackground,
        ),
      ],
    );
  }
}

