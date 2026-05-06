// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io' show Platform;

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/auth/locked_notes_intro_screen.dart';
import 'package:apex_note/screens/auth/vault_entry_screen.dart';
import 'package:apex_note/screens/mobile/locked_notes_screen.dart';
import 'package:apex_note/screens/other/about_screen.dart';
import 'package:apex_note/screens/other/support_form_screen.dart';
import 'package:apex_note/services/cloud/google_drive_auth.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/widgets/home/categories_panel.dart';
import 'package:apex_note/widgets/home/drawer_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _CatMode { normal, delete, edit }

/// ظٹط¨ظ‚ظ‰ ط­ظٹط§ظ‹ ط·ظˆظ„ ط¹ظ…ط± ط§ظ„طھط·ط¨ظٹظ‚ â€” ظ„ط§ ظٹط¶ظٹط¹ ط¹ظ†ط¯ ط¥ط؛ظ„ط§ظ‚ ط§ظ„ظ€ Drawer
final _activeExtraNotifier = ValueNotifier<String?>(null);

/// ط­ط§ظ„ط© ط§ظ„ط®ط²ظ†ط© â€” ظ…ط±ط¦ظٹط© ظ„ظƒظ„ ط§ظ„ظ€ widgets
final vaultOpenNotifier = ValueNotifier<bool>(false);

class HomeDrawerWidget extends StatefulWidget {
  final VoidCallback onBackupTap;
  final VoidCallback onNotesChanged;

  const HomeDrawerWidget({
    super.key,
    required this.onBackupTap,
    required this.onNotesChanged,
  });

  @override
  State<HomeDrawerWidget> createState() => _HomeDrawerWidgetState();
}

class _HomeDrawerWidgetState extends State<HomeDrawerWidget> {
  bool _categoriesExpanded = false;
  _CatMode _catMode = _CatMode.normal;
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    return ValueListenableBuilder<String?>(
      valueListenable: _activeExtraNotifier,
      builder: (context, activeExtra, _) => Drawer(
        backgroundColor: scheme.surface,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_rounded,
                    title: l10n.home,
                    scheme: scheme,
                    isDark: isDark,
                    isActive: currentRoute == '/' && activeExtra == null,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      Navigator.of(context, rootNavigator: true)
                          .popUntil((route) => route.isFirst);
                    },
                  ),
                  // â”€â”€â”€ ط²ط± ط§ظ„طھطµظ†ظٹظپط§طھ â”€â”€â”€
                  _buildCategoriesItem(context, l10n, scheme, isDark),
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _categoriesExpanded
                          ? Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(start: 16),
                              child: CategoriesPanelWrapper(
                                mode: _catMode == _CatMode.delete
                                    ? CatPanelMode.delete
                                    : _catMode == _CatMode.edit
                                        ? CatPanelMode.edit
                                        : CatPanelMode.normal,
                                isAdding: _isAdding,
                                onAddDone: () =>
                                    setState(() => _isAdding = false),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.inventory_2_rounded,
                    title: l10n.archive,
                    scheme: scheme,
                    isDark: isDark,
                    isActive: currentRoute == '/archive',
                    onTap: () async {
                      debugPrint(
                          'ًں§­ Drawer â†’ Archive (pop + popUntil + pushNamed)');
                      Navigator.of(context, rootNavigator: true).pop();
                      if (!context.mounted) return;
                      Navigator.of(context, rootNavigator: true)
                          .popUntil((route) => route.isFirst);
                      await Navigator.of(context, rootNavigator: true)
                          .pushNamed('/archive');
                      if (!context.mounted) return;
                      widget.onNotesChanged();
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.delete_sweep_rounded,
                    title: l10n.trash,
                    scheme: scheme,
                    isDark: isDark,
                    isActive: currentRoute == '/trash',
                    onTap: () async {
                      debugPrint(
                          'ًں§­ Drawer â†’ Trash (pop + popUntil + pushNamed)');
                      Navigator.of(context, rootNavigator: true).pop();
                      if (!context.mounted) return;
                      Navigator.of(context, rootNavigator: true)
                          .popUntil((route) => route.isFirst);
                      await Navigator.of(context, rootNavigator: true)
                          .pushNamed('/trash');
                      if (!context.mounted) return;
                      widget.onNotesChanged();
                    },
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: _activeExtraNotifier,
                    builder: (context, extra, _) => _buildDrawerItem(
                      context,
                      icon: Icons.shield_rounded,
                      title: l10n.locked,
                      scheme: scheme,
                      isDark: isDark,
                      isActive: extra == 'vault',
                      isVaultOpen: extra == 'vault',
                      onTap: () => _openLockedNotes(context),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1, color: scheme.outlineVariant),
                  ),
                  if (!Platform.isWindows &&
                      !Platform.isLinux &&
                      !Platform.isMacOS)
                    ValueListenableBuilder<bool>(
                      valueListenable: GoogleDriveService.autoSyncEnabled,
                      builder: (context, autoSync, _) => _buildDrawerItem(
                        context,
                        icon: Icons.cloud_sync_rounded,
                        title: l10n.googleDrive,
                        subtitle: GoogleDriveAuth.isSignedIn
                            ? (autoSync ? l10n.driveSyncOn : l10n.driveSyncOff)
                            : l10n.driveSignIn,
                        iconColor: const Color(0xFF4285F4),
                        scheme: scheme,
                        isDark: isDark,
                        isActive: currentRoute == '/drive',
                        onTap: () async {
                          debugPrint(
                              'ًں§­ Drawer â†’ Drive (pop + popUntil + pushNamed)');
                          Navigator.of(context, rootNavigator: true).pop();
                          if (!context.mounted) return;
                          Navigator.of(context, rootNavigator: true)
                              .popUntil((route) => route.isFirst);
                          await Navigator.of(context, rootNavigator: true)
                              .pushNamed('/drive');
                        },
                      ),
                    ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.manage_history_rounded,
                    title: l10n.noteHistory,
                    subtitle: l10n.noteHistory,
                    iconColor: Colors.orange,
                    scheme: scheme,
                    isDark: isDark,
                    isActive: currentRoute == '/history',
                    onTap: () async {
                      debugPrint(
                          'ًں§­ Drawer â†’ History (pop + popUntil + pushNamed)');
                      Navigator.of(context, rootNavigator: true).pop();
                      if (!context.mounted) return;
                      Navigator.of(context, rootNavigator: true)
                          .popUntil((route) => route.isFirst);
                      await Navigator.of(context, rootNavigator: true)
                          .pushNamed('/history');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.tune_rounded,
                    title: l10n.settings,
                    scheme: scheme,
                    isDark: isDark,
                    isActive: currentRoute == '/settings',
                    onTap: () async {
                      debugPrint(
                          'ًں§­ Drawer â†’ Settings (pop + popUntil + pushNamed)');
                      Navigator.of(context, rootNavigator: true).pop();
                      if (!context.mounted) return;
                      Navigator.of(context, rootNavigator: true)
                          .popUntil((route) => route.isFirst);
                      await Navigator.of(context, rootNavigator: true)
                          .pushNamed('/settings');
                      if (!context.mounted) return;
                      widget.onNotesChanged();
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '© 2025 Apex Flow Group',
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SupportFormScreen()));
                    },
                    child: Icon(Icons.support_agent_rounded,
                        size: 18, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AboutScreen()));
                    },
                    child: Icon(Icons.info_outline_rounded,
                        size: 18, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesItem(BuildContext context, AppLocalizations l10n,
      ColorScheme scheme, bool isDark) {
    final catProvider = context.watch<CategoriesProvider>();
    final selectedId = catProvider.selectedCategoryId;
    final hasSelection = selectedId != null;
    final selectedName = hasSelection
        ? (selectedId == kProCategoryId
            ? AppLocalizations.of(context)!.professional
            : catProvider.categories
                .where((c) => c.id == selectedId)
                .map((c) => c.name)
                .firstOrNull)
        : null;

    // ظ†ظپط³ ط§ظ„ط­ط§ظˆظٹط© ظ„ظƒظ„ظٹظ‡ظ…ط§ ظ„طھط«ط¨ظٹطھ ط§ظ„ط­ط¬ظ…
    final iconBox = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          Icon(Icons.label_important_rounded, color: scheme.primary, size: 20),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: SizedBox(
        height: 56,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _categoriesExpanded
                ? null
                : () => setState(() => _categoriesExpanded = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  iconBox,
                  const SizedBox(width: 16),
                  // â”€â”€â”€ ط§ظ„ظ…ط­طھظˆظ‰ ظٹطھط؛ظٹظ‘ط± ط¨ط§ظ†ظٹظ…ظٹط´ظ† â”€â”€â”€
                  Expanded(
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: _categoriesExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      // â”€â”€â”€ ظˆط¶ط¹ ط§ظ„ظ†طµ â”€â”€â”€
                      firstChild: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.categories,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasSelection
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                if (selectedName != null)
                                  Text(
                                    selectedName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                else
                                  Text(
                                    l10n.allNotes,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 20, color: scheme.onSurfaceVariant),
                        ],
                      ),
                      // â”€â”€â”€ ظˆط¶ط¹ ط§ظ„ط£ط¯ظˆط§طھ â”€â”€â”€
                      secondChild: Row(
                        children: [
                          DrawerModeBtn(
                            icon: Icons.add_rounded,
                            active: _isAdding,
                            color: context
                                        .read<CategoriesProvider>()
                                        .categories
                                        .length >=
                                    kMaxCategories
                                ? scheme.onSurface.withValues(alpha: 0.3)
                                : scheme.primary,
                            onTap: () {
                              final isArabic = Localizations.localeOf(context)
                                      .languageCode ==
                                  'ar';
                              if (context
                                      .read<CategoriesProvider>()
                                      .categories
                                      .length >=
                                  kMaxCategories) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                    isArabic
                                        ? 'ًںژ¯ ظˆطµظ„طھ ظ„ظ„ط­ط¯ ط§ظ„ط£ظ‚طµظ‰! 20 ظƒطھط§ظ„ظˆط¬ ظٹظƒظپظٹ ظ„طھظ†ط¸ظٹظ… ط§ظ„ط¹ط§ظ„ظ… ظƒظ„ظ‡ ًںک„'
                                        : 'ًںژ¯ Max reached! 20 catalogs is enough to organize the whole world ًںک„',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ));
                                return;
                              }
                              setState(() {
                                _isAdding = !_isAdding;
                                _catMode = _CatMode.normal;
                              });
                            },
                          ),
                          DrawerModeBtn(
                            icon: Icons.delete_outline_rounded,
                            active: _catMode == _CatMode.delete,
                            color: scheme.error,
                            onTap: () => setState(() {
                              _catMode = _catMode == _CatMode.delete
                                  ? _CatMode.normal
                                  : _CatMode.delete;
                              _isAdding = false;
                            }),
                          ),
                          DrawerModeBtn(
                            icon: Icons.edit_outlined,
                            active: _catMode == _CatMode.edit,
                            color: scheme.primary,
                            onTap: () => setState(() {
                              _catMode = _catMode == _CatMode.edit
                                  ? _CatMode.normal
                                  : _CatMode.edit;
                              _isAdding = false;
                            }),
                          ),
                          const Spacer(),
                          DrawerModeBtn(
                            icon: Icons.close_rounded,
                            active: false,
                            color: scheme.onSurfaceVariant,
                            onTap: () => setState(() {
                              _categoriesExpanded = false;
                              _catMode = _CatMode.normal;
                              _isAdding = false;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLockedNotes(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // ظپظˆط± ط§ظ„ط¶ط؛ط· â†’ ط£ظˆظ‚ظپ طھط¸ظ„ظٹظ„ ط§ظ„ط±ط¦ظٹط³ظٹط©
    _activeExtraNotifier.value = 'vault';

    if (!settings.hasSeenLockedIntro) {
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LockedNotesIntroScreen()),
      );
      _activeExtraNotifier.value = null;
      if (!context.mounted) return;
      widget.onNotesChanged();
    } else {
      final biometricEnabled = await VaultService.isBiometricEnabled();
      if (!context.mounted) return;

      if (biometricEnabled) {
        final nav = Navigator.of(context);
        nav.pop(); // close drawer before biometric
        final authenticated = await BiometricService.authenticate();

        if (authenticated) {
          await nav.pushReplacement(
            MaterialPageRoute(builder: (_) => const LockedNotesScreen()),
          );
          _activeExtraNotifier.value = null;
          widget.onNotesChanged();
        } else {
          _activeExtraNotifier.value = null;
        }
      } else {
        Navigator.pop(context);

        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VaultEntryScreen()),
        );
        _activeExtraNotifier.value = null;
        if (!context.mounted) return;
        widget.onNotesChanged();
      }
    }
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required ColorScheme scheme,
    required bool isDark,
    required VoidCallback onTap,
    bool isActive = false,
    bool isVaultOpen = false,
  }) {
    final effectiveColor = iconColor ?? scheme.primary;
    final effectiveIcon = isVaultOpen ? Icons.shield_outlined : icon;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? scheme.primary.withValues(alpha: isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: effectiveColor.withValues(
                  alpha: isActive
                      ? (isDark ? 0.28 : 0.18)
                      : (isDark ? 0.18 : 0.1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(effectiveIcon, color: effectiveColor, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? scheme.primary : scheme.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(subtitle,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
              : null,
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
