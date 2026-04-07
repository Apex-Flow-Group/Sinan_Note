// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/shared/settings/backup_validators.dart';
import 'package:apex_note/services/storage/backup_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class DatabaseRestoreHandler {
  static Future<void> handle(
    BuildContext context,
    String lang,
    AppLocalizations l10n,
    String backupPath,
  ) async {
    final isDb = BackupValidators.isDatabaseFile(backupPath.split('/').last);
    final validationError =
        await BackupValidators.validate(backupPath, isDatabase: isDb);
    if (validationError != null) {
      if (!context.mounted) return;
      UnifiedNotificationService().show(
          context: context,
          message: validationError,
          type: NotificationType.error);
      return;
    }

    try {
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
        if (isDb) {
          await _restoreIsarFile(backupPath);
        } else {
          await BackupService().replaceDatabase(backupPath);
        }
        if (!context.mounted) return;
        await Provider.of<NotesProvider>(context, listen: false)
            .loadNotes(force: true);
        final restoredCount = await BackupService().checkLocalNotesCount();
        if (!context.mounted) return;
        Navigator.pop(context);

        final dbService = IsarDatabaseService();
        final lockedNotes = await dbService.getLockedNotes();
        final unlockedCount = restoredCount - lockedNotes.length;
        final message = lockedNotes.isNotEmpty
            ? (lang == 'ar'
                ? 'تم استعادة $restoredCount ملاحظة\n($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
                : 'Restored $restoredCount notes\n($unlockedCount normal, ${lockedNotes.length} encrypted)')
            : (lang == 'ar'
                ? 'تم استعادة $restoredCount ملاحظة.'
                : 'Successfully restored $restoredCount notes.');

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

      if (action == null || action == 'cancel') return;

      if (isDb) {
        await _restoreIsarFile(backupPath);
      } else if (action == 'merge') {
        await BackupService().mergeDatabase(backupPath);
      } else {
        await BackupService().replaceDatabase(backupPath);
      }

      if (!context.mounted) return;
      await Provider.of<NotesProvider>(context, listen: false)
          .loadNotes(force: true);

      final dbService = IsarDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();
      final totalNotes = await BackupService().checkLocalNotesCount();
      final unlockedCount = totalNotes - lockedNotes.length;

      if (!context.mounted) return;
      UnifiedNotificationService().show(
        context: context,
        message: lockedNotes.isNotEmpty
            ? (lang == 'ar'
                ? '${action == 'merge' ? 'تم الدمج' : 'تم الاستبدال'}: $totalNotes ملاحظة ($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
                : '${action == 'merge' ? 'Merged' : 'Replaced'}: $totalNotes notes ($unlockedCount normal, ${lockedNotes.length} encrypted)')
            : (action == 'merge' ? l10n.mergedSuccessfully : l10n.restoredSuccessfully),
        type: NotificationType.success,
        duration: const Duration(seconds: 5),
      );

      if (action == 'replace' && context.mounted) {
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

  static Future<void> _restoreIsarFile(String backupPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final targetPath = p.join(dir.path, 'sinan_notes.isar');
    await IsarDatabaseService().closeDB();
    await File(backupPath).copy(targetPath);
    await IsarDatabaseService.initialize();
  }
}
