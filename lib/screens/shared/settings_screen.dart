// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/settings/sections/data_about_sections.dart';
import 'package:sinan_note/screens/shared/settings/sections/general_section.dart';
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
    final settings = context.watch<SettingsProvider>();
    final systemLocale =
        View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system'
        ? systemLocale
        : settings.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      drawer: HomeDrawerWidget(onBackupTap: () {}, onNotesChanged: () {}),
      body: widget.isDesktopLayout
          ? _buildDesktopLayout(currentLang)
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16),
                  children: [
                    const GeneralSection(showBetaSeparate: true),
                    const BetaSection(),
                    const SwipeSection(),
                    const SecuritySection(),
                    DataSection(currentLang: currentLang),
                    AboutSection(version: _version, currentLang: currentLang),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDesktopLayout(String currentLang) {
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
                  DataSection(currentLang: currentLang),
                  const SizedBox(height: 24),
                  AboutSection(version: _version, currentLang: currentLang),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

