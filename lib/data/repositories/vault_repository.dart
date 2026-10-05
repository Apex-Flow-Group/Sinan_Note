// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sinan_note/data/services/vault/key_derivation.dart';
import 'package:sinan_note/data/services/vault/vault_cipher.dart';
import 'package:sinan_note/data/services/vault/vault_key_store.dart';
import 'package:sinan_note/domain/errors.dart';

/// جلسة الخزنة: المصدر الوحيد للمفتاح الرئيسي.
///
/// المفتاح المفكوك في الذاكرة فقط ما دامت الخزنة مفتوحة، ويُمسح عند [lock]
/// أو بعد [autoLockAfter] بلا استخدام — إلا ما دامت شاشة تحجزها مفتوحة
/// ([hold])، فتلك تقفلها صراحةً عند خروجها. أي تشفير/فك تشفير والخزنة
/// مقفلة يرمي [VaultLockedException] — لا مسار يصل للمحتوى دون مصادقة.
class VaultRepository extends ChangeNotifier {
  VaultRepository({
    VaultKeyStore? store,
    this.autoLockAfter = const Duration(minutes: 5),
  }) : _store = store ?? VaultKeyStore();

  final VaultKeyStore _store;
  final Duration autoLockAfter;

  Uint8List? _key;
  Timer? _autoLock;
  int _holds = 0;

  bool get isUnlocked => _key != null;

  /// يحذف مواد إصدارات سابقة: المفتاح الخام كان يُحفظ دائماً، وأصبح يُحفظ
  /// فقط والبصمة مفعّلة.
  Future<void> initialize() async {
    await _store.deleteObsolete();
    if (!await _store.biometricEnabled()) await _store.deleteBiometricKey();
  }

  Future<bool> isSetUp() async => await _store.wrappedByPassword() != null;

  // ── الإعداد والفتح ────────────────────────────────────────────────────────

  /// ينشئ خزنة جديدة بمفتاح جديد ويفتحها. يُرجع رمز الاسترداد.
  Future<String> setUp(String password) async {
    final key = KeyDerivation.randomBytes(32);
    final recoveryCode = await _writeKeyMaterial(key, password);
    _open(key);
    return recoveryCode;
  }

  Future<bool> unlockWithPassword(String password) async {
    final wrapped = await _store.wrappedByPassword();
    return wrapped != null && await _unlockWith(wrapped, password);
  }

  Future<bool> unlockWithRecoveryCode(String code) async {
    final wrapped = await _store.wrappedByRecovery();
    return wrapped != null && await _unlockWith(wrapped, code);
  }

  /// يُستدعى بعد نجاح مصادقة البصمة في الواجهة.
  Future<bool> unlockWithBiometricKey() async {
    if (!await _store.biometricEnabled()) return false;
    final key = await _store.biometricKey();
    if (key == null) return false;
    _open(key);
    return true;
  }

  Future<bool> _unlockWith(String wrapped, String secret) async {
    try {
      _open(await KeyDerivation.unwrap(wrapped, secret, await _salt()));
      return true;
    } on VaultDecryptionException {
      return false;
    }
  }

  Future<bool> verifyPassword(String password) async {
    final hash = await _store.passwordHash();
    return hash != null && await KeyDerivation.verify(password, hash);
  }

  /// تبقي الخزنة مفتوحة بلا مهلة ما دامت الشاشة التي فتحتها ظاهرة؛ القراءة
  /// والكتابة فيها لا تُقطع بالمؤقت. كل [hold] يقابله [release].
  void hold() {
    _holds++;
    _autoLock?.cancel();
  }

  void release() {
    if (_holds == 0) return;
    _holds--;
    if (_key != null) _restartAutoLock();
  }

  void lock() {
    if (_key == null) return;
    _wipe();
    notifyListeners();
  }

  // ── التشفير ──────────────────────────────────────────────────────────────

  String seal(String plain) => VaultCipher.seal(plain, _requireKey());

  /// يرمي [VaultDecryptionException] إن لم تُفك القيمة بهذا المفتاح.
  String open(String sealed) => VaultCipher.open(sealed, _requireKey());

  Uint8List _requireKey() {
    final key = _key;
    if (key == null) throw const VaultLockedException('Vault is locked');
    _restartAutoLock();
    return key;
  }

  // ── إدارة المفتاح ────────────────────────────────────────────────────────

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (!await verifyPassword(oldPassword)) return false;
    await setPassword(newPassword);
    return true;
  }

  /// كلمة سر جديدة للمفتاح نفسه (بعد الفتح برمز الاسترداد مثلاً).
  Future<void> setPassword(String newPassword) async {
    final key = _requireKey();
    final salt = await _salt();
    await _store.writePasswordMaterial(
      await KeyDerivation.wrap(key, newPassword, salt),
      await KeyDerivation.hash(newPassword),
    );
  }

  Future<bool> isBiometricEnabled() => _store.biometricEnabled();

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      await _store.writeBiometricKey(_requireKey());
    } else {
      await _store.deleteBiometricKey();
    }
    await _store.writeBiometricEnabled(enabled);
  }

  Future<bool> isBiometricButtonVisible() => _store.biometricButtonVisible();

  Future<void> setBiometricButtonVisible(bool visible) =>
      _store.writeBiometricButtonVisible(visible);

  /// مفتاح جديد لكل الخزنة (عند نسيان كلمة السر ورمز الاسترداد مع بقاء
  /// الخزنة مفتوحة بالبصمة). يتطلب الخزنة مفتوحة.
  ///
  /// [reencrypt] يعيد تشفير كل البيانات بالدالة المعطاة داخل transaction
  /// واحدة؛ إن رمى، لا يتغير شيء: المفتاح القديم ومواده باقية. مواد المفتاح
  /// الجديد تُكتب فقط بعد نجاحه. يُرجع رمز الاسترداد الجديد.
  Future<String> rotateKey(
    String newPassword,
    Future<void> Function(String Function(String sealed) reseal) reencrypt,
  ) async {
    final oldKey = Uint8List.fromList(_requireKey());
    final newKey = KeyDerivation.randomBytes(32);

    await reencrypt(
        (sealed) => VaultCipher.seal(VaultCipher.open(sealed, oldKey), newKey));

    final recoveryCode = await _writeKeyMaterial(newKey, newPassword);
    if (await _store.biometricEnabled()) await _store.writeBiometricKey(newKey);
    _open(newKey);
    return recoveryCode;
  }

  /// يحذف الخزنة نهائياً (لا يمس البيانات المشفّرة).
  Future<void> clear() async {
    await _store.clear();
    lock();
  }

  // ── داخلي ────────────────────────────────────────────────────────────────

  Future<String> _writeKeyMaterial(Uint8List key, String password) async {
    final salt = await _salt();
    final recoveryCode = KeyDerivation.recoveryCode();
    await _store.writePasswordMaterial(
      await KeyDerivation.wrap(key, password, salt),
      await KeyDerivation.hash(password),
    );
    await _store.writeRecoveryMaterial(
      await KeyDerivation.wrap(key, recoveryCode, salt),
      await KeyDerivation.hash(recoveryCode),
    );
    return recoveryCode;
  }

  Future<Uint8List> _salt() async {
    final existing = await _store.salt();
    if (existing != null) return existing;
    final salt = KeyDerivation.randomBytes(16);
    await _store.writeSalt(salt);
    return salt;
  }

  void _open(Uint8List key) {
    _wipe();
    _key = key;
    _restartAutoLock();
    notifyListeners();
  }

  void _restartAutoLock() {
    _autoLock?.cancel();
    if (_holds > 0) return;
    _autoLock = Timer(autoLockAfter, lock);
  }

  void _wipe() {
    _autoLock?.cancel();
    _autoLock = null;
    final key = _key;
    if (key != null) key.fillRange(0, key.length, 0);
    _key = null;
  }

  @override
  void dispose() {
    _wipe();
    super.dispose();
  }
}
