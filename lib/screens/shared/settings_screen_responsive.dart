// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/theme/app_theme.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/other/about_screen.dart';
import 'package:apex_note/screens/other/support_form_screen.dart';
import 'package:apex_note/screens/shared/backup_wizard_screen.dart';
import 'package:apex_note/screens/shared/settings/settings_dialogs.dart';
import 'package:apex_note/screens/shared/settings/settings_utils.dart';
import 'package:apex_note/screens/shared/settings_screen.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/home/home_drawer_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsScreenResponsive extends StatelessWidget {
  const SettingsScreenResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
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
      (icon: Icons.edit_note, label: l10n.editor),
      (icon: Icons.lock_outline, label: l10n.security),
      (icon: Icons.storage_outlined, label: l10n.data),
      (icon: Icons.info_outline, label: l10n.about),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).popUntil((r) => r.isFirst);
      },
      child: Scaffold(
        drawer: HomeDrawerWidget(
          onBackupTap: () {},
          onNotesChanged: () {},
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
        body: Padding(
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
                        selectedTileColor:
                            colorScheme.primaryContainer.withValues(alpha: 0.4),
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
                    child: _buildSection(
                      _selectedIndex,
                      context,
                      l10n,
                      settings,
                      currentLang,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    int index,
    BuildContext context,
    AppLocalizations l10n,
    SettingsProvider settings,
    String currentLang,
  ) {
    return switch (index) {
      0 => _buildGeneral(context, l10n, settings),
      1 => _buildEditor(context, l10n, settings, currentLang),
      2 => _buildSecurity(context, l10n, settings),
      3 => _buildData(context, l10n, currentLang),
      4 => _buildAbout(context, l10n, currentLang),
      _ => const SizedBox(),
    };
  }

  Widget _sectionList(List<Widget> children) => ListView(
        padding: const EdgeInsets.all(24),
        children: children,
      );

  Widget _buildGeneral(BuildContext context, AppLocalizations l10n,
          SettingsProvider settings) =>
      _sectionList([
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.language),
          subtitle:
              Text(SettingsUtils.getLanguageText(settings.languageCode, l10n)),
          onTap: () =>
              SettingsDialogs.showLanguageDialog(context, settings, l10n),
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
          subtitle: Text('${(settings.textScaleFactor * 100).round()}%'),
          trailing: SizedBox(
            width: 200,
            child: Slider(
              value: settings.textScaleFactor,
              min: 0.8,
              max: 1.5,
              divisions: 7,
              onChanged: settings.setTextScaleFactor,
            ),
          ),
        ),
      ]);


  Widget _buildEditor(BuildContext context, AppLocalizations l10n,
          SettingsProvider settings, String currentLang) =>
      _sectionList([
        SwitchListTile(
          secondary: const Icon(Icons.swipe),
          title: Text(l10n.swipeGestures),
          subtitle: Text(settings.swipeEnabled ? l10n.enabled : l10n.disabled),
          value: settings.swipeEnabled,
          onChanged: settings.setSwipeEnabled,
        ),
        if (settings.swipeEnabled) ...[
          ListTile(
            contentPadding:
                const EdgeInsetsDirectional.only(start: 72, end: 16),
            title: Text(l10n.swipeRight),
            subtitle: Text(SettingsUtils.getSwipeActionText(
                settings.swipeRightAction, l10n)),
            onTap: () => SettingsDialogs.showSwipeActionDialog(
                context, settings, true, currentLang),
          ),
          ListTile(
            contentPadding:
                const EdgeInsetsDirectional.only(start: 72, end: 16),
            title: Text(l10n.swipeLeft),
            subtitle: Text(SettingsUtils.getSwipeActionText(
                settings.swipeLeftAction, l10n)),
            onTap: () => SettingsDialogs.showSwipeActionDialog(
                context, settings, false, currentLang),
          ),
        ],
      ]);

  Widget _buildSecurity(BuildContext context, AppLocalizations l10n,
          SettingsProvider settings) =>
      _sectionList([
        SwitchListTile(
          secondary: const Icon(Icons.lock),
          title: Text(l10n.appLock),
          subtitle:
              Text(settings.isAppLockEnabled ? l10n.enabled : l10n.disabled),
          value: settings.isAppLockEnabled,
          onChanged: (val) async {
            final ok = await BiometricService.authenticate();
            if (ok) {
              await settings.setAppLockEnabled(val);
            } else if (mounted) {
              setState(() {});
            }
          },
        ),
        if (settings.isAppLockEnabled)
          SwitchListTile(
            contentPadding:
                const EdgeInsetsDirectional.only(start: 72, end: 16),
            title: Text(l10n.lockDelay),
            subtitle: Text(settings.lockDelayEnabled
                ? SettingsUtils.getLockDelayText(
                    settings.lockDelaySeconds, l10n)
                : l10n.immediate),
            value: settings.lockDelayEnabled,
            onChanged: (val) async {
              if (val) {
                await SettingsDialogs.showLockDelayDialog(
                    context, settings, l10n);
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
          onChanged: settings.setHideContentInBackground,
        ),
      ]);

  Widget _buildData(
          BuildContext context, AppLocalizations l10n, String currentLang) =>
      _sectionList([
        ListTile(
          leading: Icon(Icons.backup_outlined,
              color: Theme.of(context).colorScheme.primary),
          title: Text(currentLang == 'ar' ? 'النسخ الاحتياطي والاستعادة' : 'Backup & Restore'),
          subtitle: Text(currentLang == 'ar'
              ? 'تصدير واستيراد ملاحظاتك'
              : 'Export and import your notes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BackupWizardScreen()),
          ),
        ),
      ]);

  Widget _buildAbout(
          BuildContext context, AppLocalizations l10n, String currentLang) =>
      _sectionList([
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: Text(l10n.feedback),
          subtitle: Text(l10n.contactUs),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SupportFormScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.share),
          title: Text(l10n.shareApp),
          onTap: () => CustomShareSheet.show(context,
              currentLang == 'ar' ? 'جرب Sinan Note!' : 'Try Sinan Note!'),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.aboutApp),
          subtitle: Text(_version),
          onTap: () => showDialog(
              context: context,
              builder: (_) => const Dialog(child: AboutScreen())),
        ),
        if (kDebugMode)
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.red),
            title: Text(l10n.diagnostics),
            subtitle: Text(l10n.developersOnly),
            onTap: () =>
                SettingsUtils.showDiagnostics(context, l10n, currentLang),
          ),
        const SizedBox(height: 24),
        Center(
          child: Column(children: [
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
          ]),
        ),
      ]);
}
