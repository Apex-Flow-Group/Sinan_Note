// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:apex_note/screens/sync/google_drive_sync/sync_step.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleDriveSyncController extends ChangeNotifier {
  SyncStep _currentStep = SyncStep.signIn;
  String? _errorMessage;
  String? snackBarMessage;

  // Temporary data (NOT saved until success)
  int _localNotesCount = 0;
  int _driveNotesCount = 0;
  bool _hasLockedNotes = false;
  bool _hasConflict = false;

  // Getters
  SyncStep get currentStep => _currentStep;
  String? get errorMessage => _errorMessage;
  int get localNotesCount => _localNotesCount;
  int get driveNotesCount => _driveNotesCount;
  bool get hasLockedNotes => _hasLockedNotes;
  bool get hasConflict => _hasConflict;

  /// تسجيل الدخول
  Future<bool> signIn() async {
    try {
      // 🚧 DEBUG: للاختبار على Linux
      if (Platform.isLinux) {
        // محاكاة تسجيل دخول ناجح
        _currentStep = SyncStep.checking;
        notifyListeners();
        await _checkState();
        return true;
      }

      final success = await GoogleDriveService.signIn();
      if (success) {
        _currentStep = SyncStep.checking;
        notifyListeners();
        await _checkState();
        return true;
      }
      _errorMessage = 'Sign in cancelled or failed';
      _currentStep = SyncStep.error;
      notifyListeners();
      return false;
    } on MissingPluginException {
      _errorMessage =
          'Google Sign In is not supported on this platform. Use Android/iOS/Web.';
      _currentStep = SyncStep.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _currentStep = SyncStep.error;
      notifyListeners();
      return false;
    }
  }

  /// فحص الحالة (تعارض، ملاحظات مقفلة)
  Future<void> _checkState() async {
    try {
      // ✅ تهيئة قاعدة البيانات أولاً
      final dbService = IsarDatabaseService();
      await dbService.database;

      // فحص الملاحظات المحلية (العادية فقط)
      final localNotes = await dbService.getAllNotes();
      _localNotesCount = localNotes.where((n) => !n.isLocked).length;

      // فحص الملاحظات المقفلة (للتحذير فقط)
      final lockedNotes = await dbService.getLockedNotes();
      _hasLockedNotes = lockedNotes.isNotEmpty;

      // 🚧 DEBUG: على Linux
      if (Platform.isLinux) {
        _hasConflict = false;
        // تخطي تحذير الخزنة في Demo Mode
        _currentStep = SyncStep.success;
        notifyListeners();
        return;
      }

      // فحص وجود backup في Drive
      final hasBackup = await GoogleDriveService.hasBackupInDrive();

      if (hasBackup) {
        _driveNotesCount = await GoogleDriveService.getDriveNotesCount();
        _hasConflict = _driveNotesCount != _localNotesCount;
      }

      // 🎯 المنطق الجديد:
      if (_localNotesCount == 0 && _driveNotesCount > 0) {
        // جهاز فارغ → تنزيل مباشر
        await _downloadFromDrive();
      } else if (_localNotesCount > 0 && _driveNotesCount == 0) {
        // Drive فارغ → رفع مباشر
        await _executeSync();
      } else if (_hasConflict) {
        // تعارض → اسأل المستخدم
        _currentStep = SyncStep.conflict;
        notifyListeners();
      } else {
        // لا تعارض → مزامنة عادية
        await _executeSync();
      }

      // ⚠️ تحذير الخزنة (إعلامي فقط - لا يؤثر على المزامنة)
      if (_hasLockedNotes && _currentStep == SyncStep.success) {
        snackBarMessage = 'Locked notes will not be synced to Google Drive';
      }
    } catch (e) {
      _errorMessage = e.toString();
      _currentStep = SyncStep.error;
      notifyListeners();
    }
  }

  /// حل التعارض
  Future<void> resolveConflict(String action) async {
    try {
      _currentStep = SyncStep.syncing;
      notifyListeners();

      if (action == 'useDrive') {
        final success = await GoogleDriveService.downloadDatabase(null);
        if (!success) {
          _errorMessage = 'Failed to download from Drive';
          _currentStep = SyncStep.error;
          notifyListeners();
          return;
        }
      } else if (action == 'useDevice') {
        final success = await GoogleDriveService.uploadDatabase(null);
        if (!success) {
          _errorMessage = 'Failed to upload to Drive';
          _currentStep = SyncStep.error;
          notifyListeners();
          return;
        }
      } else if (action == 'merge') {
        final success = await GoogleDriveService.mergeWithDrive(null);
        if (!success) {
          _errorMessage = 'Failed to merge';
          _currentStep = SyncStep.error;
          notifyListeners();
          return;
        }
      }

      // ✅ النجاح مباشرة (لا تحذير خزنة)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('google_drive_auto_sync', true);
      _currentStep = SyncStep.success;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _currentStep = SyncStep.error;
      notifyListeners();
    }
  }

  /// تنزيل من Drive (جهاز فارغ)
  Future<void> _downloadFromDrive() async {
    try {
      _currentStep = SyncStep.syncing;
      notifyListeners();

      final success = await GoogleDriveService.downloadDatabase(null);

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('google_drive_auto_sync', true);
        _currentStep = SyncStep.success;
        notifyListeners();
      } else {
        _errorMessage = 'Failed to download from Drive';
        _currentStep = SyncStep.error;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _currentStep = SyncStep.error;
      notifyListeners();
    }
  }

  /// تنفيذ المزامنة
  Future<void> _executeSync() async {
    try {
      _currentStep = SyncStep.syncing;
      notifyListeners();

      // 🚧 DEBUG: على Linux محاكاة فقط
      if (Platform.isLinux) {
        // محاكاة تأخير المزامنة
        await Future.delayed(const Duration(seconds: 2));

        // حفظ الحالة
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('google_drive_auto_sync', true);

        _currentStep = SyncStep.success;
        notifyListeners();
        return;
      }

      // تنفيذ المزامنة الحقيقية
      final success = await GoogleDriveService.uploadDatabase(null);

      if (success) {
        // ✅ حفظ الحالة فقط بعد النجاح
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('google_drive_auto_sync', true);

        _currentStep = SyncStep.success;
        notifyListeners();
      } else {
        _errorMessage = 'Sync failed';
        _currentStep = SyncStep.error;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _currentStep = SyncStep.error;
      notifyListeners();
    }
  }

  /// إلغاء العملية
  Future<void> abort() async {
    await GoogleDriveService.signOut();
    _currentStep = SyncStep.signIn;
    _errorMessage = null;
    notifyListeners();
  }

  /// إعادة المحاولة
  void retry() {
    _currentStep = SyncStep.signIn;
    _errorMessage = null;
    notifyListeners();
  }

  void consumeSnackBar() {
    snackBarMessage = null;
  }
}
