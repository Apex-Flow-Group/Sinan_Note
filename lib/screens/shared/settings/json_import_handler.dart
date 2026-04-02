// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/screens/shared/settings/backup_messages.dart';
import 'package:apex_note/screens/shared/settings/backup_validators.dart';
import 'package:apex_note/screens/shared/settings/recovery_code_dialog.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/storage/backup_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class JsonImportHandler {
  static Future<void> handle(
    BuildContext context,
    String lang,
    AppLocalizations l10n,
    String filePath,
  ) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    try {
      final validationError =
          await BackupValidators.validate(filePath, isDatabase: false);
      if (validationError != null) {
        if (!context.mounted) return;
        UnifiedNotificationService().show(
            context: context,
            message: validationError,
            type: NotificationType.error);
        return;
      }

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

      final notesToImport =
          notesList.map((json) => Note.fromMap(json)).toList();

      final dbService = IsarDatabaseService();
      await IsarDatabaseService.initialize();
      final localCount = await BackupService().checkLocalNotesCount();

      if (localCount == 0) {
        await _writeNotes(dbService, notesToImport, replace: false);
        await notesProvider.loadNotes(force: true);
        // ignore: use_build_context_synchronously
        await _showResult(context, lang, l10n, dbService, notesToImport.length,
            action: 'import');
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
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      );

      if (action == null || action == 'cancel') return;

      await _writeNotes(dbService, notesToImport, replace: action == 'replace');
      await notesProvider.loadNotes(force: true);

      final totalNotes = await BackupService().checkLocalNotesCount();
      // ignore: use_build_context_synchronously
      await _showResult(context, lang, l10n, dbService, totalNotes,
          action: action);
    } catch (e) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
          context: context,
          message: e.toString().replaceAll('Exception:', ''),
          type: NotificationType.error);
    }
  }

  static Future<void> _writeNotes(
    IsarDatabaseService dbService,
    List<Note> notes, {
    required bool replace,
  }) async {
    final isar = await dbService.database;
    await isar.writeTxn(() async {
      if (replace) await isar.notes.clear();
      for (final note in notes) {
        note.updatedAt = DateTime.now();
        await isar.notes.put(note);
      }
    });
  }

  static Future<void> _showResult(
    BuildContext context,
    String lang,
    AppLocalizations l10n,
    IsarDatabaseService dbService,
    int count, {
    required String action,
  }) async {
    if (!context.mounted) return;
    final lockedNotes = await dbService.getLockedNotes();
    final unlockedCount = count - lockedNotes.length;

    String message;
    if (lockedNotes.isNotEmpty) {
      final prefix = action == 'merge'
          ? (lang == 'ar' ? 'تم الدمج' : 'Merged')
          : action == 'replace'
              ? (lang == 'ar' ? 'تم الاستبدال' : 'Replaced')
              : (lang == 'ar' ? 'تم الاستيراد' : 'Imported');
      message = lang == 'ar'
          ? '$prefix: $count ملاحظة ($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
          : '$prefix: $count notes ($unlockedCount normal, ${lockedNotes.length} encrypted)';
    } else {
      message = action == 'merge'
          ? l10n.mergedSuccessfully
          : action == 'replace'
              ? l10n.restoredSuccessfully
              : '$count ${l10n.importedSuccessfully}';
    }

    if (!context.mounted) return;
    UnifiedNotificationService().show(
      context: context,
      message: message,
      type: NotificationType.success,
      duration: const Duration(seconds: 5),
    );
  }
}
