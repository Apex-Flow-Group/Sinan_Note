// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/categories/categories_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/auth/locked_notes_intro_screen.dart';
import 'package:apex_note/screens/auth/vault_entry_screen.dart';
import 'package:apex_note/screens/mobile/locked_notes_screen.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/widgets/home/categories_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _CatMode { normal, delete, edit }

/// يبقى حياً طول عمر التطبيق — لا يضيع عند إغلاق الـ Drawer
final _activeExtraNotifier = ValueNotifier<String?>(null);

/// حالة الخزنة — مرئية لكل الـ widgets
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
                      Navigator.pop(context);
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                  // ─── زر التصنيفات ───
                  _buildCategoriesItem(context, l10n, scheme, isDark),
                  ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _categoriesExpanded
                          ? Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(start: 16),
                              child: CategoriesPanel(
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
                          '🧭 Drawer → Archive (pop + popUntil + pushNamed)');
                      Navigator.pop(context);
                      if (!context.mounted) return;
                      Navigator.popUntil(context, (route) => route.isFirst);
                      await Navigator.pushNamed(context, '/archive');
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
                          '🧭 Drawer → Trash (pop + popUntil + pushNamed)');
                      Navigator.pop(context);
                      if (!context.mounted) return;
                      Navigator.popUntil(context, (route) => route.isFirst);
                      await Navigator.pushNamed(context, '/trash');
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
                  _buildDrawerItem(
                    context,
                    icon: Icons.cloud_sync_rounded,
                    title: l10n.googleDrive,
                    subtitle: isArabic ? 'مزامنة السحابة' : 'Cloud sync',
                    iconColor: const Color(0xFF4285F4),
                    scheme: scheme,
                    isDark: isDark,
                    isActive: currentRoute == '/drive',
                    onTap: () async {
                      debugPrint(
                          '🧭 Drawer → Drive (pop + popUntil + pushNamed)');
                      Navigator.pop(context);
                      if (!context.mounted) return;
                      Navigator.popUntil(context, (route) => route.isFirst);
                      await Navigator.pushNamed(context, '/drive');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.manage_history_rounded,
                    title: l10n.noteHistory,
                    subtitle: isArabic ? 'سجل التعديلات' : 'Version history',
                    iconColor: Colors.orange,
                    scheme: scheme,
                    isDark: isDark,
                    isActive: currentRoute == '/history',
                    onTap: () async {
                      debugPrint(
                          '🧭 Drawer → History (pop + popUntil + pushNamed)');
                      Navigator.pop(context);
                      if (!context.mounted) return;
                      Navigator.popUntil(context, (route) => route.isFirst);
                      await Navigator.pushNamed(context, '/history');
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
                          '🧭 Drawer → Settings (pop + popUntil + pushNamed)');
                      Navigator.pop(context);
                      if (!context.mounted) return;
                      Navigator.popUntil(context, (route) => route.isFirst);
                      await Navigator.pushNamed(context, '/settings');
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
              child: Text(
                '© 2025 Apex Flow Group',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
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

    // نفس الحاوية لكليهما لتثبيت الحجم
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
                  // ─── المحتوى يتغيّر بانيميشن ───
                  Expanded(
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: _categoriesExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      // ─── وضع النص ───
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
                      // ─── وضع الأدوات ───
                      secondChild: Row(
                        children: [
                          _ModeBtn(
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
                                        ? '🎯 وصلت للحد الأقصى! 20 كتالوج يكفي لتنظيم العالم كله 😄'
                                        : '🎯 Max reached! 20 catalogs is enough to organize the whole world 😄',
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
                          _ModeBtn(
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
                          _ModeBtn(
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
                          _ModeBtn(
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

    // فور الضغط → أوقف تظليل الرئيسية
    _activeExtraNotifier.value = 'vault';

    if (!settings.hasSeenLockedIntro) {
      Navigator.pop(context);
      await Navigator.pushReplacement(
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

        await Navigator.pushReplacement(
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

class _ModeBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ModeBtn(
      {required this.icon,
      required this.active,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color:
              active ? color : scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
