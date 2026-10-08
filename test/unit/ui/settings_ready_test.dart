// Copyright © 2025 Apex Flow Group. All rights reserved.

// شاشة التحميل تنتظر الإعدادات بـ ready، لا بحلقة تفحص كل 50 مللي ثانية.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/data/services/security/unified_lock_service.dart';
import 'package:sinan_note/ui/features/auth/view_models/security_controller.dart';
import 'package:sinan_note/ui/features/settings/view_models/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SettingsProvider settings() {
    final lock = UnifiedLockService();
    return SettingsProvider(
        lock: lock, security: SecurityController(lock: lock));
  }

  test('ready completes with the stored settings loaded', () async {
    SharedPreferences.setMockInitialValues({'appLockEnabled': true});
    final s = settings();
    expect(s.isInitialized, isFalse);

    await s.ready;
    expect(s.isInitialized, isTrue);
    expect(s.isAppLockEnabled, isTrue);
  });

  test('ready is one load, shared by everyone waiting', () async {
    SharedPreferences.setMockInitialValues({});
    final s = settings();
    expect(identical(s.ready, s.ready), isTrue);
    await Future.wait([s.ready, s.ready]);
    expect(s.isInitialized, isTrue);
    expect(s.isAppLockEnabled, isFalse);
  });
}
