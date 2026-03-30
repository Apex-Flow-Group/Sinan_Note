// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/cloud/google_drive_auth.dart';
import 'package:apex_note/services/cloud/google_drive_merge.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:apex_note/services/storage/compression_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GoogleDriveService {
  // ── Auth delegates ────────────────────────────────────────────────────────
  static bool get isSignedIn => GoogleDriveAuth.isSignedIn;
  static String? get currentUserEmail => GoogleDriveAuth.currentUserEmail;
  static DateTime? _lastSyncTime;
  static DateTime? get lastSyncTime => _lastSyncTime;

  static Future<void> initializeSignIn() => GoogleDriveAuth.initializeSignIn();
  static Future<bool> signIn() => GoogleDriveAuth.signIn();
  static Future<void> signOut() async {
    await GoogleDriveAuth.signOut();
    _lastSyncTime = null;
  }

  // ── Rate limiting ─────────────────────────────────────────────────────────
  static bool _isUploading = false;
  static bool _isDownloading = false;
  static DateTime? _lastUploadTime;
  static int _uploadCount = 0;
  static const _minUploadInterval = Duration(seconds: 30);
  static const _maxUploadsPerHour = 60;

  // ── Upload ────────────────────────────────────────────────────────────────
  static Future<bool> uploadDatabase(dynamic context,
      {bool uploadMasterKey = false, bool uploadVault = false}) async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');

    if (_lastUploadTime != null) {
      final elapsed = DateTime.now().difference(_lastUploadTime!);
      if (elapsed < _minUploadInterval) return false;
      if (elapsed > const Duration(hours: 1)) _uploadCount = 0;
      if (_uploadCount >= _maxUploadsPerHour) return false;
    }

    if (_isUploading) return false;
    _isUploading = true;

    try {
      _lastUploadTime = DateTime.now();
      _uploadCount++;

      final dbService = IsarDatabaseService();
      final notes = await dbService.getAllNotes();
      final vaultData = await VaultService.getVaultDataForBackup();

      final backupData = <String, dynamic>{
        'version': '2.0',
        'created_at': DateTime.now().toIso8601String(),
        'notes': notes.map((n) => n.toMap()).toList(),
        if (vaultData != null) 'vault_data': vaultData,
      };

      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'sinan_backup.gz');
      await File(tempPath)
          .writeAsBytes(CompressionService.compress(jsonEncode(backupData)));

      final backupFile = File(tempPath);
      const fileName = 'sinan_backup.gz';
      final existingFile = await GoogleDriveAuth.findFile(fileName);
      final media = drive.Media(backupFile.openRead(), await backupFile.length());

      if (existingFile != null) {
        await GoogleDriveAuth.driveApi!.files
            .update(drive.File(), existingFile.id!, uploadMedia: media);
      } else {
        await GoogleDriveAuth.driveApi!.files.create(
          drive.File()..name = fileName..mimeType = 'application/gzip',
          uploadMedia: media,
        );
      }

      await backupFile.delete();
      _lastSyncTime = DateTime.now();
      AppLogger.success('Uploaded ${notes.length} notes', 'GoogleDrive');
      return true;
    } catch (e) {
      AppLogger.error('Upload failed', 'GoogleDrive', e);
      return false;
    } finally {
      _isUploading = false;
    }
  }

  // ── Download ──────────────────────────────────────────────────────────────
  static Future<bool> downloadDatabase(dynamic context) async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');
    if (_isDownloading) return false;
    _isDownloading = true;

    try {
      var file = await GoogleDriveAuth.findFile('sinan_backup.json');
      bool isCompressed = false;
      if (file == null) {
        file = await GoogleDriveAuth.findFile('sinan_backup.gz');
        isCompressed = true;
      }
      if (file == null) throw Exception('No backup found in Drive');

      final response = await GoogleDriveAuth.driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(join(tempDir.path, 'drive_backup.json'));
      final sink = tempFile.openWrite();
      await response.stream.forEach((chunk) => sink.add(chunk));
      await sink.close();

      final json = isCompressed
          ? CompressionService.decompress(await tempFile.readAsBytes())
          : await tempFile.readAsString();

      final dynamic jsonData = jsonDecode(json);
      List<dynamic> notesList;

      if (jsonData is Map<String, dynamic>) {
        notesList = jsonData['notes'] ?? [];
        final vaultData = jsonData['vault_data'];
        if (vaultData != null) {
          await VaultService.restoreVaultDataFromBackup(vaultData);
        }
      } else {
        notesList = jsonData;
      }

      final dbService = IsarDatabaseService();
      final isar = await dbService.database;
      await isar.writeTxn(() async {
        await isar.notes.clear();
        for (final noteMap in notesList) {
          await isar.notes.put(Note.fromMap(noteMap));
        }
      });

      await tempFile.delete();
      _lastSyncTime = DateTime.now();
      AppLogger.success('Downloaded ${notesList.length} notes', 'GoogleDrive');
      return true;
    } catch (e) {
      AppLogger.error('Download failed', 'GoogleDrive', e);
      return false;
    } finally {
      _isDownloading = false;
    }
  }

  // ── Merge ─────────────────────────────────────────────────────────────────
  static Future<bool> mergeWithDrive(dynamic context,
      {bool uploadMasterKey = false, bool uploadVault = false}) {
    return GoogleDriveMerge.mergeWithDrive(
      context,
      uploadMasterKey: uploadMasterKey,
      uploadVault: uploadVault,
      uploadFn: uploadDatabase,
    );
  }

  // ── Queries ───────────────────────────────────────────────────────────────
  static Future<bool> hasBackupInDrive() async {
    if (GoogleDriveAuth.driveApi == null) return false;
    try {
      return await GoogleDriveAuth.findFile('sinan_backup.json') != null ||
          await GoogleDriveAuth.findFile('sinan_backup.gz') != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> checkForVaultData() async {
    if (GoogleDriveAuth.driveApi == null) return false;
    try {
      final file = await GoogleDriveAuth.findFile('sinan_backup.gz');
      if (file == null) return false;

      final response = await GoogleDriveAuth.driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> data = [];
      await for (final chunk in response.stream) { data.addAll(chunk); }

      final dynamic jsonData =
          jsonDecode(CompressionService.decompress(data));
      return jsonData is Map<String, dynamic> &&
          jsonData.containsKey('vault_data');
    } catch (e) {
      AppLogger.error('Check vault data error', 'GoogleDrive', e);
      return false;
    }
  }

  static Future<int> getDriveNotesCount() async {
    if (GoogleDriveAuth.driveApi == null) return 0;
    try {
      var file = await GoogleDriveAuth.findFile('sinan_backup.json');
      bool isCompressed = false;
      if (file == null) {
        file = await GoogleDriveAuth.findFile('sinan_backup.gz');
        isCompressed = true;
      }
      if (file == null) return 0;

      final response = await GoogleDriveAuth.driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> data = [];
      await for (final chunk in response.stream) { data.addAll(chunk); }

      final jsonString = isCompressed
          ? CompressionService.decompress(data)
          : String.fromCharCodes(data);
      final dynamic jsonData = jsonDecode(jsonString);

      if (jsonData is Map<String, dynamic>) {
        return (jsonData['notes'] as List?)?.length ?? 0;
      } else if (jsonData is List) {
        return jsonData.length;
      }
      return 0;
    } catch (e) {
      AppLogger.error('Get Drive notes count error', 'GoogleDrive', e);
      return 0;
    }
  }

  Future<DateTime?> checkForRemoteUpdates() async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');
    try {
      final file = await GoogleDriveAuth.findFile('sinan_backup.gz');
      return file?.modifiedTime;
    } catch (e) {
      AppLogger.error('Check updates error', 'GoogleDrive', e);
      return null;
    }
  }
}
