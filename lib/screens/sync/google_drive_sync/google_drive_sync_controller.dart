// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/screens/sync/google_drive_sync/sync_step.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:apex_note/services/sync/cloud_sync_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GoogleDriveSyncController extends ChangeNotifier {
  SyncStep _currentStep = SyncStep.signIn;
  String? _errorMessage;
  String? snackBarMessage;

  int _localNotesCount = 0;
  int _driveNotesCount = 0;
  bool _hasConflict = false;

  SyncStep get currentStep => _currentStep;
  String? get errorMessage => _errorMessage;
  int get localNotesCount => _localNotesCount;
  int get driveNotesCount => _driveNotesCount;
  bool get hasConflict => _hasConflict;

  Future<bool> signIn() async {
    try {
      final success = await CloudSyncGateway.signIn();
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
      _errorMessage = 'Google Sign In is not supported on this platform.';
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

  Future<void> _checkState() async {
    try {
      final dbService = SqliteDatabaseService();
      await dbService.database;

      // العادية فقط — الخزنة محلية لا تُحسب
      final localNotes = await dbService.getAllNotes();
      _localNotesCount = localNotes.where((n) => !n.isLocked).length;

      final hasBackup = await CloudSyncGateway.hasBackupInCloud();
      AppLogger.info('hasBackup: $hasBackup', 'SyncController');

      if (hasBackup) {
        _driveNotesCount = await CloudSyncGateway.getCloudNotesCount();
      } else {
        _driveNotesCount = 0;
      }

      _hasConflict = hasBackup && _driveNotesCount != _localNotesCount;

      if (_localNotesCount == 0 && _driveNotesCount > 0) {
        await _downloadFromDrive();
      } else if (_localNotesCount > 0 && _driveNotesCount == 0) {
        await _executeSync();
      } else if (_hasConflict) {
        _currentStep = SyncStep.conflict;
        notifyListeners();
      } else {
        await _executeSync();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _currentStep = SyncStep.error;
      notifyListeners();
    }
  }

  Future<void> resolveConflict(String action) async {
    try {
      _currentStep = SyncStep.syncing;
      notifyListeners();

      bool success = false;
      if (action == 'useDrive') {
        success = await CloudSyncGateway.download();
      } else if (action == 'useDevice') {
        success = await CloudSyncGateway.upload();
      } else if (action == 'merge') {
        success = await CloudSyncGateway.mergeWithDialog(null);
      }

      if (!success) {
        _errorMessage = 'Operation failed';
        _currentStep = SyncStep.error;
        notifyListeners();
        return;
      }

      await CloudSyncGateway.setAutoSync(true);
      _currentStep = SyncStep.success;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _currentStep = SyncStep.error;
      notifyListeners();
    }
  }

  Future<void> _downloadFromDrive() async {
    try {
      _currentStep = SyncStep.syncing;
      notifyListeners();

      final success = await CloudSyncGateway.download();
      if (success) {
        await CloudSyncGateway.setAutoSync(true);
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

  Future<void> _executeSync() async {
    try {
      _currentStep = SyncStep.syncing;
      notifyListeners();

      final success = await CloudSyncGateway.upload();
      if (success) {
        await CloudSyncGateway.setAutoSync(true);
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

  Future<void> abort() async {
    await CloudSyncGateway.signOut();
    _currentStep = SyncStep.signIn;
    _errorMessage = null;
    notifyListeners();
  }

  void retry() {
    _currentStep = SyncStep.signIn;
    _errorMessage = null;
    notifyListeners();
  }

  void consumeSnackBar() {
    snackBarMessage = null;
  }
}
