// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/theme/app_theme.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/main.dart' show currentTabIndexNotifier;
import 'package:sinan_note/screens/shared/settings/sections/data_about_sections.dart';
import 'package:sinan_note/screens/shared/settings/sections/general_section.dart';
import 'package:sinan_note/screens/shared/settings/sections/security_section.dart';
import 'package:sinan_note/screens/shared/settings/sections/swipe_section.dart';
import 'package:sinan_note/screens/shared/settings_screen.dart';
import 'package:sinan_note/widgets/home/home_drawer_widget.dart';

class SettingsScreenResponsive extends StatelessWidget {
  const SettingsScreenResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (PlatformHelper.shouldUseDesktopLayout(context)) {
          return const _SettingsDesktop();
        }
        return const SettingsScreen();
      },
    );
  }
}

class _SettingsDesktop extends StatefulWidget {
  const _SettingsDesktop();

  @override
  State<_SettingsDesktop> createState() => _SettingsDesktopState();
}

class _SettingsDesktopState extends State<_SettingsDesktop> {
  int _selectedIndex = 0;
  String _version = '...';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = 'v${info.version}');
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);
    final systemLocale =
        View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system'
        ? systemLocale
        : settings.languageCode;
    final colorScheme = Theme.of(context).colorScheme;

    final sections = [
      (icon: Icons.tune, label: l10n.general),
      (icon: Icons.swipe_rounded, label: l10n.swipeGestures),
      (icon: Icons.lock_outline, label: l10n.security),
      (icon: Icons.storage_outlined, label: l10n.data),
      (icon: Icons.info_outline, label: l10n.about),
    ];

    return PopScope(
      canPop: true,
      child: Scaffold(
        drawer: HomeDrawerWidget(
          onBackupTap: () {},
          onNotesChanged: () {},
          onTabSelected: (index) {
            Navigator.of(context, rootNavigator: true)
                .popUntil((r) => r.settings.name == '/main' || r.isFirst);
            currentTabIndexNotifier.value = index;
          },
        ),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(l10n.settings),
        ),
        body: SafeArea(
          top: false, // AppBar يتعامل مع الأعلى
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Master — قائمة الأقسام
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 220,
                    color: AppTheme.sidebarBackground(colorScheme),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: sections.length,
                      itemBuilder: (_, i) {
                        final selected = i == _selectedIndex;
                        return ListTile(
                          leading: Icon(
                            sections[i].icon,
                            color: selected ? colorScheme.primary : null,
                          ),
                          title: Text(
                            sections[i].label,
                            style: TextStyle(
                              color: selected ? colorScheme.primary : null,
                              fontWeight: selected ? FontWeight.w600 : null,
                            ),
                          ),
                          selected: selected,
                          selectedTileColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          onTap: () => setState(() => _selectedIndex = i),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Details — محتوى القسم
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedIndex),
                      child: _buildSection(_selectedIndex, currentLang),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(int index, String currentLang) {
    return switch (index) {
      0 => _wrap(const GeneralSection()),
      1 => _wrap(const SwipeSection()),
      2 => _wrap(const SecuritySection()),
      3 => _wrap(DataSection(currentLang: currentLang)),
      4 => _wrap(AboutSection(version: _version, currentLang: currentLang)),
      _ => const SizedBox(),
    };
  }

  Widget _wrap(Widget child) => ListView(
        padding: const EdgeInsets.all(24),
        children: [child],
      );
}
