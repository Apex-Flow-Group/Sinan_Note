// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/other/about_screen.dart';
import 'package:apex_note/screens/other/support_form_screen.dart';
import 'package:apex_note/screens/shared/backup_wizard_screen.dart';
import 'package:apex_note/screens/shared/settings/settings_dialogs.dart';
import 'package:apex_note/screens/shared/settings/settings_utils.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

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

    return Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        drawer: HomeDrawerWidget(
          onBackupTap: () {},
          onNotesChanged: () {},
        ),
        body: widget.isDesktopLayout
            ? _buildDesktopLayout(context, l10n, settings, currentLang)
            : Center(
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
                    min: 0.9,
                    max: 1.4,
                    divisions: 5,
                    onChanged: (value) => settings.setTextScaleFactor(value),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.font_download_outlined),
                title: Text(l10n.fontFamily),
                subtitle: Text(_fontFamilyLabel(settings.fontFamily, l10n)),
                onTap: () => _showFontFamilySheet(context, settings, l10n),
              ),

              // EDITOR SECTION
              SettingsUtils.buildSectionHeader(context, l10n.editor),
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
                leading: Icon(Icons.backup_outlined,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(currentLang == 'ar' ? 'النسخ الاحتياطي والاستعادة' : 'Backup & Restore'),
                subtitle: Text(currentLang == 'ar'
                    ? 'تصدير واستيراد ملاحظاتك'
                    : 'Export and import your notes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BackupWizardScreen())),
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
                onTap: () {
                  final msg = currentLang == 'ar'
                      ? 'جرّب Sinan Note — تطبيق الملاحظات الذكي والآمن! تشفير AES-256 ، محرر كود، قوائم مهام وتذكيرات. حمّله مجاناً من Google Play:\nhttps://play.google.com/store/apps/dev?id=5409981776310932919'
                      : 'Try Sinan Note — The smart & secure notes app! AES-256 encryption, code editor, checklists & reminders. Free on Google Play:\nhttps://play.google.com/store/apps/dev?id=5409981776310932919';
                  CustomShareSheet.show(context, msg, appShare: true);
                },
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

            ],
          ),
        ),
      ),
    );
  }

  String _fontFamilyLabel(String family, AppLocalizations l10n) {
    switch (family) {
      case 'Cairo': return 'Cairo';
      case 'Tajawal': return 'Tajawal';
      default: return l10n.fontFamilySystem;
    }
  }

  void _showFontFamilySheet(BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    final fonts = [
      ('system', l10n.fontFamilySystem, l10n.fontFamilySystemDesc),
      ('Cairo', 'Cairo', l10n.fontFamilyCairoDesc),
      ('Tajawal', 'Tajawal', l10n.fontFamilyTajawalDesc),
      ('Vazirmatn', 'Vazirmatn', l10n.fontFamilyVazirmatnDesc),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.font_download_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.fontFamily,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(),
              ...fonts.map((f) {
                final isSelected = settings.fontFamily == f.$1;
                final cs = Theme.of(context).colorScheme;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary.withValues(alpha: 0.12)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('أ',
                        style: TextStyle(
                          fontFamily: f.$1 == 'system' ? null : f.$1,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  title: Text(f.$2,
                    style: TextStyle(
                      fontFamily: f.$1 == 'system' ? null : f.$1,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? cs.primary : null,
                    ),
                  ),
                  subtitle: Text(f.$3,
                    style: TextStyle(
                      fontFamily: f.$1 == 'system' ? null : f.$1,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: cs.primary)
                      : null,
                  onTap: () {
                    settings.setFontFamily(f.$1);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AppLocalizations l10n,
    SettingsProvider settings,
    String currentLang,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العمود الأيسر
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildGeneralSection(context, l10n, settings),
                  const SizedBox(height: 24),
                  _buildEditorSection(context, l10n, settings, currentLang),
                ],
              ),
            ),
            // العمود الأيمن
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSecuritySection(context, l10n, settings),
                  const SizedBox(height: 24),
                  _buildDataSection(context, l10n, currentLang),
                  const SizedBox(height: 24),
                  _buildAboutSection(context, l10n, currentLang),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSection(BuildContext context, AppLocalizations l10n, SettingsProvider settings) {
    return Card(
      child: Column(
        children: [
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
                min: 0.9,
                max: 1.4,
                divisions: 5,
                onChanged: (value) => settings.setTextScaleFactor(value),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.font_download_outlined),
            title: Text(l10n.fontFamily),
            subtitle: Text(_fontFamilyLabel(settings.fontFamily, l10n)),
            onTap: () => _showFontFamilySheet(context, settings, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorSection(BuildContext context, AppLocalizations l10n, SettingsProvider settings, String currentLang) {
    return Card(
      child: Column(
        children: [
          SettingsUtils.buildSectionHeader(context, l10n.editor),
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
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context, AppLocalizations l10n, SettingsProvider settings) {
    return Card(
      child: Column(
        children: [
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
          SwitchListTile(
            secondary: const Icon(Icons.visibility_off),
            title: Text(l10n.hideContentInBackground),
            subtitle: Text(l10n.applyBlurEffect),
            value: settings.hideContentInBackground,
            onChanged: (val) => settings.setHideContentInBackground(val),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context, AppLocalizations l10n, String currentLang) {
    return Card(
      child: Column(
        children: [
          SettingsUtils.buildSectionHeader(context, l10n.data),
          ListTile(
            leading: Icon(Icons.backup_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: Text(currentLang == 'ar' ? 'النسخ الاحتياطي والاستعادة' : 'Backup & Restore'),
            subtitle: Text(currentLang == 'ar'
                ? 'تصدير واستيراد ملاحظاتك'
                : 'Export and import your notes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BackupWizardScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, AppLocalizations l10n, String currentLang) {
    return Card(
      child: Column(
        children: [
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
            onTap: () {
              final msg = currentLang == 'ar'
                  ? 'جرّب Sinan Note — تطبيق الملاحظات الذكي والآمن! تشفير AES-256 ، محرر كود، قوائم مهام وتذكيرات. حمّله مجاناً من Google Play:\nhttps://play.google.com/store/apps/dev?id=5409981776310932919'
                  : 'Try Sinan Note — The smart & secure notes app! AES-256 encryption, code editor, checklists & reminders. Free on Google Play:\nhttps://play.google.com/store/apps/dev?id=5409981776310932919';
              CustomShareSheet.show(context, msg, appShare: true);
            },
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
