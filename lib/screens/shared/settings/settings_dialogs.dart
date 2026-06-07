// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/settings/settings_utils.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';

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
      isScrollControlled: true,
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
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
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...options.map((o) => _OptionTile(option: o, cs: cs)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showLanguageDialog(
      BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    _showSheet(context,
        title: l10n.language,
        titleIcon: Icons.language_rounded,
        options: [
          _SheetOption(
              label: l10n.system,
              icon: Icons.phone_android_rounded,
              selected: settings.languageCode == 'system',
              onTap: () => settings.setLanguage('system')),
          _SheetOption(
              label: l10n.arabic,
              icon: Icons.translate_rounded,
              selected: settings.languageCode == 'ar',
              onTap: () => settings.setLanguage('ar')),
          _SheetOption(
              label: l10n.english,
              icon: Icons.translate_rounded,
              selected: settings.languageCode == 'en',
              onTap: () => settings.setLanguage('en')),
        ]);
  }

  static void showThemeDialog(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
    _showSheet(context,
        title: l10n.chooseTheme,
        titleIcon: Icons.palette_rounded,
        options: [
          _SheetOption(
              label: l10n.systemTheme,
              icon: Icons.brightness_auto_rounded,
              selected: settings.themeMode == ThemeMode.system,
              onTap: () => settings.setThemeMode(ThemeMode.system)),
          _SheetOption(
              label: l10n.lightTheme,
              icon: Icons.light_mode_rounded,
              selected: settings.themeMode == ThemeMode.light,
              onTap: () => settings.setThemeMode(ThemeMode.light)),
          _SheetOption(
              label: l10n.darkTheme,
              icon: Icons.dark_mode_rounded,
              selected: settings.themeMode == ThemeMode.dark,
              onTap: () => settings.setThemeMode(ThemeMode.dark)),
        ]);
  }

  static void showSwipeActionDialog(BuildContext context,
      SettingsProvider settings, bool isRight, String lang) {
    final l10n = AppLocalizations.of(context)!;
    final currentValue =
        isRight ? settings.swipeRightAction : settings.swipeLeftAction;
    final otherValue =
        isRight ? settings.swipeLeftAction : settings.swipeRightAction;
    void set(String val) {
      if (val == 'custom' && otherValue == 'custom') {
        isRight
            ? settings.setSwipeLeftAction('archive')
            : settings.setSwipeRightAction('delete');
      }
      isRight
          ? settings.setSwipeRightAction(val)
          : settings.setSwipeLeftAction(val);
    }

    _showSheet(
      context,
      title: isRight ? l10n.swipeRight : l10n.swipeLeft,
      titleIcon: isRight ? Icons.swipe_right_rounded : Icons.swipe_left_rounded,
      options: [
        _SheetOption(
            label: l10n.delete,
            icon: Icons.delete_outline_rounded,
            color: SettingsUtils.getSwipeActionColor('delete'),
            selected: currentValue == 'delete',
            onTap: () => set('delete')),
        _SheetOption(
            label: l10n.actionArchive,
            icon: Icons.archive_outlined,
            color: SettingsUtils.getSwipeActionColor('archive'),
            selected: currentValue == 'archive',
            onTap: () => set('archive')),
        _SheetOption(
            label: l10n.share,
            icon: Icons.share_outlined,
            color: SettingsUtils.getSwipeActionColor('share'),
            selected: currentValue == 'share',
            onTap: () => set('share')),
        _SheetOption(
            label: l10n.reminder,
            icon: Icons.alarm_rounded,
            color: SettingsUtils.getSwipeActionColor('reminder'),
            selected: currentValue == 'reminder',
            onTap: () => set('reminder')),
        _SheetOption(
            label: l10n.categories,
            icon: Icons.label_outlined,
            color: SettingsUtils.getSwipeActionColor('category'),
            selected: currentValue == 'category',
            onTap: () => set('category')),
        _SheetOption(
            label: l10n.noteCopy,
            icon: Icons.copy_all_rounded,
            color: SettingsUtils.getSwipeActionColor('duplicate'),
            selected: currentValue == 'duplicate',
            onTap: () => set('duplicate')),
        _SheetOption(
            label: l10n.custom,
            icon: Icons.bolt_rounded,
            color: SettingsUtils.getSwipeActionColor('custom'),
            selected: currentValue == 'custom',
            onTap: () => set('custom')),
      ],
    );
  }

  static void showCustomActionsDialog(
      BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    final allActions = [
      (
        'delete',
        l10n.delete,
        Icons.delete_outline_rounded,
        SettingsUtils.getSwipeActionColor('delete')
      ),
      (
        'archive',
        l10n.actionArchive,
        Icons.archive_outlined,
        SettingsUtils.getSwipeActionColor('archive')
      ),
      (
        'share',
        l10n.share,
        Icons.share_outlined,
        SettingsUtils.getSwipeActionColor('share')
      ),
      (
        'reminder',
        l10n.reminder,
        Icons.alarm_rounded,
        SettingsUtils.getSwipeActionColor('reminder')
      ),
      (
        'category',
        l10n.categories,
        Icons.label_outlined,
        SettingsUtils.getSwipeActionColor('category')
      ),
      (
        'duplicate',
        l10n.noteCopy,
        Icons.copy_all_rounded,
        SettingsUtils.getSwipeActionColor('duplicate')
      ),
    ];

    AppBottomSheet.show(
      context,
      isScrollControlled: true,
      child: _CustomActionsSelector(
        allActions: allActions,
        settings: settings,
        l10n: l10n,
      ),
    );
  }

  static Future<void> showLockDelayDialog(BuildContext context,
      SettingsProvider settings, AppLocalizations l10n) async {
    final delays = [
      {'seconds': 30, 'label': l10n.seconds30, 'icon': Icons.timer_outlined},
      {'seconds': 120, 'label': l10n.minutes2, 'icon': Icons.timer_outlined},
      {'seconds': 180, 'label': l10n.minutes3, 'icon': Icons.timer_outlined},
      {'seconds': 300, 'label': l10n.minutes5, 'icon': Icons.timer_outlined},
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
                width: 40,
                height: 4,
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
                      style: Theme.of(ctx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
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

// ── Custom Actions Selector ──────────────────────────────────────────────────
class _CustomActionsSelector extends StatefulWidget {
  final List<(String, String, IconData, Color)> allActions;
  final SettingsProvider settings;
  final AppLocalizations l10n;

  const _CustomActionsSelector({
    required this.allActions,
    required this.settings,
    required this.l10n,
  });

  @override
  State<_CustomActionsSelector> createState() => _CustomActionsSelectorState();
}

class _CustomActionsSelectorState extends State<_CustomActionsSelector> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.settings.swipeCustomActions);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = widget.l10n;

    return AppBottomSheet(
      title: l10n.custom,
      titleIcon: Icons.bolt_rounded,
      scrollable: true,
      actions: [
        IconButton.filled(
          onPressed: () {
            widget.settings.setSwipeCustomActions(_selected.toList());
            Navigator.pop(context);
          },
          icon: const Icon(Icons.check_rounded),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.allActions.map((entry) {
          final (key, label, icon, color) = entry;
          final checked = _selected.contains(key);
          return CheckboxListTile(
            value: checked,
            onChanged: (_) => setState(() {
              if (checked) {
                _selected.remove(key);
              } else {
                _selected.add(key);
              }
            }),
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: checked
                    ? color.withValues(alpha: 0.15)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18, color: checked ? color : scheme.onSurfaceVariant),
            ),
            title: Text(label),
            activeColor: color,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            controlAffinity: ListTileControlAffinity.trailing,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          );
        }).toList(),
      ),
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
    final iconColor = option.color ?? cs.primary;
    return ListTile(
      onTap: () {
        option.onTap();
        Navigator.pop(context);
      },
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: option.selected
              ? iconColor.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          option.icon,
          size: 20,
          color: option.selected ? iconColor : cs.onSurfaceVariant,
        ),
      ),
      title: Text(
        option.label,
        style: TextStyle(
          fontWeight: option.selected ? FontWeight.w600 : FontWeight.normal,
          color: option.selected ? iconColor : null,
        ),
      ),
      trailing: option.selected
          ? Icon(Icons.check_circle_rounded, color: iconColor, size: 22)
          : Icon(Icons.circle_outlined,
              color: cs.onSurface.withValues(alpha: 0.3), size: 22),
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
  final Color? color;
  const _SheetOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
  });
}
