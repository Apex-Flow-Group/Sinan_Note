// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/shared/settings/settings_dialogs.dart';
import 'package:apex_note/screens/shared/settings/settings_utils.dart';
import 'package:apex_note/screens/shared/settings/widgets/settings_section_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SwipeSection extends StatelessWidget {
  const SwipeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final systemLocale =
        View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system'
        ? systemLocale
        : settings.languageCode;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return SettingsSectionCard(
      title: l10n.swipeGestures,
      icon: Icons.swipe_rounded,
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.vertical_align_bottom_rounded),
          title: Text(isAr ? 'إخفاء الشريط عند السكرول' : 'Hide bar on scroll'),
          subtitle: Text(
            isAr
                ? 'يُخفي الشريط السفلي وشريط البحث عند السكرول للأسفل'
                : 'Hides bottom bar and search bar when scrolling down',
          ),
          value: settings.hideNavOnScroll,
          onChanged: settings.setHideNavOnScroll,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.swipe),
          title: Text(l10n.swipeGesturesDesc),
          subtitle: Text(settings.swipeEnabled ? l10n.enabled : l10n.disabled),
          value: settings.swipeEnabled,
          onChanged: settings.setSwipeEnabled,
        ),
        if (settings.swipeEnabled) ...[
          ListTile(
            contentPadding:
                const EdgeInsetsDirectional.only(start: 72, end: 16),
            leading: const Icon(Icons.swipe_right_rounded),
            title: Text(l10n.swipeRight),
            subtitle: Text(SettingsUtils.getSwipeActionText(
                settings.swipeRightAction, l10n)),
            trailing: Icon(
                SettingsUtils.getSwipeActionIcon(settings.swipeRightAction)),
            onTap: () => SettingsDialogs.showSwipeActionDialog(
                context, settings, true, currentLang),
          ),
          ListTile(
            contentPadding:
                const EdgeInsetsDirectional.only(start: 72, end: 16),
            leading: const Icon(Icons.swipe_left_rounded),
            title: Text(l10n.swipeLeft),
            subtitle: Text(SettingsUtils.getSwipeActionText(
                settings.swipeLeftAction, l10n)),
            trailing: Icon(
                SettingsUtils.getSwipeActionIcon(settings.swipeLeftAction)),
            onTap: () => SettingsDialogs.showSwipeActionDialog(
                context, settings, false, currentLang),
          ),
          if (settings.swipeRightAction == 'custom' ||
              settings.swipeLeftAction == 'custom')
            ListTile(
              contentPadding:
                  const EdgeInsetsDirectional.only(start: 72, end: 16),
              leading: const Icon(Icons.bolt_rounded),
              title: Text(l10n.custom),
              subtitle: Text(
                  '${settings.swipeCustomActions.length} ${l10n.selected}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => SettingsDialogs.showCustomActionsDialog(
                  context, settings, l10n),
            ),
        ],
      ],
    );
  }
}
