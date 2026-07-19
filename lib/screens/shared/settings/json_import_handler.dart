// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/screens/shared/settings/backup_validators.dart';
import 'package:sinan_note/services/security/vault_service.dart';
import 'package:sinan_note/services/storage/backup_service.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';

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

      final file = File(filePath);
      final jsonString = await file.readAsString();
      final dynamic jsonData = jsonDecode(jsonString);

      List<dynamic> notesList;
      if (jsonData is Map<String, dynamic>) {
        notesList = jsonData['notes'] ?? [];
      } else {
        notesList = jsonData;
      }

      if (notesList.isEmpty) {
        throw Exception(
            lang == 'ar' ? 'لا توجد ملاحظات في الملف' : 'No notes in file');
      }

      // فك تشفير تلقائي لو عنده مفتاح — بدون إجبار
      final hasKey = await VaultService.isVaultSetup();
      enc.Key? masterKey;
      if (hasKey) {
        try {
          masterKey = await VaultService.getMasterKey();
        } catch (_) {}
      }

      final notesToImport = <Note>[];
      for (final map in notesList) {
        final note = Note.fromMap(map);
        if (note.isLocked &&
            masterKey != null &&
            VaultService.isEncrypted(note.content)) {
          try {
            final decTitle = VaultService.decryptWithKey(note.title, masterKey);
            final decContent =
                VaultService.decryptWithKey(note.content, masterKey);
            notesToImport
                .add(note.copyWith(title: decTitle, content: decContent));
          } catch (_) {
            notesToImport.add(note);
          }
        } else {
          notesToImport.add(note);
        }
      }
      if (masterKey != null) VaultService.wipeMasterKey(masterKey);

      final dbService = SqliteDatabaseService();
      await SqliteDatabaseService.initialize();
      final localCount = await BackupService().checkLocalNotesCount();

      if (localCount == 0) {
        await _writeNotes(dbService, notesToImport, replace: false);
        await notesProvider.loadNotes(force: true);
        if (!context.mounted) return;
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
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ),
          ],
        ),
      );

      if (action == null || action == 'cancel') return;

      await _writeNotes(dbService, notesToImport, replace: action == 'replace');
      await notesProvider.loadNotes(force: true);

      final totalNotes = await BackupService().checkLocalNotesCount();
      if (!context.mounted) return;
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
    SqliteDatabaseService dbService,
    List<Note> notes, {
    required bool replace,
  }) async {
    if (replace) {
      final existing = await dbService.getAllNotes();
      for (final n in existing) {
        if (n.id != null) await dbService.deleteNote(n.id!);
      }
    }
    for (final note in notes) {
      note.updatedAt = DateTime.now();
      await dbService.insertNote(note);
    }
  }

  static Future<void> _showResult(
    BuildContext context,
    String lang,
    AppLocalizations l10n,
    SqliteDatabaseService dbService,
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
