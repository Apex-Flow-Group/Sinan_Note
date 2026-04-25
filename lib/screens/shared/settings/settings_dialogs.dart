// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SettingsDialogs {
  // ── helper مشترك ─────────────────────────────────────────────────
  static Future<void> _showSheet(
    BuildContext context, {
    required String title,
    required IconData titleIcon,
    required List<_SheetOption> options,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // مقبض
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // عنوان مع أيقونة
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(titleIcon, size: 22, color: cs.primary),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              ...options.map((o) => _OptionTile(option: o, cs: cs)),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  static void showLanguageDialog(
      BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    _showSheet(context, title: l10n.language, titleIcon: Icons.language_rounded, options: [
      _SheetOption(label: l10n.system,  icon: Icons.phone_android_rounded,  selected: settings.languageCode == 'system', onTap: () => settings.setLanguage('system')),
      _SheetOption(label: l10n.arabic,  icon: Icons.translate_rounded,       selected: settings.languageCode == 'ar',     onTap: () => settings.setLanguage('ar')),
      _SheetOption(label: l10n.english, icon: Icons.translate_rounded,       selected: settings.languageCode == 'en',     onTap: () => settings.setLanguage('en')),
    ]);
  }

  static void showThemeDialog(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    _showSheet(context, title: l10n.chooseTheme, titleIcon: Icons.palette_rounded, options: [
      _SheetOption(label: l10n.systemTheme, icon: Icons.brightness_auto_rounded,  selected: settings.themeMode == ThemeMode.system, onTap: () => settings.setThemeMode(ThemeMode.system)),
      _SheetOption(label: l10n.lightTheme,  icon: Icons.light_mode_rounded,        selected: settings.themeMode == ThemeMode.light,  onTap: () => settings.setThemeMode(ThemeMode.light)),
      _SheetOption(label: l10n.darkTheme,   icon: Icons.dark_mode_rounded,         selected: settings.themeMode == ThemeMode.dark,   onTap: () => settings.setThemeMode(ThemeMode.dark)),
    ]);
  }

  static void showSwipeActionDialog(BuildContext context,
      SettingsProvider settings, bool isRight, String lang) {
    final l10n = AppLocalizations.of(context)!;
    final currentValue = isRight ? settings.swipeRightAction : settings.swipeLeftAction;
    void set(String val) => isRight ? settings.setSwipeRightAction(val) : settings.setSwipeLeftAction(val);

    _showSheet(
      context,
      title: isRight ? l10n.swipeRight : l10n.swipeLeft,
      titleIcon: isRight ? Icons.swipe_right_rounded : Icons.swipe_left_rounded,
      options: [
        _SheetOption(label: l10n.delete,  icon: Icons.delete_outline_rounded,  selected: currentValue == 'delete',  onTap: () => set('delete')),
        _SheetOption(label: l10n.archive, icon: Icons.archive_outlined,         selected: currentValue == 'archive', onTap: () => set('archive')),
        _SheetOption(label: l10n.share,   icon: Icons.share_outlined,           selected: currentValue == 'share',   onTap: () => set('share')),
      ],
    );
  }

  static Future<void> showLockDelayDialog(BuildContext context,
      SettingsProvider settings, AppLocalizations l10n) async {
    final delays = [
      {'seconds': 30,  'label': l10n.seconds30, 'icon': Icons.timer_outlined},
      {'seconds': 120, 'label': l10n.minutes2,  'icon': Icons.timer_outlined},
      {'seconds': 180, 'label': l10n.minutes3,  'icon': Icons.timer_outlined},
      {'seconds': 300, 'label': l10n.minutes5,  'icon': Icons.timer_outlined},
    ];

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_clock_rounded, size: 22, color: cs.primary),
                  const SizedBox(width: 10),
                  Text(l10n.selectLockDelay,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              ...delays.map((d) {
                final selected = settings.lockDelaySeconds == d['seconds'];
                return _OptionTile(
                  option: _SheetOption(
                    label: d['label'] as String,
                    icon: d['icon'] as IconData,
                    selected: selected,
                    onTap: () async {
                      await settings.setLockDelaySeconds(d['seconds'] as int);
                      await settings.setLockDelayEnabled(true);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                  ),
                  cs: cs,
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

// ── Tile ─────────────────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final _SheetOption option;
  final ColorScheme cs;
  const _OptionTile({required this.option, required this.cs});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        option.onTap();
        Navigator.pop(context);
      },
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: option.selected
              ? cs.primaryContainer
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          option.icon,
          size: 20,
          color: option.selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        ),
      ),
      title: Text(
        option.label,
        style: TextStyle(
          fontWeight: option.selected ? FontWeight.w600 : FontWeight.normal,
          color: option.selected ? cs.primary : null,
        ),
      ),
      trailing: option.selected
          ? Icon(Icons.check_circle_rounded, color: cs.primary, size: 22)
          : Icon(Icons.circle_outlined, color: cs.onSurface.withValues(alpha: 0.3), size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

class _SheetOption {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SheetOption({required this.label, required this.icon, required this.selected, required this.onTap});
}
