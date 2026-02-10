// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../controllers/settings/settings_provider.dart';
import '../widgets/home/home_drawer_widget.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'settings/settings_dialogs.dart';
import 'settings/settings_backup_handlers.dart';
import 'settings/settings_utils.dart';
import 'support_form_screen.dart';
import 'about_screen.dart';
import '../widgets/common/custom_share_sheet.dart';
import '../services/security/biometric_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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
    } catch (e) {
      // Failed to load version info
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);
    final systemLocale = View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system' ? systemLocale : settings.languageCode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        drawer: HomeDrawerWidget(
          onBackupTap: () {},
          onNotesChanged: () {},
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
            children: [
              // GENERAL SECTION
              SettingsUtils.buildSectionHeader(context, l10n.general),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                subtitle: Text(SettingsUtils.getLanguageText(settings.languageCode, l10n)),
                onTap: () => SettingsDialogs.showLanguageDialog(context, settings, l10n),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: Text(l10n.theme),
                subtitle: Text(SettingsUtils.getThemeText(settings.themeMode, l10n)),
                onTap: () => SettingsDialogs.showThemeDialog(context, settings),
              ),
              ListTile(
                leading: const Icon(Icons.format_size),
                title: Text(l10n.fontSize),
                subtitle: Text("${(settings.textScaleFactor * 100).round()}%"),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: settings.textScaleFactor,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    onChanged: (value) => settings.setTextScaleFactor(value),
                  ),
                ),
              ),

              // EDITOR SECTION
              SettingsUtils.buildSectionHeader(context, l10n.editor),
              SwitchListTile(
                secondary: const Icon(Icons.auto_awesome),
                title: Text(l10n.cardShineEffect),
                subtitle: Text(settings.cardMotionEnabled ? l10n.enabled : l10n.disabled),
                value: settings.cardMotionEnabled,
                onChanged: (val) => settings.setCardMotionEnabled(val),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.swipe),
                title: Text(l10n.swipeGestures),
                subtitle: Text(settings.swipeEnabled ? l10n.enabled : l10n.disabled),
                value: settings.swipeEnabled,
                onChanged: (val) => settings.setSwipeEnabled(val),
              ),
              if (settings.swipeEnabled) ...[
                ListTile(
                  contentPadding: const EdgeInsetsDirectional.only(start: 72, end: 16),
                  title: Text(l10n.swipeRight),
                  subtitle: Text(SettingsUtils.getSwipeActionText(settings.swipeRightAction, l10n)),
                  onTap: () => SettingsDialogs.showSwipeActionDialog(context, settings, true, currentLang),
                ),
                ListTile(
                  contentPadding: const EdgeInsetsDirectional.only(start: 72, end: 16),
                  title: Text(l10n.swipeLeft),
                  subtitle: Text(SettingsUtils.getSwipeActionText(settings.swipeLeftAction, l10n)),
                  onTap: () => SettingsDialogs.showSwipeActionDialog(context, settings, false, currentLang),
                ),
              ],

              // SECURITY SECTION
              SettingsUtils.buildSectionHeader(context, l10n.security),
              SwitchListTile(
                secondary: const Icon(Icons.lock),
                title: Text(l10n.appLock),
                subtitle: Text(settings.isAppLockEnabled ? l10n.enabled : l10n.disabled),
                value: settings.isAppLockEnabled,
                onChanged: (val) async {
                  final authenticated = await BiometricService.authenticate();
                  if (authenticated) {
                    await settings.setAppLockEnabled(val);
                  } else {
                    if (mounted) setState(() {});
                  }
                },
              ),
              if (settings.isAppLockEnabled)
                SwitchListTile(
                  contentPadding: const EdgeInsetsDirectional.only(start: 72, end: 16),
                  title: Text(l10n.lockDelay),
                  subtitle: Text(settings.lockDelayEnabled
                      ? SettingsUtils.getLockDelayText(settings.lockDelaySeconds, l10n)
                      : l10n.immediate),
                  value: settings.lockDelayEnabled,
                  onChanged: (val) async {
                    if (val) {
                      await SettingsDialogs.showLockDelayDialog(context, settings, l10n);
                    } else {
                      await settings.setLockDelayEnabled(false);
                    }
                  },
                ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_off),
                title: Text(l10n.hideContentInBackground),
                subtitle: Text(l10n.applyBlurEffect),
                value: settings.hideContentInBackground,
                onChanged: (val) => settings.setHideContentInBackground(val),
              ),

              // DATA SECTION
              SettingsUtils.buildSectionHeader(context, l10n.data),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined, color: Colors.green),
                title: Text(l10n.exportBackup),
                subtitle: Text(l10n.exportDatabase),
                onTap: () => SettingsBackupHandlers.showBackupDialog(context, currentLang, l10n),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.blue),
                title: Text(l10n.exportJson),
                subtitle: Text(l10n.saveAsJsonFile),
                onTap: () => SettingsBackupHandlers.showExportDialog(context, currentLang, l10n),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined, color: Colors.orange),
                title: Text(l10n.restore),
                subtitle: Text(currentLang == 'ar' ? 'استيراد من JSON أو Database' : 'Import from JSON or Database'),
                onTap: () => SettingsBackupHandlers.handleSmartImport(context, currentLang, l10n),
              ),

              // ABOUT SECTION
              SettingsUtils.buildSectionHeader(context, l10n.about),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(l10n.feedback),
                subtitle: Text(l10n.contactUs),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportFormScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.shareApp),
                onTap: () => CustomShareSheet.show(context, currentLang == 'ar'
                    ? 'جرب Sinan Note!'
                    : 'Try Sinan Note!'),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutApp),
                subtitle: Text(_version),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.bug_report, color: Colors.red),
                  title: Text(l10n.diagnostics),
                  subtitle: Text(l10n.developersOnly),
                  onTap: () => SettingsUtils.showDiagnostics(context, l10n, currentLang),
                ),

              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(l10n.poweredBy,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    Text(l10n.companyName,
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
