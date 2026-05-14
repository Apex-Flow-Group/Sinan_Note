// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/shared/settings/database_restore_handler.dart';
import 'package:apex_note/screens/shared/settings/json_import_handler.dart';
import 'package:apex_note/services/storage/backup_service.dart';
import 'package:apex_note/services/storage/storage_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class BackupWizardScreen extends StatefulWidget {
  const BackupWizardScreen({super.key});

  @override
  State<BackupWizardScreen> createState() => _BackupWizardScreenState();
}

class _BackupWizardScreenState extends State<BackupWizardScreen> {
  // null = home, 'backup' = backup flow, 'restore' = restore flow
  String? _flow;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 800;

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
    _flow ??= 'backup';
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
              _SideItem(
                icon: Icons.cloud_upload_outlined,
                label: isArabic ? 'إنشاء نسخة احتياطية' : 'Create Backup',
                selected: _flow == 'backup',
                color: scheme.primary,
                onTap: () => setState(() => _flow = 'backup'),
              ),
              _SideItem(
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
          _FlowCard(
            icon: Icons.cloud_upload_outlined,
            color: scheme.primary,
            title: isArabic ? 'إنشاء نسخة احتياطية' : 'Create Backup',
            subtitle: isArabic
                ? 'صدّر ملاحظاتك كملف JSON أو قاعدة بيانات'
                : 'Export your notes as JSON or database file',
            onTap: () => setState(() => _flow = 'backup'),
          ),
          const SizedBox(height: 16),
          _FlowCard(
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
          _SectionHeader(
            icon: Icons.description_outlined,
            label: isArabic ? 'تصدير JSON' : 'JSON Export',
            color: scheme.primary,
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.note_outlined,
            title: isArabic ? 'تصدير عادي' : 'Normal Export',
            subtitle: isArabic
                ? 'ملاحظاتك العادية فقط — نص قابل للقراءة في أي مكان'
                : 'Regular notes only — readable anywhere',
            color: scheme.primary,
            actions: [
              _ActionBtn(
                icon: Icons.save_alt,
                label: isArabic ? 'حفظ' : 'Save',
                onTap: () => _exportJson(includeVault: false, share: false),
              ),
              _ActionBtn(
                icon: Icons.share,
                label: isArabic ? 'مشاركة' : 'Share',
                onTap: () => _exportJson(includeVault: false, share: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.lock_outlined,
            title: isArabic
                ? 'تصدير كامل (مع المشفرة)'
                : 'Full Export (with encrypted)',
            subtitle: isArabic
                ? 'يشمل الملاحظات المشفرة كـ ciphertext — تحتاج مفتاح الخزنة للاستعادة'
                : 'Includes encrypted notes as ciphertext — vault key needed to restore',
            color: Colors.orange,
            actions: [
              _ActionBtn(
                icon: Icons.save_alt,
                label: isArabic ? 'حفظ' : 'Save',
                onTap: () => _exportJson(includeVault: true, share: false),
              ),
              _ActionBtn(
                icon: Icons.share,
                label: isArabic ? 'مشاركة' : 'Share',
                onTap: () => _exportJson(includeVault: true, share: true),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.storage_outlined,
            label: isArabic ? 'تصدير قاعدة البيانات' : 'Database Export',
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.storage_outlined,
            title: isArabic ? 'ملف .db' : '.db File',
            subtitle: isArabic
                ? 'نسخة كاملة من قاعدة البيانات — أسرع استعادة'
                : 'Full database copy — fastest restore',
            color: Colors.teal,
            actions: [
              _ActionBtn(
                icon: Icons.save_alt,
                label: isArabic ? 'حفظ' : 'Save',
                onTap: () => _exportDatabase(share: false),
              ),
              _ActionBtn(
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
          _OptionTile(
            icon: Icons.upload_file_outlined,
            title: isArabic ? 'استيراد من JSON' : 'Import from JSON',
            subtitle: isArabic
                ? 'استورد من ملف .json — يدعم الدمج أو الاستبدال'
                : 'Import from .json file — supports merge or replace',
            color: Colors.green,
            actions: [
              _ActionBtn(
                icon: Icons.folder_open,
                label: isArabic ? 'اختر ملف' : 'Choose File',
                onTap: () => _restoreJson(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // استعادة .db/.sinannote/.isar — متاحة دائماً لمن عنده نسخة قديمة
          _OptionTile(
            icon: Icons.storage_outlined,
            title: isArabic ? 'استعادة قاعدة البيانات' : 'Restore Database',
            subtitle: isArabic
                ? 'استعد من ملف .db أو .sinannote أو .isar'
                : 'Restore from .db, .sinannote or .isar file',
            color: Colors.purple,
            actions: [
              _ActionBtn(
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

class _FlowCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FlowCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final List<_ActionBtn> actions;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: actions
                .map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: a,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _SideItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: selected ? color : scheme.onSurfaceVariant),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? color : null,
          ),
        ),
        selected: selected,
        selectedTileColor: color.withValues(alpha: 0.1),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
      ),
    );
  }
}
