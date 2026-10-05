// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/widgets/app_dialog.dart';
import 'package:sinan_note/ui/core/widgets/custom_share_sheet.dart';
import 'package:sinan_note/ui/features/about/about_screen.dart';
import 'package:sinan_note/ui/features/about/support_form_screen.dart';
import 'package:sinan_note/ui/features/backup/backup_wizard_screen.dart';
import 'package:sinan_note/ui/features/diagnostics/db_inspector_sheet.dart';
import 'package:sinan_note/ui/features/diagnostics/view_models/diagnostics.dart';
import 'package:sinan_note/ui/features/onboarding/tour_screen.dart';
import 'package:sinan_note/ui/features/onboarding/whats_new_dialog.dart';
import 'package:sinan_note/ui/features/settings/settings_utils.dart';
import 'package:sinan_note/ui/features/settings/widgets/settings_section_card.dart';

class DataSection extends StatelessWidget {
  const DataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsSectionCard(
      title: l10n.data,
      icon: Icons.storage_rounded,
      children: [
        ListTile(
          leading: Icon(Icons.backup_outlined, color: context.colors.success),
          title: Text(l10n.backupAndRestore),
          subtitle: Text(l10n.backupAndRestoreDesc),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => AppDialog.show(context, const BackupWizardScreen()),
        ),
      ],
    );
  }
}

class AboutSection extends StatelessWidget {
  final String version;
  const AboutSection({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    return SettingsSectionCard(
      title: l10n.about,
      icon: Icons.info_outline_rounded,
      children: [
        ListTile(
          leading: Icon(Icons.mail_outline, color: primary),
          title: Text(l10n.feedback),
          subtitle: Text(l10n.contactUs),
          onTap: () => AppDialog.show(context, const SupportFormScreen()),
        ),
        ListTile(
          leading: Icon(Icons.share, color: primary),
          title: Text(l10n.shareApp),
          onTap: () => CustomShareSheet.show(context, l10n.shareAppMessage,
              appShare: true),
        ),
        ListTile(
          leading: Icon(Icons.info_outline, color: primary),
          title: Text(l10n.aboutApp),
          subtitle: Text(version),
          onTap: () => AppDialog.show(context, const AboutScreen()),
        ),
        if (kDebugMode)
          ListTile(
            leading: Icon(Icons.bug_report, color: context.colors.danger),
            title: Text(l10n.diagnostics),
            subtitle: Text(l10n.developersOnly),
            onTap: () => SettingsUtils.showDiagnostics(context, l10n),
          ),
        if (kDebugMode)
          ListTile(
            leading: Icon(Icons.storage_rounded, color: context.colors.warning),
            title: Text(l10n.dbInspector),
            subtitle: Text(l10n.dbInspectorDesc),
            onTap: () async {
              final report = await context.read<Diagnostics>().databaseReport();
              if (context.mounted) await showDbInspector(context, report);
            },
          ),
        if (kDebugMode)
          ListTile(
            leading: Icon(Icons.celebration_rounded,
                color: context.scheme.secondary),
            title: Text(l10n.whatsNewDialogPreview),
            subtitle: Text(l10n.whatsNewDialogPreviewDesc),
            onTap: () => WhatsNewDialog.show(context),
          ),
        if (kDebugMode)
          ListTile(
            leading: Icon(Icons.tour_rounded, color: context.scheme.tertiary),
            title: Text(l10n.tourScreenPreview),
            subtitle: Text(l10n.tourScreenPreviewDesc),
            onTap: () => AppDialog.show(context, const TourScreen()),
          ),
      ],
    );
  }
}
