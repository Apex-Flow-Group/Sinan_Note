// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:sinan_note/data/services/sync/google_drive_auth.dart';
import 'package:sinan_note/domain/errors.dart' show SyncException;

/// بصمة ملف السحابة: تكفي لمعرفة إن تغيّر منذ آخر رفع.
class RemoteFile {
  const RemoteFile({this.md5, this.modified});

  final String? md5;
  final DateTime? modified;
}

/// مكان لقطة المزامنة وحسابه. كل فشل يرمي [SyncException]؛ null يعني فقط
/// أنه لا ملف بعد.
abstract interface class SyncRemote {
  bool get isSignedIn;
  String? get accountEmail;

  /// يستعيد جلسة سابقة بصمت (عند البدء والعودة من الخلفية).
  Future<void> restoreSession();
  Future<bool> signIn();
  Future<void> signOut();

  Future<RemoteFile?> stat();

  /// JSON المفكوك، أو null إن لم يوجد ملف.
  Future<Object?> read();

  Future<RemoteFile> write(Map<String, Object?> json);
}

/// ملف واحد مضغوط (gzip) في Google Drive.
class DriveSyncRemote implements SyncRemote {
  DriveSyncRemote(
      {required GoogleDriveAuth auth, this.fileName = currentFileName})
      : _auth = auth;

  final GoogleDriveAuth _auth;

  /// ملف هذا الإصدار وما بعده.
  static const currentFileName = 'sinan_sync_v3.gz';

  /// ملف الإصدارات السابقة: تقرؤه الأجهزة المحدَّثة ولا تكتب فيه أبداً،
  /// فلا يتضرر جهاز لم يُحدَّث بعد.
  static const legacyFileName = 'sinan_backup.gz';

  final String fileName;

  @override
  bool get isSignedIn => _auth.isSignedIn;

  @override
  String? get accountEmail => _auth.currentUserEmail;

  @override
  Future<void> restoreSession() => _auth.restoreSession();

  @override
  Future<bool> signIn() => _auth.signIn();

  @override
  Future<void> signOut() => _auth.signOut();

  drive.DriveApi get _api =>
      _auth.driveApi ?? (throw const SyncException('Not signed in'));

  @override
  Future<RemoteFile?> stat() async {
    final file = await _find();
    return file == null ? null : _stat(file);
  }

  @override
  Future<Object?> read() async {
    final file = await _find();
    if (file == null) return null;
    try {
      final media = await _api.files.get(file.id!,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final bytes = <int>[];
      await media.stream.forEach(bytes.addAll);
      return jsonDecode(utf8.decode(gzip.decode(bytes)));
    } on Object catch (e) {
      throw SyncException('Drive download failed', e);
    }
  }

  @override
  Future<RemoteFile> write(Map<String, Object?> json) async {
    final bytes = gzip.encode(utf8.encode(jsonEncode(json)));
    final existing = await _find();
    try {
      final media = drive.Media(Stream.value(bytes), bytes.length);
      final written = existing == null
          ? await _api.files.create(
              drive.File()
                ..name = fileName
                ..mimeType = 'application/gzip',
              uploadMedia: media,
              $fields: 'id, md5Checksum, modifiedTime',
            )
          : await _api.files.update(drive.File(), existing.id!,
              uploadMedia: media, $fields: 'id, md5Checksum, modifiedTime');
      return _stat(written);
    } on Object catch (e) {
      throw SyncException('Drive upload failed', e);
    }
  }

  Future<drive.File?> _find() async {
    try {
      final list = await _api.files.list(
        q: "name='$fileName' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, md5Checksum, modifiedTime)',
      );
      final files = list.files ?? const [];
      return files.isEmpty ? null : files.first;
    } on SyncException {
      rethrow;
    } on Object catch (e) {
      throw SyncException('Drive lookup failed', e);
    }
  }

  static RemoteFile _stat(drive.File f) =>
      RemoteFile(md5: f.md5Checksum, modified: f.modifiedTime);
}
