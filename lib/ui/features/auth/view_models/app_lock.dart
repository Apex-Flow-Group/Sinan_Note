// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:sinan_note/data/services/security/biometric_service.dart';
import 'package:sinan_note/data/services/security/rate_limiter_service.dart';
import 'package:sinan_note/data/services/security/unified_lock_service.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/features/auth/view_models/security_controller.dart';

export 'package:sinan_note/data/services/security/unified_lock_service.dart'
    show LockType;

/// قفل التطبيق للواجهات: PIN، البصمة، محاولات PIN، وحالة القفل.
class AppLock {
  AppLock({
    UnifiedLockService? lock,
    SecurityController? security,
  })  : _lock = lock ?? UnifiedLockService(),
        _security = security ?? SecurityController();

  final UnifiedLockService _lock;
  final SecurityController _security;

  // ── حالة القفل ────────────────────────────────────────────────────────────

  /// يتغيّر عند القفل وفكه.
  Listenable get lockState => _security;
  bool get isLocked => _security.isLocked;
  void forceUnlock() => _security.forceUnlock();

  // ── PIN والبصمة ───────────────────────────────────────────────────────────

  Future<LockType> getLockType() => _lock.getLockType();
  Future<bool> hasPinSet() => _lock.hasPinSet();
  Future<void> setPin(String pin) => _lock.setPin(pin);
  Future<bool> verifyPin(String pin) => _lock.verifyPin(pin);

  Future<bool> authenticate({
    String context = 'app_lock',
    bool biometricEnabled = false,
    bool reuseSession = true,
  }) =>
      _lock.authenticate(
          context: context,
          biometricEnabled: biometricEnabled,
          reuseSession: reuseSession);

  void markAuthenticated() => _lock.markAuthenticated();
  void resetSession() => _lock.resetSession();

  /// مصادقة جارية داخل الخزنة (نافذة البصمة): لا تُقفل الخزنة بسببها.
  bool get isVaultOperation => _lock.isVaultOperation;

  Future<bool> hasBiometrics() => BiometricService.hasBiometrics();
  Future<bool> authenticateBiometric() => BiometricService.authenticate();

  // ── محاولات PIN ───────────────────────────────────────────────────────────

  /// الثواني المتبقية من قفل المحاولات، أو null.
  Future<int?> getRemainingLockTime() =>
      RateLimiterService.getRemainingLockTime();
  Future<int> getRemainingAttempts() =>
      RateLimiterService.getRemainingAttempts();

  /// يُرجع مدة القفل بالثواني إن بلغ الحد.
  Future<int?> recordFailedAttempt() =>
      RateLimiterService.recordFailedAttempt();
  Future<void> resetAttempts() => RateLimiterService.reset();
}

/// مدة انتظار بلغة المستخدم: "5 د 30 ث" / "5m 30s".
String formatWait(AppLocalizations l10n, int seconds) {
  final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
  return [
    if (h > 0) l10n.waitHours(h),
    if (m > 0) l10n.waitMinutes(m),
    if (h == 0 && (s > 0 || m == 0)) l10n.waitSeconds(s),
  ].join(' ');
}
