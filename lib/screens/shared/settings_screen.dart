// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/main.dart' show currentTabIndexNotifier;
import 'package:sinan_note/screens/shared/settings/sections/data_about_sections.dart';
import 'package:sinan_note/screens/shared/settings/sections/general_section.dart';
import 'package:sinan_note/screens/shared/settings/sections/motion_navigation_section.dart';
import 'package:sinan_note/screens/shared/settings/sections/security_section.dart';
import 'package:sinan_note/screens/shared/settings/sections/swipe_section.dart';
import 'package:sinan_note/widgets/home/home_drawer_widget.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDesktopLayout;
  const SettingsScreen({super.key, this.isDesktopLayout = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = 'v${info.version}');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      drawer: HomeDrawerWidget(
        onBackupTap: () {},
        onNotesChanged: () {},
        onTabSelected: (index) {
          Navigator.of(context, rootNavigator: true)
              .popUntil((r) => r.settings.name == '/main' || r.isFirst);
          currentTabIndexNotifier.value = index;
        },
      ),
      body: widget.isDesktopLayout
          ? _buildDesktopLayout()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16),
                  children: [
                    const GeneralSection(showBetaSeparate: true),
                    const MotionNavigationSection(),
                    const BetaSection(),
                    const SwipeSection(),
                    const SecuritySection(),
                    const DataSection(),
                    AboutSection(version: _version),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  GeneralSection(),
                  SizedBox(height: 24),
                  MotionNavigationSection(),
                  SizedBox(height: 24),
                  SwipeSection(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SecuritySection(),
                  const SizedBox(height: 24),
                  const DataSection(),
                  const SizedBox(height: 24),
                  AboutSection(version: _version),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
