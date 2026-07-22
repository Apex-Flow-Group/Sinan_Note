// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/settings/font_family_sheet.dart';
import 'package:sinan_note/screens/shared/settings/settings_dialogs.dart';
import 'package:sinan_note/screens/shared/settings/settings_utils.dart';
import 'package:sinan_note/screens/shared/settings/widgets/settings_section_card.dart';

class GeneralSection extends StatelessWidget {
  final bool showBetaSeparate;
  const GeneralSection({super.key, this.showBetaSeparate = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    final tiles = <Widget>[
      ListTile(
        leading: Icon(Icons.language, color: primary),
        title: Text(l10n.language),
        subtitle:
            Text(SettingsUtils.getLanguageText(settings.languageCode, l10n)),
        onTap: () =>
            SettingsDialogs.showLanguageDialog(context, settings, l10n),
      ),
      ListTile(
        leading: Icon(Icons.brightness_6, color: primary),
        title: Text(l10n.theme),
        subtitle: Text(SettingsUtils.getThemeText(settings.themeMode, l10n)),
        onTap: () => SettingsDialogs.showThemeDialog(context, settings),
      ),
      ListTile(
        leading: Icon(Icons.format_size, color: primary),
        title: Text(l10n.fontSize),
        subtitle: Text("${(settings.textScaleFactor * 100).round()}%"),
        trailing: SizedBox(
          width: 150,
          child: Slider(
            value: settings.textScaleFactor,
            min: 0.8,
            max: 1.3,
            divisions: 5,
            onChanged: settings.setTextScaleFactor,
          ),
        ),
      ),
      ListTile(
        leading: Icon(Icons.font_download_outlined, color: primary),
        title: Text(l10n.fontFamily),
        subtitle: Text(_fontFamilyLabel(settings.fontFamily, l10n)),
        onTap: () => _showFontFamilySheet(context, settings, l10n),
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
      case 'Cairo':
        return 'Cairo';
      case 'Tajawal':
        return 'Tajawal';
      default:
        return l10n.fontFamilySystem;
    }
  }

  void _showFontFamilySheet(
      BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: FontFamilySheet(settings: settings, l10n: l10n),
      ),
    );
  }
}

class BetaSection extends StatelessWidget {
  const BetaSection({super.key});

  @override
  Widget build(BuildContext context) {
    // لا توجد مميزات تجريبية حالياً
    return const SizedBox.shrink();
  }
}
