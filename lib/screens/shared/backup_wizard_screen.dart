// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/backup/backup_wizard_widgets.dart';
import 'package:sinan_note/screens/shared/settings/database_restore_handler.dart';
import 'package:sinan_note/screens/shared/settings/json_import_handler.dart';
import 'package:sinan_note/services/storage/backup_service.dart';
import 'package:sinan_note/services/storage/storage_service.dart';
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
                ? (isArabic ? 'النسخ الاحتياطي والاستعادة' : 'Backup & Restore')
                : _flow == null
                    ? (isArabic ? 'النسخ الاحتياطي' : 'Backup & Restore')
                    : _flow == 'backup'
                        ? (isArabic ? 'إنشاء نسخة احتياطية' : 'Create Backup')
                        : (isArabic ? 'استعادة البيانات' : 'Restore Data'),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? _buildLoading(isArabic)
            : isWide
                ? _buildWideLayout(l10n, isArabic, scheme)
                : _flow == null
                    ? _buildHome(l10n, isArabic, scheme)
                    : _flow == 'backup'
                        ? _buildBackupFlow(l10n, isArabic, scheme)
                        : _buildRestoreFlow(l10n, isArabic, scheme),
      ),
    );
  }

  // ── Wide Layout (Master-Details) ──────────────────────────────────────────
  Widget _buildWideLayout(
      AppLocalizations l10n, bool isArabic, ColorScheme scheme) {
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
                isArabic ? 'بياناتك في أمان' : 'Your data is safe',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              BackupSideItem(
                icon: Icons.cloud_upload_outlined,
                label: isArabic ? 'إنشاء نسخة احتياطية' : 'Create Backup',
                selected: _flow == 'backup',
                color: scheme.primary,
                onTap: () => setState(() => _flow = 'backup'),
              ),
              BackupSideItem(
                icon: Icons.cloud_download_outlined,
                label: isArabic ? 'استعادة البيانات' : 'Restore Data',
                selected: _flow == 'restore',
                color: Colors.green,
                onTap: () => setState(() => _flow = 'restore'),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Details — المحتوى
        Expanded(
          child: _flow == 'backup'
              ? _buildBackupFlow(l10n, isArabic, scheme)
              : _buildRestoreFlow(l10n, isArabic, scheme),
        ),
      ],
    );
  }

  // ── Home ──────────────────────────────────────────────────────────────────
  Widget _buildHome(AppLocalizations l10n, bool isArabic, ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.shield_outlined, size: 72, color: scheme.primary),
          const SizedBox(height: 16),
          Text(
            isArabic ? 'بياناتك في أمان' : 'Your data is safe',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'احفظ نسخة من ملاحظاتك أو استعدها من نسخة سابقة'
                : 'Save a copy of your notes or restore from a previous backup',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FlowCard(
            icon: Icons.cloud_upload_outlined,
            color: scheme.primary,
            title: isArabic ? 'إنشاء نسخة احتياطية' : 'Create Backup',
            subtitle: isArabic
                ? 'صدّر ملاحظاتك كملف JSON أو قاعدة بيانات'
                : 'Export your notes as JSON or database file',
            onTap: () => setState(() => _flow = 'backup'),
          ),
          const SizedBox(height: 16),
          FlowCard(
            icon: Icons.cloud_download_outlined,
            color: Colors.green,
            title: isArabic ? 'استعادة البيانات' : 'Restore Data',
            subtitle: isArabic
                ? 'استورد من ملف JSON أو قاعدة بيانات سابقة'
                : 'Import from a JSON or database backup file',
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
                    isArabic
                        ? 'الملاحظات المشفرة في الخزنة لا تُصدَّر تلقائياً — اختر "تصدير كامل" لتضمينها'
                        : 'Encrypted vault notes are not exported by default — choose "Full Export" to include them',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
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
  Widget _buildBackupFlow(
    AppLocalizations l10n,
    bool isArabic,
    ColorScheme scheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BackupSectionHeader(
            icon: Icons.description_outlined,
            label: isArabic ? 'تصدير JSON' : 'JSON Export',
            color: scheme.primary,
          ),
          const SizedBox(height: 12),
          BackupOptionTile(
            icon: Icons.note_outlined,
            title: isArabic ? 'تصدير عادي' : 'Normal Export',
            subtitle: isArabic
                ? 'ملاحظاتك العادية فقط — نص قابل للقراءة في أي مكان'
                : 'Regular notes only — readable anywhere',
            color: scheme.primary,
            actions: [
              BackupActionBtn(
                icon: Icons.save_alt,
                label: isArabic ? 'حفظ' : 'Save',
                onTap: () => _exportJson(includeVault: false, share: false),
              ),
              BackupActionBtn(
                icon: Icons.share,
                label: isArabic ? 'مشاركة' : 'Share',
                onTap: () => _exportJson(includeVault: false, share: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BackupOptionTile(
            icon: Icons.lock_outlined,
            title: isArabic
                ? 'تصدير كامل (مع المشفرة)'
                : 'Full Export (with encrypted)',
            subtitle: isArabic
                ? 'يشمل الملاحظات المشفرة كـ ciphertext — تحتاج مفتاح الخزنة للاستعادة'
                : 'Includes encrypted notes as ciphertext — vault key needed to restore',
            color: Colors.orange,
            actions: [
              BackupActionBtn(
                icon: Icons.save_alt,
                label: isArabic ? 'حفظ' : 'Save',
                onTap: () => _exportJson(includeVault: true, share: false),
              ),
              BackupActionBtn(
                icon: Icons.share,
                label: isArabic ? 'مشاركة' : 'Share',
                onTap: () => _exportJson(includeVault: true, share: true),
              ),
            ],
          ),
          const SizedBox(height: 24),
          BackupSectionHeader(
            icon: Icons.storage_outlined,
            label: isArabic ? 'تصدير قاعدة البيانات' : 'Database Export',
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          BackupOptionTile(
            icon: Icons.storage_outlined,
            title: isArabic ? 'ملف .db' : '.db File',
            subtitle: isArabic
                ? 'نسخة كاملة من قاعدة البيانات — أسرع استعادة'
                : 'Full database copy — fastest restore',
            color: Colors.teal,
            actions: [
              BackupActionBtn(
                icon: Icons.save_alt,
                label: isArabic ? 'حفظ' : 'Save',
                onTap: () => _exportDatabase(share: false),
              ),
              BackupActionBtn(
                icon: Icons.share,
                label: isArabic ? 'مشاركة' : 'Share',
                onTap: () => _exportDatabase(share: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Restore Flow ──────────────────────────────────────────────────────────
  Widget _buildRestoreFlow(
    AppLocalizations l10n,
    bool isArabic,
    ColorScheme scheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BackupOptionTile(
            icon: Icons.upload_file_outlined,
            title: isArabic ? 'استيراد من JSON' : 'Import from JSON',
            subtitle: isArabic
                ? 'استورد من ملف .json — يدعم الدمج أو الاستبدال'
                : 'Import from .json file — supports merge or replace',
            color: Colors.green,
            actions: [
              BackupActionBtn(
                icon: Icons.folder_open,
                label: isArabic ? 'اختر ملف' : 'Choose File',
                onTap: () => _restoreJson(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // استعادة .db/.sinannote/.isar — متاحة دائماً لمن عنده نسخة قديمة
          BackupOptionTile(
            icon: Icons.storage_outlined,
            title: isArabic ? 'استعادة قاعدة البيانات' : 'Restore Database',
            subtitle: isArabic
                ? 'استعد من ملف .db أو .sinannote أو .isar'
                : 'Restore from .db, .sinannote or .isar file',
            color: Colors.purple,
            actions: [
              BackupActionBtn(
                icon: Icons.folder_open,
                label: isArabic ? 'اختر ملف' : 'Choose File',
                onTap: () => _restoreDatabase(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_fix_high, size: 18, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isArabic
                        ? 'الملاحظات المشفرة تُفك تلقائياً عند توفر مفتاح الخزنة'
                        : 'If the file contains encrypted notes and you have the vault key — they will be decrypted automatically',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(bool isArabic) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(isArabic ? 'جاري المعالجة...' : 'Processing...'),
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
      if (share) {
        await StorageService().shareNotesFile(includeVault: includeVault);
      } else {
        final dir = await FilePicker.platform.getDirectoryPath();
        if (dir == null) return;
        final msg = await StorageService().exportNotesToPath(
          dir,
          includeVault: includeVault,
        );
        if (mounted) {
          UnifiedNotificationService().show(
            context: context,
            message: msg,
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

  Future<void> _restoreJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    await JsonImportHandler.handle(
      context,
      lang,
      l10n,
      result.files.single.path!,
    );
  }

  Future<void> _restoreDatabase() async {
    final backupPath = await BackupService().pickBackupFile();
    if (backupPath == null) return;
    if (!mounted) return;
    final lang = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    await DatabaseRestoreHandler.handle(context, lang, l10n, backupPath);
  }

  Future<void> _exportDatabase({required bool share}) async {
    setState(() => _isLoading = true);
    try {
      if (share) {
        await BackupService().shareDatabase();
      } else {
        final dir = await FilePicker.platform.getDirectoryPath();
        if (dir == null) return;
        final outputPath = await BackupService().exportDatabaseToPath(dir);
        if (mounted) {
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          UnifiedNotificationService().show(
            context: context,
            message: isArabic
                ? 'تم حفظ النسخة الاحتياطية:\n$outputPath'
                : 'Backup saved:\n$outputPath',
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
