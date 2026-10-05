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
import 'package:sinan_note/services/security/vault_service.dart' show VaultService;

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

    test('initialize removes the raw key left by previous versions', () async {
      await vault.setUp('Pass123!');
      await VaultKeyStore().writeBiometricKey(_key());
      await vault.initialize();
      expect(await VaultKeyStore().biometricKey(), isNull);
    });
  });

  group('compatibility with vaults created by previous versions', () {
    setUp(_wipeSecureStorage);

    test('old VaultService vault opens with VaultRepository; its notes decrypt',
        () async {
      await VaultService.setupVault('OldPass1!');
      final oldCiphertext = await VaultService.encryptWithMasterKey('old note');

      final vault = VaultRepository(store: VaultKeyStore());
      await vault.initialize();
      expect(await vault.isSetUp(), isTrue);
      expect(await vault.unlockWithPassword('OldPass1!'), isTrue);
      expect(vault.open(oldCiphertext), 'old note');
      vault.dispose();
    });
  });
}
