// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/core/utils/logger.dart';
import 'package:sinan_note/services/cloud/google_drive_auth.dart';
import 'package:sinan_note/services/storage/compression_service.dart';

/// Transport layer — مسؤول فقط عن رفع/تنزيل bytes من/إلى Google Drive.
/// لا يقرر، لا يدمج، لا يعرف شيئاً عن النوتات.
class SyncTransport {
  SyncTransport._();

  // ── Rate limiting ─────────────────────────────────────────────────────────
  static DateTime? _lastUploadTime;
  static int _uploadCount = 0;
  static const _maxUploadsPerHour = 180;

  /// هل الإنترنت متاح؟
  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('www.googleapis.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// رفع JSON مضغوط إلى Drive — يُرجع true عند النجاح
  static Future<bool> uploadCompressed(Map<String, dynamic> data) async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');
    if (!await hasInternet()) throw Exception('No internet connection');

    // Rate limiting
    if (_lastUploadTime != null) {
      final elapsed = DateTime.now().difference(_lastUploadTime!);
      if (elapsed > const Duration(hours: 1)) _uploadCount = 0;
      if (_uploadCount >= _maxUploadsPerHour) return false;
    }

    try {
      _lastUploadTime = DateTime.now();
      _uploadCount++;

      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'sinan_backup.gz');
      await File(tempPath)
          .writeAsBytes(CompressionService.compress(jsonEncode(data)));

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

      // حفظ MD5 بعد الرفع — أساس Fast Path
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_upload_timestamp', DateTime.now().millisecondsSinceEpoch);
      final uploadedFile = await GoogleDriveAuth.findFile(fileName);
      if (uploadedFile?.md5Checksum != null) {
        await prefs.setString(
            'last_known_drive_md5', uploadedFile!.md5Checksum!);
      }

      AppLogger.success('Upload complete', 'SyncTransport');
      return true;
    } catch (e) {
      AppLogger.error('Upload failed', 'SyncTransport', e);
      return false;
    }
  }

  /// تنزيل وفك ضغط من Drive — يُرجع JSON كـ Map أو null
  static Future<Map<String, dynamic>?> downloadAndDecompress() async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');
    if (!await hasInternet()) throw Exception('No internet connection');

    try {
      final file = await GoogleDriveAuth.findFile('sinan_backup.gz');
      if (file == null) return null;

      final response = await GoogleDriveAuth.driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(join(tempDir.path, 'drive_download.gz'));
      final sink = tempFile.openWrite();
      await response.stream.forEach((chunk) => sink.add(chunk));
      await sink.close();

      final json = CompressionService.decompress(await tempFile.readAsBytes());
      final dynamic jsonData = jsonDecode(json);
      await tempFile.delete();

      // Normalize: old format (List) → new format (Map)
      if (jsonData is Map<String, dynamic>) {
        return jsonData;
      } else if (jsonData is List) {
        return {'notes': jsonData, 'categories': [], 'deleted_ids': {}};
      }
      return null;
    } catch (e) {
      AppLogger.error('Download failed', 'SyncTransport', e);
      return null;
    }
  }

  /// جلب MD5 الحالي من Drive (للـ Fast Path check)
  static Future<String?> getDriveMd5() async {
    try {
      final file = await GoogleDriveAuth.findFile('sinan_backup.gz');
      return file?.md5Checksum;
    } catch (_) {
      return null;
    }
  }

  /// عدد النوتات في Drive (للعرض فقط)
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

      final jsonString =
          CompressionService.decompress(Uint8List.fromList(data));
      final dynamic jsonData = jsonDecode(jsonString);

      if (jsonData is Map<String, dynamic>) {
        return (jsonData['notes'] as List?)?.length ?? 0;
      } else if (jsonData is List) {
        return jsonData.length;
      }
      return 0;
    } catch (e) {
      AppLogger.error('Get Drive notes count error', 'SyncTransport', e);
      return 0;
    }
  }
}

