// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:sinan_note/services/security/biometric_service.dart';

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

  /// حماية جلسة الخزنة أثناء عمليات المصادقة الداخلية
  /// يمنع LockedNotesScreen من طرد المستخدم عند ظهور dialog البيومتري
  bool _isVaultOperation = false;
  bool get isVaultOperation => _isVaultOperation;

  /// تغليف عملية تتطلب مصادقة داخل الخزنة
  Future<T> runVaultOperation<T>(Future<T> Function() operation) async {
    _isVaultOperation = true;
    try {
      return await operation();
    } finally {
      _isVaultOperation = false;
    }
  }

  /// إعادة تعيين حالة الجلسة (عند القفل)
  void resetSession() {
    _isAuthenticatedThisSession = false;
    _isVaultOperation = false;
  }

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
    final hash = await _hashPin(pin, salt);
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
    final inputHash = await _hashPin(pin, salt);

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
  /// [reuseSession]: false لدخول الخزنة وتغيير إعدادات الأمان — مصادقة فعلية
  /// كل مرة، لا جلسة سابقة (كانت تفتح الخزنة بعد إلغاء طلب البصمة).
  Future<bool> authenticate({
    String context = 'app_lock',
    bool biometricEnabled = false,
    bool reuseSession = true,
  }) async {
    if (reuseSession && _isAuthenticatedThisSession) return true;

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
        // بلا PIN ولا بصمة: قفل التطبيق غير مفعّل، أما الخزنة فلها كلمة سرها
        if (!reuseSession) return false;
        _isAuthenticatedThisSession = true;
        return true;
    }
  }

  /// تسجيل نجاح المصادقة (يُستدعى من PinLockScreen بعد التحقق)
  void markAuthenticated() => _isAuthenticatedThisSession = true;

  // ── PBKDF2 helpers ──────────────────────────────────────────────────────────

  /// 16 بايتاً من مولّد النظام الآمن. (كان كل بايت من بذرة Fortuna هو
  /// البايت الأدنى من الوقت نفسه: نحو 256 ملحاً ممكناً فقط.)
  static Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
  }

  /// PBKDF2 بنفس المعاملات (فتبقى أرقام PIN المحفوظة صالحة)، في isolate
  /// حتى لا تتجمد الواجهة.
  static Future<Uint8List> _hashPin(String pin, Uint8List salt) =>
      compute(_pbkdf2, (pin, salt));
}

Uint8List _pbkdf2((String, Uint8List) input) {
  final (pin, salt) = input;
  final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
    ..init(pc.Pbkdf2Parameters(salt, 100000, 32));
  return pbkdf2.process(Uint8List.fromList(utf8.encode(pin)));
}

