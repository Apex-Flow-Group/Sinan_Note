// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';

typedef StartupStep = ({String step, Duration took, Duration at});

/// توقيت خطوات بدء التشغيل. [mark] لخطوات المسار المتتالية (مدة كل خطوة منذ
/// السابقة)، و[background] لما يجري في الخلفية (مدته هو، دون أن يُحسب على
/// المسار). يُطبع في debug وprofile لقياس السرعة على الجهاز، لا في release.
/// يُنشأ مرة في main ويُمرَّر لمن يحتاجه.
class StartupTrace {
  StartupTrace({Duration Function()? elapsed})
      : _elapsed = elapsed ?? _stopwatch();

  final Duration Function() _elapsed;
  Duration _last = Duration.zero;
  final _steps = <StartupStep>[];

  static Duration Function() _stopwatch() {
    final watch = Stopwatch()..start();
    return () => watch.elapsed;
  }

  List<StartupStep> get steps => List.unmodifiable(_steps);

  void mark(String step) {
    final at = _elapsed();
    _record(step, at - _last, at);
    _last = at;
  }

  Future<T> background<T>(String step, Future<T> Function() work) async {
    final start = _elapsed();
    try {
      return await work();
    } finally {
      final at = _elapsed();
      _record('$step (background)', at - start, at);
    }
  }

  void _record(String step, Duration took, Duration at) {
    _steps.add((step: step, took: took, at: at));
    if (!kReleaseMode) {
      debugPrint('⏱ startup ${step.padRight(28)} '
          '+${took.inMilliseconds} ms  (${at.inMilliseconds} ms)');
    }
  }
}
