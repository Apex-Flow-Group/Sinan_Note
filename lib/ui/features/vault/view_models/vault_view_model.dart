// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:sinan_note/data/repositories/notes_repository.dart';
import 'package:sinan_note/data/repositories/vault_repository.dart';
import 'package:sinan_note/domain/errors.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/vault_policy.dart';
import 'package:sinan_note/services/security/biometric_service.dart';
import 'package:sinan_note/services/security/unified_lock_service.dart';

/// مراحل تدوير مفتاح الخزنة كما تراها الواجهة.
enum VaultResetStep { idle, reEncrypting, completed, failed }

/// منطق الخزنة كله للواجهات: الإعداد، الفتح بأي وسيلة، كلمة السر، البصمة،
/// تدوير المفتاح، وحذف الخزنة. الواجهات لا تلمس المفاتيح ولا التشفير.
class VaultViewModel extends ChangeNotifier {
  VaultViewModel({
    required VaultRepository vault,
    required NotesRepository notes,
  })  : _vault = vault,
        _notes = notes {
    _vault.addListener(notifyListeners);
  }

  final VaultRepository _vault;
  final NotesRepository _notes;

  bool get isUnlocked => _vault.isUnlocked;

  /// عملية طويلة جارية (تدوير المفتاح أو الحذف): لا تُغلق الخزنة أثناءها.
  bool get isBusy => _busy;
  bool _busy = false;

  final resetStep = ValueNotifier(VaultResetStep.idle);

  Future<bool> isSetUp() => _vault.isSetUp();

  bool isStrongPassword(String password) =>
      VaultPolicy.isStrongPassword(password);

  // ── الإعداد ──────────────────────────────────────────────────────────────

  /// ينشئ الخزنة ويفتحها. يُرجع رمز الاسترداد.
  Future<String> setUp(String password, {required bool biometric}) async {
    final code = await _vault.setUp(password);
    await _vault.setBiometricEnabled(biometric);
    return code;
  }

  // ── الفتح ────────────────────────────────────────────────────────────────

  /// البصمة متاحة على الجهاز ومفعّلة للخزنة.
  Future<bool> canUseBiometrics() async =>
      await _vault.isBiometricEnabled() &&
      await BiometricService.hasBiometrics();

  Future<bool> unlockWithBiometrics() async {
    final authenticated = await UnifiedLockService()
        .runVaultOperation(BiometricService.authenticate);
    return authenticated && await unlockAfterDeviceAuth();
  }

  /// الفتح السريع بعد مصادقة الجهاز (بصمة أو PIN التطبيق): يعمل فقط إن كان
  /// الفتح السريع مفعّلاً، وإلا فكلمة سر الخزنة.
  Future<bool> unlockAfterDeviceAuth() async {
    if (!await _vault.unlockWithBiometricKey()) return false;
    await _afterUnlock();
    return true;
  }

  Future<bool> unlockWithPassword(String password) async {
    if (!await _vault.unlockWithPassword(password)) return false;
    await _afterUnlock();
    return true;
  }

  Future<bool> unlockWithRecoveryCode(String code) async {
    if (!await _vault.unlockWithRecoveryCode(code)) return false;
    await _afterUnlock();
    return true;
  }

  /// قيم التشفير القديمة تُرحَّل للصيغة الحالية فور توفر المفتاح.
  Future<void> _afterUnlock() => _notes.migrateLegacyCiphertext();

  void lock() => _vault.lock();

  /// شاشة الخزنة ظاهرة: لا قفل بالمهلة. [release] عند زوالها.
  void hold() => _vault.hold();

  void release() => _vault.release();

  /// الملاحظات المقفلة مفكوكة. يرمي [VaultLockedException] والخزنة مقفلة.
  Future<List<Note>> lockedNotes() => _notes.lockedNotes();

  // ── كلمة السر والبصمة ────────────────────────────────────────────────────

  Future<bool> verifyPassword(String password) =>
      _vault.verifyPassword(password);

  Future<bool> changePassword(String oldPassword, String newPassword) =>
      _vault.changePassword(oldPassword, newPassword);

  /// كلمة سر جديدة بعد الفتح برمز الاسترداد.
  Future<void> setPassword(String newPassword) =>
      _vault.setPassword(newPassword);

  Future<bool> isBiometricEnabled() => _vault.isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled) =>
      _vault.setBiometricEnabled(enabled);

  Future<bool> isBiometricButtonVisible() => _vault.isBiometricButtonVisible();

  Future<void> setBiometricButtonVisible(bool visible) =>
      _vault.setBiometricButtonVisible(visible);

  // ── تدوير المفتاح وحذف الخزنة ────────────────────────────────────────────

  /// مفتاح وكلمة سر جديدان مع بقاء كل الملاحظات (الخزنة مفتوحة بالبصمة).
  /// يُرجع رمز الاسترداد الجديد، أو null إن فشل — ولا يتغير شيء حينها.
  Future<String?> resetKey(String newPassword) => _whileBusy(() async {
        resetStep.value = VaultResetStep.reEncrypting;
        try {
          final code = await _vault.rotateKey(newPassword, _notes.resealAll);
          resetStep.value = VaultResetStep.completed;
          return code;
        } on Object {
          resetStep.value = VaultResetStep.failed;
          return null;
        }
      });

  /// يحذف الخزنة. [keepNotes]: تُفك الملاحظات كلها أولاً وتبقى في الملاحظات
  /// العادية؛ إن تعذّر فك أي منها يرمي ولا يُحذف شيء. وإلا تُحذف نهائياً.
  Future<void> destroy({required bool keepNotes}) => _whileBusy(() async {
        if (keepNotes) {
          await _notes.unlockAll();
        } else {
          await _notes.deleteAllLocked();
        }
        await _vault.clear();
      });

  Future<T> _whileBusy<T>(Future<T> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _vault.removeListener(notifyListeners);
    resetStep.dispose();
    super.dispose();
  }
}
