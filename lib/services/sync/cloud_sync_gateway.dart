// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';import 'package:flutter/foundation.dart';import 'package:shared_preferences/shared_preferences.dart'; import 'package:sinan_note/core/utils/logger.dart'; import 'package:sinan_note/services/cloud/google_drive_auth.dart'; import 'package:sinan_note/services/cloud/google_drive_merge.dart'; import 'package:sinan_note/services/sync/sync_engine.dart'; import 'package:sinan_note/services/sync/sync_transport.dart';
/// بوابة المزامنة الموحدة — نقطة الدخول الوحيدة لكل عمليات المزامنة.
///
/// كل الشاشات والـ providers تتحدث مع هذا الملف فقط.
/// هو يقرر: متى نرفع، متى ننزل، متى ندمج، ومتى نتجاهل.
class CloudSyncGateway {
  CloudSyncGateway._();

  // ── State ─────────────────────────────────────────────────────────────────
  static final ValueNotifier<bool> isSyncing = ValueNotifier(false);
  static DateTime? _lastSyncTime;
  static DateTime? get lastSyncTime => _lastSyncTime;

  // ── Dirty tracking ────────────────────────────────────────────────────────
  static bool _hasPendingChanges = false;
  static bool get hasPendingChanges => _hasPendingChanges;

  /// يُستدعى عند تعديل/إضافة/حذف ملاحظة أو كتالوج
  static void markDirty() {
    _hasPendingChanges = true;
  }

  // ── Auth delegates ────────────────────────────────────────────────────────
  static bool get isSignedIn => GoogleDriveAuth.isSignedIn;
  static String? get currentUserEmail => GoogleDriveAuth.currentUserEmail;

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

  // ── Auto sync preference ─────────────────────────────────────────────────
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

  // ── Core sync operations ──────────────────────────────────────────────────

  /// المزامنة الذكية — تُقرر تلقائياً: merge / upload / skip
  static Future<void> smartSync() async {
    if (!isSignedIn) return;
    if (GoogleDriveAuth.driveApi == null) return;
    if (!await SyncTransport.hasInternet()) return;

    isSyncing.value = true;
    try {
      final driveFile = await GoogleDriveAuth.findFile('sinan_backup.gz');

      if (driveFile == null) {
        await upload();
        return;
      }

      final driveModified = driveFile.modifiedTime;
      if (driveModified == null) {
        await upload();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastUploadMs = prefs.getInt('last_upload_timestamp');
      final lastUpload = lastUploadMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastUploadMs)
          : null;

      // جهاز جديد أو بعد استعادة — ادمج
      if (lastUpload == null) {
        AppLogger.info('First sync on this device → silent merge', 'CloudSync');
        await silentMerge();
        return;
      }

      // Drive أحدث → ادمج
      final driveIsNewer =
          driveModified.isAfter(lastUpload.add(const Duration(seconds: 10)));

      if (driveIsNewer) {
        AppLogger.info('Drive is newer → silent merge', 'CloudSync');
        await silentMerge();
      } else if (_hasPendingChanges) {
        AppLogger.info('Local has pending changes → uploading', 'CloudSync');
        await upload();
        await prefs.setInt(
            'last_upload_timestamp', DateTime.now().millisecondsSinceEpoch);
      } else {
        AppLogger.info('No pending changes → skip', 'CloudSync');
      }
    } catch (e) {
      AppLogger.error('Smart sync failed', 'CloudSync', e);
    } finally {
      _lastSyncTime = DateTime.now();
      isSyncing.value = false;
    }
  }

  /// رفع قاعدة البيانات إلى السحابة
  static Future<bool> upload() async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');
    if (!await SyncTransport.hasInternet()) {
      throw Exception('No internet connection');
    }
    isSyncing.value = true;
    try {
      final success = await SyncEngine.upload();
      if (success) {
        _hasPendingChanges = false;
        _lastSyncTime = DateTime.now();
      }
      return success;
    } finally {
      isSyncing.value = false;
    }
  }

  /// تنزيل قاعدة البيانات من السحابة (استبدال كامل)
  static Future<bool> download() async {
    if (GoogleDriveAuth.driveApi == null) throw Exception('Not signed in');
    if (!await SyncTransport.hasInternet()) {
      throw Exception('No internet connection');
    }
    isSyncing.value = true;
    try {
      final success = await SyncEngine.download();
      if (success) {
        _hasPendingChanges = false;
        _lastSyncTime = DateTime.now();
      }
      return success;
    } finally {
      isSyncing.value = false;
    }
  }

  /// دمج صامت (بدون dialog) — الأحدث يفوز
  static Future<void> silentMerge() async {
    isSyncing.value = true;
    try {
      await SyncEngine.silentMerge();
      _hasPendingChanges = false;
      _lastSyncTime = DateTime.now();
    } finally {
      isSyncing.value = false;
    }
  }

  /// دمج مع dialog (يسأل المستخدم)
  static Future<bool> mergeWithDialog(dynamic context) async {
    return GoogleDriveMerge.mergeWithDrive(
      context,
      uploadFn: (_) => upload(),
    );
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  static Future<bool> hasBackupInCloud() async {
    if (GoogleDriveAuth.driveApi == null) return false;
    try {
      return await GoogleDriveAuth.findFile('sinan_backup.gz') != null;
    } catch (_) {
      return false;
    }
  }

  static Future<int> getCloudNotesCount() async {
    return await SyncTransport.getDriveNotesCount();
  }
}

