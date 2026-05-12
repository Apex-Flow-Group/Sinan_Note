// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class GoogleDriveWidgets {
  static Widget buildAccountSection(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    bool isSignedIn,
    String? userEmail,
    VoidCallback? onSignOut,
    VoidCallback? onSignIn,
  ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle,
                    size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(l10n.account,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (isSignedIn) ...[
              Row(
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.signedInAs,
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(userEmail ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.signOut)),
              ),
            ] else ...[
              Row(
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: Colors.grey[400], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(l10n.notSignedIn,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed: onSignIn,
                    icon: const Icon(Icons.login),
                    label: Text(l10n.signIn)),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync,
                    size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(l10n.syncStatus,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.lastSync,
                    style: Theme.of(context).textTheme.bodyLarge),
                Text(lastSyncTimeStr,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: isSignedIn ? onSync : null,
                  icon: const Icon(Icons.sync),
                  label: Text(l10n.syncNow)),
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    void showUploadSheet() {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_upload, color: Colors.blue, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.uploadDatabase,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(l10n.uploadDatabaseDesc,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAr
                      ? 'سيتم رفع ملاحظاتك العادية إلى Drive.\nالخزنة المشفرة لا تُرفع أبداً.'
                      : 'Your regular notes will be uploaded to Drive.\nEncrypted vault notes are never uploaded.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onUpload?.call();
                      },
                      icon: const Icon(Icons.cloud_upload, size: 18),
                      label: Text(isAr ? 'رفع' : 'Upload'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    void showDownloadSheet() {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_download, color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.downloadDatabase,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(l10n.downloadDatabaseDesc,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'سيتم استبدال ملاحظاتك المحلية بنسخة Drive.'
                            : 'Your local notes will be replaced with the Drive version.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDownload?.call();
                      },
                      icon: const Icon(Icons.cloud_download, size: 18),
                      label: Text(isAr ? 'تنزيل' : 'Download'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync,
                    size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(l10n.syncActions,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.cloud_upload, color: Colors.blue),
              ),
              title: Text(l10n.uploadDatabase),
              subtitle: Text(l10n.uploadDatabaseDesc),
              trailing: const Icon(Icons.chevron_right),
              enabled: isSignedIn,
              onTap: isSignedIn ? showUploadSheet : null,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.cloud_download, color: Colors.green),
              ),
              title: Text(l10n.downloadDatabase),
              subtitle: Text(l10n.downloadDatabaseDesc),
              trailing: const Icon(Icons.chevron_right),
              enabled: isSignedIn,
              onTap: isSignedIn ? showDownloadSheet : null,
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
    ValueChanged<bool>? onChanged, {
    bool pullToRefresh = true,
    ValueChanged<bool>? onPullToRefreshChanged,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings,
                        size: 28, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(l10n.settings,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
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
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(isArabic ? 'السحب للمزامنة' : 'Pull to Sync'),
                  subtitle: Text(isArabic
                      ? 'اسحب للأسفل لمزامنة يدوية'
                      : 'Pull down to manually sync'),
                  value: pullToRefresh,
                  onChanged: isSignedIn ? onPullToRefreshChanged : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // ── بطاقة تعليمية ثابتة ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'الخزنة المشفرة' : 'Encrypted Vault',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isArabic
                    ? '• الخزنة محلية بالكامل — لا تُرفع أبداً إلى Google Drive.\n• لمزامنة الخزنة يجب فك تشفير الملاحظات ونقلها يدوياً.\n• التطبيق غير مسؤول عن فقدان محتوى الخزنة.'
                    : '• The vault is fully local — never uploaded to Google Drive.\n• To sync vault notes, decrypt them manually first.\n• The app is not responsible for vault content loss.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
