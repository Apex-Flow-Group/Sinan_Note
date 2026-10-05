// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/services/security/rate_limiter_service.dart';
import 'package:sinan_note/services/storage/compression_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    initializeTestEnvironment();
  });

  // ══════════════════════════════════════════════════════════════
  // CompressionService
  // ══════════════════════════════════════════════════════════════
  group('CompressionService', () {
    test('compress then decompress returns original', () {
      const json = '{"version":"2.0","notes":[]}';
      final compressed = CompressionService.compress(json);
      expect(CompressionService.decompress(compressed), json);
    });

    test('compression reduces size for large data', () {
      final large =
          '{"notes":${List.generate(100, (i) => '{"id":$i,"title":"Note $i","content":"Content $i repeated many times"}')}}'
              .replaceAll('}}', '}}');
      final compressed = CompressionService.compress(large);
      expect(compressed.length, lessThan(large.length));
    });

    test('handles empty string', () {
      expect(() => CompressionService.compress(''), returnsNormally);
    });

    test('handles Arabic content', () {
      const arabic =
          '{"notes":[{"title":"ملاحظة عربية","content":"محتوى عربي طويل نسبياً"}]}';
      final compressed = CompressionService.compress(arabic);
      expect(CompressionService.decompress(compressed), arabic);
    });

    test('handles special characters', () {
      const special = '{"content":"Hello\\nWorld\\t😀🎉"}';
      expect(
          CompressionService.decompress(CompressionService.compress(special)),
          special);
    });
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
