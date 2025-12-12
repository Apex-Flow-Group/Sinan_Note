// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import '../services/settings_provider.dart';
import '../services/notes_provider.dart';
import '../services/biometric_service.dart';
import '../services/storage_service.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import '../services/apex_diagnostics_engine.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../utils/adaptive_color.dart';
import '../widgets/apex_snackbar.dart';
import 'transfer_screen.dart';
import 'transfer_screen_helper.dart';
import 'support_form_screen.dart';
import 'about_screen.dart';
import '../widgets/custom_share_sheet.dart';
import '../config/flavor_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = 'v${info.version}');
    } catch (e) {
      // Failed to load version info
    }
  }

  // Reusable Section Header Widget
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);
    final systemLocale =
        View.of(context).platformDispatcher.locale.languageCode;
    final currentLang = settings.languageCode == 'system'
        ? systemLocale
        : settings.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16),
            children: [
              // GENERAL SECTION
              _buildSectionHeader(l10n.general),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.language),
                subtitle: Text(_getLanguageText(settings.languageCode, l10n)),
                onTap: () => _showLanguageDialog(context, settings, l10n),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: Text(l10n.theme),
                subtitle: Text(_getThemeText(settings.themeMode, currentLang)),
                onTap: () => _showThemeDialog(context, settings),
              ),
              ListTile(
                leading: const Icon(Icons.format_size),
                title: Text(l10n.fontSize),
                subtitle: Text("${(settings.textScaleFactor * 100).round()}%"),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: settings.textScaleFactor,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    onChanged: (value) => settings.setTextScaleFactor(value),
                  ),
                ),
              ),

              // EDITOR SECTION
              _buildSectionHeader(l10n.editor),
              ListTile(
                leading: const Icon(Icons.palette),
                title: Text(l10n.noteColors),
                subtitle: Text(l10n.chooseDefaultColor),
              ),
              _buildColorOption(
                  context, settings, 'simple', l10n.simpleNote, currentLang),
              _buildColorOption(
                  context, settings, 'reminder', l10n.reminder, currentLang),
              _buildColorOption(context, settings, 'professional',
                  l10n.proEditor, currentLang),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.auto_awesome),
                title: Text(l10n.cardShineEffect),
                subtitle: Text(
                  settings.cardMotionEnabled ? l10n.enabled : l10n.disabled,
                ),
                value: settings.cardMotionEnabled,
                onChanged: (val) => settings.setCardMotionEnabled(val),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.swipe),
                title: Text(l10n.swipeGestures),
                subtitle: Text(
                  settings.swipeEnabled ? l10n.enabled : l10n.disabled,
                ),
                value: settings.swipeEnabled,
                onChanged: (val) => settings.setSwipeEnabled(val),
              ),
              if (settings.swipeEnabled) ...[
                ListTile(
                  contentPadding:
                      const EdgeInsetsDirectional.only(start: 72, end: 16),
                  title: Text(l10n.swipeRight),
                  subtitle: Text(_getSwipeActionText(
                      settings.swipeRightAction, currentLang)),
                  onTap: () => _showSwipeActionDialog(
                      context, settings, true, currentLang),
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsetsDirectional.only(start: 72, end: 16),
                  title: Text(l10n.swipeLeft),
                  subtitle: Text(_getSwipeActionText(
                      settings.swipeLeftAction, currentLang)),
                  onTap: () => _showSwipeActionDialog(
                      context, settings, false, currentLang),
                ),
              ],

              // SECURITY SECTION
              _buildSectionHeader(l10n.security),
              SwitchListTile(
                secondary: const Icon(Icons.lock),
                title: Text(l10n.appLock),
                subtitle: Text(
                  settings.isAppLockEnabled ? l10n.enabled : l10n.disabled,
                ),
                value: settings.isAppLockEnabled,
                onChanged: (val) async {
                  final authenticated = await BiometricService.authenticate();
                  if (authenticated) {
                    await settings.setAppLockEnabled(val);
                  } else {
                    if (mounted) setState(() {});
                  }
                },
              ),
              if (settings.isAppLockEnabled)
                SwitchListTile(
                  contentPadding:
                      const EdgeInsetsDirectional.only(start: 72, end: 16),
                  title: Text(l10n.lockDelay),
                  subtitle: Text(settings.lockDelayEnabled
                      ? _getLockDelayText(settings.lockDelaySeconds, l10n)
                      : l10n.immediate),
                  value: settings.lockDelayEnabled,
                  onChanged: (val) async {
                    if (val) {
                      await _showLockDelayDialog(context, settings, l10n);
                    } else {
                      await settings.setLockDelayEnabled(false);
                    }
                  },
                ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_off),
                title: Text(l10n.hideContentInBackground),
                subtitle: Text(l10n.applyBlurEffect),
                value: settings.hideContentInBackground,
                onChanged: (val) => settings.setHideContentInBackground(val),
              ),

              // DATA SECTION
              _buildSectionHeader(l10n.data),
              if (FlavorConfig.hasTransferFeature)
                ListTile(
                  leading: const Icon(Icons.sync_alt, color: Colors.blue),
                  title: Text(l10n.transferTitle),
                  subtitle: Text(l10n.localNetworkTransfer),
                  onTap: () async {
                    final dbService = DatabaseService();
                    final db = await dbService.database;
                    final lockedCount = Sqflite.firstIntValue(await db.rawQuery(
                            'SELECT COUNT(*) FROM notes WHERE isLocked = 1')) ??
                        0;

                    if (lockedCount > 0) {
                      final agreed = await TransferAgreementDialog.show(
                          context, currentLang == 'ar', lockedCount);
                      if (agreed != true) return;
                    }

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TransferScreen()));
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined,
                    color: Colors.green),
                title: Text(l10n.exportBackup),
                subtitle: Text(l10n.exportDatabase),
                onTap: () => _showBackupDialog(context, currentLang, l10n),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined,
                    color: Colors.orange),
                title: Text(l10n.restore),
                subtitle: Text(l10n.restoreFromBackup),
                onTap: () => _handleSmartRestore(context, currentLang, l10n),
              ),
              ListTile(
                leading: const Icon(Icons.upload_file, color: Colors.blue),
                title: Text(l10n.exportJson),
                subtitle: Text(l10n.saveAsJsonFile),
                onTap: () => _showExportDialog(context, currentLang, l10n),
              ),
              ListTile(
                leading:
                    const Icon(Icons.download_for_offline, color: Colors.green),
                title: Text(l10n.importJson),
                subtitle: Text(l10n.restoreFromJson),
                onTap: () => _handleImportJSON(context, l10n),
              ),

              // ABOUT SECTION
              _buildSectionHeader(l10n.about),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(l10n.feedback),
                subtitle: Text(l10n.contactUs),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportFormScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.shareApp),
                onTap: () => CustomShareSheet.show(context, currentLang == 'ar'
                    ? 'جرب Sinan Note!'
                    : 'Try Sinan Note!'),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutApp),
                subtitle: Text(_version),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              if (kDebugMode)
                ListTile(
                  leading: const Icon(Icons.bug_report, color: Colors.red),
                  title: Text(l10n.diagnostics),
                  subtitle: Text(l10n.developersOnly),
                  onTap: () => _showDiagnostics(context, l10n, currentLang),
                ),

              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(l10n.poweredBy,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    Text(l10n.companyName,
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Methods
  String _getLanguageText(String code, AppLocalizations l10n) {
    switch (code) {
      case 'ar':
        return l10n.arabic;
      case 'en':
        return l10n.english;
      default:
        return l10n.system;
    }
  }

  String _getThemeText(ThemeMode mode, String lang) {
    final l10n = AppLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.system:
        return l10n.systemTheme;
      case ThemeMode.light:
        return l10n.lightTheme;
      case ThemeMode.dark:
        return l10n.darkTheme;
    }
  }

  String _getSwipeActionText(String action, String lang) {
    final l10n = AppLocalizations.of(context)!;
    switch (action) {
      case 'delete':
        return l10n.delete;
      case 'archive':
        return l10n.archive;
      case 'share':
        return l10n.share;
      default:
        return l10n.delete;
    }
  }

  Widget _buildColorOption(BuildContext context, SettingsProvider settings,
      String mode, String title, String lang) {
    final brightness = Theme.of(context).brightness;
    final colorIndex = settings.getDefaultColorIndex(mode);
    final color = AppColorPalette.palette[colorIndex].getColor(brightness);
    
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 72, end: 16),
      title: Text(title),
      trailing: GestureDetector(
        onTap: () => _showColorPicker(context, settings, mode, lang),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                color: Theme.of(context).colorScheme.outline, width: 2),
          ),
        ),
      ),
    );
  }

  // Dialog Methods (keeping existing implementations)
  void _showLanguageDialog(
      BuildContext context, SettingsProvider settings, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.system),
              leading: Radio<String>(
                value: 'system',
                groupValue: settings.languageCode,
                onChanged: (val) {
                  settings.setLanguage(val!);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                settings.setLanguage('system');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.arabic),
              leading: Radio<String>(
                value: 'ar',
                groupValue: settings.languageCode,
                onChanged: (val) {
                  settings.setLanguage(val!);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                settings.setLanguage('ar');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.english),
              leading: Radio<String>(
                value: 'en',
                groupValue: settings.languageCode,
                onChanged: (val) {
                  settings.setLanguage(val!);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                settings.setLanguage('en');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chooseTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.systemTheme),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                onChanged: (val) {
                  settings.setThemeMode(val!);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                settings.setThemeMode(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.lightTheme),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                onChanged: (val) {
                  settings.setThemeMode(val!);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                settings.setThemeMode(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.darkTheme),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: settings.themeMode,
                onChanged: (val) {
                  settings.setThemeMode(val!);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                settings.setThemeMode(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSwipeActionDialog(BuildContext context, SettingsProvider settings,
      bool isRight, String lang) {
    final l10n = AppLocalizations.of(context)!;
    final currentValue = isRight ? settings.swipeRightAction : settings.swipeLeftAction;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRight ? l10n.swipeRight : l10n.swipeLeft),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.delete),
              leading: Radio<String>(
                value: 'delete',
                groupValue: currentValue,
                onChanged: (val) {
                  if (isRight) {
                    settings.setSwipeRightAction(val!);
                  } else {
                    settings.setSwipeLeftAction(val!);
                  }
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                if (isRight) {
                  settings.setSwipeRightAction('delete');
                } else {
                  settings.setSwipeLeftAction('delete');
                }
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.archive),
              leading: Radio<String>(
                value: 'archive',
                groupValue: currentValue,
                onChanged: (val) {
                  if (isRight) {
                    settings.setSwipeRightAction(val!);
                  } else {
                    settings.setSwipeLeftAction(val!);
                  }
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                if (isRight) {
                  settings.setSwipeRightAction('archive');
                } else {
                  settings.setSwipeLeftAction('archive');
                }
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.share),
              leading: Radio<String>(
                value: 'share',
                groupValue: currentValue,
                onChanged: (val) {
                  if (isRight) {
                    settings.setSwipeRightAction(val!);
                  } else {
                    settings.setSwipeLeftAction(val!);
                  }
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                if (isRight) {
                  settings.setSwipeRightAction('share');
                } else {
                  settings.setSwipeLeftAction('share');
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, SettingsProvider settings,
      String mode, String lang) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final currentIndex = settings.getDefaultColorIndex(mode);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chooseColor),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(AppColorPalette.palette.length, (index) {
            final adaptiveColor = AppColorPalette.palette[index];
            final color = adaptiveColor.getColor(brightness);
            
            return GestureDetector(
              onTap: () {
                settings.setDefaultColorIndex(mode, index);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentIndex == index
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showBackupDialog(
      BuildContext context, String lang, AppLocalizations l10n) async {
    // Check for locked notes
    try {
      final dbService = DatabaseService();
      final db = await dbService.database;
      final lockedCount = Sqflite.firstIntValue(await db
              .rawQuery('SELECT COUNT(*) FROM notes WHERE isLocked = 1')) ??
          0;

      if (lockedCount > 0) {
        final agreed =
            await _showEncryptionAgreement(context, l10n, lang, lockedCount);
        if (agreed != true) return;
      }
    } catch (e) {
      if (context.mounted) {
        ApexSnackBar.show(context, 'Database error', type: SnackBarType.error);
      }
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exportBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: Text(l10n.saveToFolder),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final result = await FilePicker.platform.getDirectoryPath();
                  if (result == null) {
                    ApexSnackBar.show(context, l10n.noFileSelected,
                        type: SnackBarType.warning);
                    return;
                  }
                  final outputPath = await BackupService().exportDatabaseToPath(result);
                  ApexSnackBar.show(context, '${l10n.backupSaved}\n$outputPath',
                      type: SnackBarType.success,
                      duration: const Duration(seconds: 4));
                } catch (e) {
                  ApexSnackBar.show(
                      context, e.toString().replaceAll('Exception:', ''),
                      type: SnackBarType.error);
                }
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: Text(l10n.share),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await BackupService().shareDatabase();
                } catch (e) {
                  ApexSnackBar.show(
                      context, e.toString().replaceAll('Exception:', ''),
                      type: SnackBarType.error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showEncryptionAgreement(BuildContext context,
      AppLocalizations l10n, String lang, int lockedCount) {
    bool agreed = false;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.security, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.disclaimer,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      lang == 'ar'
                          ? '''تحذير هام - النسخ الاحتياطي للملاحظات المشفرة

تحذير: لديك $lockedCount ملاحظة مقفلة ومشفرة.

ما يجب أن تعرفه:

1. التشفير المستخدم:
   • يستخدم التطبيق تشفير AES-256 لحماية ملاحظاتك المقفلة.
   • المفتاح محفوظ في مخزن آمن على جهازك.

2. النسخ الاحتياطي:
   • سيتم حفظ الملاحظات المقفلة في النسخة الاحتياطية بصيغة مشفرة.
   • لا يمكن قراءتها بدون مفتاح التشفير الخاص بجهازك.

3. الاستعادة:
   • يمكنك استعادة النسخة الاحتياطية على نفس الجهاز بدون مشاكل.
   • إذا قمت بتثبيت التطبيق على جهاز جديد، سيتم إنشاء مفتاح تشفير جديد.
   • الملاحظات المقفلة من الجهاز القديم ستبقى مشفرة ولن يمكن فك تشفيرها.

تحذير حرج:
   • إذا قمت بإلغاء تثبيت التطبيق، سيتم فقدان مفتاح التشفير نهائياً.
   • إذا قمت بمسح بيانات التطبيق، سيتم فقدان مفتاح التشفير نهائياً.
   • لا توجد طريقة لاستعادة الملاحظات المشفرة بدون المفتاح الأصلي.

التوصيات:
   • احتفظ بنسخة احتياطية من ملاحظاتك المهمة بصيغة غير مشفرة (فك القفل أولاً).
   • لا تعتمد على النسخ الاحتياطية المشفرة كمصدر وحيد.
   • تأكد من حفظ ملاحظاتك الحساسة في أماكن متعددة.

إخلاء المسؤولية:
   • Apex Flow Group غير مسؤولة عن فقدان البيانات المشفرة.
   • أنت المسؤول الوحيد عن إدارة نسخك الاحتياطية.
   • التشفير يوفر الأمان لكنه يزيد من خطر فقدان البيانات في حالة فقدان المفتاح.

بالمتابعة، أنت تقر بأنك:
✓ قرأت وفهمت جميع المخاطر المذكورة أعلاه.
✓ تتحمل المسؤولية الكاملة عن بياناتك المشفرة.
✓ تدرك أنه لا يمكن استعادة البيانات المشفرة بدون المفتاح الأصلي.'''
                          : '''Important Warning - Encrypted Notes Backup

Warning: You have $lockedCount locked and encrypted notes.

What you need to know:

1. Encryption Used:
   • The app uses AES-256 encryption to protect your locked notes.
   • The key is stored in secure storage on your device.

2. Backup:
   • Locked notes will be saved in encrypted format in the backup.
   • They cannot be read without your device's encryption key.

3. Restoration:
   • You can restore the backup on the same device without issues.
   • If you install the app on a new device, a new encryption key will be generated.
   • Locked notes from the old device will remain encrypted and cannot be decrypted.

Critical Warning:
   • If you uninstall the app, the encryption key will be permanently lost.
   • If you clear app data, the encryption key will be permanently lost.
   • There is NO way to recover encrypted notes without the original key.

Recommendations:
   • Keep a backup of important notes in unencrypted format (unlock first).
   • Don't rely solely on encrypted backups.
   • Ensure you save sensitive notes in multiple locations.

Disclaimer:
   • Apex Flow Group is NOT responsible for loss of encrypted data.
   • You are solely responsible for managing your backups.
   • Encryption provides security but increases risk of data loss if key is lost.

By continuing, you acknowledge that:
✓ You have read and understood all risks mentioned above.
✓ You take full responsibility for your encrypted data.
✓ You understand that encrypted data cannot be recovered without the original key.''',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: agreed,
                  onChanged: (val) =>
                      setDialogState(() => agreed = val ?? false),
                  title: Text(
                    lang == 'ar'
                        ? 'نعم، قرأت وأنا على اطلاع كامل بالمخاطر'
                        : 'Yes, I have read and fully understand the risks',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: agreed ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: agreed ? Colors.red : Colors.grey,
              ),
              child: Text(l10n.continueAction),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(
      BuildContext context, String lang, AppLocalizations l10n) async {
    // Check for locked notes
    try {
      final dbService = DatabaseService();
      final db = await dbService.database;
      final lockedCount = Sqflite.firstIntValue(await db
              .rawQuery('SELECT COUNT(*) FROM notes WHERE isLocked = 1')) ??
          0;

      if (lockedCount > 0) {
        final agreed =
            await _showEncryptionAgreement(context, l10n, lang, lockedCount);
        if (agreed != true) return;
      }
    } catch (e) {
      if (context.mounted) {
        ApexSnackBar.show(context, 'Database error', type: SnackBarType.error);
      }
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.exportJson),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: Text(l10n.saveToFolder),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final result = await FilePicker.platform.getDirectoryPath();
                  if (result == null) {
                    ApexSnackBar.show(context, l10n.noFileSelected,
                        type: SnackBarType.warning);
                    return;
                  }
                  final message = await StorageService().exportNotesToPath(result);
                  ApexSnackBar.show(context, message,
                      type: SnackBarType.success,
                      duration: const Duration(seconds: 4));
                } catch (e) {
                  ApexSnackBar.show(
                      context, e.toString().replaceAll('Exception:', ''),
                      type: SnackBarType.error);
                }
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: Text(l10n.share),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await StorageService().shareNotesFile();
                } catch (e) {
                  ApexSnackBar.show(
                      context, e.toString().replaceAll('Exception:', ''),
                      type: SnackBarType.error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImportJSON(
      BuildContext context, AppLocalizations l10n) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.warning),
        content: Text(l10n.replaceAllNotes),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.replace,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        int count = await StorageService().importNotesFromDevice();
        if (count > 0 && mounted) {
          setState(() {});
          ApexSnackBar.show(context, "$count ${l10n.importedSuccessfully}",
              type: SnackBarType.success);
        }
      } catch (e) {
        ApexSnackBar.show(context, e.toString().replaceAll('Exception:', ''),
            type: SnackBarType.error);
      }
    }
  }

  void _handleSmartRestore(
      BuildContext context, String lang, AppLocalizations l10n) async {
    // Check for locked notes in current database
    try {
      final dbService = DatabaseService();
      final db = await dbService.database;
      final lockedCount = Sqflite.firstIntValue(await db
              .rawQuery('SELECT COUNT(*) FROM notes WHERE isLocked = 1')) ??
          0;

      if (lockedCount > 0) {
        final agreed =
            await _showEncryptionAgreement(context, l10n, lang, lockedCount);
        if (agreed != true) return;
      }
    } catch (e) {
      if (context.mounted) {
        ApexSnackBar.show(context, 'Database error', type: SnackBarType.error);
      }
      return;
    }

    try {
      final backupPath = await BackupService().pickBackupFile();
      if (backupPath == null) {
        // User cancelled - do nothing
        return;
      }

      final localCount = await BackupService().checkLocalNotesCount();

      if (localCount == 0) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary),
            ),
          );
        }

        final dbService = DatabaseService();
        await dbService.closeDB();
        await BackupService().replaceDatabase(backupPath);
        await dbService.reopenDatabase();

        if (context.mounted) {
          await Provider.of<NotesProvider>(context, listen: false).loadNotes();
        }

        final restoredCount = await BackupService().checkLocalNotesCount();

        if (context.mounted) {
          Navigator.pop(context);

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A2332)
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              icon: Icon(Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary, size: 50),
              title: Text(
                l10n.restoreSuccessful,
                textAlign: TextAlign.center,
              ),
              content: Text(
                lang == 'ar'
                    ? 'تم استعادة $restoredCount ملاحظة/مذكرات.'
                    : 'Successfully restored $restoredCount notes.',
                textAlign: TextAlign.center,
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.ok),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        final action = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.warning),
            content: Text(lang == 'ar'
                ? 'لديك $localCount ملاحظة حالياً. ماذا تريد أن تفعل؟'
                : 'You have $localCount notes. What do you want to do?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'merge'),
                child: Text(l10n.merge),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'replace'),
                child: Text(l10n.replace,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        );

        if (action == 'merge') {
          await BackupService().mergeDatabase(backupPath);
          if (context.mounted) {
            await Provider.of<NotesProvider>(context, listen: false)
                .loadNotes();
            ApexSnackBar.show(context, l10n.mergedSuccessfully,
                type: SnackBarType.success);
          }
        } else if (action == 'replace') {
          final dbService = DatabaseService();
          await dbService.closeDB();
          await BackupService().replaceDatabase(backupPath);
          await dbService.reopenDatabase();
          if (context.mounted) {
            await Provider.of<NotesProvider>(context, listen: false)
                .loadNotes();
            ApexSnackBar.show(context, l10n.restoredSuccessfully,
                type: SnackBarType.success);
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ApexSnackBar.show(context, e.toString().replaceAll('Exception:', ''),
            type: SnackBarType.error);
      }
    }
  }

  String _getLockDelayText(int seconds, AppLocalizations l10n) {
    switch (seconds) {
      case 30:
        return l10n.seconds30;
      case 120:
        return l10n.minutes2;
      case 180:
        return l10n.minutes3;
      case 300:
        return l10n.minutes5;
      default:
        return '$seconds ${l10n.seconds30.split(' ')[1]}';
    }
  }

  Future<void> _showLockDelayDialog(
      BuildContext context, SettingsProvider settings, AppLocalizations l10n) async {
    final delays = [
      {'seconds': 30, 'label': l10n.seconds30},
      {'seconds': 120, 'label': l10n.minutes2},
      {'seconds': 180, 'label': l10n.minutes3},
      {'seconds': 300, 'label': l10n.minutes5},
    ];

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.selectLockDelay),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: delays.map((delay) {
            return ListTile(
              title: Text(delay['label'] as String),
              leading: Radio<int>(
                value: delay['seconds'] as int,
                groupValue: settings.lockDelaySeconds,
                onChanged: (val) async {
                  await settings.setLockDelaySeconds(val!);
                  await settings.setLockDelayEnabled(true);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () async {
                await settings.setLockDelaySeconds(delay['seconds'] as int);
                await settings.setLockDelayEnabled(true);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDiagnostics(
      BuildContext context, AppLocalizations l10n, String lang) async {
    final log = await ApexDiagnosticsEngine().getErrorLog();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.errorLog),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(log,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ApexDiagnosticsEngine().clearLog();
              Navigator.pop(ctx);
              ApexSnackBar.show(context, l10n.cleared,
                  type: SnackBarType.success);
            },
            child: Text(l10n.clear),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }


}
