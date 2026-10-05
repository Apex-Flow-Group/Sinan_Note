// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as legacy;
import 'package:pointycastle/export.dart';
import 'package:sinan_note/domain/errors.dart';

/// تشفير نصوص الخزنة — بلا حالة؛ المفتاح يُمرَّر في كل استدعاء.
///
/// الصيغة الحالية `g1:<nonce>:<ciphertext+tag>`: AES-256-GCM، يكشف أي عبث
/// أو مفتاح خاطئ فيرمي [VaultDecryptionException] بدل إرجاع نص فاسد.
///
/// الصيغة القديمة `<iv>:<ciphertext>` (AES-CTR بلا مصادقة) تُقرأ فقط لترحيلها،
/// ولا يُكتب بها شيء جديد.
abstract final class VaultCipher {
  static const _prefix = 'g1:';
  static const _nonceLength = 12;
  static const _tagBits = 128;
  static final _random = Random.secure();

  /// نص مشفّر بأي صيغة (الحالية أو القديمة).
  static bool isSealed(String text) =>
      text.startsWith(_prefix) || isLegacy(text);

  /// نص بالصيغة القديمة: iv بطول 16 بايت (24 حرف base64) ثم النص المشفّر.
  static bool isLegacy(String text) {
    final parts = text.split(':');
    if (parts.length != 2 || parts[0].length != 24) return false;
    try {
      return base64.decode(parts[0]).length == 16;
    } on FormatException {
      return false;
    }
  }

  static String seal(String plain, Uint8List key) {
    final nonce = Uint8List.fromList(
        List.generate(_nonceLength, (_) => _random.nextInt(256)));
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true,
          AEADParameters(KeyParameter(key), _tagBits, nonce, Uint8List(0)));
    final sealed = cipher.process(Uint8List.fromList(utf8.encode(plain)));
    return '$_prefix${base64.encode(nonce)}:${base64.encode(sealed)}';
  }

  static String open(String sealed, Uint8List key) {
    if (sealed.startsWith(_prefix)) return _openGcm(sealed, key);
    if (isLegacy(sealed)) return _openLegacy(sealed, key);
    throw const VaultDecryptionException('Not a sealed vault value');
  }

  static String _openGcm(String sealed, Uint8List key) {
    final parts = sealed.substring(_prefix.length).split(':');
    if (parts.length != 2) {
      throw const VaultDecryptionException('Malformed sealed value');
    }
    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
            false,
            AEADParameters(KeyParameter(key), _tagBits, base64.decode(parts[0]),
                Uint8List(0)));
      return utf8.decode(cipher.process(base64.decode(parts[1])));
    } on InvalidCipherTextException {
      throw const VaultDecryptionException('Wrong key or tampered value');
    } on FormatException {
      throw const VaultDecryptionException('Malformed sealed value');
    }
  }

  /// AES-CTR بحشو PKCS7 كما كتبتها الإصدارات السابقة. بلا مصادقة، فالمفتاح
  /// الخاطئ يظهر غالباً كحشو أو UTF-8 غير صالح.
  static String _openLegacy(String sealed, Uint8List key) {
    final parts = sealed.split(':');
    try {
      return legacy.Encrypter(legacy.AES(legacy.Key(key)))
          .decrypt64(parts[1], iv: legacy.IV.fromBase64(parts[0]));
    } on Object {
      throw const VaultDecryptionException('Wrong key or corrupt legacy value');
    }
  }
}
