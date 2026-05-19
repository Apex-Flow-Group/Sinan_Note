// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/settings/font_family_sheet.dart';
import 'package:sinan_note/screens/shared/settings/settings_dialogs.dart';
import 'package:sinan_note/screens/shared/settings/settings_utils.dart';
import 'package:sinan_note/screens/shared/settings/widgets/hero_animation_info_sheet.dart';
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
      if (!showBetaSeparate && PlatformHelper.isMobilePlatform)
        SwitchListTile(
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_outlined, color: primary),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => HeroAnimationInfoSheet.show(context, l10n),
                child: const Icon(Icons.info_outline_rounded,
                    size: 18, color: Colors.orange),
              ),
            ],
          ),
          title: Text(l10n.heroAnimation),
          subtitle: Text(
              settings.heroAnimationEnabled ? l10n.enabled : l10n.disabled),
          value: settings.heroAnimationEnabled,
          onChanged: settings.setHeroAnimationEnabled,
        ),
      ListTile(
        leading: Icon(Icons.swipe_down_rounded, color: primary),
        title: Text(_pullToRefreshTitle(context, settings.pullToRefreshMode)),
        subtitle:
            Text(_pullToRefreshSubtitle(context, settings.pullToRefreshMode)),
        onTap: () => _showPullToRefreshDialog(context, settings),
      ),
      // ── إعدادات المحرر ──────────────────────────────────────────
      SwitchListTile(
        secondary: Icon(Icons.touch_app_rounded, color: primary),
        title: Text(l10n.doubleTapToEdit),
        subtitle: Text(l10n.doubleTapToEditDesc),
        value: settings.doubleTapToEdit,
        onChanged: settings.setDoubleTapToEdit,
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
      builder: (_) => FontFamilySheet(settings: settings, l10n: l10n),
    );
  }

  String _pullToRefreshTitle(BuildContext context, String mode) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return isAr ? 'سحب للتحديث' : 'Pull to Refresh';
  }

  String _pullToRefreshSubtitle(BuildContext context, String mode) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    switch (mode) {
      case 'full':
        return isAr ? 'تحديث كامل التطبيق' : 'Full app refresh';
      case 'normal':
        return isAr ? 'تحديث الصفحة الرئيسية فقط' : 'Home page only';
      case 'disabled':
        return isAr ? 'معطّل' : 'Disabled';
      default:
        return isAr ? 'تحديث كامل التطبيق' : 'Full app refresh';
    }
  }

  void _showPullToRefreshDialog(
      BuildContext context, SettingsProvider settings) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr ? 'سحب للتحديث' : 'Pull to Refresh',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              _PullRefreshOption(
                title: isAr ? 'تحديث كامل التطبيق' : 'Full app refresh',
                subtitle: isAr
                    ? 'مزامنة + تحديث كل البيانات + إعادة بناء الواجهة'
                    : 'Sync + reload all data + rebuild UI',
                value: 'full',
                currentValue: settings.pullToRefreshMode,
                onTap: () {
                  settings.setPullToRefreshMode('full');
                  Navigator.pop(ctx);
                },
              ),
              _PullRefreshOption(
                title: isAr ? 'تحديث الصفحة الرئيسية' : 'Home page refresh',
                subtitle: isAr
                    ? 'تحديث قائمة الملاحظات فقط'
                    : 'Refresh notes list only',
                value: 'normal',
                currentValue: settings.pullToRefreshMode,
                onTap: () {
                  settings.setPullToRefreshMode('normal');
                  Navigator.pop(ctx);
                },
              ),
              _PullRefreshOption(
                title: isAr ? 'معطّل' : 'Disabled',
                subtitle:
                    isAr ? 'تعطيل السحب للتحديث' : 'Disable pull to refresh',
                value: 'disabled',
                currentValue: settings.pullToRefreshMode,
                onTap: () {
                  settings.setPullToRefreshMode('disabled');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class BetaSection extends StatelessWidget {
  const BetaSection({super.key});

  @override
  Widget build(BuildContext context) {
    // يظهر فقط في وضع التطوير (debug) — مخفي في الإنتاج تلقائياً
    if (!kDebugMode) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    return SettingsSectionCard(
      title: 'Beta',
      icon: Icons.science_outlined,
      children: [
        SwitchListTile(
          title: Text(l10n.heroAnimation),
          subtitle: Text(
              settings.heroAnimationEnabled ? l10n.enabled : l10n.disabled),
          value: settings.heroAnimationEnabled,
          onChanged: settings.setHeroAnimationEnabled,
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_outlined),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => HeroAnimationInfoSheet.show(context, l10n),
                child: const Icon(Icons.info_outline_rounded,
                    size: 18, color: Colors.orange),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PullRefreshOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String currentValue;
  final VoidCallback onTap;

  const _PullRefreshOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.currentValue,
    required this.onTap,
  });

  IconData get _icon {
    switch (value) {
      case 'full':
        return Icons.sync_rounded;
      case 'normal':
        return Icons.refresh_rounded;
      case 'disabled':
        return Icons.sync_disabled_rounded;
      default:
        return Icons.refresh_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = value == currentValue;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _icon,
          size: 20,
          color:
              isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: colorScheme.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
