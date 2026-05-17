# 🛎️ الخادم — VaultService & Security Services

**الملفات:**
- `lib/services/security/vault_service.dart`
- `lib/services/security/biometric_service.dart`
- `lib/services/security/unified_lock_service.dart`
- `lib/services/security/security_gate.dart`
- `lib/services/security/rate_limiter_service.dart`
- `lib/services/security/vault_reset_service.dart`

---

## VaultService — البنية

```
VaultService (static class)
├── Setup:    setupVault(password) → recoveryCode
├── Unlock:   unlockWithPassword() / recoverWithCode()
├── Session:  markVaultUnlocked() / isVaultUnlocked() / lockVault()
├── Crypto:   encryptWithMasterKey() / decryptWithMasterKey() / decryptWithKey()
├── Backup:   getVaultDataForBackup() / restoreVaultDataFromBackup()
└── Utils:    isEncrypted() / wipeMasterKey() / validatePasswordStrength()
```

### التشفير
| الخوارزمية | الاستخدام |
|-----------|----------|
| AES-256-CBC | تشفير المحتوى |
| PBKDF2-SHA256 | اشتقاق المفتاح من كلمة المرور |
| Isolate | PBKDF2 يعمل في thread منفصل |
| FlutterSecureStorage | تخزين المفاتيح |

---

## المشاكل المكتشفة

### 🔴 S1 — `_kIterations = 10000` ضعيف جداً
```dart
static const _kIterations = 10000;       // ← الحالي
static const _kLegacyIterations = 100000; // ← القديم!
```
**الأثر:** الإصدار الجديد أضعف من القديم بـ 10x — PBKDF2 بـ 10,000 iteration قابل للـ brute-force على GPU حديث.
**المعيار الموصى به:** 600,000+ (OWASP 2023) أو على الأقل 100,000.
**الحل:** رفع `_kIterations` إلى 100,000 مع migration للبيانات القديمة.

### 🟠 S2 — `isEncrypted()` يقبل أي نص يحتوي `:` وbase64 صالح
```dart
static bool isEncrypted(String text) {
  final parts = text.split(':');
  if (parts.length != 2) return false;
  try {
    IV.fromBase64(parts[0]); // ← إذا نجح → encrypted
    return true;
  } catch (e) {
    return false;
  }
}
```
**الأثر:** نص عادي مثل `"hello:world"` إذا كان `hello` base64 صالح → يُعتبر مشفراً.
**الحل:** إضافة فحص طول IV (16 bytes = 24 chars base64).

### 🟠 S3 — `changePassword('')` يتجاوز التحقق
```dart
static Future<bool> changePassword(String oldPassword, String newPassword) async {
  if (oldPassword.isEmpty) {
    // يتجاوز verifyPassword تماماً!
    final masterKeyBase64 = await _storage.read(key: _masterKeyName);
    ...
  }
}
```
**الأثر:** أي كود يستدعي `changePassword('', newPass)` يغير كلمة المرور بدون تحقق.
**الحل:** تغيير الـ API — دالة منفصلة `setPasswordAfterRecovery()` بدلاً من الـ empty string trick.

### 🟡 S4 — `_validatePassword` في `vault_unlock_screen.dart` مختلفة عن `validatePasswordStrength` في `VaultService`
```dart
// vault_unlock_screen.dart (top-level):
String? _validatePassword(String password) {
  if (password.length < 8) return 'Minimum 8 characters';
  if (!RegExp(r'[0-9]').hasMatch(password)) return '...';
  if (!RegExp(r'[!@#...]').hasMatch(password)) return '...';
  return null;
}

// VaultService:
static bool validatePasswordStrength(String password) {
  final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])...$');
  return regex.hasMatch(password);
}
```
**الأثر:** قواعد مختلفة في مكانين — يمكن قبول كلمة مرور في مكان ورفضها في آخر.
**الحل:** استخدام `VaultService.validatePasswordStrength()` في كل مكان.

### 🟡 S5 — `vault_intro_pages.dart` تحتوي `validateVaultPassword()` ثالثة
```dart
// في vault_intro_pages.dart:
String? validateVaultPassword(String password) { ... }
```
**الأثر:** 3 دوال تحقق من كلمة المرور في 3 ملفات مختلفة.

---

## خريطة تدفق الخزنة

```
أول مرة:
LockedNotesIntroScreen → setupVault() → recoveryCode → setBiometricEnabled() → LockedNotesScreen

فتح عادي:
VaultEntryScreen → VaultUnlockScreen
  ├── كلمة مرور → unlockWithPassword() → LockedNotesScreen
  └── بصمة → BiometricService.authenticate() → getMasterKey() → LockedNotesScreen

استرداد:
VaultUnlockScreen → recoverWithCode() → changePassword('', new) → LockedNotesScreen

قفل:
AppLifecycle.paused → clearLockedSession() → lockVault() → popUntil(isFirst)
```

---

## التقييم

| المعيار | الدرجة |
|---------|--------|
| بنية التشفير | 8/10 |
| أمان PBKDF2 | 4/10 (S1 خطير) |
| نظافة الـ API | 6/10 |
| **الإجمالي** | **6/10** |

**الحكم:** S1 مشكلة أمان حقيقية — يجب إصلاحها قبل أي شيء آخر.
