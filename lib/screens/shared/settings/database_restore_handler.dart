// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/screens/shared/settings/backup_validators.dart';
import 'package:apex_note/services/storage/backup_service.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseRestoreHandler {
  static Future<void> handle(
    BuildContext context,
    String lang,
    AppLocalizations l10n,
    String backupPath,
  ) async {
    final isDb = BackupValidators.isDatabaseFile(
        backupPath.split(Platform.pathSeparator).last);
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
          await _restoreDbFile(backupPath);
        } else {
          await BackupService().replaceDatabase(backupPath);
        }
        if (!context.mounted) return;
        await Provider.of<NotesProvider>(context, listen: false)
            .loadNotes(force: true);
        final restoredCount = await BackupService().checkLocalNotesCount();
        if (!context.mounted) return;
        Navigator.pop(context); // dismiss loading

        final dbService = SqliteDatabaseService();
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
        _showSuccessSheet(context, l10n, message);
        return;
      }

      // لديه ملاحظات — اسأله: دمج أو استبدال
      if (!context.mounted) return;
      final action =
          await _showRestoreOptionsSheet(context, lang, l10n, localCount);
      if (action == null || action == 'cancel') return;

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
            child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary)),
      );

      if (isDb) {
        await _restoreDbFile(backupPath);
      } else if (action == 'merge') {
        await BackupService().mergeDatabase(backupPath);
      } else {
        await BackupService().replaceDatabase(backupPath);
      }

      if (!context.mounted) return;
      await Provider.of<NotesProvider>(context, listen: false)
          .loadNotes(force: true);

      final dbService = SqliteDatabaseService();
      final lockedNotes = await dbService.getLockedNotes();
      final totalNotes = await BackupService().checkLocalNotesCount();
      final unlockedCount = totalNotes - lockedNotes.length;

      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading

      final successMsg = lockedNotes.isNotEmpty
          ? (lang == 'ar'
              ? '${action == 'merge' ? 'تم الدمج' : 'تم الاستبدال'}: $totalNotes ملاحظة ($unlockedCount عادية، ${lockedNotes.length} مشفرة)'
              : '${action == 'merge' ? 'Merged' : 'Replaced'}: $totalNotes notes ($unlockedCount normal, ${lockedNotes.length} encrypted)')
          : (lang == 'ar'
              ? '${action == 'merge' ? 'تم الدمج' : 'تم الاستبدال'}: $totalNotes ملاحظة'
              : '${action == 'merge' ? 'Merged' : 'Replaced'}: $totalNotes notes');

      if (!context.mounted) return;
      _showSuccessSheet(context, l10n, successMsg);
    } catch (e) {
      // dismiss loading if showing
      if (context.mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      if (!context.mounted) return;
      UnifiedNotificationService().show(
          context: context,
          message: e.toString().replaceAll('Exception:', ''),
          type: NotificationType.error);
    }
  }

  // ── Bottom Sheets ─────────────────────────────────────────────────────────

  static Future<String?> _showRestoreOptionsSheet(
    BuildContext context,
    String lang,
    AppLocalizations l10n,
    int localCount,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AppBottomSheet.show<String>(
      context,
      child: AppBottomSheet(
        title: lang == 'ar' ? 'استعادة البيانات' : 'Restore Data',
        titleIcon: Icons.restore_rounded,
        scrollable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lang == 'ar'
                            ? 'لديك $localCount ملاحظة حالياً'
                            : 'You have $localCount notes currently',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, 'merge'),
                  icon: const Icon(Icons.merge_rounded),
                  label: Text(l10n.merge),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'replace'),
                  icon: Icon(Icons.swap_horiz_rounded, color: scheme.error),
                  label:
                      Text(l10n.replace, style: TextStyle(color: scheme.error)),
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  child: Text(l10n.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showSuccessSheet(
    BuildContext context,
    AppLocalizations l10n,
    String message,
  ) {
    final scheme = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      child: AppBottomSheet(
        scrollable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: scheme.primary, size: 56),
              const SizedBox(height: 16),
              Text(
                l10n.restoreSuccessful,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── DB Restore ────────────────────────────────────────────────────────────

  static Future<void> _restoreDbFile(String backupPath) async {
    final dbService = SqliteDatabaseService();
    await dbService.closeDB();
    final dbPath = await _getSqliteDbPath();
    await File(backupPath).copy(dbPath);
    await dbService.reopenDatabase();
  }

  static Future<String> _getSqliteDbPath() async {
    if (Platform.isAndroid) {
      final dbDir = await getDatabasesPath();
      return p.join(dbDir, 'sinan_notes.db');
    }
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'sinan_notes.db');
  }
}
