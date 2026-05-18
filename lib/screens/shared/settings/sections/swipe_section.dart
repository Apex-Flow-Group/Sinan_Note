// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/settings/settings_dialogs.dart';
import 'package:sinan_note/screens/shared/settings/settings_utils.dart';
import 'package:sinan_note/screens/shared/settings/widgets/settings_section_card.dart';

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
        if (!PlatformHelper.isDesktopPlatform) ...[
          // ─── شريط البحث ─────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.search_rounded),
            title: Text(isAr ? 'شريط البحث بالرئيسية' : 'Home search bar'),
            trailing: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(isAr ? 'ثابت' : 'Fixed',
                      style: const TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(isAr ? 'متحرك' : 'Animated',
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
              selected: {settings.hideSearchOnScroll},
              onSelectionChanged: (val) =>
                  settings.setHideSearchOnScroll(val.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          // ─── شريط التنقل السفلي ─────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.vertical_align_bottom_rounded),
            title: Text(isAr ? 'شريط التنقل السفلي' : 'Bottom navigation bar'),
            trailing: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(isAr ? 'ثابت' : 'Fixed',
                      style: const TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(isAr ? 'متحرك' : 'Animated',
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
              selected: {settings.hideNavOnScroll},
              onSelectionChanged: (val) =>
                  settings.setHideNavOnScroll(val.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
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
