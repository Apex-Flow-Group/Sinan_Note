// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as legacy;
import 'package:pointycastle/export.dart';
import 'package:sinan_note/data/services/vault/vault_cipher.dart';
import 'package:sinan_note/domain/errors.dart';

/// اشتقاق المفاتيح من كلمة السر ورمز الاسترداد (PBKDF2-SHA256 في isolate)،
/// وتغليف المفتاح الرئيسي بها. بلا حالة.
abstract final class KeyDerivation {
  /// 100k: توازن بين الأمان وزمن الأجهزة المتوسطة (~300ms).
  static const iterations = 100000;

  /// بيانات قديمة جداً بصيغة `iv:ciphertext` غُلّفت بـ 10k.
  static const _legacyIterations = 10000;

  static const _wrapPrefix = 'w2:';
  static final _random = Random.secure();

  static Uint8List randomBytes(int length) =>
      Uint8List.fromList(List.generate(length, (_) => _random.nextInt(256)));

  static Future<Uint8List> derive(String secret, Uint8List salt,
      {int iterations = iterations}) {
    final password = Uint8List.fromList(utf8.encode(secret));
    return Isolate.run(() => _pbkdf2(password, salt, iterations));
  }

  static Uint8List _pbkdf2(Uint8List password, Uint8List salt, int rounds) {
    final kdf = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, rounds, 32));
    return kdf.process(password);
  }

  /// يغلّف [masterKey] بمفتاح مشتق من [secret]: `w2:<iterations>:<g1 sealed>`.
  static Future<String> wrap(
      Uint8List masterKey, String secret, Uint8List salt) async {
    final derived = await derive(secret, salt);
    return '$_wrapPrefix$iterations:'
        '${VaultCipher.seal(base64.encode(masterKey), derived)}';
  }

  /// يفك التغليف بأي صيغة سابقة. يرمي [VaultDecryptionException] إن كان
  /// [secret] خاطئاً.
  static Future<Uint8List> unwrap(
      String wrapped, String secret, Uint8List salt) async {
    if (wrapped.startsWith(_wrapPrefix)) {
      final rest = wrapped.substring(_wrapPrefix.length);
      final colon = rest.indexOf(':');
      final rounds = int.parse(rest.substring(0, colon));
      final derived = await derive(secret, salt, iterations: rounds);
      return _keyFrom(VaultCipher.open(rest.substring(colon + 1), derived));
    }

    // الصيغ القديمة (AES-CTR): `iterations:iv:ct` ثم `iv:ct` بـ 10k
    final parts = wrapped.split(':');
    final (rounds, iv, ct) = switch (parts.length) {
      3 => (int.tryParse(parts[0]) ?? iterations, parts[1], parts[2]),
      2 => (_legacyIterations, parts[0], parts[1]),
      _ => throw const VaultDecryptionException('Malformed wrapped key'),
    };
    final derived = await derive(secret, salt, iterations: rounds);
    try {
      final key = legacy.Encrypter(legacy.AES(legacy.Key(derived)))
          .decrypt64(ct, iv: legacy.IV.fromBase64(iv));
      return _keyFrom(key);
    } on Object {
      throw const VaultDecryptionException('Wrong secret');
    }
  }

  static Uint8List _keyFrom(String base64Key) {
    final key = base64.decode(base64Key);
    if (key.length != 32) {
      throw const VaultDecryptionException('Wrong secret');
    }
    return key;
  }

  /// بصمة للتحقق من كلمة السر/الرمز: `salt:hash`.
  static Future<String> hash(String input) async {
    final salt = randomBytes(16);
    final digest = await derive(input, salt);
    return '${base64.encode(salt)}:${base64.encode(digest)}';
  }

  static Future<bool> verify(String input, String stored) async {
    if (!stored.contains(':')) {
      // بصمات SHA-256 المجردة من الإصدارات الأولى
      return stored == sha256.convert(utf8.encode(input)).toString();
    }
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final expected = base64.decode(parts[1]);
    final actual = await derive(input, base64.decode(parts[0]));
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  /// رمز استرداد بصيغة SN-XXXX-XXXX-XXXX (بلا أحرف ملتبسة).
  static String recoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String segment() =>
        List.generate(4, (_) => chars[_random.nextInt(chars.length)]).join();
    return 'SN-${segment()}-${segment()}-${segment()}';
  }
}
