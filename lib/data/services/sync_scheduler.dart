// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/services/sync/cloud_sync_gateway.dart';

/// يرفع التعديلات المحلية في الخلفية: بعد [debounce] من آخر كتابة محلية،
/// إن كان المستخدم مسجلاً والمزامنة التلقائية مفعّلة، ثم يعيد تحميل
/// الملاحظات وينفّذ [afterSync] (تحديث التصنيفات مثلاً).
class SyncScheduler {
  SyncScheduler({
    required NotesRepository notes,
    required Future<void> Function() afterSync,
    this.debounce = const Duration(seconds: 5),
  })  : _notes = notes,
        _afterSync = afterSync {
    _notes.localWrites.addListener(_onLocalWrite);
  }

  final NotesRepository _notes;
  final Future<void> Function() _afterSync;
  final Duration debounce;

  Timer? _timer;
  bool _syncing = false;

  void _onLocalWrite() {
    CloudSyncGateway.markDirty();
    _timer?.cancel();
    _timer = Timer(debounce, _sync);
  }

  Future<void> _sync() async {
    if (_syncing ||
        !CloudSyncGateway.isSignedIn ||
        !CloudSyncGateway.autoSyncEnabled.value) {
      return;
    }
    _syncing = true;
    try {
      await CloudSyncGateway.smartSync();
      await _notes.load();
      await _afterSync();
    } on Object {
      // المزامنة في الخلفية لا تُظهر أخطاء؛ تُعاد مع الكتابة التالية
    } finally {
      _syncing = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    _notes.localWrites.removeListener(_onLocalWrite);
  }
}
