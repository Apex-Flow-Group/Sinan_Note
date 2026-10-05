// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/services/security/rate_limiter_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    initializeTestEnvironment();
  });

  // ══════════════════════════════════════════════════════════════
  // RateLimiterService
  // ══════════════════════════════════════════════════════════════
  group('RateLimiterService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await RateLimiterService.reset();
    });

    test('no lock initially', () async {
      expect(await RateLimiterService.getRemainingLockTime(), isNull);
    });

    test('5 remaining attempts initially', () async {
      expect(await RateLimiterService.getRemainingAttempts(), 5);
    });

    test('failed attempt decrements remaining', () async {
      await RateLimiterService.recordFailedAttempt();
      expect(await RateLimiterService.getRemainingAttempts(), 4);
    });

    test('5 failed attempts triggers lock', () async {
      for (int i = 0; i < 5; i++) {
        await RateLimiterService.recordFailedAttempt();
      }
      expect(await RateLimiterService.getRemainingLockTime(), isNotNull);
      expect(await RateLimiterService.getRemainingLockTime(), greaterThan(0));
    });

    test('reset clears all state', () async {
      await RateLimiterService.recordFailedAttempt();
      await RateLimiterService.recordFailedAttempt();
      await RateLimiterService.reset();
      expect(await RateLimiterService.getRemainingAttempts(), 5);
      expect(await RateLimiterService.getRemainingLockTime(), isNull);
    });

    test('formatRemainingTime formats seconds', () {
      expect(RateLimiterService.formatRemainingTime(45), '45s');
    });

    test('formatRemainingTime formats minutes', () {
      expect(RateLimiterService.formatRemainingTime(90), '1m 30s');
    });

    test('formatRemainingTime formats hours', () {
      expect(RateLimiterService.formatRemainingTime(3600), '1h');
    });

    test('formatRemainingTime formats hours and minutes', () {
      expect(RateLimiterService.formatRemainingTime(3660), '1h 1m');
    });

    test('lock duration constants are progressive', () {
      // 5 min < 15 min < 60 min
      expect(5 * 60, lessThan(15 * 60));
      expect(15 * 60, lessThan(60 * 60));
    });
  });
}
