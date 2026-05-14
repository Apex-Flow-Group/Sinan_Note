// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/onboarding/tour_screen.dart';
import 'package:apex_note/screens/onboarding/whats_new_dialog.dart';
import 'package:apex_note/screens/other/about_screen.dart';
import 'package:apex_note/screens/other/support_form_screen.dart';
import 'package:apex_note/screens/shared/backup_wizard_screen.dart';
import 'package:apex_note/screens/shared/settings/settings_utils.dart';
import 'package:apex_note/screens/shared/settings/widgets/settings_section_card.dart';
import 'package:apex_note/services/storage/db_inspector_service.dart';
import 'package:apex_note/widgets/common/app_dialog.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DataSection extends StatelessWidget {
  final String currentLang;
  const DataSection({super.key, required this.currentLang});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsSectionCard(
      title: l10n.data,
      icon: Icons.storage_rounded,
      children: [
        ListTile(
          leading: Icon(Icons.backup_outlined,
              color: Theme.of(context).colorScheme.primary),
          title: Text(currentLang == 'ar'
              ? 'النسخ الاحتياطي والاستعادة'
              : 'Backup & Restore'),
          subtitle: Text(currentLang == 'ar'
              ? 'تصدير واستيراد ملاحظاتك'
              : 'Export and import your notes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => AppDialog.show(context, const BackupWizardScreen()),
        ),
      ],
    );
  }
}

class AboutSection extends StatelessWidget {
  final String version;
  final String currentLang;
  const AboutSection(
      {super.key, required this.version, required this.currentLang});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsSectionCard(
      title: l10n.about,
      icon: Icons.info_outline_rounded,
      children: [
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: Text(l10n.feedback),
          subtitle: Text(l10n.contactUs),
          onTap: () => AppDialog.show(context, const SupportFormScreen()),
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
          subtitle: Text(version),
          onTap: () => AppDialog.show(context, const AboutScreen()),
        ),
        if (kDebugMode)
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.red),
            title: Text(l10n.diagnostics),
            subtitle: Text(l10n.developersOnly),
            onTap: () =>
                SettingsUtils.showDiagnostics(context, l10n, currentLang),
          ),
        if (kDebugMode)
          ListTile(
            leading: const Icon(Icons.storage_rounded, color: Colors.orange),
            title: const Text('DB Inspector'),
            subtitle: const Text('SQLite report'),
            onTap: () => DbInspectorService.showReport(context),
          ),
        if (kDebugMode)
          ListTile(
            leading:
                const Icon(Icons.celebration_rounded, color: Colors.purple),
            title: const Text('What\'s New Dialog'),
            subtitle: const Text('Preview the dialog'),
            onTap: () => WhatsNewDialog.show(context),
          ),
        if (kDebugMode)
          ListTile(
            leading: const Icon(Icons.tour_rounded, color: Colors.teal),
            title: const Text('Tour Screen'),
            subtitle: const Text('Preview onboarding tour'),
            onTap: () => AppDialog.show(context, const TourScreen()),
          ),
      ],
    );
  }
}
