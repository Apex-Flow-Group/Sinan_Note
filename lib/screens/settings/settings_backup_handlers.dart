// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../controllers/notes/notes_provider.dart';
import '../../services/storage/backup_service.dart';
import '../../services/storage/storage_service.dart';
import '../../services/storage/isar_database_service.dart';
import '../../widgets/common/apex_snackbar.dart';

class SettingsBackupHandlers {
  static void showBackupDialog(BuildContext context, String lang, AppLocalizations l10n) async {
    try {
      final dbService = IsarDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();
      if (lockedNotes.isNotEmpty) {
        final agreed = await _showEncryptionAgreement(context, l10n, lang, lockedNotes.length);
        if (agreed != true) return;
      }
    } catch (e) {
      if (context.mounted) {
        ApexSnackBar.show(context, l10n.databaseError, type: SnackBarType.error);
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
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final result = await FilePicker.platform.getDirectoryPath();
                  if (result == null) {
                    ApexSnackBar.show(context, l10n.noFileSelected, type: SnackBarType.warning);
                    return;
                  }
                  final outputPath = await BackupService().exportDatabaseToPath(result);
                  ApexSnackBar.show(context, '${l10n.backupSaved}\n$outputPath',
                      type: SnackBarType.success, duration: const Duration(seconds: 4));
                } catch (e) {
                  ApexSnackBar.show(context, e.toString().replaceAll('Exception:', ''), type: SnackBarType.error);
                }
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: Text(l10n.share),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await BackupService().shareDatabase();
                } catch (e) {
                  ApexSnackBar.show(context, e.toString().replaceAll('Exception:', ''), type: SnackBarType.error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showExportDialog(BuildContext context, String lang, AppLocalizations l10n) async {
    try {
      final dbService = IsarDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();
      if (lockedNotes.isNotEmpty) {
        final agreed = await _showEncryptionAgreement(context, l10n, lang, lockedNotes.length);
        if (agreed != true) return;
      }
    } catch (e) {
      if (context.mounted) {
        ApexSnackBar.show(context, l10n.databaseError, type: SnackBarType.error);
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
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final result = await FilePicker.platform.getDirectoryPath();
                  if (result == null) {
                    ApexSnackBar.show(context, l10n.noFileSelected, type: SnackBarType.warning);
                    return;
                  }
                  final message = await StorageService().exportNotesToPath(result);
                  ApexSnackBar.show(context, message, type: SnackBarType.success, duration: const Duration(seconds: 4));
                } catch (e) {
                  ApexSnackBar.show(context, e.toString().replaceAll('Exception:', ''), type: SnackBarType.error);
                }
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: Text(l10n.share),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await StorageService().shareNotesFile();
                } catch (e) {
                  ApexSnackBar.show(context, e.toString().replaceAll('Exception:', ''), type: SnackBarType.error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> handleImportJSON(BuildContext context, AppLocalizations l10n) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.warning),
        content: Text(l10n.replaceAllNotes),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.replace, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        int count = await StorageService().importNotesFromDevice();
        if (count > 0 && context.mounted) {
          ApexSnackBar.show(context, "$count ${l10n.importedSuccessfully}", type: SnackBarType.success);
        }
      } catch (e) {
        ApexSnackBar.show(context, e.toString().replaceAll('Exception:', ''), type: SnackBarType.error);
      }
    }
  }

  static void handleSmartRestore(BuildContext context, String lang, AppLocalizations l10n) async {
    try {
      final dbService = IsarDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();
      if (lockedNotes.isNotEmpty) {
        final agreed = await _showEncryptionAgreement(context, l10n, lang, lockedNotes.length);
        if (agreed != true) return;
      }
    } catch (e) {
      if (context.mounted) {
        ApexSnackBar.show(context, l10n.databaseError, type: SnackBarType.error);
      }
      return;
    }

    try {
      final backupPath = await BackupService().pickBackupFile();
      if (backupPath == null) return;

      final localCount = await BackupService().checkLocalNotesCount();

      if (localCount == 0) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
          );
        }

        await BackupService().replaceDatabase(backupPath);

        if (context.mounted) {
          await Provider.of<NotesProvider>(context, listen: false).loadNotes(force: true);
        }

        final restoredCount = await BackupService().checkLocalNotesCount();

        if (context.mounted) {
          Navigator.pop(context);
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              icon: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary, size: 50),
              title: Text(l10n.restoreSuccessful, textAlign: TextAlign.center),
              content: Text(
                lang == 'ar' ? 'تم استعادة $restoredCount ملاحظة/مذكرات.' : 'Successfully restored $restoredCount notes.',
                textAlign: TextAlign.center,
              ),
              actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok))],
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
            content: Text(lang == 'ar' ? 'لديك $localCount ملاحظة حالياً. ماذا تريد أن تفعل؟' : 'You have $localCount notes. What do you want to do?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: Text(l10n.cancel)),
              TextButton(onPressed: () => Navigator.pop(ctx, 'merge'), child: Text(l10n.merge)),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'replace'),
                child: Text(l10n.replace, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ],
          ),
        );

        if (action == 'merge') {
          await BackupService().mergeDatabase(backupPath);
          if (context.mounted) {
            await Provider.of<NotesProvider>(context, listen: false).loadNotes(force: true);
            ApexSnackBar.show(context, l10n.mergedSuccessfully, type: SnackBarType.success);
          }
        } else if (action == 'replace') {
          await BackupService().replaceDatabase(backupPath);
          if (context.mounted) {
            await Provider.of<NotesProvider>(context, listen: false).loadNotes(force: true);
            ApexSnackBar.show(context, l10n.restoredSuccessfully, type: SnackBarType.success);
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ApexSnackBar.show(context, e.toString().replaceAll('Exception:', ''), type: SnackBarType.error);
      }
    }
  }

  static Future<bool?> _showEncryptionAgreement(BuildContext context, AppLocalizations l10n, String lang, int lockedCount) {
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
              Expanded(child: Text(l10n.disclaimer, style: const TextStyle(fontSize: 18))),
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
                          ? 'تحذير: لديك $lockedCount ملاحظة مشفرة. النسخ الاحتياطي يحتوي على بيانات مشفرة لا يمكن فك تشفيرها على جهاز آخر.'
                          : 'Warning: You have $lockedCount encrypted notes. Backup contains encrypted data that cannot be decrypted on another device.',
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: agreed,
                  onChanged: (val) => setDialogState(() => agreed = val ?? false),
                  title: Text(
                    lang == 'ar' ? 'نعم، أنا على اطلاع بالمخاطر' : 'Yes, I understand the risks',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: agreed ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(backgroundColor: agreed ? Colors.red : Colors.grey),
              child: Text(l10n.continueAction),
            ),
          ],
        ),
      ),
    );
  }
}
