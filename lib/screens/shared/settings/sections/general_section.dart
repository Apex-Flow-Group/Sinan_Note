// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/shared/settings/font_family_sheet.dart';
import 'package:apex_note/screens/shared/settings/settings_dialogs.dart';
import 'package:apex_note/screens/shared/settings/settings_utils.dart';
import 'package:apex_note/screens/shared/settings/widgets/hero_animation_info_sheet.dart';
import 'package:apex_note/screens/shared/settings/widgets/settings_section_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GeneralSection extends StatelessWidget {
  final bool showBetaSeparate;
  const GeneralSection({super.key, this.showBetaSeparate = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();

    final tiles = <Widget>[
      ListTile(
        leading: const Icon(Icons.language),
        title: Text(l10n.language),
        subtitle: Text(SettingsUtils.getLanguageText(settings.languageCode, l10n)),
        onTap: () => SettingsDialogs.showLanguageDialog(context, settings, l10n),
      ),
      ListTile(
        leading: const Icon(Icons.brightness_6),
        title: Text(l10n.theme),
        subtitle: Text(SettingsUtils.getThemeText(settings.themeMode, l10n)),
        onTap: () => SettingsDialogs.showThemeDialog(context, settings),
      ),
      ListTile(
        leading: const Icon(Icons.format_size),
        title: Text(l10n.fontSize),
        subtitle: Text("${(settings.textScaleFactor * 100).round()}%"),
        trailing: SizedBox(
          width: 150,
          child: Slider(
            value: settings.textScaleFactor,
            min: 0.9,
            max: 1.4,
            divisions: 5,
            onChanged: settings.setTextScaleFactor,
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.font_download_outlined),
        title: Text(l10n.fontFamily),
        subtitle: Text(_fontFamilyLabel(settings.fontFamily, l10n)),
        onTap: () => _showFontFamilySheet(context, settings, l10n),
      ),
      if (!showBetaSeparate)
        SwitchListTile(
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_outlined),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => HeroAnimationInfoSheet.show(context, l10n),
                child: const Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange),
              ),
            ],
          ),
          title: Text(l10n.heroAnimation),
          subtitle: Text(settings.heroAnimationEnabled ? l10n.enabled : l10n.disabled),
          value: settings.heroAnimationEnabled,
          onChanged: settings.setHeroAnimationEnabled,
        ),
    ];

    return SettingsSectionCard(
      title: l10n.general,
      icon: Icons.tune_rounded,
      children: tiles,
    );
  }

  String _fontFamilyLabel(String family, AppLocalizations l10n) {
    switch (family) {
      case 'Cairo': return 'Cairo';
      case 'Tajawal': return 'Tajawal';
      default: return l10n.fontFamilySystem;
    }
  }

  void _showFontFamilySheet(BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FontFamilySheet(settings: settings, l10n: l10n),
    );
  }
}

class BetaSection extends StatelessWidget {
  const BetaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    return SettingsSectionCard(
      title: 'Beta',
      icon: Icons.science_outlined,
      children: [
        SwitchListTile(
          title: Text(l10n.heroAnimation),
          subtitle: Text(settings.heroAnimationEnabled ? l10n.enabled : l10n.disabled),
          value: settings.heroAnimationEnabled,
          onChanged: settings.setHeroAnimationEnabled,
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_outlined),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => HeroAnimationInfoSheet.show(context, l10n),
                child: const Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
