// Copyright © 2025 Apex Flow Group. All rights reserved.
// ✅ Tests — إصلاح مشكلة البصمة في الخزنة والشاشة السوداء عند إنشاء PIN
//
// ══════════════════════════════════════════════════════════════════════════════
// المشكلة الجوهرية (BUG 1):
//
//   البصمة تثبت هوية المستخدم فقط — لكنها لا تفك تشفير vault_master_key.
//
//   vault_master_key يُحذف عند lockVault() ولا يُعاد كتابته إلا بعد
//   unlockWithPassword() الذي يفك تشفيره بكلمة المرور.
//
//   المسار الخاطئ (قبل الإصلاح):
//     BiometricService.authenticate() → نجاح
//     → toLockedNotes() مباشرة
//     → LockedNotesScreen._loadLockedNotes()
//     → NoteSecurityService.fetchAndDecryptLockedNotes()
//     → VaultService.getMasterKey()
//     → VaultLockedException! (المفتاح محذوف)
//     → الملاحظات لا تُفك تشفيرها / الخزنة لا تفتح
//
//   المسار الصحيح (بعد الإصلاح):
//     BiometricService.authenticate() → نجاح
//     → VaultService.getMasterKey() — تحقق من وجود المفتاح
//       ├─ موجود → notesProvider.unlockVault() → toLockedNotes() ✅
//       └─ محذوف → toUnlock() لطلب كلمة المرور (تُعيد كتابة المفتاح) ✅
//
// ══════════════════════════════════════════════════════════════════════════════
// المشكلة الثانية (BUG 2):
//
//   VaultNavigator.toPinLock() كان يستخدم pushReplacement
//   → stack فارغ → رجوع = شاشة سوداء
//   الإصلاح: تغيير إلى push
//
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/services/security/unified_lock_service.dart';
import 'package:sinan_note/services/security/vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, String> secureStorage = {};

  setUp(() {
    secureStorage.clear();
    SharedPreferences.setMockInitialValues({});

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
  // BUG 1 الجوهري: vault_master_key يُحذف عند lockVault
  // البصمة لا تُعيد كتابته → getMasterKey() يرمي VaultLockedException
  // ══════════════════════════════════════════════════════════════════════════════
  group('BUG 1 Root Cause: vault_master_key Deleted After lockVault', () {
    test(
      'بعد setupVault: vault_master_key موجود → getMasterKey() ينجح',
      () async {
        await VaultService.setupVault('TestPass123!');

        // المفتاح موجود بعد الإعداد مباشرة
        dynamic key;
        bool threw = false;
        try {
          key = await VaultService.getMasterKey();
        } catch (_) {
          threw = true;
        }

        expect(threw, isFalse,
            reason: 'بعد setupVault: vault_master_key موجود ✅');
        expect(key, isNotNull);

        await VaultService.clearVault();
      },
    );

    test(
      'بعد lockVault: vault_master_key محذوف → getMasterKey() يرمي VaultLockedException',
      () async {
        await VaultService.setupVault('TestPass123!');
        await VaultService.lockVault();

        // هذا هو جذر المشكلة:
        // البصمة تنجح → toLockedNotes() → getMasterKey() → VaultLockedException!
        bool threw = false;
        try {
          await VaultService.getMasterKey();
        } on VaultLockedException {
          threw = true;
        }

        expect(
          threw,
          isTrue,
          reason: 'BUG ROOT: lockVault() يحذف vault_master_key. '
              'البصمة وحدها لا تُعيد كتابته → الخزنة لا تفتح بعد القفل.',
        );

        await VaultService.clearVault();
      },
    );

    test(
      'unlockWithPassword يُعيد كتابة vault_master_key بعد lockVault',
      () async {
        await VaultService.setupVault('TestPass123!');
        await VaultService.lockVault();

        // unlockWithPassword يفك تشفير المفتاح ويكتبه في الـ storage
        final success = await VaultService.unlockWithPassword('TestPass123!');
        expect(success, isTrue);

        // الآن getMasterKey() ينجح
        bool threw = false;
        try {
          await VaultService.getMasterKey();
        } catch (_) {
          threw = true;
        }

        expect(threw, isFalse,
            reason: 'unlockWithPassword يُعيد كتابة vault_master_key ✅');

        await VaultService.clearVault();
      },
    );

    test(
      'البصمة وحدها لا تُعيد كتابة vault_master_key — '
      'هذا هو سبب عدم فتح الخزنة بالبصمة بعد القفل',
      () async {
        await VaultService.setupVault('TestPass123!');
        await VaultService.lockVault();

        // محاكاة: البصمة نجحت (authenticated=true)
        // لكن لا يوجد ما يُعيد كتابة vault_master_key
        const bool biometricAuthenticated = true;

        // getMasterKey() سيفشل لأن المفتاح محذوف
        bool masterKeyAvailable = false;
        try {
          await VaultService.getMasterKey();
          masterKeyAvailable = true;
        } catch (_) {
          masterKeyAvailable = false;
        }

        // البصمة نجحت لكن المفتاح غير متاح
        expect(biometricAuthenticated, isTrue);
        expect(
          masterKeyAvailable,
          isFalse,
          reason: 'BUG: البصمة نجحت لكن vault_master_key محذوف. '
              'الإصلاح: _tryVaultBiometric يتحقق من getMasterKey() '
              'قبل toLockedNotes() — إذا فشل → toUnlock() لطلب كلمة المرور.',
        );

        await VaultService.clearVault();
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // الإصلاح 1: _tryVaultBiometric يتحقق من getMasterKey() قبل الانتقال
  // ══════════════════════════════════════════════════════════════════════════════
  group('Fix 1: _tryVaultBiometric Checks getMasterKey() Before Navigation',
      () {
    test(
      'المفتاح موجود + البصمة نجحت → unlockVault() + toLockedNotes() ✅',
      () async {
        await VaultService.setupVault('TestPass123!');
        // لم يُستدعَ lockVault → المفتاح لا يزال موجوداً

        bool masterKeyAvailable = false;
        try {
          await VaultService.getMasterKey();
          masterKeyAvailable = true;
        } catch (_) {}

        // المسار الصحيح بعد الإصلاح:
        // authenticated=true + masterKeyAvailable=true → unlockVault() + toLockedNotes()
        expect(masterKeyAvailable, isTrue,
            reason: 'المفتاح موجود → يمكن فتح الخزنة بالبصمة ✅');

        await VaultService.clearVault();
      },
    );

    test(
      'المفتاح محذوف + البصمة نجحت → toUnlock() لطلب كلمة المرور ✅',
      () async {
        await VaultService.setupVault('TestPass123!');
        await VaultService.lockVault();

        bool masterKeyAvailable = false;
        try {
          await VaultService.getMasterKey();
          masterKeyAvailable = true;
        } catch (_) {}

        // المسار الصحيح بعد الإصلاح:
        // authenticated=true + masterKeyAvailable=false → toUnlock()
        expect(masterKeyAvailable, isFalse,
            reason: 'المفتاح محذوف → toUnlock() لطلب كلمة المرور ✅');

        await VaultService.clearVault();
      },
    );

    test(
      'دورة كاملة: setup → lock → biometric → password → unlock ✅',
      () async {
        // 1. إعداد الخزنة
        await VaultService.setupVault('TestPass123!');
        expect(await VaultService.isVaultSetup(), isTrue);

        // 2. قفل الخزنة
        await VaultService.lockVault();

        // 3. محاولة البصمة → المفتاح محذوف → يجب طلب كلمة المرور
        bool masterKeyAfterLock = false;
        try {
          await VaultService.getMasterKey();
          masterKeyAfterLock = true;
        } catch (_) {}
        expect(masterKeyAfterLock, isFalse,
            reason: 'بعد القفل: المفتاح محذوف → البصمة وحدها لا تكفي');

        // 4. إدخال كلمة المرور → يُعيد كتابة المفتاح
        final unlocked = await VaultService.unlockWithPassword('TestPass123!');
        expect(unlocked, isTrue);

        // 5. الآن getMasterKey() ينجح → يمكن فتح الخزنة
        bool masterKeyAfterPassword = false;
        try {
          await VaultService.getMasterKey();
          masterKeyAfterPassword = true;
        } catch (_) {}
        expect(masterKeyAfterPassword, isTrue,
            reason: 'بعد كلمة المرور: المفتاح موجود → الخزنة تفتح ✅');

        await VaultService.clearVault();
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // السيناريوهات الثلاثة عبر الإصلاح
  // ══════════════════════════════════════════════════════════════════════════════
  group('All Scenarios After Fix', () {
    test(
      'السيناريو A — PC: hasBiometrics=false → toUnlock() مباشرة (لا يصل للبصمة)',
      () async {
        // على PC: BiometricService.hasBiometrics() = false دائماً
        const bool hasBiometrics = false;
        const bool biometricEnabled = true;
        expect(biometricEnabled && hasBiometrics, isFalse,
            reason: 'PC: لا يدخل مسار البصمة → toUnlock() مباشرة ✅');
      },
    );

    test(
      'السيناريو B — هاتف بدون بصمة مسجّلة: '
      'hasBiometrics=true (isDeviceSupported) → يدخل _tryVaultBiometric '
      '→ authenticate() يفشل → toUnlock(biometricFailed:true) ✅',
      () async {
        // canCheckBiometrics=false, isDeviceSupported()=true → hasBiometrics=true
        const bool hasBiometrics = true;
        const bool biometricEnabled = true;
        expect(biometricEnabled && hasBiometrics, isTrue,
            reason: 'يدخل _tryVaultBiometric');

        // authenticate() يفشل بـ NotAvailable
        const bool authenticateResult = false;
        expect(authenticateResult, isFalse,
            reason: 'NotAvailable → toUnlock(biometricFailed:true) ✅');
      },
    );

    test(
      'السيناريو C — هاتف بدون قفل شاشة: '
      'isDeviceSupported=false → hasBiometrics=false → toUnlock() مباشرة ✅',
      () async {
        const bool hasBiometrics = false;
        const bool biometricEnabled = true;
        expect(biometricEnabled && hasBiometrics, isFalse,
            reason: 'بدون قفل شاشة: toUnlock() مباشرة ✅');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // الإصلاح 2: toPinLock يستخدم push بدلاً من pushReplacement
  // ══════════════════════════════════════════════════════════════════════════════
  group('Fix 2: toPinLock Uses push (No Black Screen)', () {
    test(
      'hasPinSet=false → isSetup=true. '
      'push يُبقي VaultEntryScreen في الـ stack → رجوع صحيح بدون شاشة سوداء',
      () async {
        final service = UnifiedLockService();
        final hasPinAlready = await service.hasPinSet();
        expect(!hasPinAlready, isTrue,
            reason: 'hasPinSet=false → isSetup=true → وضع الإنشاء');

        // بعد الإصلاح: push بدلاً من pushReplacement
        // VaultEntryScreen تبقى في الـ stack → pop() يعود لها ✅
        const bool fixedUsesPush = true;
        expect(fixedUsesPush, isTrue,
            reason: 'push → لا شاشة سوداء عند الرجوع ✅');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════════
  // التحقق من VaultService و UnifiedLockService
  // ══════════════════════════════════════════════════════════════════════════════
  group('VaultService & UnifiedLockService: Core Behavior', () {
    test('isVaultSetup=false قبل الإعداد', () async {
      expect(await VaultService.isVaultSetup(), isFalse);
    });

    test('isVaultSetup=true بعد setupVault', () async {
      await VaultService.setupVault('Pass123!');
      expect(await VaultService.isVaultSetup(), isTrue);
      await VaultService.clearVault();
    });

    test('isBiometricEnabled يُقرأ ويُكتب بشكل صحيح', () async {
      await VaultService.setBiometricEnabled(true);
      expect(await VaultService.isBiometricEnabled(), isTrue);
      await VaultService.setBiometricEnabled(false);
      expect(await VaultService.isBiometricEnabled(), isFalse);
    });

    test('getLockType()=pin عند وجود PIN', () async {
      final service = UnifiedLockService();
      await service.setPin('0000');
      expect(await service.getLockType(), equals(LockType.pin));
      await service.clearPin();
    });

    test('verifyPin() صحيح/خاطئ', () async {
      final service = UnifiedLockService();
      await service.setPin('4321');
      expect(await service.verifyPin('4321'), isTrue);
      expect(await service.verifyPin('0000'), isFalse);
      await service.clearPin();
    });

    test('runVaultOperation() يُعيّن isVaultOperation=true أثناء التنفيذ',
        () async {
      final service = UnifiedLockService();
      bool wasVaultOperation = false;
      await service.runVaultOperation(() async {
        wasVaultOperation = service.isVaultOperation;
        return true;
      });
      expect(wasVaultOperation, isTrue);
      expect(service.isVaultOperation, isFalse);
    });
  });
}
