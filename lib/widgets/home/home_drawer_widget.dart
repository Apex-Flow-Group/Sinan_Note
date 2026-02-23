// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/auth/locked_notes_intro_screen.dart';
import 'package:apex_note/screens/auth/vault_entry_screen.dart';
import 'package:apex_note/screens/mobile/locked_notes_screen.dart';
import 'package:apex_note/screens/other/version_history_screen.dart';
import 'package:apex_note/screens/shared/settings_screen_responsive.dart';
import 'package:apex_note/screens/sync/google_drive_screen_responsive.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeDrawerWidget extends StatelessWidget {
  final VoidCallback onBackupTap;
  final VoidCallback onNotesChanged;

  const HomeDrawerWidget({
    super.key,
    required this.onBackupTap,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Drawer(
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_rounded,
                  title: l10n.home,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.archive_rounded,
                  title: l10n.archive,
                  onTap: () async {
                    Navigator.pop(context);
                    if (!context.mounted) return;
                    Navigator.popUntil(context, (route) => route.isFirst);
                    await Navigator.pushNamed(context, '/archive');
                    if (!context.mounted) return;
                    onNotesChanged();
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.delete_rounded,
                  title: l10n.trash,
                  onTap: () async {
                    Navigator.pop(context);
                    if (!context.mounted) return;
                    Navigator.popUntil(context, (route) => route.isFirst);
                    await Navigator.pushNamed(context, '/trash');
                    if (!context.mounted) return;
                    onNotesChanged();
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.lock_rounded,
                  title: l10n.locked,
                  onTap: () => _openLockedNotes(context),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.cloud_rounded,
                  title: l10n.googleDrive,
                  subtitle: isArabic ? 'مزامنة السحابة' : 'Cloud sync',
                  iconColor: const Color(0xFF4285F4),
                  onTap: () {
                    Navigator.pop(context);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoogleDriveScreenResponsive(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history_rounded,
                  title: l10n.noteHistory,
                  subtitle: isArabic ? 'سجل التعديلات' : 'Version history',
                  iconColor: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VersionHistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: l10n.settings,
                  onTap: () async {
                    Navigator.pop(context);
                    if (!context.mounted) return;
                    Navigator.popUntil(context, (route) => route.isFirst);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreenResponsive()),
                    );
                    if (!context.mounted) return;
                    onNotesChanged();
                  },
                ),

              ],
            ),
          ),
          Container(
            padding:
                EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).padding.bottom + 24),
            child: const Text(
              '© 2025 Apex Flow Group',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

Future<void> _openLockedNotes(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    if (!settings.hasSeenLockedIntro) {
      Navigator.pop(context);
      if (!context.mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const LockedNotesIntroScreen()),
      );
      if (!context.mounted) return;
      onNotesChanged();
    } else {
      // Check if biometric is enabled
      final biometricEnabled = await VaultService.isBiometricEnabled();
      if (!context.mounted) return;
      
      if (biometricEnabled) {
        // Biometric enabled -> authenticate
        final authenticated = await BiometricService.authenticate();

        if (!context.mounted) return;

        Navigator.pop(context);
        Navigator.popUntil(context, (route) => route.isFirst);

        if (authenticated) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LockedNotesScreen()),
          );
          if (!context.mounted) return;
          onNotesChanged();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.authenticationFailed),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Biometric disabled -> go to VaultEntryScreen
        Navigator.pop(context);
        if (!context.mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
        
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VaultEntryScreen()),
        );
        if (!context.mounted) return;
        onNotesChanged();
      }
    }
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = iconColor ??
        (isDark
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).primaryColor);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: effectiveColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
