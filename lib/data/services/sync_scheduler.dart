// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sinan_note/data/repositories/sync_repository.dart';

/// يزامن في الخلفية: بعد [debounce] من آخر تغيير محلي (ملاحظة أو تصنيف)،
/// إن كان المستخدم مسجلاً والمزامنة التلقائية مفعّلة.
class SyncScheduler {
  SyncScheduler({
    required SyncRepository sync,
    required List<ValueListenable<int>> localWrites,
    this.debounce = const Duration(seconds: 5),
  })  : _sync = sync,
        _sources = localWrites {
    for (final source in _sources) {
      source.addListener(_onLocalWrite);
    }
  }

  final SyncRepository _sync;
  final List<ValueListenable<int>> _sources;
  final Duration debounce;
  Timer? _timer;

  void _onLocalWrite() {
    _timer?.cancel();
    _timer = Timer(debounce, _run);
  }

  Future<void> _run() async {
    if (!_sync.isSignedIn || !_sync.autoSync) return;
    try {
      await _sync.sync();
    } on Object {
      // في الخلفية لا تُعرض الأخطاء؛ التغييرات تبقى معلّمة وتُرفع لاحقاً
    }
  }

  void dispose() {
    _timer?.cancel();
    for (final source in _sources) {
      source.removeListener(_onLocalWrite);
    }
  }
}
