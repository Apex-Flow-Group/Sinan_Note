// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';

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
    VoidCallback? onMerge,
  ) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    void showUploadSheet() {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          final bottomPad = MediaQuery.of(ctx).padding.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPad),
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
        );
        },
      );
    }

    void showDownloadSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          final bottomPad = MediaQuery.of(ctx).padding.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 16 + bottomPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان
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
                        Text(
                          isAr ? 'جلب من Drive' : 'Download from Drive',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAr ? 'اختر طريقة الجلب' : 'Choose how to download',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // خيار الدمج
              _buildDownloadOption(
                context: context,
                icon: Icons.merge,
                iconColor: Colors.blue,
                title: isAr ? 'دمج ذكي' : 'Smart Merge',
                description: isAr
                    ? 'يحتفظ بأحدث نسخة من كل ملاحظة.\nالأفضل للمزامنة بين أجهزة متعددة.'
                    : 'Keeps the latest version of each note.\nBest for syncing across multiple devices.',
                recommended: true,
                isAr: isAr,
                onTap: () {
                  Navigator.pop(ctx);
                  onMerge?.call();
                },
              ),
              const SizedBox(height: 12),

              // خيار الاستبدال
              _buildDownloadOption(
                context: context,
                icon: Icons.download_for_offline,
                iconColor: Colors.orange,
                title: isAr ? 'استبدال كامل' : 'Full Replace',
                description: isAr
                    ? 'يحذف كل الملاحظات المحلية ويستبدلها بنسخة Drive.\nاستخدم عند إعادة التثبيت فقط.'
                    : 'Deletes all local notes and replaces with Drive.\nUse only when reinstalling the app.',
                recommended: false,
                isAr: isAr,
                onTap: () {
                  Navigator.pop(ctx);
                  onDownload?.call();
                },
              ),
              const SizedBox(height: 16),

              // زر إلغاء
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
              ),
            ],
          ),
        );
        },
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

  static Widget _buildDownloadOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool recommended,
    required bool isAr,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: recommended
                ? Colors.blue.withValues(alpha: 0.5)
                : Colors.orange.withValues(alpha: 0.4),
            width: recommended ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: recommended
              ? Colors.blue.withValues(alpha: 0.04)
              : Colors.orange.withValues(alpha: 0.04),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAr ? 'موصى به' : 'Recommended',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: iconColor.withValues(alpha: 0.7), size: 20),
          ],
        ),
      ),
    );
  }
}

