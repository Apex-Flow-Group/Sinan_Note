// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/screens/shared/settings/backup_dialogs.dart';
import 'package:apex_note/screens/shared/settings/backup_messages.dart';
import 'package:apex_note/screens/shared/settings/backup_validators.dart';
import 'package:apex_note/screens/shared/settings/recovery_code_dialog.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/storage/backup_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:apex_note/services/storage/storage_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsBackupHandlers {
  static void showBackupDialog(
      BuildContext context, String lang, AppLocalizations l10n) async {
    try {
      final dbService = IsarDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();
      if (lockedNotes.isNotEmpty) {
        if (!context.mounted) return;
        final agreed = await BackupDialogs.showEncryptionAgreement(
            context, l10n, lang, lockedNotes.length);
        if (agreed != true) return;
      }
    } catch (e) {
      if (context.mounted) {
        UnifiedNotificationService().show(
          context: context,
          message: l10n.databaseError,
          type: NotificationType.error,
        );
      }
      return;
    }

    if (!context.mounted) return;
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
                    if (!context.mounted) return;
                    UnifiedNotificationService().show(
                      context: context,
                      message: l10n.noFileSelected,
                      type: NotificationType.warning,
                    );
                    return;
                  }
                  final outputPath =
                      await BackupService().exportDatabaseToPath(result);
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                    context: context,
                    message: '${l10n.backupSaved}\n$outputPath',
                    type: NotificationType.success,
                    duration: const Duration(seconds: 4),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                    context: context,
                    message: e.toString().replaceAll('Exception:', ''),
                    type: NotificationType.error,
                  );
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
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: e.toString().replaceAll('Exception:', ''),
                      type: NotificationType.error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static void showExportDialog(
      BuildContext context, String lang, AppLocalizations l10n) async {
    try {
      final dbService = IsarDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();
      if (lockedNotes.isNotEmpty) {
        if (!context.mounted) return;
        final agreed = await BackupDialogs.showEncryptionAgreement(
            context, l10n, lang, lockedNotes.length);
        if (agreed != true) return;
      }
    } catch (e) {
      if (context.mounted) {
        UnifiedNotificationService().show(
            context: context,
            message: l10n.databaseError,
            type: NotificationType.error);
      }
      return;
    }

    if (!context.mounted) return;
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
                    if (!context.mounted) return;
                    UnifiedNotificationService().show(
                        context: context,
                        message: l10n.noFileSelected,
                        type: NotificationType.warning);
                    return;
                  }
                  final message =
                      await StorageService().exportNotesToPath(result);
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: message,
                      type: NotificationType.success,
                      duration: const Duration(seconds: 4));
                } catch (e) {
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: e.toString().replaceAll('Exception:', ''),
                      type: NotificationType.error);
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
                  if (!context.mounted) return;
                  UnifiedNotificationService().show(
                      context: context,
                      message: e.toString().replaceAll('Exception:', ''),
                      type: NotificationType.error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> handleImportJSON(
      BuildContext context, AppLocalizations l10n) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.warning),
        content: Text(l10n.replaceAllNotes),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
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
        // Pick file first
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result == null || result.files.single.path == null) return;

        final filePath = result.files.single.path!;

        // Check if file contains vault_data
        final hasVaultData = await BackupValidators.checkForVaultData(filePath);

        if (hasVaultData) {
          if (!context.mounted) return;
          // Show recovery code dialog
          final recovered = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const RecoveryCodeDialog(),
          );

          if (recovered != true) {
            if (!context.mounted) return;
            UnifiedNotificationService().show(
              context: context,
              message: Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم إلغاء الاستيراد'
                  : 'Import cancelled',
              type: NotificationType.warning,
            );
            return;
          }
        }

        // Now import
        int count = await StorageService().importNotesFromDevice();

        // ✅ Reload notes in provider
        if (!context.mounted) return;
        await Provider.of<NotesProvider>(context, listen: false)
            .loadNotes(force: true);

        if (count > 0 && context.mounted) {
          // Check if there are locked notes
          final dbService = IsarDatabaseService();
          final lockedNotes = await dbService.getLockedNotes();
          final unlockedCount = count - lockedNotes.length;

          if (lockedNotes.isNotEmpty) {
            if (!context.mounted) return;
            final lang = Localizations.localeOf(context).languageCode;
            UnifiedNotificationService().show(
              context: context,
              message: lang == 'ar'
                  ? 'تم استيراد $count ملاحظة ($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
                  : 'Imported $count notes ($unlockedCount normal, ${lockedNotes.length} encrypted)',
              type: NotificationType.success,
              duration: const Duration(seconds: 5),
            );
          } else {
            if (!context.mounted) return;
            UnifiedNotificationService().show(
                context: context,
                message: "$count ${l10n.importedSuccessfully}",
                type: NotificationType.success);
          }
        }
      } catch (e) {
        if (!context.mounted) return;
        UnifiedNotificationService().show(
            context: context,
            message: e.toString().replaceAll('Exception:', ''),
            type: NotificationType.error);
      }
    }
  }

  /// 🎯 Smart Import: Auto-detect file type (JSON or Database)
  static Future<void> handleSmartImport(
      BuildContext context, String lang, AppLocalizations l10n) async {
    try {
      // Pick file first
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'isar'],
      );

      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      // 🔍 Auto-detect file type
      final isDatabase =
          fileName.endsWith('.isar') || fileName.contains('backup');

      if (!context.mounted) return;
      if (isDatabase) {
        // Database restore flow
        await _handleDatabaseRestore(context, lang, l10n, filePath);
      } else {
        // JSON import flow
        await _handleJSONImport(context, lang, l10n, filePath);
      }
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
          context: context,
          message: e.toString().replaceAll('Exception:', ''),
          type: NotificationType.error);
    }
  }

  /// Handle Database Restore (.isar files)
  static Future<void> _handleDatabaseRestore(BuildContext context, String lang,
      AppLocalizations l10n, String backupPath) async {
    try {
      final dbService = IsarDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();
      if (lockedNotes.isNotEmpty) {
        if (!context.mounted) return;
        final agreed = await BackupDialogs.showEncryptionAgreement(
            context, l10n, lang, lockedNotes.length);
        if (agreed != true) return;
      }
    } catch (e) {
      if (context.mounted) {
        UnifiedNotificationService().show(
            context: context,
            message: l10n.databaseError,
            type: NotificationType.error);
      }
      return;
    }

    try {
      // Check if backup contains vault_data
      final hasVaultData = await BackupValidators.checkForVaultData(backupPath);

      if (hasVaultData) {
        if (!context.mounted) return;
        final recovered = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const RecoveryCodeDialog(),
        );

        if (recovered != true) {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
            context: context,
            message: BackupMessages.getCancelMessage(lang, 'restore'),
            type: NotificationType.warning,
          );
          return;
        }
      }

      final localCount = await BackupService().checkLocalNotesCount();

      if (localCount == 0) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary)),
        );

        await BackupService().replaceDatabase(backupPath);

        if (!context.mounted) return;
        await Provider.of<NotesProvider>(context, listen: false)
            .loadNotes(force: true);

        final restoredCount = await BackupService().checkLocalNotesCount();

        if (!context.mounted) return;
        Navigator.pop(context);

        final dbService = IsarDatabaseService();
        final lockedNotes = await dbService.getLockedNotes();
        final unlockedCount = restoredCount - lockedNotes.length;

        String message;
        if (lockedNotes.isNotEmpty) {
          message = lang == 'ar'
              ? 'تم استعادة $restoredCount ملاحظة\n($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
              : 'Restored $restoredCount notes\n($unlockedCount normal, ${lockedNotes.length} encrypted)';
        } else {
          message = lang == 'ar'
              ? 'تم استعادة $restoredCount ملاحظة/مذكرات.'
              : 'Successfully restored $restoredCount notes.';
        }

        if (!context.mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: Icon(Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.primary, size: 50),
            title: Text(l10n.restoreSuccessful, textAlign: TextAlign.center),
            content: Text(message, textAlign: TextAlign.center),
            actions: [
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok))
            ],
          ),
        );
        return;
      }

      if (!context.mounted) return;
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
                child: Text(l10n.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'merge'),
                child: Text(l10n.merge)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'replace'),
              child: Text(l10n.replace,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      );

      if (action == 'merge') {
        await BackupService().mergeDatabase(backupPath);
        if (!context.mounted) return;
        await Provider.of<NotesProvider>(context, listen: false)
            .loadNotes(force: true);

        final dbService = IsarDatabaseService();
        final lockedNotes = await dbService.getLockedNotes();
        final totalNotes = await BackupService().checkLocalNotesCount();
        final unlockedCount = totalNotes - lockedNotes.length;

        if (lockedNotes.isNotEmpty) {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
            context: context,
            message: lang == 'ar'
                ? 'تم الدمج: $totalNotes ملاحظة ($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
                : 'Merged: $totalNotes notes ($unlockedCount normal, ${lockedNotes.length} encrypted)',
            type: NotificationType.success,
            duration: const Duration(seconds: 5),
          );
        } else {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
              context: context,
              message: l10n.mergedSuccessfully,
              type: NotificationType.success);
        }
      } else if (action == 'replace') {
        await BackupService().replaceDatabase(backupPath);
        if (!context.mounted) return;
        await Provider.of<NotesProvider>(context, listen: false)
            .loadNotes(force: true);

        final dbService = IsarDatabaseService();
        final lockedNotes = await dbService.getLockedNotes();
        final totalNotes = await BackupService().checkLocalNotesCount();
        final unlockedCount = totalNotes - lockedNotes.length;

        if (lockedNotes.isNotEmpty) {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
            context: context,
            message: lang == 'ar'
                ? 'تم الاستبدال: $totalNotes ملاحظة ($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
                : 'Replaced: $totalNotes notes ($unlockedCount normal, ${lockedNotes.length} encrypted)',
            type: NotificationType.success,
            duration: const Duration(seconds: 5),
          );
        } else {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
              context: context,
              message: l10n.restoredSuccessfully,
              type: NotificationType.success);
        }
        if (!context.mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
          context: context,
          message: e.toString().replaceAll('Exception:', ''),
          type: NotificationType.error);
    }
  }

  /// Handle JSON Import (.json files)
  static Future<void> _handleJSONImport(BuildContext context, String lang,
      AppLocalizations l10n, String filePath) async {
    try {
      // Check if file contains vault_data
      final hasVaultData = await BackupValidators.checkForVaultData(filePath);

      if (hasVaultData) {
        if (!context.mounted) return;
        final recovered = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const RecoveryCodeDialog(),
        );

        if (recovered != true) {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
            context: context,
            message: BackupMessages.getCancelMessage(lang, 'import'),
            type: NotificationType.warning,
          );
          return;
        }
      }

      // Read file
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final dynamic jsonData = jsonDecode(jsonString);

      List<dynamic> notesList;
      Map<String, dynamic>? vaultData;

      if (jsonData is Map<String, dynamic>) {
        notesList = jsonData['notes'] ?? [];
        vaultData = jsonData['vault_data'];

        if (vaultData != null) {
          await VaultService.restoreVaultDataFromBackup(vaultData);
        }
      } else {
        notesList = jsonData;
      }

      if (notesList.isEmpty) {
        throw Exception(
            lang == 'ar' ? 'لا توجد ملاحظات في الملف' : 'No notes in file');
      }

      List<Note> notesToImport =
          notesList.map((json) => Note.fromMap(json)).toList();

      // Check if there are existing notes
      final dbService = IsarDatabaseService();
      final localCount = await BackupService().checkLocalNotesCount();

      if (localCount == 0) {
        // No local notes, just import
        final isar = await dbService.database;

        await isar.writeTxn(() async {
          for (var note in notesToImport) {
            note.updatedAt = DateTime.now();
            await isar.notes.put(note);
          }
        });

        if (!context.mounted) return;
        await Provider.of<NotesProvider>(context, listen: false)
            .loadNotes(force: true);

        final lockedNotes = await dbService.getLockedNotes();
        final unlockedCount = notesToImport.length - lockedNotes.length;

        if (lockedNotes.isNotEmpty) {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
            context: context,
            message: lang == 'ar'
                ? 'تم استيراد ${notesToImport.length} ملاحظة ($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
                : 'Imported ${notesToImport.length} notes ($unlockedCount normal, ${lockedNotes.length} encrypted)',
            type: NotificationType.success,
            duration: const Duration(seconds: 5),
          );
        } else {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
              context: context,
              message: "${notesToImport.length} ${l10n.importedSuccessfully}",
              type: NotificationType.success);
        }
        return;
      }

      // There are existing notes, ask what to do
      if (!context.mounted) return;
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
                child: Text(l10n.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'merge'),
                child: Text(l10n.merge)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'replace'),
              child: Text(l10n.replace,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      );

      if (action == 'cancel' || action == null) return;

      final isar = await dbService.database;

      if (action == 'replace') {
        // Replace all
        await isar.writeTxn(() async {
          await isar.notes.clear();
          for (var note in notesToImport) {
            note.updatedAt = DateTime.now();
            await isar.notes.put(note);
          }
        });
      } else if (action == 'merge') {
        // Merge (add new notes)
        await isar.writeTxn(() async {
          for (var note in notesToImport) {
            note.updatedAt = DateTime.now();
            await isar.notes.put(note);
          }
        });
      }

      if (!context.mounted) return;
      await Provider.of<NotesProvider>(context, listen: false)
          .loadNotes(force: true);

      final lockedNotes = await dbService.getLockedNotes();
      final totalNotes = await BackupService().checkLocalNotesCount();
      final unlockedCount = totalNotes - lockedNotes.length;

      String message;
      if (action == 'replace') {
        message = lang == 'ar'
            ? 'تم الاستبدال: $totalNotes ملاحظة ($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
            : 'Replaced: $totalNotes notes ($unlockedCount normal, ${lockedNotes.length} encrypted)';
      } else {
        message = lang == 'ar'
            ? 'تم الدمج: $totalNotes ملاحظة ($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
            : 'Merged: $totalNotes notes ($unlockedCount normal, ${lockedNotes.length} encrypted)';
      }

      if (lockedNotes.isNotEmpty) {
        if (!context.mounted) return;
        UnifiedNotificationService().show(
          context: context,
          message: message,
          type: NotificationType.success,
          duration: const Duration(seconds: 5),
        );
      } else {
        if (!context.mounted) return;
        UnifiedNotificationService().show(
          context: context,
          message: action == 'replace'
              ? l10n.restoredSuccessfully
              : l10n.mergedSuccessfully,
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
          context: context,
          message: e.toString().replaceAll('Exception:', ''),
          type: NotificationType.error);
    }
  }

  static void handleSmartRestore(
      BuildContext context, String lang, AppLocalizations l10n) async {
    try {
      final dbService = IsarDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();
      if (lockedNotes.isNotEmpty) {
        if (!context.mounted) return;
        final agreed = await BackupDialogs.showEncryptionAgreement(
            context, l10n, lang, lockedNotes.length);
        if (agreed != true) return;
      }
    } catch (e) {
      if (context.mounted) {
        UnifiedNotificationService().show(
            context: context,
            message: l10n.databaseError,
            type: NotificationType.error);
      }
      return;
    }

    try {
      final backupPath = await BackupService().pickBackupFile();
      if (backupPath == null) return;

      // Check if backup contains vault_data
      final hasVaultData = await BackupValidators.checkForVaultData(backupPath);

      if (hasVaultData) {
        if (!context.mounted) return;
        // Show recovery code dialog
        final recovered = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const RecoveryCodeDialog(),
        );

        if (recovered != true) {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
            context: context,
            message: BackupMessages.getCancelMessage(lang, 'restore'),
            type: NotificationType.warning,
          );
          return;
        }
      }

      final localCount = await BackupService().checkLocalNotesCount();

      if (localCount == 0) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary)),
        );

        await BackupService().replaceDatabase(backupPath);

        if (!context.mounted) return;
        await Provider.of<NotesProvider>(context, listen: false)
            .loadNotes(force: true);

        final restoredCount = await BackupService().checkLocalNotesCount();

        if (!context.mounted) return;
        Navigator.pop(context);

        // Check if there are locked notes
        final dbService = IsarDatabaseService();
        final lockedNotes = await dbService.getLockedNotes();
        final unlockedCount = restoredCount - lockedNotes.length;

        String message;
        if (lockedNotes.isNotEmpty) {
          message = lang == 'ar'
              ? 'تم استعادة $restoredCount ملاحظة\n($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
              : 'Restored $restoredCount notes\n($unlockedCount normal, ${lockedNotes.length} encrypted)';
        } else {
          message = lang == 'ar'
              ? 'تم استعادة $restoredCount ملاحظة/مذكرات.'
              : 'Successfully restored $restoredCount notes.';
        }

        if (!context.mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: Icon(Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.primary, size: 50),
            title: Text(l10n.restoreSuccessful, textAlign: TextAlign.center),
            content: Text(message, textAlign: TextAlign.center),
            actions: [
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok))
            ],
          ),
        );
        return;
      }

      if (!context.mounted) return;
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
                child: Text(l10n.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, 'merge'),
                child: Text(l10n.merge)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'replace'),
              child: Text(l10n.replace,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      );

      if (action == 'merge') {
        await BackupService().mergeDatabase(backupPath);
        if (!context.mounted) return;
        await Provider.of<NotesProvider>(context, listen: false)
            .loadNotes(force: true);

        // Check if there are locked notes
        final dbService = IsarDatabaseService();
        final lockedNotes = await dbService.getLockedNotes();
        final totalNotes = await BackupService().checkLocalNotesCount();
        final unlockedCount = totalNotes - lockedNotes.length;

        if (lockedNotes.isNotEmpty) {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
            context: context,
            message: lang == 'ar'
                ? 'تم الدمج: $totalNotes ملاحظة ($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
                : 'Merged: $totalNotes notes ($unlockedCount normal, ${lockedNotes.length} encrypted)',
            type: NotificationType.success,
            duration: const Duration(seconds: 5),
          );
        } else {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
              context: context,
              message: l10n.mergedSuccessfully,
              type: NotificationType.success);
        }
      } else if (action == 'replace') {
        await BackupService().replaceDatabase(backupPath);
        if (!context.mounted) return;
        await Provider.of<NotesProvider>(context, listen: false)
            .loadNotes(force: true);

        // Check if there are locked notes
        final dbService = IsarDatabaseService();
        final lockedNotes = await dbService.getLockedNotes();
        final totalNotes = await BackupService().checkLocalNotesCount();
        final unlockedCount = totalNotes - lockedNotes.length;

        if (lockedNotes.isNotEmpty) {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
            context: context,
            message: lang == 'ar'
                ? 'تم الاستبدال: $totalNotes ملاحظة ($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
                : 'Replaced: $totalNotes notes ($unlockedCount normal, ${lockedNotes.length} encrypted)',
            type: NotificationType.success,
            duration: const Duration(seconds: 5),
          );
        } else {
          if (!context.mounted) return;
          UnifiedNotificationService().show(
              context: context,
              message: l10n.restoredSuccessfully,
              type: NotificationType.success);
        }
        if (!context.mounted) return;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
          context: context,
          message: e.toString().replaceAll('Exception:', ''),
          type: NotificationType.error);
    }
  }
}
