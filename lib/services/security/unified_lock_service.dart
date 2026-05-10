// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:typed_data';

import 'package:apex_note/services/security/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart' as pc;

/// نوع المصادقة المستخدم
enum LockType { biometric, pin, none }

/// خدمة القفل الموحّدة — Singleton
/// تحدد نوع القفل (بيومتري أو PIN) وتشارك حالة المصادقة بين الأنظمة
class UnifiedLockService {
  static final UnifiedLockService _instance = UnifiedLockService._internal();
  factory UnifiedLockService() => _instance;
  UnifiedLockService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _pinHashKey = 'unified_lock_pin_hash';
  static const _pinSaltKey = 'unified_lock_pin_salt';

  /// حالة المصادقة المشتركة بين قفل التطبيق وقفل الخزنة
  bool _isAuthenticatedThisSession = false;
  bool get isAuthenticatedThisSession => _isAuthenticatedThisSession;

  /// إعادة تعيين حالة الجلسة (عند القفل)
  void resetSession() => _isAuthenticatedThisSession = false;

  /// تحديد نوع القفل المناسب للجهاز
  /// PIN هو الطبقة الأساسية — البيومتري ثانوي اختياري
  Future<LockType> getLockType() async {
    if (await hasPinSet()) return LockType.pin;
    if (await BiometricService.hasBiometrics()) return LockType.biometric;
    return LockType.none;
  }

  /// هل تم إعداد PIN مخصص؟
  Future<bool> hasPinSet() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null;
  }

  /// حفظ PIN جديد (مع PBKDF2 hashing)
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _pinSaltKey, value: base64.encode(salt));
    await _storage.write(key: _pinHashKey, value: base64.encode(hash));
  }

  /// التحقق من صحة PIN
  Future<bool> verifyPin(String pin) async {
    final saltB64 = await _storage.read(key: _pinSaltKey);
    final storedHashB64 = await _storage.read(key: _pinHashKey);
    if (saltB64 == null || storedHashB64 == null) return false;

    final salt = base64.decode(saltB64);
    final storedHash = base64.decode(storedHashB64);
    final inputHash = _hashPin(pin, salt);

    if (inputHash.length != storedHash.length) return false;
    int diff = 0;
    for (int i = 0; i < inputHash.length; i++) {
      diff |= inputHash[i] ^ storedHash[i];
    }
    return diff == 0;
  }

  /// حذف PIN (عند تعطيل القفل)
  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
  }

  /// المصادقة الموحّدة — تحدد النوع تلقائياً وتشارك الجلسة
  /// [context]: 'app_lock' | 'vault_entry'
  /// [biometricEnabled]: إذا كان المستخدم فعّل البصمة مع PIN
  Future<bool> authenticate({String context = 'app_lock', bool biometricEnabled = false}) async {
    if (_isAuthenticatedThisSession) return true;

    final lockType = await getLockType();

    switch (lockType) {
      case LockType.biometric:
        final result = await BiometricService.authenticate();
        if (result) _isAuthenticatedThisSession = true;
        return result;

      case LockType.pin:
        // إذا البصمة مفعّلة مع PIN → جرّب البصمة أولاً
        if (biometricEnabled && await BiometricService.hasBiometrics()) {
          final result = await BiometricService.authenticate();
          if (result) {
            _isAuthenticatedThisSession = true;
            return true;
          }
        }
        // PIN يتطلب واجهة مستخدم
        return false;

      case LockType.none:
        _isAuthenticatedThisSession = true;
        return true;
    }
  }

  /// تسجيل نجاح المصادقة (يُستدعى من PinLockScreen بعد التحقق)
  void markAuthenticated() => _isAuthenticatedThisSession = true;

  // ── PBKDF2 helpers ──────────────────────────────────────────────────────────

  Uint8List _generateSalt() {
    final random = pc.SecureRandom('Fortuna');
    final seed = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      seed[i] = DateTime.now().microsecondsSinceEpoch & 0xFF;
    }
    random.seed(pc.KeyParameter(seed));
    return random.nextBytes(16);
  }

  Uint8List _hashPin(String pin, Uint8List salt) {
    final params = pc.Pbkdf2Parameters(salt, 100000, 32);
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
    pbkdf2.init(params);
    return pbkdf2.process(Uint8List.fromList(utf8.encode(pin)));
  }
}
