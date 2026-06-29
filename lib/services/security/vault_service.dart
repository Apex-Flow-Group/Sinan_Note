// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:sinan_note/services/diagnostics/apex_error_manager.dart';

class VaultService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _masterKeyName = 'vault_master_key';
  static const _passwordHashName = 'vault_password_hash';
  static const _recoveryHashName = 'vault_recovery_hash';
  static const _biometricEnabledName = 'vault_biometric_enabled';

  /// Check if vault is already set up
  static Future<bool> isVaultSetup() async {
    final masterKey = await _storage.read(key: _masterKeyName);
    return masterKey != null;
  }

  /// Validate password strength (English letters, min 8 chars, 1 number, 1 symbol)
  static bool validatePasswordStrength(String password) {
    // لا يسمح بالعربية، يتطلب حرف إنجليزي واحد على الأقل، رقم واحد على الأقل، ورمز واحد، والطول 8+
    // الرموز المقبولة: !@#$%^&*()-_=+[]{};:'",.<>/?\\|`~
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*()\-_=+\[\]{};:'
        "'"
        r'",./<>?\\|`~])[A-Za-z\d!@#$%^&*()\-_=+\[\]{};:'
        "'"
        r'",./<>?\\|`~]{8,}$');
    return regex.hasMatch(password);
  }

  /// Generate recovery code (format: SN-XXXX-XXXX-XXXX)
  static String generateRecoveryCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No confusing chars

    String generateSegment() {
      return List.generate(4, (_) => chars[random.nextInt(chars.length)])
          .join();
    }

    return 'SN-${generateSegment()}-${generateSegment()}-${generateSegment()}';
  }

  /// Setup vault with password and recovery code
  static Future<String> setupVault(String password) async {
    return await ApexErrorManager.monitorCritical(() async {
      final masterKey = Key.fromSecureRandom(32);
      final recoveryCode = generateRecoveryCode();
      final encryptedWithPassword =
          await _encryptMasterKey(masterKey, password);
      final encryptedWithRecovery =
          await _encryptMasterKey(masterKey, recoveryCode);

      await _storage.write(
          key: '${_masterKeyName}_password', value: encryptedWithPassword);
      await _storage.write(
          key: '${_masterKeyName}_recovery', value: encryptedWithRecovery);
      await _storage.write(
          key: _passwordHashName, value: await _hashSecure(password));
      await _storage.write(
          key: _recoveryHashName, value: await _hashSecure(recoveryCode));
      await _storage.write(key: _masterKeyName, value: masterKey.base64);

      return recoveryCode;
    }, 'VaultSetup');
  }

  /// Verify password
  static Future<bool> verifyPassword(String password) async {
    final storedHash = await _storage.read(key: _passwordHashName);
    if (storedHash == null) return false;
    return await _verifySecureHash(password, storedHash);
  }

  /// Verify recovery code
  static Future<bool> verifyRecoveryCode(String recoveryCode) async {
    final storedHash = await _storage.read(key: _recoveryHashName);
    if (storedHash == null) return false;
    return await _verifySecureHash(recoveryCode, storedHash);
  }

  /// Unlock vault with password
  static Future<bool> unlockWithPassword(String password) async {
    return await ApexErrorManager.monitorCritical(() async {
      final encrypted = await _storage.read(key: '${_masterKeyName}_password');
      if (encrypted == null) return false;

      try {
        final masterKey = await _decryptMasterKey(encrypted, password);
        await _storage.write(key: _masterKeyName, value: masterKey.base64);
        return true;
      } catch (e) {
        return false;
      }
    }, 'VaultUnlock');
  }

  /// Recover vault with recovery code
  static Future<bool> recoverWithCode(String recoveryCode) async {
    final encrypted = await _storage.read(key: '${_masterKeyName}_recovery');
    if (encrypted == null) return false;

    try {
      final masterKey = await _decryptMasterKey(encrypted, recoveryCode);
      await _storage.write(key: _masterKeyName, value: masterKey.base64);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark vault as unlocked in current session
  static Future<void> markVaultUnlocked() async {
    await _storage.write(key: 'vault_session_unlocked', value: 'true');
  }

  /// Check if vault is unlocked in current session
  static Future<bool> isVaultUnlocked() async {
    final value = await _storage.read(key: 'vault_session_unlocked');
    return value == 'true';
  }

  /// Lock vault (clear session + wipe memory)
  static Future<void> lockVault() async {
    // Read and wipe master key before deleting
    final masterKeyBase64 = await _storage.read(key: _masterKeyName);
    if (masterKeyBase64 != null) {
      try {
        final key = Key.fromBase64(masterKeyBase64);
        _wipeKey(key);
      } catch (_) {}
    }

    await _storage.delete(key: 'vault_session_unlocked');
    await _storage.delete(key: _masterKeyName);
  }

  /// Change password (requires old password verification).
  /// For post-recovery password reset use [setPasswordAfterRecovery] instead.
  static Future<bool> changePassword(
      String oldPassword, String newPassword) async {
    // Normal password change — always requires old password
    if (!await verifyPassword(oldPassword)) return false;

    final masterKeyBase64 = await _storage.read(key: _masterKeyName);
    if (masterKeyBase64 == null) return false;

    final masterKey = Key.fromBase64(masterKeyBase64);
    final encryptedWithNewPassword =
        await _encryptMasterKey(masterKey, newPassword);
    await _storage.write(
        key: '${_masterKeyName}_password', value: encryptedWithNewPassword);
    await _storage.write(
        key: _passwordHashName, value: await _hashSecure(newPassword));

    return true;
  }

  /// Set a new password after successful recovery code verification.
  /// Only valid when the vault is already unlocked via [recoverWithCode].
  /// Does NOT require the old password — recovery code already proved identity.
  static Future<bool> setPasswordAfterRecovery(String newPassword) async {
    // Vault must be unlocked (master key in storage) — recoverWithCode does this
    final masterKeyBase64 = await _storage.read(key: _masterKeyName);
    if (masterKeyBase64 == null) return false;

    final masterKey = Key.fromBase64(masterKeyBase64);
    final encryptedWithNewPassword =
        await _encryptMasterKey(masterKey, newPassword);
    await _storage.write(
        key: '${_masterKeyName}_password', value: encryptedWithNewPassword);
    await _storage.write(
        key: _passwordHashName, value: await _hashSecure(newPassword));
    return true;
  }

  /// Enable/disable biometric quick access
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledName, value: enabled.toString());
  }

  /// Check if biometric is enabled
  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledName);
    return value == 'true';
  }

  static const _biometricButtonVisibleName = 'vault_biometric_button_visible';

  /// إظهار/إخفاء زر البصمة في شاشة القفل
  static Future<void> setBiometricButtonVisible(bool visible) async {
    await _storage.write(
        key: _biometricButtonVisibleName, value: visible.toString());
  }

  /// هل زر البصمة ظاهر؟ (الافتراضي: true)
  static Future<bool> isBiometricButtonVisible() async {
    final value = await _storage.read(key: _biometricButtonVisibleName);
    if (value == null) return true;
    return value == 'true';
  }

  static const _saltKeyName = 'vault_pbkdf2_salt';
  // OWASP 2023 minimum for PBKDF2-SHA256 is 600,000 — we use 100,000 as a
  // practical balance between security and mobile performance (~300ms on mid-range).
  // Legacy value was accidentally lowered to 10,000; this restores the original.
  static const _kIterations = 100000;
  // Kept for decrypting data encrypted with the old 10,000-iteration scheme.
  // _decryptMasterKey reads the stored iteration count, so migration is automatic.
  static const _kLegacyIterations = 10000;

  /// Derive a 32-byte key from secret using PBKDF2-SHA256 (in isolate)
  static Future<Key> _deriveKey(String secret,
      {Uint8List? salt, int iterations = _kIterations}) async {
    final storedSalt = salt ?? await _getOrCreateSalt();
    final keyBytes = await Isolate.run(() => _pbkdf2Sync(
          utf8.encode(secret),
          storedSalt,
          iterations,
          32,
        ));
    return Key(keyBytes);
  }

  /// PBKDF2-SHA256 — runs in isolate (no async allowed inside)
  static Uint8List _pbkdf2Sync(
      List<int> password, Uint8List salt, int iterations, int keyLength) {
    final params = pc.Pbkdf2Parameters(salt, iterations, keyLength);
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
    pbkdf2.init(params);
    return pbkdf2.process(Uint8List.fromList(password));
  }

  static Future<Uint8List> _getOrCreateSalt() async {
    final stored = await _storage.read(key: _saltKeyName);
    if (stored != null) return base64.decode(stored);
    final salt = IV.fromSecureRandom(16).bytes;
    await _storage.write(key: _saltKeyName, value: base64.encode(salt));
    return salt;
  }

  /// Encrypt master key with password/recovery code
  static Future<String> _encryptMasterKey(Key masterKey, String secret) async {
    final derivedKey = await _deriveKey(secret, iterations: _kIterations);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(derivedKey));
    final encrypted = encrypter.encrypt(masterKey.base64, iv: iv);
    // تخزين عدد الإيتراشنز مع البيانات: iterations:iv:ciphertext
    return '$_kIterations:${iv.base64}:${encrypted.base64}';
  }

  /// Decrypt master key with password/recovery code
  static Future<Key> _decryptMasterKey(String encrypted, String secret) async {
    final parts = encrypted.split(':');

    // الصيغة الجديدة: iterations:iv:ciphertext
    if (parts.length == 3) {
      final iterations = int.tryParse(parts[0]) ?? _kIterations;
      final iv = IV.fromBase64(parts[1]);
      final derivedKey = await _deriveKey(secret, iterations: iterations);
      final encrypter = Encrypter(AES(derivedKey));
      final decrypted = encrypter.decrypt64(parts[2], iv: iv);
      return Key.fromBase64(decrypted);
    }

    // الصيغة القديمة جداً: iv:ciphertext (قبل إضافة iterations في الصيغة)
    // كانت تستخدم 100,000 iterations في الإصدار الأول، ثم خُفِّضت خطأً لـ 10,000
    // نستخدم _kLegacyIterations للتوافق مع تلك البيانات
    if (parts.length == 2) {
      final iv = IV.fromBase64(parts[0]);
      final derivedKey =
          await _deriveKey(secret, iterations: _kLegacyIterations);
      final encrypter = Encrypter(AES(derivedKey));
      final decrypted = encrypter.decrypt64(parts[1], iv: iv);
      return Key.fromBase64(decrypted);
    }

    throw Exception('Invalid encrypted data');
  }

  /// Hash with PBKDF2 for verification (stored as salt:hash)
  static Future<String> _hashSecure(String input) async {
    final salt = IV.fromSecureRandom(16).bytes;
    final hash = await Isolate.run(() => _pbkdf2Sync(
          utf8.encode(input),
          salt,
          _kIterations,
          32,
        ));
    return '${base64.encode(salt)}:${base64.encode(hash)}';
  }

  static Future<bool> _verifySecureHash(String input, String stored) async {
    if (!stored.contains(':')) {
      return stored == sha256.convert(utf8.encode(input)).toString();
    }
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = base64.decode(parts[0]);
    final expectedHash = base64.decode(parts[1]);
    final hash = await Isolate.run(() => _pbkdf2Sync(
          utf8.encode(input),
          salt,
          _kIterations,
          32,
        ));
    if (hash.length != expectedHash.length) return false;
    int diff = 0;
    for (int i = 0; i < hash.length; i++) {
      diff |= hash[i] ^ expectedHash[i];
    }
    return diff == 0;
  }

  /// Clear vault (for testing/reset) - secure wipe
  static Future<void> clearVault() async {
    // Wipe master key before deletion
    final masterKeyBase64 = await _storage.read(key: _masterKeyName);
    if (masterKeyBase64 != null) {
      try {
        final key = Key.fromBase64(masterKeyBase64);
        _wipeKey(key);
      } catch (_) {}
    }

    await _storage.delete(key: _masterKeyName);
    await _storage.delete(key: '${_masterKeyName}_password');
    await _storage.delete(key: '${_masterKeyName}_recovery');
    await _storage.delete(key: _passwordHashName);
    await _storage.delete(key: _recoveryHashName);
    await _storage.delete(key: _biometricEnabledName);
    await _storage.delete(key: 'vault_session_unlocked');
  }

  // ============================================================================
  // ENCRYPTION/DECRYPTION WITH MASTER KEY
  // ============================================================================

  /// Get current master key (must be unlocked first).
  ///
  /// **Security note (SEC-3):** The master key is stored in FlutterSecureStorage
  /// (backed by Android Keystore / iOS Secure Enclave) for the duration of the
  /// unlocked session. This is an intentional performance trade-off:
  /// - Pro: avoids re-deriving the key (PBKDF2) on every encrypt/decrypt call
  /// - Con: key persists in secure storage until [lockVault] is called
  /// - Mitigation: [encryptWithMasterKey] and [decryptWithMasterKey] wipe the
  ///   key from Dart memory immediately after use via [_wipeKey]
  static Future<Key> getMasterKey() async {
    final masterKeyBase64 = await _storage.read(key: _masterKeyName);
    if (masterKeyBase64 == null) {
      throw VaultLockedException('Vault is locked or not setup');
    }
    return Key.fromBase64(masterKeyBase64);
  }

  /// Encrypt data with master key (auto-cleanup)
  static Future<String> encryptWithMasterKey(String plainText) async {
    return await ApexErrorManager.monitorCritical(() async {
      if (plainText.isEmpty) return '';

      Key? masterKey;
      try {
        masterKey = await getMasterKey();
        final iv = IV.fromSecureRandom(16);
        final encrypter = Encrypter(AES(masterKey));
        final encrypted = encrypter.encrypt(plainText, iv: iv);
        return '${iv.base64}:${encrypted.base64}';
      } finally {
        if (masterKey != null) _wipeKey(masterKey);
      }
    }, 'VaultEncrypt', expectedError: true);
  }

  /// Decrypt data with master key (auto-cleanup)
  static Future<String> decryptWithMasterKey(String encryptedText) async {
    return await ApexErrorManager.monitorCritical(() async {
      if (encryptedText.isEmpty) return '';

      final parts = encryptedText.split(':');
      if (parts.length != 2) return encryptedText;

      Key? masterKey;
      try {
        masterKey = await getMasterKey();
        final iv = IV.fromBase64(parts[0]);
        final encrypter = Encrypter(AES(masterKey));
        return encrypter.decrypt64(parts[1], iv: iv);
      } catch (e) {
        return encryptedText;
      } finally {
        if (masterKey != null) _wipeKey(masterKey);
      }
    }, 'VaultDecrypt', expectedError: true);
  }

  /// فك تشفير بمفتاح جاهز (sync) — للاستخدام عند فك تشفير ملاحظات متعددة
  static String decryptWithKey(String encryptedText, Key masterKey) {
    if (encryptedText.isEmpty) return '';
    final parts = encryptedText.split(':');
    if (parts.length != 2) return encryptedText;
    try {
      final iv = IV.fromBase64(parts[0]);
      final encrypter = Encrypter(AES(masterKey));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (_) {
      return encryptedText;
    }
  }

  /// مسح المفتاح من الذاكرة بعد الانتهاء
  static void wipeMasterKey(Key key) => _wipeKey(key);

  /// Wipe key bytes from memory (security best practice)
  static void _wipeKey(Key key) {
    try {
      // Overwrite key bytes with zeros
      final bytes = key.bytes;
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = 0;
      }
    } catch (_) {
      // Ignore wipe errors
    }
  }

  /// Check if text is encrypted (matches iv:ciphertext pattern).
  /// IV must be exactly 16 bytes = 24 base64 characters.
  static bool isEncrypted(String text) {
    if (text.isEmpty) return false;
    final parts = text.split(':');
    if (parts.length != 2) return false;
    // IV is always 16 bytes → 24 base64 chars (with padding)
    if (parts[0].length != 24) return false;
    try {
      IV.fromBase64(parts[0]);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // VAULT DATA EXPORT/IMPORT FOR BACKUP
  // ============================================================================

  /// Get vault data for backup (encrypted master key + recovery hash)
  static Future<Map<String, dynamic>?> getVaultDataForBackup() async {
    try {
      if (!await isVaultSetup()) return null;

      final encryptedMasterKey =
          await _storage.read(key: '${_masterKeyName}_recovery');
      final recoveryHash = await _storage.read(key: _recoveryHashName);

      if (encryptedMasterKey == null || recoveryHash == null) return null;

      return {
        'encrypted_master_key': encryptedMasterKey,
        'recovery_hash': recoveryHash,
        'created_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }

  /// Restore vault data from backup
  static Future<bool> restoreVaultDataFromBackup(
      Map<String, dynamic> vaultData) async {
    try {
      final encryptedMasterKey = vaultData['encrypted_master_key'] as String?;
      final recoveryHash = vaultData['recovery_hash'] as String?;

      if (encryptedMasterKey == null || recoveryHash == null) return false;

      // Save vault data locally
      await _storage.write(
          key: '${_masterKeyName}_recovery', value: encryptedMasterKey);
      await _storage.write(key: _recoveryHashName, value: recoveryHash);

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Exception thrown when vault is locked
class VaultLockedException implements Exception {
  final String message;
  VaultLockedException(this.message);

  @override
  String toString() => 'VaultLockedException: $message';
}
