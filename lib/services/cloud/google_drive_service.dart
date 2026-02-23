// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/storage/compression_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  static GoogleSignInAccount? _currentUser;
  static drive.DriveApi? _driveApi;
  static DateTime? _lastSyncTime;

  static bool get isSignedIn => _currentUser != null;
  static String? get currentUserEmail => _currentUser?.email;
  static DateTime? get lastSyncTime => _lastSyncTime;

  static Future<void> initializeSignIn() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        final authClient = await _googleSignIn.authenticatedClient();
        if (authClient != null) {
          _driveApi = drive.DriveApi(authClient);
          AppLogger.success(
              'Restored session: ${_currentUser!.email}', 'GoogleDrive');
        }
      }
    } catch (e) {
      AppLogger.warning('Silent sign-in failed', 'GoogleDrive');
    }
  }

  static Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) {
        AppLogger.info('Sign in cancelled by user', 'GoogleDrive');
        return false;
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        AppLogger.error('Failed to get authenticated client', 'GoogleDrive');
        return false;
      }

      _driveApi = drive.DriveApi(authClient);
      AppLogger.success(
          'Successfully signed in as: ${_currentUser!.email}', 'GoogleDrive');
      return true;
    } catch (e) {
      AppLogger.error('Sign in error', 'GoogleDrive', e);
      return false;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
    _lastSyncTime = null;
  }

  static Future<bool> uploadDatabase(dynamic context,
      {bool uploadMasterKey = false, bool uploadVault = false}) async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      final dbService = IsarDatabaseService();
      final notes = await dbService.getAllNotes();

      // Get vault data if exists
      final vaultData = await VaultService.getVaultDataForBackup();

      // Create backup in new format
      final Map<String, dynamic> backupData = {
        'version': '2.0',
        'created_at': DateTime.now().toIso8601String(),
        'notes': notes.map((n) => n.toMap()).toList(),
      };

      // Add vault_data if exists
      if (vaultData != null) {
        backupData['vault_data'] = vaultData;
        AppLogger.info('✓ Vault data included in backup', 'GoogleDrive');
      }

      final json = jsonEncode(backupData);
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'sinan_backup.gz');
      await File(tempPath).writeAsBytes(CompressionService.compress(json));

      final backupFile = File(tempPath);
      const fileName = 'sinan_backup.gz';
      final existingFile = await _findFile(fileName);

      final media =
          drive.Media(backupFile.openRead(), await backupFile.length());

      if (existingFile != null) {
        await _driveApi!.files.update(
          drive.File(),
          existingFile.id!,
          uploadMedia: media,
        );
        AppLogger.success(
            'Updated backup in Google Drive (${notes.length} notes)',
            'GoogleDrive');
      } else {
        final driveFile = drive.File()
          ..name = fileName
          ..mimeType = 'application/gzip';

        await _driveApi!.files.create(
          driveFile,
          uploadMedia: media,
        );
        AppLogger.success(
            'Created backup in Google Drive (${notes.length} notes)',
            'GoogleDrive');
      }

      await backupFile.delete();
      _lastSyncTime = DateTime.now();
      return true;
    } catch (e) {
      AppLogger.error('Upload failed', 'GoogleDrive', e);
      return false;
    }
  }

  Future<DateTime?> checkForRemoteUpdates() async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      final file = await _findFile('sinan_backup.gz');
      if (file == null) return null;

      return file.modifiedTime;
    } catch (e) {
      AppLogger.error('Check updates error', 'GoogleDrive', e);
      return null;
    }
  }

  static Future<bool> downloadDatabase(dynamic context) async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      final file = await _findFile('sinan_backup.gz');
      if (file == null) throw Exception('No backup found in Drive');

      final response = await _driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'drive_backup.json');
      final tempFile = File(tempPath);
      final sink = tempFile.openWrite();

      await response.stream.forEach((chunk) {
        sink.add(chunk);
      });

      await sink.close();

      if (!await tempFile.exists()) {
        throw Exception('Downloaded file is invalid');
      }

      final json = CompressionService.decompress(await tempFile.readAsBytes());
      final dynamic jsonData = jsonDecode(json);

      List<dynamic> notesList;
      Map<String, dynamic>? vaultData;

      // Check if new format (with version and vault_data)
      if (jsonData is Map<String, dynamic>) {
        notesList = jsonData['notes'] ?? [];
        vaultData = jsonData['vault_data'];

        // Restore vault data if exists
        if (vaultData != null) {
          await VaultService.restoreVaultDataFromBackup(vaultData);
          AppLogger.info(
              '✓ Vault data restored from Google Drive', 'GoogleDrive');
        }
      } else {
        // Old format (array of notes)
        notesList = jsonData;
      }

      final dbService = IsarDatabaseService();
      final isar = await dbService.database;

      await isar.writeTxn(() async {
        await isar.notes.clear();
        for (var noteMap in notesList) {
          final note = Note.fromMap(noteMap);
          await isar.notes.put(note);
        }
      });

      await tempFile.delete();
      _lastSyncTime = DateTime.now();

      AppLogger.success(
          'Downloaded ${notesList.length} notes from Google Drive',
          'GoogleDrive');
      return true;
    } catch (e) {
      AppLogger.error('Download failed', 'GoogleDrive', e);
      return false;
    }
  }

  static Future<bool> mergeWithDrive(dynamic context,
      {bool uploadMasterKey = false, bool uploadVault = false}) async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      // 1. Fetch notes from Drive
      final file = await _findFile('sinan_backup.gz');
      if (file == null) {
        // No backup, just upload local
        return await uploadDatabase(context,
            uploadMasterKey: uploadMasterKey, uploadVault: uploadVault);
      }

      final response = await _driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'drive_merge.json');
      final tempFile = File(tempPath);
      final sink = tempFile.openWrite();

      await response.stream.forEach((chunk) => sink.add(chunk));
      await sink.close();

      final driveJson =
          CompressionService.decompress(await tempFile.readAsBytes());
      final dynamic jsonData = jsonDecode(driveJson);

      List<dynamic> driveNotesList;
      Map<String, dynamic>? vaultData;

      // Check if new format (with version and vault_data)
      if (jsonData is Map<String, dynamic>) {
        driveNotesList = jsonData['notes'] ?? [];
        vaultData = jsonData['vault_data'];

        // Restore vault data if exists
        if (vaultData != null) {
          await VaultService.restoreVaultDataFromBackup(vaultData);
          AppLogger.info(
              '✓ Vault data restored from Google Drive', 'GoogleDrive');
        }
      } else {
        // Old format (array of notes)
        driveNotesList = jsonData;
      }

      final driveNotes = driveNotesList.map((m) => Note.fromMap(m)).toList();

      // 2. Fetch local notes
      final dbService = IsarDatabaseService();
      final localNotes = await dbService.getAllNotes();

      // 3. Show dialog to user
      final action =
          await _showMergeDialog(context, localNotes.length, driveNotes.length);

      if (action == null || action == 'cancel') {
        await tempFile.delete();
        return false;
      }

      final isar = await dbService.database;

      if (action == 'useLocal') {
        // استخدم المحلي فقط
        await tempFile.delete();
        await uploadDatabase(context,
            uploadMasterKey: uploadMasterKey, uploadVault: uploadVault);
        _lastSyncTime = DateTime.now();
        AppLogger.success(
            'Used local notes (${localNotes.length})', 'GoogleDrive');
        return true;
      } else if (action == 'useDrive') {
        // استخدم Drive فقط
        await isar.writeTxn(() async {
          await isar.notes.clear();
          for (var note in driveNotes) {
            await isar.notes.put(note);
          }
        });
        await tempFile.delete();
        _lastSyncTime = DateTime.now();
        AppLogger.success(
            'Used Drive notes (${driveNotes.length})', 'GoogleDrive');
        return true;
      } else {
        // دمج ذكي
        final Map<int, Note> mergedMap = {};

        // أضف المحلية أولاً
        for (var note in localNotes) {
          if (note.id != null) {
            mergedMap[note.id!] = note;
          }
        }

        // دمج من Drive (خذ الأحدث)
        for (var driveNote in driveNotes) {
          if (driveNote.id != null) {
            if (mergedMap.containsKey(driveNote.id!)) {
              // موجود، قارن التاريخ
              if (driveNote.updatedAt
                  .isAfter(mergedMap[driveNote.id!]!.updatedAt)) {
                mergedMap[driveNote.id!] = driveNote;
              }
            } else {
              // جديد، أضفه
              mergedMap[driveNote.id!] = driveNote;
            }
          }
        }

        // احفظ المدمج محلياً
        await isar.writeTxn(() async {
          await isar.notes.clear();
          for (var note in mergedMap.values) {
            await isar.notes.put(note);
          }
        });

        // ارفع المدمج لـ Drive
        await tempFile.delete();
        await uploadDatabase(context,
            uploadMasterKey: uploadMasterKey, uploadVault: uploadVault);

        _lastSyncTime = DateTime.now();
        AppLogger.success('Merged ${mergedMap.length} notes', 'GoogleDrive');
        return true;
      }
    } catch (e) {
      AppLogger.error('Merge failed', 'GoogleDrive', e);
      return false;
    }
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('${l10n.onDevice}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(l10n.notesCount(localCount)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('${l10n.onDrive}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(l10n.notesCount(driveCount)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.chooseAction,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(l10n.cancel),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'useDrive'),
            icon: const Icon(Icons.cloud, size: 18),
            label: Text(l10n.useDrive),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, 'useLocal'),
            icon: const Icon(Icons.phone_android, size: 18),
            label: Text(l10n.useDevice),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, 'merge'),
            icon: const Icon(Icons.merge, size: 18),
            label: Text(l10n.smartMerge),
          ),
        ],
      ),
    );
  }

  static Future<bool> hasBackupInDrive() async {
    if (_driveApi == null) return false;
    try {
      final file = await _findFile('sinan_backup.gz');
      return file != null;
    } catch (_) {
      return false;
    }
  }

  static Future<drive.File?> _findFile(String fileName) async {
    try {
      final fileList = await _driveApi!.files.list(
        q: "name='$fileName' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name, modifiedTime)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first;
      }
      return null;
    } catch (e) {
      AppLogger.error('Find file error', 'GoogleDrive', e);
      return null;
    }
  }

  /// Check if backup file contains vault_data
  static Future<bool> checkForVaultData() async {
    if (_driveApi == null) return false;

    try {
      const fileName = 'sinan_backup.gz';
      final file = await _findFile(fileName);

      if (file == null) return false;

      // Download and check content
      final response = await _driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await for (var chunk in response.stream) {
        dataStore.addAll(chunk);
      }

      final jsonString = CompressionService.decompress(dataStore);
      final dynamic jsonData = jsonDecode(jsonString);

      if (jsonData is Map<String, dynamic>) {
        return jsonData.containsKey('vault_data');
      }

      return false;
    } catch (e) {
      AppLogger.error('Check vault data error', 'GoogleDrive', e);
      return false;
    }
  }

  /// Get notes count from Drive backup
  static Future<int> getDriveNotesCount() async {
    if (_driveApi == null) return 0;

    try {
      const fileName = 'sinan_backup.gz';
      final file = await _findFile(fileName);

      if (file == null) return 0;

      // Download and parse
      final response = await _driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await for (var chunk in response.stream) {
        dataStore.addAll(chunk);
      }

      final jsonString = CompressionService.decompress(dataStore);
      final dynamic jsonData = jsonDecode(jsonString);

      if (jsonData is Map<String, dynamic>) {
        final notesList = jsonData['notes'] as List?;
        return notesList?.length ?? 0;
      } else if (jsonData is List) {
        return jsonData.length;
      }

      return 0;
    } catch (e) {
      AppLogger.error('Get Drive notes count error', 'GoogleDrive', e);
      return 0;
    }
  }
}
