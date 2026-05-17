# 🔍 المشاكل المكتشفة — ملخص كامل

> آخر تحديث: 2026-05-17 — نهاية الريفاكتور

---

## ✅ مُنجز — الجولة 1 (أمان)

| الكود | الملف | المشكلة | الحل |
|-------|-------|---------|------|
| SEC-1 | `vault_service.dart` | PBKDF2 = 10,000 ضعيف | رُفع إلى 100,000 — migration تلقائي |
| SEC-2 | `vault_service.dart` | `changePassword('')` يتجاوز التحقق | `setPasswordAfterRecovery()` منفصلة |
| SEC-4 | `vault_service.dart` | `isEncrypted()` false positives | فحص طول IV = 24 chars base64 |
| SEC-5 + S4 + S5 | 3 ملفات | 3 دوال تحقق مختلفة | توحيد عبر `validateVaultPassword()` |
| AUTH1 | `locked_notes_screen.dart` | `_isAuthenticating = false` لا يتغير | `bool` قابل للتغيير + ضبطه حول dialogs |
| UI5 | `search_mixin.dart` | `' '` hack كـ toggle | `_searchActive` bool نظيف في SearchMixin |
| RESP1 | `locked_notes_screen_responsive.dart` | Desktop يعرض ملاحظات مشفرة | يقرأ `lockedNotes` بدل `activeNotes` |
| P1 | `notes_provider.dart` | `convertNoteType` rebuild مزدوج | حذف `refreshAllNotes()` الزائدة |
| M2 | `note_state_service.dart` | `List.from` بعد sort بلا قيمة | حُذفت |
| M3 | `note_state_service.dart` | `markDirty()` مرتين في `removeNote` | حُذف الاستدعاء الصريح |

---

## ✅ مُنجز — الجولة 2 (تحسين)

| الكود | الملف | المشكلة | الحل |
|-------|-------|---------|------|
| P2 | `notes_provider.dart` | قراءة DB إضافية في archive/trash/restore | `copyWith` على الـ state |
| M1 | `note_state_service.dart` | `reminderNotes` بلا cache | `_cachedReminderNotes` مع invalidation |
| M2(addNote) | `note_state_service.dart` | `List.from` زائدة في `addNote` | حُذفت |
| UI7 | `vault_unlock_screen.dart` | `FutureBuilder` للبصمة يُعاد بناؤه | `_loadBiometricState()` في `initState` |
| UX-4 | `vault_unlock_screen.dart` | `'Failed to set new password'` hardcoded | `l10n.decryptionFailed` |
| UX-5 | `vault_reset_screen.dart` | `'Passwords do not match'` hardcoded | `l10n.passwordMismatch` |
| ENTRY1 | `vault_entry_screen.dart` | `'جاري التحقق...'` hardcoded | `l10n.verifyingIdentity` |
| RESET1 | `vault_reset_service.dart` | `StreamController` لا يتحقق من `isClosed` | فحص `isClosed` قبل `add()` |

---

## ✅ مُنجز — الجولة 3 (Navigation + تنظيف)

| الكود | الملف | المشكلة | الحل |
|-------|-------|---------|------|
| N3 | متعدد | لا يوجد مركز تنقل | `VaultNavigator` لتنقلات الخزنة |
| N1 | `locked_notes_screen.dart` | `popUntil(isFirst)` هش | `VaultNavigator.exitVault()` بـ route name |
| N2 | `main_layout_screen.dart` | Navigator من داخل Listener | `addPostFrameCallback` |
| P4 | `notes_provider.dart` | `insertNote` alias غير ضروري | حُذف |
| P3 | `notes_provider.dart` | `loadNotes` غير موثّقة | أُضيف توثيق |
| UI10 | `locked_notes_intro_screen.dart` | `_totalPages = 4` hardcoded | `_pagesWithBiometrics/WithoutBiometrics` |
| SEC-3 | `vault_service.dart` | Master key في storage غير موثّق | أُضيف توثيق مفصّل |

---

## 🔴 لم يُحل — يحتاج AppRouter/Shell Route

| الكود | المشكلة | السبب | الحل المطلوب |
|-------|---------|-------|-------------|
| NAV-HERO | Hero يطير فوق BottomNavBar | BottomNavBar خارج Navigator | Shell Route / Nested Navigator |
| NAV-DRAWER | "حول" و"تواصل" يحتاجان معرفة حالة الخزنة | لا يوجد مركز تنقل | AppRouter.showOverlay() |

**التوثيق الكامل:** `.refactoring/ui/findings/navigation.md`

**الخلاصة:** إذا لم تُحل بـ pure navigation — الهيكلة فاشلة.

---

## 📋 متبقي منخفض الأولوية

| الكود | الملف | المشكلة |
|-------|-------|---------|
| UI1 | `locked_notes_screen.dart` | `_ImportSheet` 300+ سطر في نفس الملف |
| UI3 | `locked_notes_screen.dart` | `_displayInfo()` تفك JSON يدوياً في UI |
| RATE1 | `unified_lock_service.dart` | `_generateSalt()` entropy ضعيف |
| UI11 | `locked_notes_intro_screen.dart` | `_buildBottomButton` منطق معقد inline |
