// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/screens/shared/settings/backup_dialogs.dart';
import 'package:sinan_note/screens/shared/settings/backup_validators.dart';
import 'package:sinan_note/services/storage/backup_service.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import 'package:sinan_note/widgets/common/app_bottom_sheet.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';
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
          await BackupDialogs.showActionDialog(context, l10n, lang, localCount);
      if (action == null || action == 'cancel') return;

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
            child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary)),
      );

      if (action == 'merge') {
        if (isDb) {
          await BackupService().mergeDatabaseFile(backupPath);
        } else {
          await BackupService().mergeDatabase(backupPath);
        }
      } else if (isDb) {
        await _restoreDbFile(backupPath);
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
    // ملف ليس SQLite (مثل .sinannote القديمة بصيغة Isar) يُتلف قاعدة التطبيق
    if (!await BackupService.isSqliteFile(backupPath)) {
      throw Exception('الملف ليس قاعدة بيانات صالحة لهذا الإصدار');
    }
    final dbService = SqliteDatabaseService();
    await dbService.closeDB();
    final dbPath = await _getSqliteDbPath();
    // نسخة أمان من القاعدة الحالية قبل استبدالها
    final current = File(dbPath);
    if (await current.exists()) await current.copy('$dbPath.before-restore');
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
