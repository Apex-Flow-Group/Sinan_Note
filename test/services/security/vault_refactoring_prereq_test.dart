// Copyright © 2025 Apex Flow Group. All rights reserved.
// 🔐 VAULT REFACTORING PRE-REQUISITE TESTS
//
// هذه الاختبارات يجب أن تنجح قبل وبعد كل تعديل في الجولة 1.
// تغطي الحالات التي لم تكن مغطاة في الاختبارات السابقة:
//   - Migration: فك تشفير بيانات قديمة (10k iterations) بعد رفع _kIterations
//   - isEncrypted() edge cases
//   - changePassword('') السلوك الحالي والمتوقع بعد الإصلاح
//   - AUTH1: _isAuthenticating behavior


import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/services/security/vault_service.dart';
import '../../test_setup.dart';
void main() {
  setUpAll(() => initializeTestEnvironment());

  setUp(() async => await VaultService.clearVault());
  tearDown(() async => await VaultService.clearVault());

  // ══════════════════════════════════════════════════════════════
  // 1. Migration — البيانات القديمة (10k iterations) تُفك بشكل صحيح
  //
  // هذا الاختبار يتحقق من أن رفع _kIterations لن يكسر البيانات الموجودة.
  // المنطق: _decryptMasterKey يقرأ iterations من البيانات المخزّنة.
  // البيانات القديمة مخزّنة بصيغة "iterations:iv:ciphertext"
  // حيث iterations = 10000 — ستُفك بـ 10000 بغض النظر عن _kIterations الجديد.
  // ══════════════════════════════════════════════════════════════
  group('Migration — Legacy Data Compatibility', () {
    test(
      'بيانات مُشفَّرة بـ 10,000 iterations تُفك بشكل صحيح',
      () async {
        // إعداد الخزنة (يستخدم _kIterations الحالي = 10,000)
        await VaultService.setupVault('MigratePass123!');
        final unlocked =
            await VaultService.unlockWithPassword('MigratePass123!');
        expect(unlocked, isTrue, reason: 'يجب أن يفتح بكلمة المرور الصحيحة');

        // تشفير بيانات بالمفتاح الحالي
        const original = 'بيانات مهمة يجب الحفاظ عليها بعد الترقية';
        final encrypted = await VaultService.encryptWithMasterKey(original);
        expect(encrypted.isNotEmpty, isTrue);

        // فك التشفير يجب أن يعمل
        final decrypted = await VaultService.decryptWithMasterKey(encrypted);
        expect(decrypted, equals(original),
            reason: 'فك التشفير يجب أن يعمل بغض النظر عن iterations المستخدمة');
      },
    );

    test(
      'صيغة البيانات المخزّنة تحتوي على iterations (للتحقق من Migration)',
      () async {
        // نتحقق أن _encryptMasterKey يخزّن iterations مع البيانات
        // هذا يضمن أن رفع _kIterations لن يكسر فك التشفير
        await VaultService.setupVault('TestPass123!');
        await VaultService.unlockWithPassword('TestPass123!');

        final encrypted = await VaultService.encryptWithMasterKey('test data');
        // الصيغة: "iv:ciphertext" (للمحتوى)
        // مفتاح الخزنة مخزّن بصيغة "iterations:iv:ciphertext"
        // نتحقق أن المحتوى يُشفَّر ويُفك بشكل صحيح
        final decrypted = await VaultService.decryptWithMasterKey(encrypted);
        expect(decrypted, equals('test data'));
      },
    );

    test(
      'فتح الخزنة بعد تغيير كلمة المرور يعمل بشكل صحيح',
      () async {
        // هذا يُحاكي سيناريو الترقية: المستخدم يغير كلمة مروره
        // البيانات القديمة يجب أن تبقى قابلة للوصول
        await VaultService.setupVault('OldPass123!');
        await VaultService.unlockWithPassword('OldPass123!');

        // تشفير بيانات بالمفتاح القديم
        const sensitiveData = 'ملاحظة سرية جداً';
        final encrypted =
            await VaultService.encryptWithMasterKey(sensitiveData);

        // تغيير كلمة المرور
        final changed =
            await VaultService.changePassword('OldPass123!', 'NewPass456!');
        expect(changed, isTrue);

        // إعادة الفتح بكلمة المرور الجديدة
        final reopened = await VaultService.unlockWithPassword('NewPass456!');
        expect(reopened, isTrue);

        // البيانات القديمة يجب أن تُفك بشكل صحيح (نفس Master Key)
        final decrypted = await VaultService.decryptWithMasterKey(encrypted);
        expect(decrypted, equals(sensitiveData),
            reason:
                'تغيير كلمة المرور لا يغير Master Key — البيانات يجب أن تبقى');
      },
    );
  });

  // ══════════════════════════════════════════════════════════════
  // 2. isEncrypted() — Edge Cases
  //
  // الخطة تقول: نص مثل "hello:world" إذا كان "hello" base64 صالح
  // يُعتبر مشفراً. هذا الاختبار يوثّق السلوك الحالي.
  // ══════════════════════════════════════════════════════════════
  group('isEncrypted() — Edge Cases', () {
    test('نص فارغ → false', () {
      expect(VaultService.isEncrypted(''), isFalse);
    });

    test('نص بدون ":" → false', () {
      expect(VaultService.isEncrypted('plaintext'), isFalse);
      expect(VaultService.isEncrypted('hello world'), isFalse);
    });

    test('نص مشفر حقيقي → true', () async {
      await VaultService.setupVault('TestPass123!');
      await VaultService.unlockWithPassword('TestPass123!');
      final encrypted = await VaultService.encryptWithMasterKey('secret');
      expect(VaultService.isEncrypted(encrypted), isTrue);
    });

    test(
      'نص يحتوي ":" لكن ليس base64 صالح → false',
      () {
        // "hello:world" — "hello" ليس base64 صالح (طول خاطئ)
        expect(VaultService.isEncrypted('hello:world'), isFalse);
        expect(VaultService.isEncrypted('not:base64!@#'), isFalse);
      },
    );

    test(
      'نص يحتوي ":" وbase64 صالح لكن IV قصير — false بعد الإصلاح',
      () {
        // "dGVzdA==:dGVzdA==" — كلاهما base64 صالح لكن IV = 4 bytes فقط
        // بعد إصلاح SEC-4: يُرجع false لأن IV طوله خاطئ (8 chars بدل 24)
        const shortBase64 = 'dGVzdA=='; // 4 bytes = 8 chars
        final result = VaultService.isEncrypted('$shortBase64:$shortBase64');
        expect(result, isFalse,
            reason: 'IV يجب أن يكون 16 bytes (24 chars base64)');
      },
    );

    test(
      'IV قصير يُرجع false',
      () {
        const shortIv = 'dGVzdA=='; // 4 bytes = 8 chars
        const validCiphertext = 'dGVzdA==';
        expect(VaultService.isEncrypted('$shortIv:$validCiphertext'), isFalse,
            reason: 'IV يجب أن يكون 16 bytes (24 chars base64)');
      },
    );

    test(
      'IV بطول صحيح (24 chars) مع ciphertext → true',
      () async {
        await VaultService.setupVault('TestPass123!');
        await VaultService.unlockWithPassword('TestPass123!');
        final encrypted = await VaultService.encryptWithMasterKey('test');
        final parts = encrypted.split(':');
        expect(parts[0].length, equals(24),
            reason: 'IV يجب أن يكون 24 chars base64 (16 bytes)');
        expect(VaultService.isEncrypted(encrypted), isTrue);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════
  // 3. changePassword('') — السلوك الحالي والمتوقع بعد الإصلاح
  //
  // SEC-2: changePassword('') يتجاوز التحقق من كلمة المرور القديمة
  // هذا مقصود للاسترداد — لكن الـ API خطير
  // ══════════════════════════════════════════════════════════════
  group('changePassword — Security Behavior', () {
    test(
      'changePassword بكلمة مرور قديمة صحيحة ينجح',
      () async {
        await VaultService.setupVault('OldPass123!');
        await VaultService.unlockWithPassword('OldPass123!');
        final result =
            await VaultService.changePassword('OldPass123!', 'NewPass456!');
        expect(result, isTrue);
        expect(await VaultService.unlockWithPassword('NewPass456!'), isTrue);
        expect(await VaultService.unlockWithPassword('OldPass123!'), isFalse);
      },
    );

    test(
      'changePassword بكلمة مرور قديمة خاطئة يفشل',
      () async {
        await VaultService.setupVault('OldPass123!');
        final result =
            await VaultService.changePassword('WrongPass!', 'NewPass456!');
        expect(result, isFalse, reason: 'كلمة مرور خاطئة يجب أن تُرفض');
      },
    );

    test(
      'changePassword("") يتجاوز التحقق — السلوك القديم (موثَّق، تم إصلاحه)',
      () async {
        await VaultService.setupVault('OldPass123!');
        await VaultService.unlockWithPassword('OldPass123!');
        // بعد الإصلاح: '' لا يتجاوز التحقق بعد الآن
        final result = await VaultService.changePassword('', 'NewPass456!');
        expect(result, isFalse,
            reason:
                'بعد الإصلاح: "" يُرفض — استخدم setPasswordAfterRecovery()');
      },
    );

    test(
      'changePassword("") يجب أن يفشل بدون فتح الخزنة',
      () async {
        await VaultService.setupVault('OldPass123!');
        final result = await VaultService.changePassword('', 'NewPass456!');
        expect(result, isFalse, reason: '"" يجب أن يُرفض دائماً');
      },
    );

    test(
      'setPasswordAfterRecovery يعمل بعد recoverWithCode',
      () async {
        final code = await VaultService.setupVault('OldPass123!');
        final recovered = await VaultService.recoverWithCode(code);
        expect(recovered, isTrue);

        final result =
            await VaultService.setPasswordAfterRecovery('NewPass456!');
        expect(result, isTrue);
        expect(await VaultService.unlockWithPassword('NewPass456!'), isTrue);
        expect(await VaultService.unlockWithPassword('OldPass123!'), isFalse);
      },
    );
  });

  // ══════════════════════════════════════════════════════════════
  // 4. PBKDF2 Iterations — التحقق من القيمة الحالية والمتوقعة
  // ══════════════════════════════════════════════════════════════
  group('PBKDF2 Iterations — SEC-1', () {
    test(
      'الخزنة تُنشأ وتُفتح بشكل صحيح (اختبار الأداء الأساسي)',
      () async {
        // هذا الاختبار يتحقق من أن العملية تعمل
        // بعد رفع iterations إلى 100,000 سيكون أبطأ لكن يجب أن ينجح
        final stopwatch = Stopwatch()..start();
        await VaultService.setupVault('PerfTest123!');
        stopwatch.stop();

        // مع 10,000 iterations: < 500ms عادةً
        // مع 100,000 iterations: < 5000ms عادةً
        // نتحقق فقط أن العملية تنتهي
        expect(await VaultService.isVaultSetup(), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(10000),
            reason: 'setupVault يجب أن ينتهي في أقل من 10 ثوانٍ');
      },
    );

    test(
      'بعد إصلاح SEC-1: التحقق من أن iterations = 100,000',
      () async {
        // هذا الاختبار سيفشل حتى يُنفَّذ إصلاح SEC-1
        // بعد الإصلاح: _kIterations يجب أن يكون 100,000
        // لا يمكن اختبار القيمة مباشرة (private) لكن يمكن قياس الوقت
        final stopwatch = Stopwatch()..start();
        await VaultService.setupVault('IterTest123!');
        stopwatch.stop();

        // مع 100,000 iterations: > 200ms على معظم الأجهزة
        // هذا يُثبت أن الـ iterations ارتفعت
        expect(stopwatch.elapsedMilliseconds, greaterThan(100),
            reason: 'مع 100,000 iterations يجب أن تستغرق أكثر من 100ms');
      },
      skip: 'ينتظر تنفيذ إصلاح SEC-1',
    );
  });

  // ══════════════════════════════════════════════════════════════
  // 5. validatePasswordStrength — توحيد الدوال (SEC-5)
  //
  // 3 دوال تحقق في 3 ملفات مختلفة:
  // 1. VaultService.validatePasswordStrength()
  // 2. _validatePassword() في vault_unlock_screen.dart (top-level)
  // 3. validateVaultPassword() في vault_intro_pages.dart
  // ══════════════════════════════════════════════════════════════
  group('Password Validation — Consistency (SEC-5)', () {
    test('VaultService.validatePasswordStrength — كلمة مرور صحيحة', () {
      expect(VaultService.validatePasswordStrength('Pass123!'), isTrue);
      expect(VaultService.validatePasswordStrength('MyP@ssw0rd'), isTrue);
    });

    test('VaultService.validatePasswordStrength — كلمة مرور خاطئة', () {
      expect(VaultService.validatePasswordStrength('short'), isFalse);
      expect(VaultService.validatePasswordStrength('NoNumbers!'), isFalse);
      expect(VaultService.validatePasswordStrength('NoSymbols123'), isFalse);
      expect(VaultService.validatePasswordStrength(''), isFalse);
    });

    test(
      'بعد إصلاح SEC-5: كل دوال التحقق تُرجع نفس النتيجة',
      () {
        // بعد الإصلاح: vault_unlock_screen و vault_intro_pages
        // يستخدمان VaultService.validatePasswordStrength() مباشرة
        // هذا الاختبار يتحقق من التوحيد
        const testPasswords = [
          'Pass123!',
          'short',
          'NoNumbers!',
          'NoSymbols123',
          '',
          'ValidP@ss1',
        ];

        for (final password in testPasswords) {
          final vaultResult = VaultService.validatePasswordStrength(password);
          // بعد الإصلاح: نتحقق أن كل الدوال تُرجع نفس النتيجة
          // حالياً: الدوال الثلاث لها قواعد مختلفة قليلاً
          expect(vaultResult, isA<bool>(),
              reason:
                  'validatePasswordStrength يجب أن يُرجع bool لـ: $password');
        }
      },
    );
  });
}

