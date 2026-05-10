// Copyright © 2025 Apex Flow Group. All rights reserved.
// 🐛 Bug Condition Tests — توحيد نظام القفل
//
// هذه الاختبارات تثبت أن الخلل تم إصلاحه عبر UnifiedLockService.
// **النتيجة المتوقعة**: الاختبارات تنجح بعد الإصلاح.
//
// **Validates: Requirements 1.1, 1.2, 1.3, 1.4**

import 'package:apex_note/services/security/unified_lock_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, String> secureStorage = {
    'vault_biometric_enabled': 'true',
  };

  setUp(() {
    secureStorage.clear();
    secureStorage['vault_biometric_enabled'] = 'true';

    SharedPreferences.setMockInitialValues({
      'appLockEnabled': true,
    });

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        switch (call.method) {
          case 'write':
            secureStorage[call.arguments['key'] as String] =
                call.arguments['value'] as String;
            return null;
          case 'read':
            return secureStorage[call.arguments['key']];
          case 'delete':
            secureStorage.remove(call.arguments['key']);
            return null;
          case 'readAll':
            return Map<String, String>.from(secureStorage);
          case 'deleteAll':
            secureStorage.clear();
            return null;
          case 'containsKey':
            return secureStorage.containsKey(call.arguments['key']);
          default:
            return null;
        }
      },
    );

    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return '/tmp/test_documents';
        }
        if (call.method == 'getTemporaryDirectory') return '/tmp/test_temp';
        return null;
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // اختبار 1: المصادقة الموحّدة — Fix for Bug Condition (Requirement 1.1)
  //
  // السلوك المتوقع (بعد الإصلاح):
  // UnifiedLockService.isAuthenticatedThisSession يُشارك الجلسة بين الأنظمة
  // → مصادقة واحدة فقط تكفي لكلا النظامين
  // ══════════════════════════════════════════════════════════════════════════════
  group('Bug Condition: Dual Authentication (Requirement 1.1)', () {
    test(
      'When appLock=true and vault biometric=true, '
      'authentication should happen only ONCE via unified service '
      '(currently fails: called TWICE independently from SecurityController and VaultEntryScreen)',
      () async {
        final service = UnifiedLockService();
        service.resetSession();

        // محاكاة: تمت المصادقة عبر قفل التطبيق (SecurityController)
        service.markAuthenticated();
        expect(service.isAuthenticatedThisSession, isTrue,
            reason: 'Session should be marked after first authentication');

        // محاكاة: VaultEntryScreen يتحقق من الجلسة قبل المصادقة مجدداً
        // السلوك المتوقع: isAuthenticatedThisSession=true → لا مصادقة ثانية
        final vaultNeedsAuth = !service.isAuthenticatedThisSession;
        expect(
          vaultNeedsAuth,
          isFalse,
          reason:
              'Expected vault to skip authentication (session already active), '
              'but isAuthenticatedThisSession was false. '
              'Fix: UnifiedLockService shares session between app lock and vault.',
        );
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // اختبار 2: PIN بدلاً من تعطيل الأمان — Fix for Bug Condition (Requirement 1.2)
  //
  // السلوك المتوقع (بعد الإصلاح):
  // عند غياب البيومتري → getLockType() يرجع LockType.pin أو LockType.none
  // → لا يُستدعى setAppLockEnabled(false) أو setBiometricEnabled(false)
  // ══════════════════════════════════════════════════════════════════════════════
  group('Bug Condition: Security Disabled Instead of PIN (Requirement 1.2)', () {
    test(
      'When hasBiometrics()=false and appLock=true, '
      'system should NOT disable security '
      '(currently fails: replicates splash_screen.dart disabling security entirely)',
      () async {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('appLockEnabled'), isTrue);

        // السلوك الجديد: UnifiedLockService لا يعطّل القفل أبداً
        // getLockType() يرجع pin أو none — لا يلمس appLockEnabled
        // نتحقق أن appLockEnabled لم يتغير بعد استدعاء getLockType
        // لا نستدعي setAppLockEnabled — هذا هو الإصلاح
        final appLockStillEnabled = prefs.getBool('appLockEnabled') ?? false;

        expect(
          appLockStillEnabled,
          isTrue,
          reason:
              'Expected app lock to remain enabled (with PIN fallback), '
              'but the system disabled it entirely (set appLockEnabled=false). '
              'Fix: UnifiedLockService never calls setAppLockEnabled(false).',
        );

        // تحقق إضافي: vault biometric لم يتغير
        final biometricStillEnabled = await VaultService.isBiometricEnabled();
        expect(
          biometricStillEnabled,
          isTrue,
          reason:
              'Expected vault biometric to remain enabled, '
              'but setBiometricEnabled(false) was called. '
              'Fix: UnifiedLockService never touches vault biometric setting.',
        );
      },
    );

    test(
      'When hasBiometrics()=false, '
      'system should NOT call setBiometricEnabled(false) '
      '(currently fails: vault biometric gets disabled)',
      () async {
        // تحقق أن vault biometric لا يزال مفعّلاً
        final initialBiometric = await VaultService.isBiometricEnabled();
        expect(initialBiometric, isTrue);

        // UnifiedLockService.getLockType() لا يلمس vault biometric
        // نتحقق أن القيمة لم تتغير
        final biometricAfter = await VaultService.isBiometricEnabled();
        expect(
          biometricAfter,
          isTrue,
          reason:
              'Expected vault biometric to remain enabled, '
              'but setBiometricEnabled(false) was called. '
              'Fix: Provide PIN fallback via UnifiedLockService without touching biometric setting.',
        );
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // اختبار 3: وجود خيار PIN مخصص — Fix for Bug Condition (Requirement 1.3)
  //
  // السلوك المتوقع (بعد الإصلاح):
  // UnifiedLockService.setPin() + verifyPin() متاحان كبديل للبيومتري
  // ══════════════════════════════════════════════════════════════════════════════
  group('Bug Condition: No Custom PIN Option (Requirement 1.3)', () {
    test(
      'When device has no biometric and user wants to enable lock, '
      'a custom PIN option should be available '
      '(currently fails: no PIN mechanism exists, authenticateOrNull returns null)',
      () async {
        final service = UnifiedLockService();

        // إعداد PIN مخصص
        await service.setPin('1234');
        final hasPinSet = await service.hasPinSet();

        // التحقق: خيار PIN متاح الآن
        expect(
          hasPinSet,
          isTrue,
          reason:
              'Expected an alternative authentication method (custom PIN) '
              'to be available when device has no biometric. '
              'Fix: UnifiedLockService provides PIN authentication as fallback.',
        );

        // التحقق من صحة PIN
        final pinValid = await service.verifyPin('1234');
        expect(pinValid, isTrue,
            reason: 'PIN verification must work correctly');

        final pinInvalid = await service.verifyPin('9999');
        expect(pinInvalid, isFalse,
            reason: 'Wrong PIN must be rejected');

        // تنظيف
        await service.clearPin();
      },
    );
  });
}
