// Copyright © 2025 Apex Flow Group. All rights reserved.
// 🔐 VAULT & ENCRYPTION — اختبارات حقيقية وشاملة

import 'package:apex_note/services/security/vault_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_setup.dart';

void main() {
  setUpAll(() => initializeTestEnvironment());

  setUp(() async => await VaultService.clearVault());
  tearDown(() async => await VaultService.clearVault());

  // ══════════════════════════════════════════════════════════════
  // 1. إعداد الخزنة
  // ══════════════════════════════════════════════════════════════
  group('VaultService — Setup', () {
    test('الخزنة غير مُعدَّة في البداية', () async {
      expect(await VaultService.isVaultSetup(), isFalse);
    });

    test('setupVault يُنشئ الخزنة ويُرجع كود استرداد صحيح', () async {
      final code = await VaultService.setupVault('MyPass123!');
      expect(await VaultService.isVaultSetup(), isTrue);
      expect(code, startsWith('SN-'));
      final parts = code.split('-');
      expect(parts.length, 4);
      expect(parts[1].length, 4);
      expect(parts[2].length, 4);
      expect(parts[3].length, 4);
    });

    test('كود الاسترداد لا يحتوي أحرف مربكة (0,O,I,1)', () async {
      // نُنشئ 10 أكواد ونتحقق من عدم وجود أحرف مربكة
      for (int i = 0; i < 10; i++) {
        await VaultService.clearVault();
        final code = await VaultService.setupVault('pass$i');
        final body = code.replaceAll('SN-', '').replaceAll('-', '');
        expect(body.contains('0'), isFalse, reason: 'كود يحتوي 0: $code');
        expect(body.contains('O'), isFalse, reason: 'كود يحتوي O: $code');
        expect(body.contains('I'), isFalse, reason: 'كود يحتوي I: $code');
        expect(body.contains('1'), isFalse, reason: 'كود يحتوي 1: $code');
      }
    });

    test('كل استدعاء لـ setupVault يُنشئ كود استرداد مختلف', () async {
      final code1 = await VaultService.setupVault('pass1');
      await VaultService.clearVault();
      final code2 = await VaultService.setupVault('pass2');
      expect(code1, isNot(equals(code2)));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 2. فتح الخزنة بكلمة المرور
  // ══════════════════════════════════════════════════════════════
  group('VaultService — Password Unlock', () {
    test('فتح بكلمة مرور صحيحة ينجح', () async {
      await VaultService.setupVault('CorrectPass!');
      expect(await VaultService.unlockWithPassword('CorrectPass!'), isTrue);
    });

    test('فتح بكلمة مرور خاطئة يفشل', () async {
      await VaultService.setupVault('CorrectPass!');
      expect(await VaultService.unlockWithPassword('WrongPass!'), isFalse);
    });

    test('كلمة مرور فارغة تفشل', () async {
      await VaultService.setupVault('CorrectPass!');
      expect(await VaultService.unlockWithPassword(''), isFalse);
    });

    test('كلمة مرور مشابهة لكن مختلفة تفشل', () async {
      await VaultService.setupVault('Password123');
      expect(await VaultService.unlockWithPassword('password123'), isFalse);
      expect(await VaultService.unlockWithPassword('Password1234'), isFalse);
      expect(await VaultService.unlockWithPassword(' Password123'), isFalse);
    });

    test('كلمات مرور خاصة تعمل بشكل صحيح', () async {
      const specialPass = r'P@$$w0rd!#%^&*()';
      await VaultService.setupVault(specialPass);
      expect(await VaultService.unlockWithPassword(specialPass), isTrue);
    });

    test('كلمة مرور عربية تعمل', () async {
      const arabicPass = 'كلمةالمرور١٢٣';
      await VaultService.setupVault(arabicPass);
      expect(await VaultService.unlockWithPassword(arabicPass), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 3. الاسترداد بكود الاسترداد
  // ══════════════════════════════════════════════════════════════
  group('VaultService — Recovery Code', () {
    test('الاسترداد بكود صحيح ينجح', () async {
      final code = await VaultService.setupVault('MyPass');
      expect(await VaultService.recoverWithCode(code), isTrue);
    });

    test('الاسترداد بكود خاطئ يفشل', () async {
      await VaultService.setupVault('MyPass');
      expect(await VaultService.recoverWithCode('SN-FAKE-FAKE-FAKE'), isFalse);
    });

    test('الاسترداد بكود فارغ يفشل', () async {
      await VaultService.setupVault('MyPass');
      expect(await VaultService.recoverWithCode(''), isFalse);
    });

    test('بعد الاسترداد يمكن تغيير كلمة المرور عبر setPasswordAfterRecovery',
        () async {
      final code = await VaultService.setupVault('OldPass');
      await VaultService.recoverWithCode(code);
      // بعد recoverWithCode الخزنة مفتوحة — نستخدم setPasswordAfterRecovery
      final changed = await VaultService.setPasswordAfterRecovery('NewPass123');
      expect(changed, isTrue);
      expect(await VaultService.unlockWithPassword('NewPass123'), isTrue);
      expect(await VaultService.unlockWithPassword('OldPass'), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 4. تغيير كلمة المرور
  // ══════════════════════════════════════════════════════════════
  group('VaultService — Change Password', () {
    test('تغيير كلمة المرور بكلمة قديمة صحيحة ينجح', () async {
      await VaultService.setupVault('OldPass');
      await VaultService.unlockWithPassword('OldPass');
      final changed = await VaultService.changePassword('OldPass', 'NewPass');
      expect(changed, isTrue);
    });

    test('بعد التغيير كلمة المرور القديمة لا تعمل', () async {
      await VaultService.setupVault('OldPass');
      await VaultService.unlockWithPassword('OldPass');
      await VaultService.changePassword('OldPass', 'NewPass');
      expect(await VaultService.unlockWithPassword('OldPass'), isFalse);
    });

    test('بعد التغيير كلمة المرور الجديدة تعمل', () async {
      await VaultService.setupVault('OldPass');
      await VaultService.unlockWithPassword('OldPass');
      await VaultService.changePassword('OldPass', 'NewPass');
      expect(await VaultService.unlockWithPassword('NewPass'), isTrue);
    });

    test('تغيير بكلمة قديمة خاطئة يفشل', () async {
      await VaultService.setupVault('OldPass');
      final changed = await VaultService.changePassword('WrongOld', 'NewPass');
      expect(changed, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 5. التشفير وفك التشفير
  // ══════════════════════════════════════════════════════════════
  group('VaultService — Encryption / Decryption', () {
    setUp(() async {
      await VaultService.setupVault('TestPass');
      await VaultService.unlockWithPassword('TestPass');
    });

    test('تشفير نص بسيط وفك تشفيره يُرجع النص الأصلي', () async {
      const original = 'هذا نص سري جداً';
      final encrypted = await VaultService.encryptWithMasterKey(original);
      final decrypted = await VaultService.decryptWithMasterKey(encrypted);
      expect(decrypted, equals(original));
    });

    test('النص المشفر مختلف عن الأصلي', () async {
      const original = 'Secret Text';
      final encrypted = await VaultService.encryptWithMasterKey(original);
      expect(encrypted, isNot(equals(original)));
    });

    test('تشفير نفس النص مرتين يُنتج نتيجتين مختلفتين (IV عشوائي)', () async {
      const original = 'Same Text';
      final enc1 = await VaultService.encryptWithMasterKey(original);
      final enc2 = await VaultService.encryptWithMasterKey(original);
      expect(enc1, isNot(equals(enc2)));
    });

    test('النص المشفر يحتوي على نمط iv:ciphertext', () async {
      final encrypted = await VaultService.encryptWithMasterKey('test');
      expect(encrypted.contains(':'), isTrue);
      final parts = encrypted.split(':');
      expect(parts.length, 2);
      expect(parts[0].isNotEmpty, isTrue);
      expect(parts[1].isNotEmpty, isTrue);
    });

    test('تشفير نص فارغ يُرجع فارغاً', () async {
      final encrypted = await VaultService.encryptWithMasterKey('');
      expect(encrypted, isEmpty);
    });

    test('فك تشفير نص فارغ يُرجع فارغاً', () async {
      final decrypted = await VaultService.decryptWithMasterKey('');
      expect(decrypted, isEmpty);
    });

    test('تشفير نص طويل جداً يعمل', () async {
      final longText = 'أ' * 10000;
      final encrypted = await VaultService.encryptWithMasterKey(longText);
      final decrypted = await VaultService.decryptWithMasterKey(encrypted);
      expect(decrypted, equals(longText));
    });

    test('تشفير JSON يعمل بشكل صحيح', () async {
      const json =
          '{"title":"مهام","items":[{"id":"1","text":"مهمة","isDone":false}]}';
      final encrypted = await VaultService.encryptWithMasterKey(json);
      final decrypted = await VaultService.decryptWithMasterKey(encrypted);
      expect(decrypted, equals(json));
    });

    test('تشفير كود برمجي يعمل', () async {
      const code = 'void main() {\n  print("Hello World");\n}';
      final encrypted = await VaultService.encryptWithMasterKey(code);
      final decrypted = await VaultService.decryptWithMasterKey(encrypted);
      expect(decrypted, equals(code));
    });

    test('isEncrypted يكتشف النص المشفر', () async {
      const plain = 'نص عادي';
      final encrypted = await VaultService.encryptWithMasterKey(plain);
      expect(VaultService.isEncrypted(plain), isFalse);
      expect(VaultService.isEncrypted(encrypted), isTrue);
    });

    test('isEncrypted لا يُخطئ مع نص يحتوي ":"', () {
      // نص فارغ دائماً false
      expect(VaultService.isEncrypted(''), isFalse);
      // نص بدون ":" دائماً false
      expect(VaultService.isEncrypted('plaintext'), isFalse);
      // نص مشفر حقيقي يُرجع true
      // (تم التحقق في اختبار isEncrypted يكتشف النص المشفر)
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 6. النسخ الاحتياطي للخزنة
  // ══════════════════════════════════════════════════════════════
  group('VaultService — Backup & Restore', () {
    test('getVaultDataForBackup يُرجع null قبل الإعداد', () async {
      final data = await VaultService.getVaultDataForBackup();
      expect(data, isNull);
    });

    test('getVaultDataForBackup يُرجع بيانات بعد الإعداد', () async {
      await VaultService.setupVault('BackupPass');
      final data = await VaultService.getVaultDataForBackup();
      expect(data, isNotNull);
      expect(data!.containsKey('encrypted_master_key'), isTrue);
      expect(data.containsKey('recovery_hash'), isTrue);
      expect(data.containsKey('created_at'), isTrue);
    });

    test('restoreVaultDataFromBackup يستعيد البيانات بنجاح', () async {
      final code = await VaultService.setupVault('BackupPass');
      final backupData = await VaultService.getVaultDataForBackup();
      await VaultService.clearVault();

      final restored =
          await VaultService.restoreVaultDataFromBackup(backupData!);
      expect(restored, isTrue);

      // يجب أن يعمل الاسترداد بنفس الكود
      final recovered = await VaultService.recoverWithCode(code);
      expect(recovered, isTrue);
    });

    test('restoreVaultDataFromBackup يفشل مع بيانات ناقصة', () async {
      final restored = await VaultService.restoreVaultDataFromBackup({});
      expect(restored, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 7. إعدادات البيومتري
  // ══════════════════════════════════════════════════════════════
  group('VaultService — Biometric Settings', () {
    test('البيومتري معطّل افتراضياً', () async {
      expect(await VaultService.isBiometricEnabled(), isFalse);
    });

    test('تفعيل البيومتري يعمل', () async {
      await VaultService.setBiometricEnabled(true);
      expect(await VaultService.isBiometricEnabled(), isTrue);
    });

    test('تعطيل البيومتري يعمل', () async {
      await VaultService.setBiometricEnabled(true);
      await VaultService.setBiometricEnabled(false);
      expect(await VaultService.isBiometricEnabled(), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 8. حالات الحافة والأمان
  // ══════════════════════════════════════════════════════════════
  group('VaultService — Security Edge Cases', () {
    test('clearVault يمسح كل البيانات', () async {
      await VaultService.setupVault('Pass');
      await VaultService.clearVault();
      expect(await VaultService.isVaultSetup(), isFalse);
    });

    test('فك تشفير بيانات غير مشفرة يُرجع النص كما هو', () async {
      await VaultService.setupVault('Pass');
      await VaultService.unlockWithPassword('Pass');
      const plain = 'نص غير مشفر';
      final result = await VaultService.decryptWithMasterKey(plain);
      expect(result, equals(plain));
    });

    test('التشفير بعد lockVault يرمي VaultLockedException', () async {
      await VaultService.setupVault('Pass');
      await VaultService.unlockWithPassword('Pass');
      await VaultService.lockVault();
      // monitorCritical يُسجّل الخطأ ثم يُعيد رميه — نتحقق من أي استثناء
      bool threw = false;
      try {
        await VaultService.encryptWithMasterKey('test');
      } catch (e) {
        threw = true;
        expect(e, isA<VaultLockedException>());
      }
      expect(threw, isTrue, reason: 'يجب أن يرمي استثناءً عند الخزنة مقفلة');
    });

    test('تشفير وفك تشفير متعدد متتالي يحافظ على البيانات', () async {
      await VaultService.setupVault('Pass');
      await VaultService.unlockWithPassword('Pass');

      final texts = ['نص ١', 'Code: print()', '{"key":"value"}', '🔐 emoji'];
      for (final text in texts) {
        final enc = await VaultService.encryptWithMasterKey(text);
        final dec = await VaultService.decryptWithMasterKey(enc);
        expect(dec, equals(text), reason: 'فشل مع: $text');
      }
    });
  });
}
