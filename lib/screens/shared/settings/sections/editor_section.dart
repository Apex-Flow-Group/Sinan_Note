// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/shared/settings/settings_dialogs.dart';
import 'package:apex_note/screens/shared/settings/settings_utils.dart';
import 'package:apex_note/screens/shared/settings/widgets/settings_section_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditorSection extends StatelessWidget {
  const EditorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final systemLocale = View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system' ? systemLocale : settings.languageCode;

    return SettingsSectionCard(
      title: l10n.editor,
      icon: Icons.edit_note_rounded,
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.swipe),
          title: Text(l10n.swipeGestures),
          subtitle: Text(settings.swipeEnabled ? l10n.enabled : l10n.disabled),
          value: settings.swipeEnabled,
          onChanged: settings.setSwipeEnabled,
        ),
        if (settings.swipeEnabled) ...[
          ListTile(
            contentPadding: const EdgeInsetsDirectional.only(start: 72, end: 16),
            title: Text(l10n.swipeRight),
            subtitle: Text(SettingsUtils.getSwipeActionText(settings.swipeRightAction, l10n)),
            onTap: () => SettingsDialogs.showSwipeActionDialog(context, settings, true, currentLang),
          ),
          ListTile(
            contentPadding: const EdgeInsetsDirectional.only(start: 72, end: 16),
            title: Text(l10n.swipeLeft),
            subtitle: Text(SettingsUtils.getSwipeActionText(settings.swipeLeftAction, l10n)),
            onTap: () => SettingsDialogs.showSwipeActionDialog(context, settings, false, currentLang),
          ),
        ],
      ],
    );
  }
}
