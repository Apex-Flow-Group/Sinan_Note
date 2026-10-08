import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as legacy;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/data/repositories/vault_repository.dart';
import 'package:sinan_note/data/services/vault/key_derivation.dart';
import 'package:sinan_note/data/services/vault/vault_cipher.dart';
import 'package:sinan_note/data/services/vault/vault_key_store.dart';
import 'package:sinan_note/domain/errors.dart';

import '../../test_setup.dart';

Uint8List _key([int seed = 1]) =>
    Uint8List.fromList(List.generate(32, (i) => (i * 7 + seed) % 256));

Future<void> _wipeSecureStorage() async {
  const storage = FlutterSecureStorage();
  await storage.deleteAll();
}

void main() {
  setUpAll(initializeTestEnvironment);

  group('VaultCipher', () {
    test('round trip, including Arabic and empty text', () {
      for (final text in ['secret', 'كلمة سر 123', '', '😀 mixed نص']) {
        final sealed = VaultCipher.seal(text, _key());
        expect(sealed, startsWith('g1:'));
        expect(VaultCipher.isSealed(sealed), isTrue);
        expect(VaultCipher.open(sealed, _key()), text);
      }
    });

    test('the same text seals differently each time', () {
      expect(
          VaultCipher.seal('x', _key()), isNot(VaultCipher.seal('x', _key())));
    });

    test('a wrong key throws instead of returning garbage', () {
      final sealed = VaultCipher.seal('secret', _key(1));
      expect(() => VaultCipher.open(sealed, _key(2)),
          throwsA(isA<VaultDecryptionException>()));
    });

    test('a tampered value throws', () {
      final sealed = VaultCipher.seal('secret', _key());
      final bytes = base64.decode(sealed.split(':')[2])..[0] ^= 1;
      final tampered = 'g1:${sealed.split(':')[1]}:${base64.encode(bytes)}';
      expect(() => VaultCipher.open(tampered, _key()),
          throwsA(isA<VaultDecryptionException>()));
    });

    test('reads the legacy AES-CTR format written by previous versions', () {
      final iv = legacy.IV.fromSecureRandom(16);
      final ct = legacy.Encrypter(legacy.AES(legacy.Key(_key())))
          .encrypt('old secret', iv: iv);
      final old = '${iv.base64}:${ct.base64}';
      expect(VaultCipher.isLegacy(old), isTrue);
      expect(VaultCipher.open(old, _key()), 'old secret');
    });

    test('plain text is not mistaken for a sealed value', () {
      for (final text in ['https://x.com/a', '{"a":"b"}', 'a:b', 'plain']) {
        expect(VaultCipher.isSealed(text), isFalse, reason: text);
      }
    });
  });

  group('KeyDerivation', () {
    final salt = Uint8List.fromList(List.filled(16, 9));

    test('wrap and unwrap with the right secret', () async {
      final wrapped = await KeyDerivation.wrap(_key(), 'pw', salt);
      expect(await KeyDerivation.unwrap(wrapped, 'pw', salt), _key());
    });

    test('a wrong secret throws', () async {
      final wrapped = await KeyDerivation.wrap(_key(), 'pw', salt);
      expect(KeyDerivation.unwrap(wrapped, 'other', salt),
          throwsA(isA<VaultDecryptionException>()));
    });

    test('hash and verify', () async {
      final hash = await KeyDerivation.hash('pw');
      expect(await KeyDerivation.verify('pw', hash), isTrue);
      expect(await KeyDerivation.verify('nope', hash), isFalse);
    });
  });

  group('VaultRepository', () {
    late VaultRepository vault;

    setUp(() async {
      await _wipeSecureStorage();
      vault = VaultRepository(store: VaultKeyStore());
    });

    tearDown(() => vault.dispose());

    test('set up, seal, lock: locked vault refuses to seal or open', () async {
      expect(await vault.isSetUp(), isFalse);
      final code = await vault.setUp('Pass123!');
      expect(code, matches(RegExp(r'^SN-\w{4}-\w{4}-\w{4}$')));
      expect(vault.isUnlocked, isTrue);

      final sealed = vault.seal('secret');
      expect(vault.open(sealed), 'secret');

      vault.lock();
      expect(() => vault.seal('x'), throwsA(isA<VaultLockedException>()));
      expect(() => vault.open(sealed), throwsA(isA<VaultLockedException>()));
    });

    test('unlocks with the password or the recovery code, not anything else',
        () async {
      final code = await vault.setUp('Pass123!');
      final sealed = vault.seal('secret');
      vault.lock();

      expect(await vault.unlockWithPassword('wrong'), isFalse);
      expect(vault.isUnlocked, isFalse);
      expect(await vault.unlockWithPassword('Pass123!'), isTrue);
      expect(vault.open(sealed), 'secret');

      vault.lock();
      expect(await vault.unlockWithRecoveryCode(code), isTrue);
      expect(vault.open(sealed), 'secret');
    });

    test('start-up housekeeping removes a leftover raw key, once', () async {
      await vault.setUp('Pass123!');
      final store = VaultKeyStore();
      // إصدار سابق: المفتاح الخام محفوظ والبصمة غير مفعّلة
      await store.writeBiometricKey(Uint8List.fromList(List.filled(32, 7)));

      final first = vault.initialize();
      expect(identical(vault.initialize(), first), isTrue,
          reason: 'one run per launch');
      await first;
      expect(await store.biometricKey(), isNull);
    });

    test('enabling biometrics during housekeeping keeps the new key', () async {
      // التنظيف يقرأ "البصمة غير مفعّلة" ثم يتأخر؛ تفعيلها يقع في هذه
      // اللحظة. بلا انتظار، يحذف التنظيف المفتاح الذي كُتب للتو.
      final slow = VaultRepository(store: _SlowFlagStore());
      addTearDown(slow.dispose);
      await slow.setUp('Pass123!');

      final housekeeping = slow.initialize();
      await slow.setBiometricEnabled(true);
      await housekeeping;

      final store = VaultKeyStore();
      expect(await store.biometricEnabled(), isTrue);
      expect(await store.biometricKey(), isNotNull,
          reason: 'the key written while housekeeping ran survives');
    });

    test('the raw key is stored only while biometrics are enabled', () async {
      await vault.setUp('Pass123!');
      final store = VaultKeyStore();
      expect(await store.biometricKey(), isNull);

      await vault.setBiometricEnabled(true);
      expect(await store.biometricKey(), isNotNull);
      vault.lock();
      expect(await vault.unlockWithBiometricKey(), isTrue);

      await vault.setBiometricEnabled(false);
      expect(await store.biometricKey(), isNull);
      vault.lock();
      expect(await vault.unlockWithBiometricKey(), isFalse);
    });

    test('change password keeps the same key', () async {
      await vault.setUp('Pass123!');
      final sealed = vault.seal('secret');
      expect(await vault.changePassword('Pass123!', 'New456!x'), isTrue);
      vault.lock();
      expect(await vault.unlockWithPassword('Pass123!'), isFalse);
      expect(await vault.unlockWithPassword('New456!x'), isTrue);
      expect(vault.open(sealed), 'secret');
    });

    test('rotateKey re-encrypts with a new key and new password', () async {
      await vault.setUp('Pass123!');
      var stored = vault.seal('secret');

      await vault.rotateKey('Fresh789!', (reseal) async {
        stored = reseal(stored);
      });

      expect(vault.open(stored), 'secret');
      vault.lock();
      expect(await vault.unlockWithPassword('Pass123!'), isFalse);
      expect(await vault.unlockWithPassword('Fresh789!'), isTrue);
      expect(vault.open(stored), 'secret');
    });

    test('a failed rotateKey changes nothing', () async {
      await vault.setUp('Pass123!');
      final stored = vault.seal('secret');

      await expectLater(
        vault.rotateKey('Fresh789!', (_) async => throw StateError('db')),
        throwsStateError,
      );

      expect(vault.open(stored), 'secret');
      vault.lock();
      expect(await vault.unlockWithPassword('Pass123!'), isTrue);
      expect(await vault.unlockWithPassword('Fresh789!'), isFalse);
    });

    test('locks itself after the idle timeout', () async {
      final quick = VaultRepository(
          store: VaultKeyStore(),
          autoLockAfter: const Duration(milliseconds: 50));
      await quick.setUp('Pass123!');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(quick.isUnlocked, isFalse);
      quick.dispose();
    });

    test('a held vault does not time out; release restarts the timeout',
        () async {
      final quick = VaultRepository(
          store: VaultKeyStore(),
          autoLockAfter: const Duration(milliseconds: 50));
      await quick.setUp('Pass123!');
      quick.hold();
      quick.open(quick.seal('x'));
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(quick.isUnlocked, isTrue);

      quick.release();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(quick.isUnlocked, isFalse);
      quick.dispose();
    });

    test('wrong secrets lock the vault for a while, escalating', () async {
      var now = DateTime(2026, 6, 1);
      final limited = VaultRepository(store: VaultKeyStore(), clock: () => now);
      await limited.setUp('Pass123!');
      limited.lock();

      for (var i = 0; i < 4; i++) {
        expect(await limited.unlockWithPassword('wrong'), isFalse);
      }
      expect(await limited.unlockWithRecoveryCode('SN-0000-0000-0000'), isFalse,
          reason: 'the recovery code shares the counter');
      await expectLater(
          limited.unlockWithPassword('Pass123!'),
          throwsA(isA<VaultAttemptsExceededException>()
              .having((e) => e.wait, 'wait', const Duration(minutes: 5))));

      now = now.add(const Duration(minutes: 6));
      for (var i = 0; i < 5; i++) {
        expect(await limited.unlockWithPassword('wrong'), isFalse);
        now = now.add(const Duration(minutes: 6));
      }
      now = now.subtract(const Duration(minutes: 6));
      await expectLater(
          limited.unlockWithPassword('Pass123!'),
          throwsA(isA<VaultAttemptsExceededException>()
              .having((e) => e.wait, 'wait', const Duration(minutes: 15))));

      now = now.add(const Duration(minutes: 16));
      expect(await limited.unlockWithPassword('Pass123!'), isTrue);
      limited.lock();
      expect(await limited.unlockWithPassword('wrong'), isFalse,
          reason: 'success reset the counter: no lock after one miss');
      limited.dispose();
    });

    test('initialize removes the raw key left by previous versions', () async {
      await vault.setUp('Pass123!');
      await VaultKeyStore().writeBiometricKey(_key());
      await vault.initialize();
      expect(await VaultKeyStore().biometricKey(), isNull);
    });
  });

  group('compatibility with vaults created by previous versions', () {
    setUp(_wipeSecureStorage);

    /// مواد خزنة بالصيغة التي كتبها VaultService في الإصدارات السابقة، حرفياً:
    /// ملح مشترك، مفتاح مغلّف بكلمة السر `100000:iv:ct` (AES-CTR)، بصمة
    /// PBKDF2 `salt:hash`، والمفتاح الخام مخزّن دائماً.
    Future<Uint8List> writeLegacyVault(String password) async {
      const storage = FlutterSecureStorage();
      final masterKey = legacy.Key.fromSecureRandom(32);
      final salt = Uint8List.fromList(List.generate(16, (i) => i * 3));
      await storage.write(key: 'vault_pbkdf2_salt', value: base64.encode(salt));
      final derived = await KeyDerivation.derive(password, salt);
      final iv = legacy.IV.fromSecureRandom(16);
      final wrapped = legacy.Encrypter(legacy.AES(legacy.Key(derived)))
          .encrypt(masterKey.base64, iv: iv);
      await storage.write(
          key: 'vault_master_key_password',
          value: '100000:${iv.base64}:${wrapped.base64}');
      await storage.write(
          key: 'vault_password_hash',
          value: await KeyDerivation.hash(password));
      await storage.write(key: 'vault_master_key', value: masterKey.base64);
      return masterKey.bytes;
    }

    test('a vault written by previous versions opens; its notes decrypt',
        () async {
      final key = await writeLegacyVault('OldPass1!');
      final iv = legacy.IV.fromSecureRandom(16);
      final ct = legacy.Encrypter(legacy.AES(legacy.Key(key)))
          .encrypt('old note', iv: iv);
      final oldCiphertext = '${iv.base64}:${ct.base64}';

      final vault = VaultRepository(store: VaultKeyStore());
      await vault.initialize();
      expect(await vault.isSetUp(), isTrue);
      expect(await vault.unlockWithPassword('OldPass1!'), isTrue);
      expect(vault.open(oldCiphertext), 'old note');
      vault.dispose();
    });
  });
}

/// يتأخر بعد قراءة علامة البصمة، كما قد يحدث على الجهاز.
class _SlowFlagStore extends VaultKeyStore {
  @override
  Future<bool> biometricEnabled() async {
    final enabled = await super.biometricEnabled();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return enabled;
  }
}
