// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/shared/settings/settings_dialogs.dart';
import 'package:apex_note/screens/shared/settings/settings_utils.dart';
import 'package:apex_note/screens/shared/settings/widgets/settings_section_card.dart';
import 'package:apex_note/services/security/biometric_service.dart';
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
              // تفعيل — نحاول المصادقة أولاً
              final result = await BiometricService.authenticateOrNull();
              if (result == null) {
                // الجهاز بلا حماية
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    icon: const Icon(Icons.phonelink_lock, size: 40, color: Colors.orange),
                    title: Text(l10n.deviceSecurityRequired),
                    content: Text(l10n.deviceSecurityRequiredDesc),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                );
                return;
              }
              if (result) await settings.setAppLockEnabled(true);
            } else {
              // تعطيل
              final result = await BiometricService.authenticateOrNull();
              if (result == null) {
                // الجهاز بلا حماية — نسمح مباشرة
                await settings.setAppLockEnabled(false);
                return;
              }
              if (result) await settings.setAppLockEnabled(false);
            }
          },
        ),
        if (settings.isAppLockEnabled)
          SwitchListTile(
            contentPadding: const EdgeInsetsDirectional.only(start: 72, end: 16),
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
