// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/domain/errors.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/backup/backup_wizard_widgets.dart';
import 'package:sinan_note/screens/shared/settings/backup_restore_flow.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/features/backup/view_models/backup_view_model.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';

class BackupWizardScreen extends StatefulWidget {
  const BackupWizardScreen({super.key});

  @override
  State<BackupWizardScreen> createState() => _BackupWizardScreenState();
}

class _BackupWizardScreenState extends State<BackupWizardScreen> {
  // null = home (narrow only), 'backup' = backup flow, 'restore' = restore flow
  String? _flow;
  bool _isLoading = false;
  bool _wideInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isWide = PlatformHelper.isWideDisplay(context);
    if (isWide && !_wideInitialized) {
      _flow = 'backup';
      _wideInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isWide = PlatformHelper.isWideDisplay(context);

    return PopScope(
      canPop: _flow == null || isWide,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _flow = null);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: (!isWide && _flow != null)
                ? () => setState(() => _flow = null)
                : () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
          title: Text(
            isWide
                ? l10n.backupAndRestore
                : _flow == null
                    ? l10n.backupHomeTitle
                    : _flow == 'backup'
                        ? l10n.createBackup
                        : l10n.restoreDataTitle,
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? _buildLoading(l10n)
            : isWide
                ? _buildWideLayout(l10n, scheme)
                : _flow == null
                    ? _buildHome(l10n, scheme)
                    : _flow == 'backup'
                        ? _buildBackupFlow(l10n, scheme)
                        : _buildRestoreFlow(l10n, scheme),
      ),
    );
  }

  // ── Wide Layout (Master-Details) ──────────────────────────────────────────
  Widget _buildWideLayout(AppLocalizations l10n, ColorScheme scheme) {
    return Row(
      children: [
        // Master — قائمة الخيارات
        Container(
          width: 240,
          color: scheme.surfaceContainerLow,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Icon(Icons.shield_outlined, size: 48, color: scheme.primary),
              const SizedBox(height: 12),
              Text(
                l10n.yourDataIsSafe,
                style: context.text.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              BackupSideItem(
                icon: Icons.cloud_upload_outlined,
                label: l10n.createBackup,
                selected: _flow == 'backup',
                color: scheme.primary,
                onTap: () => setState(() => _flow = 'backup'),
              ),
              BackupSideItem(
                icon: Icons.cloud_download_outlined,
                label: l10n.restoreDataTitle,
                selected: _flow == 'restore',
                color: context.colors.success,
                onTap: () => setState(() => _flow = 'restore'),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Details — المحتوى
        Expanded(
          child: _flow == 'backup'
              ? _buildBackupFlow(l10n, scheme)
              : _buildRestoreFlow(l10n, scheme),
        ),
      ],
    );
  }

  // ── Home ──────────────────────────────────────────────────────────────────
  Widget _buildHome(AppLocalizations l10n, ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.shield_outlined, size: 72, color: scheme.primary),
          const SizedBox(height: 16),
          Text(
            l10n.yourDataIsSafe,
            style: context.text.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.backupHomeSubtitle,
            style: context.text.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FlowCard(
            icon: Icons.cloud_upload_outlined,
            color: scheme.primary,
            title: l10n.createBackup,
            subtitle: l10n.createBackupDesc,
            onTap: () => setState(() => _flow = 'backup'),
          ),
          const SizedBox(height: 16),
          FlowCard(
            icon: Icons.cloud_download_outlined,
            color: context.colors.success,
            title: l10n.restoreDataTitle,
            subtitle: l10n.restoreDataDesc,
            onTap: () => setState(() => _flow = 'restore'),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.vaultNotesNotExportedHint,
                    style: context.text.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Backup Flow ───────────────────────────────────────────────────────────
  Widget _buildBackupFlow(AppLocalizations l10n, ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BackupSectionHeader(
            icon: Icons.description_outlined,
            label: l10n.exportJson,
            color: scheme.primary,
          ),
          const SizedBox(height: 12),
          BackupOptionTile(
            icon: Icons.note_outlined,
            title: l10n.normalExport,
            subtitle: l10n.normalExportDesc,
            color: scheme.primary,
            actions: [
              BackupActionBtn(
                icon: Icons.save_alt,
                label: l10n.save,
                onTap: () => _exportJson(includeVault: false, share: false),
              ),
              BackupActionBtn(
                icon: Icons.share,
                label: l10n.share,
                onTap: () => _exportJson(includeVault: false, share: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BackupOptionTile(
            icon: Icons.lock_outlined,
            title: l10n.fullExportWithEncrypted,
            subtitle: l10n.fullExportWithEncryptedDesc,
            color: context.colors.vault,
            actions: [
              BackupActionBtn(
                icon: Icons.save_alt,
                label: l10n.save,
                onTap: () => _exportJson(includeVault: true, share: false),
              ),
              BackupActionBtn(
                icon: Icons.share,
                label: l10n.share,
                onTap: () => _exportJson(includeVault: true, share: true),
              ),
            ],
          ),
          const SizedBox(height: 24),
          BackupSectionHeader(
            icon: Icons.storage_outlined,
            label: l10n.exportDatabase,
            color: scheme.tertiary,
          ),
          const SizedBox(height: 12),
          BackupOptionTile(
            icon: Icons.storage_outlined,
            title: l10n.dbFileExport,
            subtitle: l10n.dbFileExportDesc,
            color: scheme.tertiary,
            actions: [
              BackupActionBtn(
                icon: Icons.save_alt,
                label: l10n.save,
                onTap: () => _exportDatabase(share: false),
              ),
              BackupActionBtn(
                icon: Icons.share,
                label: l10n.share,
                onTap: () => _exportDatabase(share: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Restore Flow ──────────────────────────────────────────────────────────
  Widget _buildRestoreFlow(AppLocalizations l10n, ColorScheme scheme) {
    final success = context.colors.success;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BackupOptionTile(
            icon: Icons.upload_file_outlined,
            title: l10n.importFromJson,
            subtitle: l10n.importFromJsonDesc,
            color: success,
            actions: [
              BackupActionBtn(
                icon: Icons.folder_open,
                label: l10n.chooseFile,
                onTap: () => _restoreJson(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // استعادة .db (SQLite) — النسخ القديمة بصيغة Isar تُرفض لأنها تتلف القاعدة
          BackupOptionTile(
            icon: Icons.storage_outlined,
            title: l10n.restoreDatabase,
            subtitle: l10n.restoreDatabaseDesc,
            color: scheme.secondary,
            actions: [
              BackupActionBtn(
                icon: Icons.folder_open,
                label: l10n.chooseFile,
                onTap: () => _restoreDatabase(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: success.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_fix_high, size: 18, color: success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.encryptedNotesAutoDecryptHint,
                    style: context.text.labelMedium?.copyWith(color: success),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(AppLocalizations l10n) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.processing),
          ],
        ),
      );

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _exportJson({
    required bool includeVault,
    required bool share,
  }) async {
    setState(() => _isLoading = true);
    try {
      final l10n = AppLocalizations.of(context)!;
      final backups = context.read<BackupViewModel>();
      if (share) {
        await backups.shareJson(
          includeVault: includeVault,
          subject: l10n.exportBackup,
          text: includeVault
              ? l10n.jsonFullBackupShareText
              : l10n.jsonBackupShareText,
        );
      } else {
        final dir = await FilePicker.platform.getDirectoryPath();
        if (dir == null) return;
        final file =
            await backups.exportJsonTo(dir, includeVault: includeVault);
        if (mounted) {
          UnifiedNotificationService().show(
            context: context,
            message: l10n.notesExportedTo(file.count, file.path),
            type: NotificationType.success,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UnifiedNotificationService().show(
          context: context,
          message: e is ValidationException
              ? AppLocalizations.of(context)!.noNotesToExport
              : '$e',
          type: NotificationType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreJson() => BackupRestoreFlow.pickAndRun(context);

  Future<void> _restoreDatabase() => BackupRestoreFlow.pickAndRun(context);

  Future<void> _exportDatabase({required bool share}) async {
    setState(() => _isLoading = true);
    try {
      if (share) {
        final l10n = AppLocalizations.of(context)!;
        await context.read<BackupViewModel>().share(
            subject: l10n.exportBackup, text: l10n.backupSaved);
      } else {
        final dir = await FilePicker.platform.getDirectoryPath();
        if (dir == null) return;
        if (!mounted) return;
        final outputPath =
            await context.read<BackupViewModel>().exportTo(dir);
        if (mounted) {
          UnifiedNotificationService().show(
            context: context,
            message:
                '${AppLocalizations.of(context)!.backupSaved}\n$outputPath',
            type: NotificationType.success,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UnifiedNotificationService().show(
          context: context,
          message: e.toString().replaceAll('Exception:', ''),
          type: NotificationType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────
