// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return false;

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) return false;

      _driveApi = drive.DriveApi(authClient);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Sign in error: $e');
      }
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  bool get isSignedIn => _currentUser != null;
  String? get userEmail => _currentUser?.email;

  Future<String?> uploadDatabase() async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      final dbPath = join(await getDatabasesPath(), 'notes.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      const fileName = 'sinan_backup.db';
      final existingFile = await _findFile(fileName);

      final media = drive.Media(dbFile.openRead(), await dbFile.length());

      if (existingFile != null) {
        // Update existing file
        await _driveApi!.files.update(
          drive.File(),
          existingFile.id!,
          uploadMedia: media,
        );
        return existingFile.id;
      } else {
        // Create new file
        final driveFile = drive.File()
          ..name = fileName
          ..mimeType = 'application/octet-stream';

        final response = await _driveApi!.files.create(
          driveFile,
          uploadMedia: media,
        );
        return response.id;
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<DateTime?> checkForRemoteUpdates() async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      final file = await _findFile('sinan_backup.db');
      if (file == null) return null;

      return file.modifiedTime;
    } catch (e) {
      if (kDebugMode) {
        print('Check updates error: $e');
      }
      return null;
    }
  }

  Future<void> downloadDatabase() async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      final file = await _findFile('sinan_backup.db');
      if (file == null) throw Exception('No backup found in Drive');

      final dbPath = join(await getDatabasesPath(), 'notes.db');
      final tempPath = join(await getDatabasesPath(), 'notes_drive_temp.db');

      final response = await _driveApi!.files.get(
        file.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final tempFile = File(tempPath);
      final sink = tempFile.openWrite();

      await response.stream.forEach((chunk) {
        sink.add(chunk);
      });

      await sink.close();

      // Verify downloaded file
      if (!await tempFile.exists() || await tempFile.length() < 1024) {
        await tempFile.delete();
        throw Exception('Downloaded file is invalid');
      }

      // Replace current database
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      await tempFile.rename(dbPath);
    } catch (e) {
      throw Exception('Download failed: $e');
    }
  }

  Future<drive.File?> _findFile(String fileName) async {
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
      if (kDebugMode) {
        print('Find file error: $e');
      }
      return null;
    }
  }
}
