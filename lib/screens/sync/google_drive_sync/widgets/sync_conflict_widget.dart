// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/sync/google_drive_sync/google_drive_sync_controller.dart';

class SyncConflictWidget extends StatelessWidget {
  const SyncConflictWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final controller = context.read<GoogleDriveSyncController>();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة التحذير
            Icon(
              Icons.sync_problem,
              size: 64,
              color: theme.colorScheme.error,
            ),

            const SizedBox(height: 24),

            // العنوان
            Text(
              l10n.syncConflictTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // الوصف
            Text(
              l10n.syncConflictDesc,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // عدد الملاحظات على الجهاز
            _buildCountCard(
              context,
              icon: Icons.phone_android,
              color: Colors.blue,
              label: l10n.onDevice,
              count: controller.localNotesCount,
            ),

            const SizedBox(height: 16),

            // عدد الملاحظات على Drive
            _buildCountCard(
              context,
              icon: Icons.cloud,
              color: Colors.green,
              label: l10n.onDrive,
              count: controller.driveNotesCount,
            ),

            const SizedBox(height: 32),

            // الخيارات
            Text(
              l10n.chooseAction,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            // زر: استخدام نسخة Drive
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => controller.resolveConflict('useDrive'),
                icon: const Icon(Icons.cloud_download),
                label: Text(l10n.useDrive),
              ),
            ),

            const SizedBox(height: 12),

            // زر: استخدام نسخة الجهاز
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => controller.resolveConflict('useDevice'),
                icon: const Icon(Icons.phone_android),
                label: Text(l10n.useDevice),
              ),
            ),

            const SizedBox(height: 12),

            // زر: دمج ذكي (موصى به)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => controller.resolveConflict('merge'),
                icon: const Icon(Icons.merge),
                label: Text(l10n.smartMerge),
              ),
            ),

            const SizedBox(height: 8),

            // وصف الدمج الذكي
            Text(
              l10n.smartMergeDesc,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(l10n.notesCount(count)),
        ],
      ),
    );
  }
}

