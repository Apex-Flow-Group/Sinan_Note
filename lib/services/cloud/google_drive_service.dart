// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/logger.dart';
import '../storage/isar_database_service.dart';
import '../../models/note.dart';

class GoogleDriveService {
  // TODO: Replace with your Web Client ID from Google Cloud Console
  static const String _serverClientId = '308129072326-kvf02s0mmvvddtqfchv2rfibtqjumm48.apps.googleusercontent.com';
  
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/drive.file',
    ],
    serverClientId: _serverClientId,
  );

  static GoogleSignInAccount? _currentUser;
  static drive.DriveApi? _driveApi;
  static DateTime? _lastSyncTime;

  static bool get isSignedIn => _currentUser != null;
  static String? get currentUserEmail => _currentUser?.email;
  static DateTime? get lastSyncTime => _lastSyncTime;

  static Future<bool> signIn() async {
    try {
      // Sign out first to clear any cached state
      await _googleSignIn.signOut();
      
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
      AppLogger.success('Successfully signed in as: ${_currentUser!.email}', 'GoogleDrive');
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

  static Future<bool> uploadDatabase(dynamic context) async {
    if (_driveApi == null) throw Exception('Not signed in');

    try {
      final dbService = IsarDatabaseService();
      final notes = await dbService.getAllNotes();
      
      final json = jsonEncode(notes.map((n) => n.toMap()).toList());
      final tempDir = await getTemporaryDirectory();
      final tempPath = join(tempDir.path, 'sinan_backup.json');
      await File(tempPath).writeAsString(json);
      
      final backupFile = File(tempPath);
      const fileName = 'sinan_backup.json';
      final existingFile = await _findFile(fileName);

      final media = drive.Media(backupFile.openRead(), await backupFile.length());

      if (existingFile != null) {
        await _driveApi!.files.update(
          drive.File(),
          existingFile.id!,
          uploadMedia: media,
        );
      } else {
        final driveFile = drive.File()
          ..name = fileName
          ..mimeType = 'application/json';

        await _driveApi!.files.create(
          driveFile,
          uploadMedia: media,
        );
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
      final file = await _findFile('sinan_backup.json');
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
      final file = await _findFile('sinan_backup.json');
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

      final json = await tempFile.readAsString();
      final List<dynamic> data = jsonDecode(json);
      
      final dbService = IsarDatabaseService();
      final isar = await dbService.database;
      
      await isar.writeTxn(() async {
        await isar.notes.clear();
        for (var noteMap in data) {
          final note = Note.fromMap(noteMap);
          await isar.notes.put(note);
        }
      });

      await tempFile.delete();
      _lastSyncTime = DateTime.now();
      return true;
    } catch (e) {
      AppLogger.error('Download failed', 'GoogleDrive', e);
      return false;
    }
  }

  static Future<bool> syncDatabase(dynamic context) async {
    return await uploadDatabase(context);
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
}
