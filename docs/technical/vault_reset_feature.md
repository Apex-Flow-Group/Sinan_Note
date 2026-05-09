# Vault Reset & Destroy Feature

## Overview

تم إضافة ميزتين جديدتين لإعدادات الخزنة:
1. **إعادة تعيين تشفير الخزنة** — إعادة تشفير كل الملاحظات بمفتاح جديد
2. **تدمير الخزنة** — حذف الخزنة نهائياً مع خيارين للتعامل مع المحتوى

---

## 1. إعادة تعيين التشفير (Vault Reset)

### الفلو الكامل

1. المستخدم يدخل إعدادات الخزنة → "إعادة تعيين التشفير"
2. شاشة تحذير + تحقق بالبصمة
3. إنشاء كلمة مرور جديدة (نفس `VaultPasswordPage` الأصلي مع الشروط الأربعة)
4. شاشة تقدم (لا يمكن الخروج — `PopScope`)
5. عرض كود الاسترداد الجديد + تأكيد الحفظ

### العملية الداخلية

```
1. نسخ ملف القاعدة (sinan_notes.isar) كـ backup
2. قراءة المفتاح الحالي (الخزنة مفتوحة بالبصمة)
3. جلب كل الملاحظات المشفرة
4. فك تشفير كل ملاحظة بالمفتاح القديم
5. مسح المفتاح القديم من الذاكرة
6. VaultService.setupVault(newPassword) → مفتاح جديد + كود استرداد جديد
7. إعادة تشفير كل ملاحظة بالمفتاح الجديد
8. كتابة كل ملاحظة للقاعدة
9. مسح المفتاح الجديد من الذاكرة
```

### الحماية من الفشل

- **قبل أي تعديل**: نسخ ملف القاعدة بالكامل
- **لو فشلت العملية**: استعادة القاعدة القديمة فوراً (`_restoreFromBackup`)
- **الاحتفاظ بالنسخة القديمة**: 15 يوم كـ fallback
- **تنظيف تلقائي**: `cleanExpiredBackups()` عند كل فتح للتطبيق

### أداء الـ UI

- `_yieldToUI()` بعد كل emit لإعطاء الـ event loop فرصة لرسم الـ frame
- yield كل 2-3 ملاحظات لتقليل overhead
- `Future.delayed(16ms)` قبل `setupVault` (PBKDF2 ثقيلة)
- `Future.delayed(100ms)` قبل `executeReset` لضمان رسم شاشة التقدم

---

## 2. تدمير الخزنة (Vault Destroy)

### الخيارات

#### فك التشفير وتدمير (Decrypt & Destroy)
- فك تشفير كل الملاحظات المقفلة
- نقلها للملاحظات العادية (`isLocked = false`)
- حذف الخزنة ومفاتيح التشفير
- تحديث الصفحة الرئيسية

#### تدمير مع المحتوى (Destroy with Content)
- حذف كل الملاحظات المقفلة نهائياً من القاعدة
- حذف الخزنة ومفاتيح التشفير
- تحديث الصفحة الرئيسية

### الحماية

- **Checkbox تأكيد**: "أفهم أن هذا الإجراء لا يمكن التراجع عنه" — الزر معطّل بدونه
- **تحقق بالبصمة**: بعد التأكيد، يُطلب التحقق بالبصمة قبل التنفيذ
- **VaultResetGuard**: يمنع `LockedNotesScreen` من الخروج أثناء البصمة

---

## 3. إصلاح مشكلة إغلاق الخزنة عند البصمة

### المشكلة
عند طلب البصمة، نافذة النظام تظهر فوق التطبيق → التطبيق يدخل حالة `paused` → `LockedNotesScreen.didChangeAppLifecycleState` يخرج من الخزنة.

### الحل
- `VaultResetGuard.isActive` — static flag في `vault_reset_service.dart`
- `LockedNotesScreen` يتجاهل lifecycle events طالما الـ guard مفعّل
- يُفعّل قبل البصمة ويُوقف عند dispose أو فشل البصمة

---

## الملفات المعدّلة/الجديدة

### ملفات جديدة
- `lib/services/security/vault_reset_service.dart` — خدمة إعادة التعيين + VaultResetGuard
- `lib/screens/auth/vault_reset_screen.dart` — شاشة الويزارد

### ملفات معدّلة
- `lib/widgets/home/dialogs/vault_dialogs.dart` — إضافة خيارات الريست والتدمير
- `lib/screens/mobile/locked_notes_screen.dart` — إضافة VaultResetGuard check
- `lib/screens/onboarding/splash_screen.dart` — إضافة cleanExpiredBackups
- `lib/l10n/app_ar.arb` — نصوص عربية جديدة
- `lib/l10n/app_en.arb` — نصوص إنجليزية جديدة
- `lib/generated/l10n/*` — ملفات مولّدة تلقائياً
