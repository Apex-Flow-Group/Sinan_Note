// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../services/biometric_service.dart';
import '../../services/settings_provider.dart';
import '../../services/database_service.dart';
import '../../screens/locked_notes_intro_screen.dart';
import '../../screens/locked_notes_screen.dart';
import '../../screens/transfer_screen_helper.dart';
import '../../screens/google_drive_screen.dart';
import '../../l10n/l10n_migration_helper.dart';
import '../../config/flavor_config.dart';

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
    final l10n = context.l10n;
    final isArabic = context.isArabic;

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
                    Navigator.popUntil(context, (route) => route.isFirst);
                    await Navigator.pushNamed(context, '/archive');
                    onNotesChanged();
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.delete_rounded,
                  title: l10n.trash,
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                    await Navigator.pushNamed(context, '/trash');
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoogleDriveScreen(),
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
                    Navigator.popUntil(context, (route) => route.isFirst);
                    await Navigator.pushNamed(context, '/settings');
                    onNotesChanged();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),
                if (FlavorConfig.hasTransferFeature)
                  _buildDrawerItem(
                    context,
                    icon: Icons.sync_alt_rounded,
                    title: l10n.transferTitle,
                    subtitle: isArabic
                        ? 'نقل البيانات عبر الشبكة'
                        : 'Transfer via network',
                    iconColor: const Color(0xFF7E57C2),
                    onTap: () => _openTransfer(context),
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

  Future<void> _openTransfer(BuildContext context) async {
    final dbService = DatabaseService();
    final db = await dbService.database;
    final lockedCount = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM notes WHERE isLocked = 1')) ??
        0;

    if (lockedCount > 0) {
      final agreed = await TransferAgreementDialog.show(
          context, context.isArabic, lockedCount);
      if (agreed != true) {
        if (context.mounted) Navigator.pop(context);
        return;
      }
    }

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushNamed(context, '/transfer');
    }
  }

  Future<void> _openLockedNotes(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (!settings.hasSeenLockedIntro) {
      Navigator.pop(context);
      if (context.mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const LockedNotesIntroScreen()),
        );
        onNotesChanged();
      }
    } else {
      final authenticated = await BiometricService.authenticate();

      if (!context.mounted) return;

      Navigator.pop(context);
      Navigator.popUntil(context, (route) => route.isFirst);

      if (authenticated) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LockedNotesScreen()),
        );
        onNotesChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.authenticationFailed),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
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
