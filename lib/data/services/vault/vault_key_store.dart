// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// مواد مفاتيح الخزنة في التخزين الآمن — الواجهة الوحيدة إليه. بلا منطق.
///
/// أسماء المفاتيح هي نفسها في الإصدارات السابقة حتى تبقى الخزنات الموجودة
/// تعمل.
class VaultKeyStore {
  VaultKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _wrappedByPassword = 'vault_master_key_password';
  static const _wrappedByRecovery = 'vault_master_key_recovery';
  static const _passwordHash = 'vault_password_hash';
  static const _recoveryHash = 'vault_recovery_hash';
  static const _salt = 'vault_pbkdf2_salt';

  /// المفتاح الخام — يُحفظ فقط والبصمة مفعّلة، لأن فتحها لا يمر بكلمة سر.
  static const _biometricKey = 'vault_master_key';
  static const _biometricEnabled = 'vault_biometric_enabled';
  static const _biometricButtonVisible = 'vault_biometric_button_visible';
  static const _failedAttempts = 'vault_failed_attempts';
  static const _lockedUntil = 'vault_locked_until';

  /// بقايا إصدارات سابقة لا تُستخدم.
  static const _obsolete = ['vault_session_unlocked'];

  Future<String?> wrappedByPassword() => _storage.read(key: _wrappedByPassword);
  Future<String?> wrappedByRecovery() => _storage.read(key: _wrappedByRecovery);
  Future<String?> passwordHash() => _storage.read(key: _passwordHash);
  Future<String?> recoveryHash() => _storage.read(key: _recoveryHash);

  Future<void> writePasswordMaterial(String wrapped, String hash) async {
    await _storage.write(key: _wrappedByPassword, value: wrapped);
    await _storage.write(key: _passwordHash, value: hash);
  }

  Future<void> writeRecoveryMaterial(String wrapped, String hash) async {
    await _storage.write(key: _wrappedByRecovery, value: wrapped);
    await _storage.write(key: _recoveryHash, value: hash);
  }

  Future<Uint8List?> salt() async {
    final value = await _storage.read(key: _salt);
    return value == null ? null : base64.decode(value);
  }

  Future<void> writeSalt(Uint8List salt) =>
      _storage.write(key: _salt, value: base64.encode(salt));

  Future<Uint8List?> biometricKey() async {
    final value = await _storage.read(key: _biometricKey);
    return value == null ? null : base64.decode(value);
  }

  Future<void> writeBiometricKey(Uint8List key) =>
      _storage.write(key: _biometricKey, value: base64.encode(key));

  Future<void> deleteBiometricKey() => _storage.delete(key: _biometricKey);

  Future<int> failedAttempts() async =>
      int.tryParse(await _storage.read(key: _failedAttempts) ?? '') ?? 0;

  Future<DateTime?> lockedUntil() async {
    final ms = int.tryParse(await _storage.read(key: _lockedUntil) ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> writeAttempts(int failures, DateTime? lockedUntil) async {
    await _storage.write(key: _failedAttempts, value: '$failures');
    if (lockedUntil == null) {
      await _storage.delete(key: _lockedUntil);
    } else {
      await _storage.write(
          key: _lockedUntil, value: '${lockedUntil.millisecondsSinceEpoch}');
    }
  }

  Future<bool> biometricEnabled() async =>
      await _storage.read(key: _biometricEnabled) == 'true';

  Future<void> writeBiometricEnabled(bool enabled) =>
      _storage.write(key: _biometricEnabled, value: '$enabled');

  Future<bool> biometricButtonVisible() async =>
      await _storage.read(key: _biometricButtonVisible) != 'false';

  Future<void> writeBiometricButtonVisible(bool visible) =>
      _storage.write(key: _biometricButtonVisible, value: '$visible');

  Future<void> deleteObsolete() async {
    for (final key in _obsolete) {
      await _storage.delete(key: key);
    }
  }

  Future<void> clear() async {
    for (final key in [
      _wrappedByPassword,
      _wrappedByRecovery,
      _passwordHash,
      _recoveryHash,
      _biometricKey,
      _biometricEnabled,
      ..._obsolete,
    ]) {
      await _storage.delete(key: key);
    }
  }
}
