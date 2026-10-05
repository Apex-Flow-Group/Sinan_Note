// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sinan_note/ui/features/sync/google_drive_sync/sync_step.dart';
import 'package:sinan_note/ui/features/sync/view_models/sync_view_model.dart';

/// معالج أول مزامنة: تسجيل الدخول، ثم تحديد ما يُفعل بالنسختين.
class GoogleDriveSyncController extends ChangeNotifier {
  GoogleDriveSyncController({required SyncViewModel sync}) : _sync = sync;

  final SyncViewModel _sync;

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
      if (!await _sync.signIn()) {
        _fail('Sign in cancelled or failed');
        return false;
      }
      _step(SyncStep.checking);
      await _checkState();
      return true;
    } on MissingPluginException {
      _fail('Google Sign In is not supported on this platform.');
      return false;
    } on Object catch (e) {
      _fail('$e');
      return false;
    }
  }

  /// لا نسخة في Drive ← رفع. الجهاز فارغ ← تنزيل. كلاهما فيه ملاحظات
  /// بأعداد مختلفة ← يسأل المستخدم. غير ذلك ← دمج. فشل القراءة يوقف كل
  /// شيء ولا يُقرأ كـ Drive فارغ.
  Future<void> _checkState() async {
    try {
      _localNotesCount = _sync.localNoteCount;
      final remote = await _sync.remoteNoteCount();
      _driveNotesCount = remote ?? 0;
      _hasConflict = remote != null &&
          _localNotesCount > 0 &&
          remote > 0 &&
          remote != _localNotesCount;

      if (remote == null) {
        await _perform(_sync.overwriteRemote);
      } else if (_localNotesCount == 0) {
        await _perform(_sync.replaceLocal);
      } else if (_hasConflict) {
        _step(SyncStep.conflict);
      } else {
        await _perform(_sync.sync);
      }
    } on Object catch (e) {
      _fail('$e');
    }
  }

  /// [action]: `useDrive` أو `useDevice` أو `merge`.
  Future<void> resolveConflict(String action) => _perform(switch (action) {
        'useDrive' => _sync.replaceLocal,
        'useDevice' => _sync.overwriteRemote,
        _ => _sync.sync,
      });

  Future<void> _perform(Future<void> Function() operation) async {
    try {
      _step(SyncStep.syncing);
      await operation();
      await _sync.setAutoSync(true);
      _step(SyncStep.success);
    } on Object catch (e) {
      _fail('$e');
    }
  }

  Future<void> abort() async {
    await _sync.signOut();
    _errorMessage = null;
    _step(SyncStep.signIn);
  }

  void retry() {
    _errorMessage = null;
    _step(SyncStep.signIn);
  }

  void consumeSnackBar() {
    snackBarMessage = null;
  }

  void _step(SyncStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void _fail(String message) {
    _errorMessage = message;
    _step(SyncStep.error);
  }
}
