// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:sinan_note/domain/logger.dart';

/// جلسة Google Drive. نسخة واحدة يتشاركها ملفا المزامنة (الحالي والقديم).
class GoogleDriveAuth {
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  GoogleSignInAccount? currentUser;
  drive.DriveApi? driveApi;

  bool get isSignedIn => currentUser != null;
  String? get currentUserEmail => currentUser?.email;

  bool _initialized = false;
  Future<void>? _restoring;

  /// أول مرة: تسجيل دخول صامت. بعدها (العودة من الخلفية): تحديث الرمز
  /// فقط. الطلبات المتزامنة طلب واحد. لا يُنتظر عند بدء التشغيل.
  Future<void> restoreSession() => _restoring ??=
      (_initialized ? refreshSessionIfNeeded() : initializeSignIn())
          .whenComplete(() => _restoring = null);

  Future<void> initializeSignIn() async {
    if (_initialized) return;
    _initialized = true;
    try {
      currentUser = await googleSignIn.signInSilently(suppressErrors: true);
      if (currentUser != null) {
        final authClient = await googleSignIn.authenticatedClient();
        if (authClient != null) {
          driveApi = drive.DriveApi(authClient);
          AppLogger.success(
              'Restored session: ${currentUser!.email}', 'GoogleDrive');
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
  Future<void> refreshSessionIfNeeded() async {
    if (currentUser == null) return;
    try {
      final authClient = await googleSignIn.authenticatedClient();
      if (authClient != null) {
        driveApi = drive.DriveApi(authClient);
      } else {
        // token منتهي — نعيد المحاولة بصمت
        final refreshed =
            await googleSignIn.signInSilently(suppressErrors: true);
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

  Future<bool> signIn() async {
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

  Future<void> signOut() async {
    await googleSignIn.signOut();
    currentUser = null;
    driveApi = null;
  }
}
