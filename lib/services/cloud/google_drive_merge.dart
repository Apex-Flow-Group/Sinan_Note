// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/cloud/google_drive_auth.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/services/storage/compression_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GoogleDriveMerge {
  static Future<bool> mergeWithDrive(
    dynamic context, {
    required Future<bool> Function(dynamic) uploadFn,
  }) async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');

    try {
      final file = await GoogleDriveAuth.findFile('sinan_backup.gz');
      if (file == null) {
        return await uploadFn(context);
      }

      final driveNotes = await _downloadDriveNotes(file);
      final dbService = IsarDatabaseService();
      final localNotes = await dbService.getAllNotes();

      final action =
          await _showMergeDialog(context, localNotes.length, driveNotes.length);
      if (action == null || action == 'cancel') return false;

      final isar = await dbService.database;

      if (action == 'useLocal') {
        await uploadFn(context);
        AppLogger.success(
            'Used local notes (${localNotes.length})', 'GoogleDrive');
        return true;
      }

      if (action == 'useDrive') {
        await isar.writeTxn(() async {
          await isar.notes.clear();
          for (final note in driveNotes) {
            await isar.notes.put(note);
          }
        });
        AppLogger.success(
            'Used Drive notes (${driveNotes.length})', 'GoogleDrive');
        return true;
      }

      // Smart merge — استخدم المنطق الكامل من _silentMerge
      await GoogleDriveService.silentMerge();
      AppLogger.success('Smart merge completed', 'GoogleDrive');
      return true;
    } catch (e) {
      AppLogger.error('Merge failed', 'GoogleDrive', e);
      return false;
    }
  }

  static Future<List<Note>> _downloadDriveNotes(drive.File file) async {
    final response = await GoogleDriveAuth.driveApi!.files.get(
      file.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(join(tempDir.path, 'drive_merge.json'));
    final sink = tempFile.openWrite();
    await response.stream.forEach((chunk) => sink.add(chunk));
    await sink.close();

    final json = CompressionService.decompress(await tempFile.readAsBytes());
    final dynamic jsonData = jsonDecode(json);
    await tempFile.delete();

    List<dynamic> notesList;
    if (jsonData is Map<String, dynamic>) {
      notesList = jsonData['notes'] ?? [];
      // vault_data لا يُستعاد تلقائياً في الدمج أيضاً
    } else {
      notesList = jsonData;
    }

    return notesList.map((m) => Note.fromMap(m)).toList();
  }

  static Future<String?> _showMergeDialog(
      dynamic context, int localCount, int driveCount) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.sync_problem, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.syncConflictTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.syncConflictDesc, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 20),
            _countRow(Icons.phone_android, Colors.blue, '${l10n.onDevice}: ',
                l10n.notesCount(localCount)),
            const SizedBox(height: 8),
            _countRow(Icons.cloud, Colors.green, '${l10n.onDrive}: ',
                l10n.notesCount(driveCount)),
            const SizedBox(height: 16),
            Text(l10n.chooseAction,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text(l10n.cancel)),
          TextButton.icon(
              onPressed: () => Navigator.pop(context, 'useDrive'),
              icon: const Icon(Icons.cloud, size: 18),
              label: Text(l10n.useDrive)),
          TextButton.icon(
              onPressed: () => Navigator.pop(context, 'useLocal'),
              icon: const Icon(Icons.phone_android, size: 18),
              label: Text(l10n.useDevice)),
          FilledButton.icon(
              onPressed: () => Navigator.pop(context, 'merge'),
              icon: const Icon(Icons.merge, size: 18),
              label: Text(l10n.smartMerge)),
        ],
      ),
    );
  }

  static Widget _countRow(
      IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
