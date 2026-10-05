// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/navigation/app_navigator.dart';
import 'package:sinan_note/ui/core/theme/settings_palette.dart';
import 'package:sinan_note/ui/features/settings/view_models/settings_provider.dart';
import 'package:sinan_note/ui/features/settings/widgets/settings_section_card.dart';
import 'package:sinan_note/ui/features/sync/view_models/sync_view_model.dart';

class MotionNavigationSection extends StatelessWidget {
  const MotionNavigationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return SettingsSectionCard(
      title: l10n.motionAndNavigation,
      icon: Icons.animation_rounded,
      children: [
        // ── Pull to Refresh ─────────────────────────────────────────
        ListTile(
          leading: Icon(Icons.swipe_down_rounded, color: primary),
          title: Text(l10n.pullToRefreshSetting),
          subtitle:
              Text(_pullToRefreshSubtitle(l10n, settings.pullToRefreshMode)),
          onTap: () => _showPullToRefreshDialog(context, settings),
        ),

        // ── Double Tap to Edit ──────────────────────────────────────
        SwitchListTile(
          secondary: Icon(Icons.touch_app_rounded, color: primary),
          title: Text(l10n.doubleTapToEdit),
          subtitle: Text(l10n.doubleTapToEditDesc),
          value: settings.doubleTapToEdit,
          onChanged: settings.setDoubleTapToEdit,
        ),
      ],
    );
  }

  String _pullToRefreshSubtitle(AppLocalizations l10n, String mode) {
    switch (mode) {
      case 'full':
        return l10n.fullAppRefresh;
      case 'normal':
        return l10n.homePageOnlyRefresh;
      case 'disabled':
        return l10n.disabled;
      default:
        return l10n.fullAppRefresh;
    }
  }

  void _showSignInRequired(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    const googleBlue = SettingsPalette.googleBlue;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── أيقونة قوقل درايف ──────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: googleBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.drive_folder_upload_rounded,
                  size: 36,
                  color: googleBlue,
                ),
              ),
              const SizedBox(height: 20),

              // ── العنوان ────────────────────────────────────────
              Text(
                l10n.signInRequiredTitle,
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),

              // ── الرسالة ────────────────────────────────────────
              Text(
                l10n.signInRequiredMessage,
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 28),

              // ── الأزرار ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        AppNavigator.toDrive(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: googleBlue,
                        foregroundColor: SettingsPalette.onGoogleBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: Text(l10n.goToSignIn),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPullToRefreshDialog(
      BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.pullToRefreshSetting,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              _PullRefreshOption(
                title: l10n.fullAppRefresh,
                subtitle: l10n.fullAppRefreshDesc,
                value: 'full',
                currentValue: settings.pullToRefreshMode,
                enabled: ctx.read<SyncViewModel>().isSignedIn,
                onInfo: () => _showSignInRequired(ctx),
                onTap: ctx.read<SyncViewModel>().isSignedIn
                    ? () {
                        settings.setPullToRefreshMode('full');
                        Navigator.pop(ctx);
                      }
                    : null,
              ),
              _PullRefreshOption(
                title: l10n.homePageRefresh,
                subtitle: l10n.homePageRefreshDesc,
                value: 'normal',
                currentValue: settings.pullToRefreshMode,
                onTap: () {
                  settings.setPullToRefreshMode('normal');
                  Navigator.pop(ctx);
                },
              ),
              _PullRefreshOption(
                title: l10n.disabled,
                subtitle: l10n.disablePullToRefresh,
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

class _PullRefreshOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String currentValue;
  final VoidCallback? onTap;
  final bool enabled;
  final VoidCallback? onInfo;

  const _PullRefreshOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.currentValue,
    required this.onTap,
    this.enabled = true,
    this.onInfo,
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
    final active = isSelected && enabled;
    return ListTile(
      enabled: enabled,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _icon,
          size: 20,
          color: active ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: !enabled && onInfo != null
          ? IconButton(
              tooltip: title,
              onPressed: onInfo,
              icon: Icon(
                Icons.info_outline_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : isSelected
              ? Icon(Icons.check_rounded, color: colorScheme.primary, size: 20)
              : null,
      onTap: onTap,
    );
  }
}
