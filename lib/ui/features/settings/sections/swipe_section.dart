// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/platform/platform_helper.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/features/settings/settings_dialogs.dart';
import 'package:sinan_note/ui/features/settings/settings_utils.dart';
import 'package:sinan_note/ui/features/settings/view_models/settings_provider.dart';
import 'package:sinan_note/ui/features/settings/widgets/settings_section_card.dart';

class SwipeSection extends StatelessWidget {
  const SwipeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final muted = context.colors.muted;

    final isDesktop = PlatformHelper.shouldUseDesktopLayout(context);

    return SettingsSectionCard(
      title: l10n.swipeGestures,
      icon: Icons.swipe_rounded,
      children: [
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.phone_android_rounded,
                    size: 16, color: muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.swipeGesturesMobileHint,
                    style: context.text.labelMedium?.copyWith(
                      color: muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Opacity(
          opacity: isDesktop ? 0.5 : 1.0,
          child: IgnorePointer(
            ignoring: isDesktop,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.search_rounded, color: primary),
                          const SizedBox(width: 16),
                          Text(l10n.homeSearchBar,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ToggleButtons(
                        value: settings.hideSearchOnScroll,
                        labelFalse: l10n.barFixed,
                        labelTrue: l10n.barAnimated,
                        onChanged: settings.setHideSearchOnScroll,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // ─── شريط التنقل السفلي ─────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.more_horiz_rounded, color: primary),
                          const SizedBox(width: 16),
                          Text(l10n.bottomNavigationBar,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ToggleButtons(
                        value: settings.hideNavOnScroll,
                        labelFalse: l10n.barFixed,
                        labelTrue: l10n.barAnimated,
                        onChanged: settings.setHideNavOnScroll,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        SwitchListTile(
          secondary: Icon(Icons.swipe, color: primary),
          title: Text(l10n.swipeGesturesDesc),
          subtitle: Text(settings.swipeEnabled ? l10n.enabled : l10n.disabled),
          value: settings.swipeEnabled,
          onChanged: settings.setSwipeEnabled,
        ),
        if (settings.swipeEnabled) ...[
          ListTile(
            contentPadding:
                const EdgeInsetsDirectional.only(start: 72, end: 16),
            leading: Icon(Icons.swipe_right_rounded, color: primary),
            title: Text(l10n.swipeRight),
            subtitle: Text(SettingsUtils.getSwipeActionText(
                settings.swipeRightAction, l10n)),
            trailing: Icon(
                SettingsUtils.getSwipeActionIcon(settings.swipeRightAction),
                color: SettingsUtils.getSwipeActionColor(
                    context, settings.swipeRightAction)),
            onTap: () =>
                SettingsDialogs.showSwipeActionDialog(context, settings, true),
          ),
          ListTile(
            contentPadding:
                const EdgeInsetsDirectional.only(start: 72, end: 16),
            leading: Icon(Icons.swipe_left_rounded, color: primary),
            title: Text(l10n.swipeLeft),
            subtitle: Text(SettingsUtils.getSwipeActionText(
                settings.swipeLeftAction, l10n)),
            trailing: Icon(
                SettingsUtils.getSwipeActionIcon(settings.swipeLeftAction),
                color: SettingsUtils.getSwipeActionColor(
                    context, settings.swipeLeftAction)),
            onTap: () =>
                SettingsDialogs.showSwipeActionDialog(context, settings, false),
          ),
          if (settings.swipeRightAction == 'custom' ||
              settings.swipeLeftAction == 'custom')
            ListTile(
              contentPadding:
                  const EdgeInsetsDirectional.only(start: 72, end: 16),
              leading: Icon(Icons.bolt_rounded, color: primary),
              title: Text(l10n.custom),
              subtitle: Text(
                  l10n.selectedCount(settings.swipeCustomActions.length)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => SettingsDialogs.showCustomActionsDialog(
                  context, settings, l10n),
            ),
        ],
      ],
    );
  }
}

/// زران متساويا الحجم — تأثير لون بدون أيقونة صح
class _ToggleButtons extends StatelessWidget {
  final bool value;
  final String labelFalse;
  final String labelTrue;
  final ValueChanged<bool> onChanged;

  const _ToggleButtons({
    required this.value,
    required this.labelFalse,
    required this.labelTrue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: 200,
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: _Btn(
                label: labelFalse,
                selected: !value,
                isFirst: true,
                isLast: false,
                cs: cs,
                onTap: () => onChanged(false),
              ),
            ),
            Expanded(
              child: _Btn(
                label: labelTrue,
                selected: value,
                isFirst: false,
                isLast: true,
                cs: cs,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadiusDirectional.horizontal(
      start: isFirst ? const Radius.circular(18) : Radius.zero,
      end: isLast ? const Radius.circular(18) : Radius.zero,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.18)
              : cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
