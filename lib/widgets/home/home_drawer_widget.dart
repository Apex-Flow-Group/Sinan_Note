// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/utils/vault_navigator.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/main.dart' show currentTabIndexNotifier;
import 'package:sinan_note/screens/auth/vault_entry_screen.dart';
import 'package:sinan_note/services/cloud/google_drive_auth.dart';
import 'package:sinan_note/services/security/biometric_service.dart';
import 'package:sinan_note/services/security/vault_service.dart';
import 'package:sinan_note/services/sync/cloud_sync_gateway.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/home/categories_panel.dart';
import 'package:sinan_note/widgets/home/drawer_widgets.dart';

enum _CatMode { normal, delete, edit }

/// يبقى حياً طول عمر التطبيق — لا يضيع عند إغلاق الـ Drawer
final _activeExtraNotifier = ValueNotifier<String?>(null);

/// ضبط حالة تفعيل الخزنة في الـ Drawer من الخارج
void setDrawerVaultActive(bool active) {
  _activeExtraNotifier.value = active ? 'vault' : null;
}

class HomeDrawerWidget extends StatefulWidget {
  final VoidCallback onBackupTap;
  final VoidCallback onNotesChanged;
  final void Function(int index)? onTabSelected;

  const HomeDrawerWidget({
    super.key,
    required this.onBackupTap,
    required this.onNotesChanged,
    this.onTabSelected,
  });

  @override
  State<HomeDrawerWidget> createState() => _HomeDrawerWidgetState();
}

class _HomeDrawerWidgetState extends State<HomeDrawerWidget> {
  bool _categoriesExpanded = false;
  _CatMode _catMode = _CatMode.normal;
  bool _isAdding = false;

  /// يُعيد تعيين حالة الخزنة في الـ Drawer عند الانتقال لشاشة أخرى.
  void _exitVaultIfActive(String destination) {
    if (_activeExtraNotifier.value == 'vault') {
      _activeExtraNotifier.value = null;
    }
  }

  /// يُغلق الـ Drawer ويتنقل للوجهة المطلوبة بأمان.
  /// يحفظ reference للـ navigator قبل pop لتجنب مشكلة context unmounted.
  Future<void> _navigateFromDrawer(
    BuildContext context, {
    required String destination,
    required String routeName,
  }) async {
    _exitVaultIfActive(destination);

    // نحفظ reference للـ root navigator
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    // نتحقق هل نحن داخل الخزنة
    bool isInVault = false;
    rootNavigator.popUntil((route) {
      if (route.settings.name == '/vault/locked' ||
          route.settings.name == '/vault/unlock' ||
          route.settings.name == '/vault/entry') {
        isInVault = true;
      }
      return true;
    });

    // إغلاق الـ Drawer
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.isDrawerOpen) {
      scaffoldState.closeDrawer();
    }

    if (isInVault) {
      // LockedNotesScreen فيها postFrameCallback يعمل exitVault عند pop.
      // نعمل pop للخزنة ثم ننتظر حتى ينتهي الـ postFrameCallback.
      rootNavigator.popUntil(
        (route) => route.settings.name == '/main' || route.isFirst,
      );
      // ننتظر حتى ينتهي postFrameCallback في LockedNotesScreen
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
    }

    // التنقل للوجهة
    await rootNavigator.pushNamed(routeName);
  }

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
                    isActive:
                        (currentRoute == '/main' || currentRoute == '/') &&
                            activeExtra == null &&
                            (widget.onTabSelected == null ||
                                currentTabIndexNotifier.value == 0) &&
                            context
                                    .watch<CategoriesProvider>()
                                    .selectedCategoryId ==
                                null,
                    onTap: () async {
                      _exitVaultIfActive('Home');
                      final rootNavigator =
                          Navigator.of(context, rootNavigator: true);
                      final scaffoldState = Scaffold.maybeOf(context);
                      if (scaffoldState != null && scaffoldState.isDrawerOpen) {
                        scaffoldState.closeDrawer();
                      }
                      rootNavigator.popUntil(
                        (route) =>
                            route.settings.name == '/main' || route.isFirst,
                      );
                      widget.onTabSelected?.call(0);
                    },
                  ),
                  // â”€â”€â”€ ط²ط± ط§ظ„طھطµظ†ظٹظپط§طھ â”€â”€â”€
                  _buildCategoriesItem(context, l10n, scheme, isDark),
                  // ── التذكيرات والمحترف (في وضع Desktop) ───
                  if (widget.onTabSelected != null) ...[
                    _buildDrawerItem(
                      context,
                      icon: Icons.alarm_rounded,
                      title: l10n.reminders,
                      scheme: scheme,
                      isDark: isDark,
                      isActive: currentTabIndexNotifier.value == 1 &&
                          (currentRoute == '/main' || currentRoute == '/'),
                      onTap: () {
                        final scaffoldState = Scaffold.maybeOf(context);
                        if (scaffoldState != null &&
                            scaffoldState.isDrawerOpen) {
                          scaffoldState.closeDrawer();
                        }
                        widget.onTabSelected!(1);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.code_rounded,
                      title: l10n.professional,
                      scheme: scheme,
                      isDark: isDark,
                      isActive: currentTabIndexNotifier.value == 2 &&
                          (currentRoute == '/main' || currentRoute == '/'),
                      onTap: () {
                        final scaffoldState = Scaffold.maybeOf(context);
                        if (scaffoldState != null &&
                            scaffoldState.isDrawerOpen) {
                          scaffoldState.closeDrawer();
                        }
                        widget.onTabSelected!(2);
                      },
                    ),
                  ],
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
                      await _navigateFromDrawer(
                        context,
                        destination: 'Archive',
                        routeName: '/archive',
                      );
                      if (!mounted) return;
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
                      await _navigateFromDrawer(
                        context,
                        destination: 'Trash',
                        routeName: '/trash',
                      );
                      if (!mounted) return;
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
                      valueListenable: CloudSyncGateway.autoSyncEnabled,
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
                          await _navigateFromDrawer(
                            context,
                            destination: 'Google Drive',
                            routeName: '/drive',
                          );
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
                      await _navigateFromDrawer(
                        context,
                        destination: 'History',
                        routeName: '/history',
                      );
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
                      await _navigateFromDrawer(
                        context,
                        destination: 'Settings',
                        routeName: '/settings',
                      );
                      if (!mounted) return;
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
              child: Text(
                '© 2025 Apex Flow Group',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
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
    final isOnHome =
        ((ModalRoute.of(context)?.settings.name ?? '/') == '/main' ||
                (ModalRoute.of(context)?.settings.name ?? '/') == '/') &&
            _activeExtraNotifier.value == null &&
            currentTabIndexNotifier.value == 0;
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
        color: scheme.primary.withValues(
            alpha: hasSelection && isOnHome
                ? (isDark ? 0.28 : 0.18)
                : (isDark ? 0.18 : 0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          Icon(Icons.label_important_rounded, color: scheme.primary, size: 20),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: hasSelection && isOnHome
              ? scheme.primary.withValues(alpha: isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
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
                                UnifiedNotificationService().show(
                                  context: context,
                                  message: isArabic
                                      ? '🎯 وصلت للحد الأقصى! 20 كتالوج يكفي لتنظيم العالم كله 😄'
                                      : '🎯 Max reached! 20 catalogs is enough to organize the whole world 😄',
                                  type: NotificationType.info,
                                  duration: const Duration(seconds: 3),
                                );
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

  /// إذا كانت الخزنة مفتوحة، نُغلقها قبل الانتقال لأي شاشة أخرى.
  /// يُستدعى من أزرار "حول" و"تواصل" في أسفل الـ Drawer.
  Future<void> _openLockedNotes(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    _activeExtraNotifier.value = 'vault';

    if (!settings.hasSeenLockedIntro) {
      final navigator = Navigator.of(context, rootNavigator: true);
      Navigator.pop(context);
      if (!context.mounted) return;
      VaultNavigator.pushIntro(navigator);
      _activeExtraNotifier.value = null;
      widget.onNotesChanged();
      return;
    }

    final hasBiometrics = await BiometricService.hasBiometrics();
    final biometricEnabled = await VaultService.isBiometricEnabled();
    if (!context.mounted) return;

    if (biometricEnabled && hasBiometrics) {
      // البصمة أولاً قبل إغلاق الـ Drawer — حتى يبقى context mounted
      final authenticated = await BiometricService.authenticate();
      if (!context.mounted) return;

      // نحفظ reference للـ navigator قبل إغلاق الـ Drawer
      final navigator = Navigator.of(context, rootNavigator: true);

      // إغلاق الـ Drawer
      Navigator.of(context).pop();

      if (authenticated) {
        VaultNavigator.pushLockedNotes(navigator);
      } else {
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => const VaultEntryScreen(),
            settings: const RouteSettings(name: '/vault/entry'),
          ),
        );
      }
    } else {
      final navigator = Navigator.of(context, rootNavigator: true);
      Navigator.pop(context);
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => const VaultEntryScreen(),
          settings: const RouteSettings(name: '/vault/entry'),
        ),
      );
    }

    _activeExtraNotifier.value = null;
    if (!context.mounted) return;
    widget.onNotesChanged();
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
