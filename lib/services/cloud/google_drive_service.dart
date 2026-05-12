// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/models/category.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/cloud/google_drive_auth.dart';
import 'package:apex_note/services/cloud/google_drive_merge.dart';
import 'package:apex_note/services/storage/compression_service.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveService {
  // ── Auth delegates ────────────────────────────────────────────────────────
  static bool get isSignedIn => GoogleDriveAuth.isSignedIn;
  static String? get currentUserEmail => GoogleDriveAuth.currentUserEmail;
  static DateTime? _lastSyncTime;
  static DateTime? get lastSyncTime => _lastSyncTime;

  static Future<void> initializeSignIn() async {
    await GoogleDriveAuth.initializeSignIn();
    await loadAutoSyncState();
  }

  static Future<bool> signIn() => GoogleDriveAuth.signIn();
  static Future<void> signOut() async {
    await GoogleDriveAuth.signOut();
    _lastSyncTime = null;
    await setAutoSync(false);
  }

  // ── Auto sync state ───────────────────────────────────────────────────────
  static final ValueNotifier<bool> autoSyncEnabled = ValueNotifier(false);

  static Future<void> loadAutoSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    autoSyncEnabled.value = prefs.getBool('google_drive_auto_sync') ?? false;
  }

  static Future<void> setAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('google_drive_auto_sync', value);
    autoSyncEnabled.value = value;
  }

  // ── Rate limiting ─────────────────────────────────────────────────────────
  static final ValueNotifier<bool> isSyncing = ValueNotifier(false);

  static bool _isUploading = false;
  static bool _isDownloading = false;
  static DateTime? _lastUploadTime;
  static int _uploadCount = 0;
  static const _maxUploadsPerHour = 180;

  // ── Dirty tracking (رفع فقط عند وجود تغييرات) ────────────────────────────
  static bool _hasPendingChanges = false;

  /// يُستدعى عند تعديل/إضافة/حذف ملاحظة لتعليم أن هناك تغييرات تحتاج رفع
  static void markDirty() {
    _hasPendingChanges = true;
  }

  /// هل هناك تغييرات محلية لم تُرفع بعد؟
  static bool get hasPendingChanges => _hasPendingChanges;

  // ── Internet check ────────────────────────────────────────────────────────
  static Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('www.googleapis.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Smart startup sync (no dialog) ───────────────────────────────────────
  static Future<void> smartSyncOnStartup() async {
    if (GoogleDriveAuth.driveApi == null) return;
    if (!await _hasInternet()) return;

    isSyncing.value = true;
    try {
      var driveFile = await GoogleDriveAuth.findFile('sinan_backup.gz');

      if (driveFile == null) {
        await uploadDatabase(null);
        return;
      }

      final driveModified = driveFile.modifiedTime;
      if (driveModified == null) {
        await uploadDatabase(null);
        return;
      }

      // نقارن وقت Drive بآخر رفع محلي
      final prefs = await _getPrefs();
      final lastUploadMs = prefs.getInt('last_upload_timestamp');
      final lastUpload = lastUploadMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastUploadMs)
          : null;

      // Drive أحدث من آخر رفع محلي → اجلب من Drive
      final driveIsNewer = lastUpload == null ||
          driveModified.isAfter(lastUpload.add(const Duration(seconds: 10)));

      if (driveIsNewer) {
        AppLogger.info('Drive is newer → silent merge', 'GoogleDrive');
        await _silentMerge();
      } else if (_hasPendingChanges) {
        AppLogger.info('Local has pending changes → uploading', 'GoogleDrive');
        await uploadDatabase(null);
        await prefs.setInt(
            'last_upload_timestamp', DateTime.now().millisecondsSinceEpoch);
      } else {
        AppLogger.info('No pending changes → skip upload', 'GoogleDrive');
      }
    } catch (e) {
      AppLogger.error('Smart sync failed', 'GoogleDrive', e);
    } finally {
      if (!_isDownloading && !_isUploading) {
        isSyncing.value = false;
      }
    }
  }

  static Future<SharedPreferences> _getPrefs() =>
      SharedPreferences.getInstance();

  // ── Silent merge (note-level, no dialog) ─────────────────────────────────
  static Future<void> silentMerge() => _silentMerge();
  static Future<void> _silentMerge() async {
    if (_isDownloading || _isUploading) return;
    _isDownloading = true;
    isSyncing.value = true;
    try {
      final file = await GoogleDriveAuth.findFile('sinan_backup.gz');
      if (file == null) {
        _isDownloading = false;
        isSyncing.value = false;
        return;
      }

      final response = await GoogleDriveAuth.driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(join(tempDir.path, 'drive_silent.gz'));
      final sink = tempFile.openWrite();
      await response.stream.forEach((chunk) => sink.add(chunk));
      await sink.close();

      final json = CompressionService.decompress(await tempFile.readAsBytes());
      final dynamic jsonData = jsonDecode(json);
      await tempFile.delete();

      final List<dynamic> driveList = jsonData is Map<String, dynamic>
          ? (jsonData['notes'] as List? ?? [])
          : jsonData as List;
      final List<dynamic> driveCats = jsonData is Map<String, dynamic>
          ? (jsonData['categories'] as List? ?? [])
          : [];

      // سجلات الحذف من Drive + المحلي
      final driveDeletedRaw =
          (jsonData is Map ? (jsonData['deleted_ids'] as Map? ?? {}) : {});
      final driveDeleted = <int, DateTime>{};
      driveDeletedRaw.forEach((k, v) {
        final id = int.tryParse(k.toString());
        final ms = v is int ? v : int.tryParse(v.toString());
        if (id != null && ms != null) {
          driveDeleted[id] = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      });
      final localDeleted = await SqliteDatabaseService.getDeletedNoteIds();
      final allDeleted = <int, DateTime>{...localDeleted};
      driveDeleted.forEach((id, dt) {
        if (!allDeleted.containsKey(id) || dt.isAfter(allDeleted[id]!)) {
          allDeleted[id] = dt;
        }
      });

      final dbService = SqliteDatabaseService();
      final localNotes = await dbService.getAllNotes();
      // فقط النوتات غير المشفرة من Drive
      final driveNotes = driveList
          .where((m) => (m['isLocked'] ?? 0) == 0)
          .map((m) => Note.fromMap(m))
          .toList();

      final Map<int, Note> merged = {};
      for (final n in localNotes) {
        if (n.id != null && !n.isLocked) merged[n.id!] = n;
      }
      for (final n in driveNotes) {
        if (n.id == null) continue;
        final local = merged[n.id!];
        if (local == null || n.updatedAt.isAfter(local.updatedAt)) {
          merged[n.id!] = n;
        }
      }

      // طبّق الحذف
      allDeleted.forEach((id, deletedAt) {
        final note = merged[id];
        if (note != null && deletedAt.isAfter(note.updatedAt)) {
          merged.remove(id);
        }
      });

      // upsert المدمجة مع الحفاظ على الـ id — بدون حذف وإعادة إدراج
      final allLocal = await dbService.getAllNotes();
      final mergedIds = merged.keys.toSet();
      for (final n in allLocal) {
        if (n.id != null && !n.isLocked && !mergedIds.contains(n.id)) {
          await dbService.deleteNote(n.id!);
        }
      }
      for (final n in merged.values) {
        await dbService.upsertNote(n);
      }
      // دمج الكتالوجات: upsert الموجودة + أضف الجديدة + احذف المحذوفة من Drive
      final existingCats = await dbService.getAllCategories();
      final existingIds = existingCats.map((c) => c.id).toSet();
      final driveCatIds = driveCats.map((c) => c['id'] as int).toSet();
      for (final c in driveCats) {
        final catId = c['id'] as int;
        final cat = NoteCategory(
          id: catId,
          name: c['name'] as String,
          sortOrder: c['sortOrder'] as int? ?? 0,
        );
        if (existingIds.contains(catId)) {
          await dbService.updateCategory(cat);
        } else {
          await dbService.insertCategory(cat);
        }
      }
      // احذف الكتالوجات المحلية غير الموجودة في Drive
      for (final c in existingCats) {
        if (!driveCatIds.contains(c.id)) {
          await dbService.deleteCategory(c.id);
        }
      }

      _lastSyncTime = DateTime.now();
      AppLogger.success('Silent merge: ${merged.length} notes', 'GoogleDrive');
    } catch (e) {
      AppLogger.error('Silent merge failed', 'GoogleDrive', e);
      _isDownloading = false;
      isSyncing.value = false;
      return; // Don't proceed to upload on merge failure
    }
    _isDownloading = false;
    // رفع بعد انتهاء الدمج كاملاً — uploadDatabase manages isSyncing in its finally
    await uploadDatabase(null);
  }

  // ── Upload (العادية فقط — الخزنة محلية دائماً) ───────────────────────────
  static Future<bool> uploadDatabase(dynamic context) async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');
    if (!await _hasInternet()) throw Exception('No internet connection');

    if (_lastUploadTime != null) {
      final elapsed = DateTime.now().difference(_lastUploadTime!);
      // تجاوز rate limit إذا كانت المزامنة مطلوبة من merge
      if (elapsed > const Duration(hours: 1)) _uploadCount = 0;
      if (_uploadCount >= _maxUploadsPerHour) return false;
    }

    if (_isUploading) return false;
    _isUploading = true;
    isSyncing.value = true;

    try {
      _lastUploadTime = DateTime.now();
      _uploadCount++;

      final dbService = SqliteDatabaseService();
      final allNotes = await dbService.getAllNotes();

      // الخزنة محلية دائماً — لا نرفع المشفر أبداً
      final notes = allNotes.where((n) => !n.isLocked).toList();

      final categories = await dbService.getAllCategories();
      final deletedIds = await SqliteDatabaseService.getDeletedNoteIds();
      await SqliteDatabaseService.cleanOldDeletions();

      final backupData = <String, dynamic>{
        'version': '2.0',
        'created_at': DateTime.now().toIso8601String(),
        'notes': notes.map((n) => n.toMap()).toList(),
        'categories': categories
            .map((c) => {'id': c.id, 'name': c.name, 'sortOrder': c.sortOrder})
            .toList(),
        'deleted_ids': deletedIds
            .map((id, dt) => MapEntry('$id', dt.millisecondsSinceEpoch)),
      };

      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'sinan_backup.gz');
      await File(tempPath)
          .writeAsBytes(CompressionService.compress(jsonEncode(backupData)));

      final backupFile = File(tempPath);
      const fileName = 'sinan_backup.gz';
      final existingFile = await GoogleDriveAuth.findFile(fileName);
      final media =
          drive.Media(backupFile.openRead(), await backupFile.length());

      if (existingFile != null) {
        await GoogleDriveAuth.driveApi!.files
            .update(drive.File(), existingFile.id!, uploadMedia: media);
      } else {
        await GoogleDriveAuth.driveApi!.files.create(
          drive.File()
            ..name = fileName
            ..mimeType = 'application/gzip',
          uploadMedia: media,
        );
      }

      await backupFile.delete();
      _lastSyncTime = DateTime.now();
      _hasPendingChanges = false; // ✅ تم الرفع — لا تغييرات معلّقة
      final prefs = await _getPrefs();
      await prefs.setInt(
          'last_upload_timestamp', _lastSyncTime!.millisecondsSinceEpoch);
      AppLogger.success('Uploaded ${notes.length} notes', 'GoogleDrive');
      return true;
    } catch (e) {
      AppLogger.error('Upload failed', 'GoogleDrive', e);
      return false;
    } finally {
      _isUploading = false;
      if (!_isDownloading) isSyncing.value = false;
    }
  }

  // ── Download ──────────────────────────────────────────────────────────────
  static Future<bool> downloadDatabase(dynamic context) async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');
    if (!await _hasInternet()) throw Exception('No internet connection');
    if (_isDownloading) return false;
    _isDownloading = true;
    isSyncing.value = true;

    try {
      final file = await GoogleDriveAuth.findFile('sinan_backup.gz');
      if (file == null) throw Exception('No backup found in Drive');

      final response = await GoogleDriveAuth.driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(join(tempDir.path, 'drive_backup.gz'));
      final sink = tempFile.openWrite();
      await response.stream.forEach((chunk) => sink.add(chunk));
      await sink.close();

      final json = CompressionService.decompress(await tempFile.readAsBytes());
      final dynamic jsonData = jsonDecode(json);
      await tempFile.delete();

      final List<dynamic> notesList = jsonData is Map<String, dynamic>
          ? (jsonData['notes'] ?? [])
          : jsonData;
      final List<dynamic> categoriesList = jsonData is Map<String, dynamic>
          ? (jsonData['categories'] ?? [])
          : [];

      // فقط النوتات غير المشفرة — الخزنة محلية دائماً
      final regularNotes =
          notesList.where((m) => (m['isLocked'] ?? 0) == 0).toList();

      final dbService = SqliteDatabaseService();
      final lockedLocal = await dbService.getLockedNotes();
      // حذف النوتات العادية وإدراج نوتات Drive مع الحفاظ على الـ id
      final allLocal = await dbService.getAllNotes();
      for (final n in allLocal) {
        if (n.id != null && !n.isLocked) await dbService.deleteNote(n.id!);
      }
      for (final m in regularNotes) {
        await dbService.upsertNote(Note.fromMap(m));
      }
      for (final n in lockedLocal) {
        await dbService.updateNote(n);
      }
      // استعادة الكتالوجات
      if (categoriesList.isNotEmpty) {
        final existingCats = await dbService.getAllCategories();
        for (final c in existingCats) {
          await dbService.deleteCategory(c.id);
        }
        for (final c in categoriesList) {
          await dbService.insertCategory(NoteCategory(
            id: c['id'] as int,
            name: c['name'] as String,
            sortOrder: c['sortOrder'] as int? ?? 0,
          ));
        }
      }

      _lastSyncTime = DateTime.now();
      AppLogger.success(
          'Downloaded ${regularNotes.length} notes', 'GoogleDrive');
      return true;
    } catch (e) {
      AppLogger.error('Download failed', 'GoogleDrive', e);
      return false;
    } finally {
      _isDownloading = false;
      if (!_isUploading) isSyncing.value = false;
    }
  }

  // ── Merge ─────────────────────────────────────────────────────────────────
  static Future<bool> mergeWithDrive(dynamic context) {
    return GoogleDriveMerge.mergeWithDrive(
      context,
      uploadFn: uploadDatabase,
    );
  }

  // ── Queries ───────────────────────────────────────────────────────────────
  static Future<bool> hasBackupInDrive() async {
    if (GoogleDriveAuth.driveApi == null) return false;
    try {
      return await GoogleDriveAuth.findFile('sinan_backup.gz') != null;
    } catch (_) {
      return false;
    }
  }

  static Future<int> getDriveNotesCount() async {
    if (GoogleDriveAuth.driveApi == null) return 0;
    try {
      final file = await GoogleDriveAuth.findFile('sinan_backup.gz');
      if (file == null) return 0;

      final response = await GoogleDriveAuth.driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> data = [];
      await for (final chunk in response.stream) {
        data.addAll(chunk);
      }

      final jsonString = CompressionService.decompress(data);
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
