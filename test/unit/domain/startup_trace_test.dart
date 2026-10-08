// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/startup_trace.dart';

void main() {
  late Duration now;
  late StartupTrace trace;

  setUp(() {
    now = Duration.zero;
    trace = StartupTrace(elapsed: () => now);
  });

  test('each mark measures the time since the previous one', () {
    now = const Duration(milliseconds: 40);
    trace.mark('database');
    now = const Duration(milliseconds: 55);
    trace.mark('first frame');

    expect(
        trace.steps
            .map((s) => (s.step, s.took.inMilliseconds, s.at.inMilliseconds)),
        [('database', 40, 40), ('first frame', 15, 55)]);
  });

  test('background work is measured on its own, off the sequence', () async {
    now = const Duration(milliseconds: 10);
    trace.mark('runApp');
    final drive = trace.background('drive session', () async {
      now = const Duration(milliseconds: 900);
      return 'signed in';
    });
    expect(await drive, 'signed in');
    // الخطوة التالية تُحسب من آخر علامة متتالية، لا من نهاية الخلفية
    trace.mark('navigate');

    expect(trace.steps.map((s) => (s.step, s.took.inMilliseconds)), [
      ('runApp', 10),
      ('drive session (background)', 890),
      ('navigate', 890),
    ]);
  });

  test('a failing background step is still measured, and still fails',
      () async {
    final failing = trace.background<void>('services', () async {
      now = const Duration(milliseconds: 30);
      throw StateError('offline');
    });
    await expectLater(failing, throwsStateError);
    expect(trace.steps.single.step, 'services (background)');
    expect(trace.steps.single.took, const Duration(milliseconds: 30));
  });
}
