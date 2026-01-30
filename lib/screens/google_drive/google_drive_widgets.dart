// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

class GoogleDriveWidgets {
  static Widget buildAccountSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isSignedIn,
    String? userEmail,
    VoidCallback? onSignOut,
  ) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.grey[850] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(l10n.account, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (isSignedIn) ...[
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.signedInAs, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(userEmail ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(onPressed: onSignOut, icon: const Icon(Icons.logout), label: Text(l10n.signOut)),
              ),
            ] else ...[
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(l10n.notSignedIn, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(onPressed: null, icon: const Icon(Icons.login), label: Text(l10n.signIn)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'ميزة المزامنة قيد التطوير وسيتم إعلامكم حين اكتمالها'
                            : 'Sync feature is under development. You will be notified when completed',
                        style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildSyncStatusSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    String lastSyncTimeStr,
    bool isSignedIn,
    VoidCallback? onSync,
  ) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.grey[850] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(l10n.syncStatus, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.lastSync, style: Theme.of(context).textTheme.bodyLarge),
                Text(lastSyncTimeStr, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(onPressed: isSignedIn ? onSync : null, icon: const Icon(Icons.sync), label: Text(l10n.syncNow)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildSyncActionsSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isSignedIn,
    VoidCallback? onUpload,
    VoidCallback? onDownload,
  ) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.grey[850] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync, size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(l10n.syncActions, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.cloud_upload, color: Colors.blue),
              ),
              title: Text(l10n.uploadDatabase),
              subtitle: Text(l10n.uploadDatabaseDesc),
              trailing: IconButton(onPressed: isSignedIn ? onUpload : null, icon: const Icon(Icons.arrow_forward)),
              onTap: isSignedIn ? onUpload : null,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.cloud_download, color: Colors.green),
              ),
              title: Text(l10n.downloadDatabase),
              subtitle: Text(l10n.downloadDatabaseDesc),
              trailing: IconButton(onPressed: isSignedIn ? onDownload : null, icon: const Icon(Icons.arrow_forward)),
              onTap: isSignedIn ? onDownload : null,
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildAutoSyncSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool autoSync,
    bool isSignedIn,
    ValueChanged<bool>? onChanged,
  ) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.grey[850] : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(l10n.settings, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.autoSync),
              subtitle: Text(l10n.autoSyncDesc),
              value: autoSync,
              onChanged: isSignedIn ? onChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
