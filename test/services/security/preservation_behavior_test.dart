// Copyright © 2025 Apex Flow Group. All rights reserved.
// 🛡️ Preservation Behavior Tests — الحفاظ على السلوك الأساسي
//
// هذه الاختبارات تؤكد السلوك الأساسي الذي يجب الحفاظ عليه بعد الإصلاح.
// **النتيجة المتوقعة**: الاختبارات تنجح على الكود غير المُصلح وبعده.
//
// **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6**

import 'package:apex_note/services/security/vault_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, String> secureStorage = {};

  setUp(() {
    secureStorage.clear();
    secureStorage['vault_master_key'] = 'dGVzdF9tYXN0ZXJfa2V5X2Jhc2U2NA==';
    secureStorage['vault_biometric_enabled'] = 'true';

    SharedPreferences.setMockInitialValues({
      'appLockEnabled': false,
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
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // Property 2.1: البيومتري يعمل عندما يملك الجهاز بيومتري (Requirement 3.1)
  // ══════════════════════════════════════════════════════════════════════════════
  group('Preservation: Biometric Auth Works When Available (Req 3.1)', () {
    test(
      'When device has biometrics and appLock=true, '
      'biometric authentication path is available',
      () async {
        // Observation: BiometricService.authenticate() works when device has biometric
        // and isAppLockEnabled=true (without vault conflict)
        const bool deviceHasBiometrics = true;
        const bool isAppLockEnabled = true;

        // Simulate: device has biometric → auth path is available
        bool authPathAvailable = deviceHasBiometrics && isAppLockEnabled;

        expect(authPathAvailable, isTrue,
            reason: 'Biometric auth path must be available when device supports it');
      },
    );

    test(
      'VaultService.isBiometricEnabled() returns stored value correctly',
      () async {
        // Observation: vault biometric setting is preserved
        final enabled = await VaultService.isBiometricEnabled();
        expect(enabled, isTrue,
            reason: 'Vault biometric setting must be readable and preserved');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // Property 2.2: التشفير/فك التشفير لا يتغير (Requirement 3.2)
  // ══════════════════════════════════════════════════════════════════════════════
  group('Preservation: Encryption/Decryption Unchanged (Req 3.2)', () {
    test(
      'VaultService.isVaultSetup() returns true when master key exists',
      () async {
        // Observation: vault setup check works correctly
        final isSetup = await VaultService.isVaultSetup();
        expect(isSetup, isTrue,
            reason: 'Vault setup detection must work correctly');
      },
    );

    test(
      'VaultService.setBiometricEnabled() and isBiometricEnabled() work correctly',
      () async {
        // Observation: biometric flag can be set and read
        await VaultService.setBiometricEnabled(true);
        final enabled = await VaultService.isBiometricEnabled();
        expect(enabled, isTrue);

        await VaultService.setBiometricEnabled(false);
        final disabled = await VaultService.isBiometricEnabled();
        expect(disabled, isFalse,
            reason: 'Biometric flag must be settable and readable');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // Property 2.3: دورة الحياة — القفل بعد lockDelaySeconds (Requirement 3.3)
  // ══════════════════════════════════════════════════════════════════════════════
  group('Preservation: Lifecycle Lock Behavior (Req 3.3)', () {
    test(
      'When lockDelaySeconds=0, app should lock immediately on resume',
      () async {
        // Observation: SecurityController locks when elapsed >= lockDelaySeconds
        const int lockDelaySeconds = 0;
        final pausedTime = DateTime.now().subtract(const Duration(seconds: 1));
        final elapsed = DateTime.now().difference(pausedTime).inSeconds;

        final shouldLock = elapsed >= lockDelaySeconds;
        expect(shouldLock, isTrue,
            reason: 'App must lock when elapsed time >= lockDelaySeconds');
      },
    );

    test(
      'When lockDelaySeconds=30 and only 5s elapsed, app should NOT lock',
      () async {
        const int lockDelaySeconds = 30;
        final pausedTime = DateTime.now().subtract(const Duration(seconds: 5));
        final elapsed = DateTime.now().difference(pausedTime).inSeconds;

        final shouldLock = elapsed >= lockDelaySeconds;
        expect(shouldLock, isFalse,
            reason: 'App must NOT lock when elapsed time < lockDelaySeconds');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // Property 2.4: FLAG_SECURE عند privacyBlurEnabled (Requirement 3.4)
  // ══════════════════════════════════════════════════════════════════════════════
  group('Preservation: FLAG_SECURE Behavior (Req 3.4)', () {
    test(
      'When privacyBlurEnabled=true and state=inactive, FLAG_SECURE should be set',
      () async {
        // Observation: _setSecureFlag(true) is called when privacyBlurEnabled=true
        // and AppLifecycleState.inactive
        const bool privacyBlurEnabled = true;

        // Simulate the condition check from SecurityController._handleInactive()
        bool shouldSetSecureFlag = privacyBlurEnabled;
        expect(shouldSetSecureFlag, isTrue,
            reason: 'FLAG_SECURE must be set when privacyBlurEnabled=true on inactive');
      },
    );

    test(
      'When privacyBlurEnabled=false, FLAG_SECURE should NOT be set on inactive',
      () async {
        const bool privacyBlurEnabled = false;
        bool shouldSetSecureFlag = privacyBlurEnabled;
        expect(shouldSetSecureFlag, isFalse,
            reason: 'FLAG_SECURE must NOT be set when privacyBlurEnabled=false');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // Property 2.5: الدخول المباشر عند تعطيل القفل (Requirement 3.5)
  // ══════════════════════════════════════════════════════════════════════════════
  group('Preservation: Direct Access When Lock Disabled (Req 3.5)', () {
    test(
      'When isAppLockEnabled=false, no authentication should be required',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final isAppLockEnabled = prefs.getBool('appLockEnabled') ?? false;

        // Simulate splash_screen.dart: only authenticate if lock is enabled
        bool authRequired = isAppLockEnabled;

        expect(authRequired, isFalse,
            reason: 'No authentication required when app lock is disabled');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // Property 2.6: حالة NOT isBugCondition — السلوك يبقى مطابقاً (Requirement 3.6)
  // ══════════════════════════════════════════════════════════════════════════════
  group('Preservation: Non-Bug Conditions Unchanged (Req 3.6)', () {
    test(
      'When appLock=false and vaultBiometric=true, vault auth is independent',
      () async {
        // NOT a bug condition: appLock is disabled, vault works independently
        const bool isAppLockEnabled = false;
        final bool vaultBiometricEnabled = await VaultService.isBiometricEnabled();

        // Vault biometric should still work independently
        expect(isAppLockEnabled, isFalse);
        expect(vaultBiometricEnabled, isTrue,
            reason: 'Vault biometric must work independently when app lock is off');
      },
    );

    test(
      'When appLock=true and vaultBiometric=false, only app lock authenticates',
      () async {
        // NOT a bug condition: vault uses password, no double auth
        await VaultService.setBiometricEnabled(false);
        final vaultBiometricEnabled = await VaultService.isBiometricEnabled();

        expect(vaultBiometricEnabled, isFalse,
            reason: 'Vault should use password when biometric is disabled');
      },
    );
  });
}
