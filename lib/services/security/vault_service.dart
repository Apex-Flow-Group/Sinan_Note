// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  /// Generate recovery code (format: SN-XXXX-XXXX-XXXX)
  static String generateRecoveryCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No confusing chars
    
    String generateSegment() {
      return List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    }
    
    return 'SN-${generateSegment()}-${generateSegment()}-${generateSegment()}';
  }

  /// Setup vault with password and recovery code
  static Future<String> setupVault(String password) async {
    // Generate master key
    final masterKey = Key.fromSecureRandom(32);
    
    // Generate recovery code
    final recoveryCode = generateRecoveryCode();
    
    // Encrypt master key with password
    final encryptedWithPassword = await _encryptMasterKey(masterKey, password);
    
    // Encrypt master key with recovery code
    final encryptedWithRecovery = await _encryptMasterKey(masterKey, recoveryCode);
    
    // Save encrypted versions
    await _storage.write(key: '${_masterKeyName}_password', value: encryptedWithPassword);
    await _storage.write(key: '${_masterKeyName}_recovery', value: encryptedWithRecovery);
    
    // Save hashes for verification
    await _storage.write(key: _passwordHashName, value: _hash(password));
    await _storage.write(key: _recoveryHashName, value: _hash(recoveryCode));
    
    // Set current master key
    await _storage.write(key: _masterKeyName, value: masterKey.base64);
    
    return recoveryCode;
  }

  /// Verify password
  static Future<bool> verifyPassword(String password) async {
    final storedHash = await _storage.read(key: _passwordHashName);
    if (storedHash == null) return false;
    return storedHash == _hash(password);
  }

  /// Verify recovery code
  static Future<bool> verifyRecoveryCode(String recoveryCode) async {
    final storedHash = await _storage.read(key: _recoveryHashName);
    if (storedHash == null) return false;
    return storedHash == _hash(recoveryCode);
  }

  /// Unlock vault with password
  static Future<bool> unlockWithPassword(String password) async {
    if (!await verifyPassword(password)) return false;
    
    final encrypted = await _storage.read(key: '${_masterKeyName}_password');
    if (encrypted == null) return false;
    
    try {
      final masterKey = await _decryptMasterKey(encrypted, password);
      await _storage.write(key: _masterKeyName, value: masterKey.base64);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Recover vault with recovery code
  static Future<bool> recoverWithCode(String recoveryCode) async {
    if (!await verifyRecoveryCode(recoveryCode)) return false;
    
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
  
  /// Lock vault (clear session)
  static Future<void> lockVault() async {
    await _storage.delete(key: 'vault_session_unlocked');
    await _storage.delete(key: _masterKeyName);
  }

  /// Change password (requires old password)
  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    // If oldPassword is empty, it means we're setting password after recovery
    if (oldPassword.isEmpty) {
      // Master key is already unlocked, just re-encrypt with new password
      final masterKeyBase64 = await _storage.read(key: _masterKeyName);
      if (masterKeyBase64 == null) return false;
      
      final masterKey = Key.fromBase64(masterKeyBase64);
      final encryptedWithNewPassword = await _encryptMasterKey(masterKey, newPassword);
      await _storage.write(key: '${_masterKeyName}_password', value: encryptedWithNewPassword);
      await _storage.write(key: _passwordHashName, value: _hash(newPassword));
      return true;
    }
    
    // Normal password change
    if (!await verifyPassword(oldPassword)) return false;
    
    // Get master key
    final masterKeyBase64 = await _storage.read(key: _masterKeyName);
    if (masterKeyBase64 == null) return false;
    
    final masterKey = Key.fromBase64(masterKeyBase64);
    
    // Re-encrypt with new password
    final encryptedWithNewPassword = await _encryptMasterKey(masterKey, newPassword);
    await _storage.write(key: '${_masterKeyName}_password', value: encryptedWithNewPassword);
    await _storage.write(key: _passwordHashName, value: _hash(newPassword));
    
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

  /// Encrypt master key with password/recovery code
  static Future<String> _encryptMasterKey(Key masterKey, String secret) async {
    final key = Key.fromUtf8(secret.padRight(32).substring(0, 32));
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(masterKey.base64, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypt master key with password/recovery code
  static Future<Key> _decryptMasterKey(String encrypted, String secret) async {
    final parts = encrypted.split(':');
    if (parts.length != 2) throw Exception('Invalid encrypted data');
    
    final key = Key.fromUtf8(secret.padRight(32).substring(0, 32));
    final iv = IV.fromBase64(parts[0]);
    final encrypter = Encrypter(AES(key));
    final decrypted = encrypter.decrypt64(parts[1], iv: iv);
    
    return Key.fromBase64(decrypted);
  }

  /// Hash password/recovery code for verification
  static String _hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Clear vault (for testing/reset)
  static Future<void> clearVault() async {
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
  
  /// Get current master key (must be unlocked first)
  static Future<Key> getMasterKey() async {
    final masterKeyBase64 = await _storage.read(key: _masterKeyName);
    if (masterKeyBase64 == null) {
      throw VaultLockedException('Vault is locked or not setup');
    }
    return Key.fromBase64(masterKeyBase64);
  }
  
  /// Encrypt data with master key
  static Future<String> encryptWithMasterKey(String plainText) async {
    if (plainText.isEmpty) return '';
    
    final masterKey = await getMasterKey();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(masterKey));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }
  
  /// Decrypt data with master key
  static Future<String> decryptWithMasterKey(String encryptedText) async {
    if (encryptedText.isEmpty) return '';
    
    final parts = encryptedText.split(':');
    if (parts.length != 2) return encryptedText; // Not encrypted
    
    try {
      final masterKey = await getMasterKey();
      final iv = IV.fromBase64(parts[0]);
      final encrypter = Encrypter(AES(masterKey));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (e) {
      return encryptedText; // Decryption failed, return as-is
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
  
  // ============================================================================
  // VAULT DATA EXPORT/IMPORT FOR BACKUP
  // ============================================================================
  
  /// Get vault data for backup (encrypted master key + recovery hash)
  static Future<Map<String, dynamic>?> getVaultDataForBackup() async {
    try {
      if (!await isVaultSetup()) return null;
      
      final encryptedMasterKey = await _storage.read(key: '${_masterKeyName}_recovery');
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
  static Future<bool> restoreVaultDataFromBackup(Map<String, dynamic> vaultData) async {
    try {
      final encryptedMasterKey = vaultData['encrypted_master_key'] as String?;
      final recoveryHash = vaultData['recovery_hash'] as String?;
      
      if (encryptedMasterKey == null || recoveryHash == null) return false;
      
      // Save vault data locally
      await _storage.write(key: '${_masterKeyName}_recovery', value: encryptedMasterKey);
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
