// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/logger.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleDriveAuth {
  static final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  static GoogleSignInAccount? currentUser;
  static drive.DriveApi? driveApi;

  static bool get isSignedIn => currentUser != null;
  static String? get currentUserEmail => currentUser?.email;

  static bool _initialized = false;

  static Future<void> initializeSignIn() async {
    if (_initialized) return;
    _initialized = true;
    try {
      currentUser = await googleSignIn.signInSilently(suppressErrors: true);
      if (currentUser != null) {
        final authClient = await googleSignIn.authenticatedClient();
        if (authClient != null) {
          driveApi = drive.DriveApi(authClient);
          AppLogger.success('Restored session: ${currentUser!.email}', 'GoogleDrive');
        } else {
          // token انتهى — نعيد التهيئة بصمت بدون dialog
          currentUser = null;
          driveApi = null;
          _initialized = false;
        }
      }
    } catch (e) {
      // أي خطأ يُسكَّت تماماً — لا dialog للمستخدم
      currentUser = null;
      driveApi = null;
      _initialized = false;
      AppLogger.warning('Silent sign-in failed silently', 'GoogleDrive');
    }
  }

  /// إعادة تهيئة الجلسة عند العودة من الخلفية
  static Future<void> refreshSessionIfNeeded() async {
    if (currentUser == null) return;
    try {
      final authClient = await googleSignIn.authenticatedClient();
      if (authClient != null) {
        driveApi = drive.DriveApi(authClient);
      } else {
        // token منتهي — نعيد المحاولة بصمت
        final refreshed = await googleSignIn.signInSilently(suppressErrors: true);
        if (refreshed != null) {
          currentUser = refreshed;
          final newClient = await googleSignIn.authenticatedClient();
          if (newClient != null) {
            driveApi = drive.DriveApi(newClient);
          } else {
            currentUser = null;
            driveApi = null;
          }
        } else {
          currentUser = null;
          driveApi = null;
        }
      }
    } catch (_) {
      // صامت تماماً
      currentUser = null;
      driveApi = null;
    }
  }

  static Future<bool> signIn() async {
    try {
      currentUser = await googleSignIn.signIn();
      if (currentUser == null) return false;
      final authClient = await googleSignIn.authenticatedClient();
      if (authClient == null) return false;
      driveApi = drive.DriveApi(authClient);
      AppLogger.success('Signed in as: ${currentUser!.email}', 'GoogleDrive');
      return true;
    } catch (e) {
      AppLogger.error('Sign in error', 'GoogleDrive', e);
      return false;
    }
  }

  static Future<void> signOut() async {
    await googleSignIn.signOut();
    currentUser = null;
    driveApi = null;
  }

  static Future<drive.File?> findFile(String fileName) async {
    try {
      final fileList = await driveApi!.files.list(
        q: "name='$fileName' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id, name, modifiedTime)',
      );
      return fileList.files?.isNotEmpty == true ? fileList.files!.first : null;
    } catch (e) {
      AppLogger.error('Find file error', 'GoogleDrive', e);
      return null;
    }
  }
}
