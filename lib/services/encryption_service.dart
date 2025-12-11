// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/exceptions.dart';

/// AES-256 Encryption Service for Locked Notes
/// CRITICAL: Only UI layer should call decrypt() after biometric auth
class EncryptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyName = 'sinan_vault_key';
  static Key? _cachedKey;

  /// Get or generate encryption key (32 bytes for AES-256)
  static Future<Key> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;

    try {
      String? keyString = await _storage.read(key: _keyName);
      if (keyString == null) {
        final key = Key.fromSecureRandom(32);
        await _storage.write(key: _keyName, value: key.base64);
        _cachedKey = key;
        return key;
      }
      _cachedKey = Key.fromBase64(keyString);
      return _cachedKey!;
    } catch (e) {
      throw EncryptionException('Failed to access encryption key', e);
    }
  }

  /// Encrypt plain text
  /// Returns: "iv:ciphertext" format
  static Future<String> encrypt(String plainText) async {
    if (plainText.isEmpty) {
      throw EncryptionException('Cannot encrypt empty text');
    }

    try {
      final key = await _getOrCreateKey();
      final iv = IV.fromSecureRandom(16);
      final encrypter = Encrypter(AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Encryption failed', e);
    }
  }

  /// Decrypt cipher text
  /// SAFETY: Returns original text if not encrypted (legacy notes)
  /// AUTHORITY: Only UI layer should call this after biometric auth
  static Future<String> decrypt(String encryptedText) async {
    if (encryptedText.isEmpty) return '';

    // Check if encrypted format
    if (!isEncrypted(encryptedText)) {
      return encryptedText; // Legacy note, return as-is
    }

    final parts = encryptedText.split(':');
    if (parts.length != 2) return encryptedText;

    try {
      final key = await _getOrCreateKey();
      final iv = IV.fromBase64(parts[0]);
      final encrypter = Encrypter(AES(key));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (e) {
      // Fallback: Return original if decryption fails
      return encryptedText;
    }
  }

  /// Check if text is encrypted (matches iv:ciphertext pattern)
  static bool isEncrypted(String text) {
    if (text.isEmpty) return false;
    final parts = text.split(':');
    if (parts.length != 2) return false;

    try {
      IV.fromBase64(parts[0]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear cached key (call on logout/security reset)
  static void clearCache() {
    _cachedKey = null;
  }
}
