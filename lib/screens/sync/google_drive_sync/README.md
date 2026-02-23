# 🚀 Google Drive Sync - Quick Start

## 📍 الموقع
```
lib/screens/sync/google_drive_sync/
```

## 🎯 الاستخدام

### من أي مكان في التطبيق:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const GoogleDriveSyncPage(),
  ),
);
```

### النتيجة:
```dart
final result = await Navigator.push<bool>(
  context,
  MaterialPageRoute(
    builder: (context) => const GoogleDriveSyncPage(),
  ),
);

if (result == true) {
  // المزامنة نجحت ✅
  print('Sync successful!');
} else {
  // المستخدم ألغى أو فشلت المزامنة ❌
  print('Sync cancelled or failed');
}
```

---

## 🏗️ الهيكل

```
google_drive_sync/
├── google_drive_sync_page.dart          # الصفحة الرئيسية
├── google_drive_sync_controller.dart    # المنطق
├── sync_step.dart                       # الحالات
└── widgets/
    ├── sync_sign_in_widget.dart         # تسجيل الدخول
    ├── sync_conflict_widget.dart        # التعارض
    ├── sync_vault_warning_widget.dart   # تحذير الخزنة
    ├── sync_progress_widget.dart        # التحميل
    └── sync_success_widget.dart         # النجاح
```

---

## 🔄 التدفق

```
1. Sign In
   ↓
2. Checking (auto)
   ↓
3. Conflict? → [Show Conflict Widget]
   ↓
4. Locked Notes? → [Show Vault Warning]
   ↓
5. Syncing
   ↓
6. Success → Auto Exit (2s)
```

---

## 🎨 الويدجتات

### 1. Sign In Widget
- يظهر دائماً في البداية
- زر تسجيل دخول واحد
- بسيط وواضح

### 2. Conflict Widget (Conditional)
- يظهر فقط عند وجود تعارض
- 3 خيارات: Drive / Device / Merge
- عرض عدد الملاحظات

### 3. Vault Warning Widget (Conditional)
- يظهر فقط عند وجود ملاحظات مقفلة
- تحذير واضح
- Checkbox "لا تذكرني"

### 4. Progress Widget
- شاشة تحميل بسيطة
- رسالة ديناميكية

### 5. Success Widget
- أيقونة نجاح
- خروج تلقائي بعد 2 ثانية

---

## 🔧 التخصيص

### إضافة خطوة جديدة:
1. أضف الحالة في `sync_step.dart`
2. أنشئ الويدجت في `widgets/`
3. أضف الحالة في `_buildBody()` في الصفحة الرئيسية
4. أضف المنطق في `Controller`

### تعديل التدفق:
- كل المنطق في `google_drive_sync_controller.dart`
- عدّل `_checkState()` لتغيير الشروط

---

## ⚠️ ملاحظات مهمة

1. **لا حفظ قبل النجاح:**
   - الحالة تُحفظ فقط في `_executeSync()` بعد النجاح

2. **الإلغاء:**
   - Back button → `abort()` → `signOut()` → `pop()`

3. **الأخطاء:**
   - كل خطأ يعرض في `SyncStep.error`
   - زر "إعادة المحاولة" متاح

---

## 🧪 الاختبار

### السيناريوهات:
- [ ] تسجيل دخول عادي (بدون تعارض أو خزنة)
- [ ] تسجيل دخول مع تعارض
- [ ] تسجيل دخول مع ملاحظات مقفلة
- [ ] تسجيل دخول مع تعارض + خزنة
- [ ] الإلغاء في كل مرحلة
- [ ] فشل تسجيل الدخول
- [ ] فشل المزامنة

---

## 📚 الرسائل المستخدمة

```dart
// Sign In
l10n.signIn
l10n.signInSuccess
l10n.signInFailed

// Conflict
l10n.syncConflictTitle
l10n.syncConflictDesc
l10n.useDrive
l10n.useDevice
l10n.smartMerge

// Vault
l10n.disclaimer
l10n.googleDriveVaultWarning
l10n.dontShowAgain
l10n.continueAction

// General
l10n.syncing
l10n.syncSuccess
l10n.syncFailed
l10n.cancel
```

---

**للمزيد من التفاصيل، راجع:** `GOOGLE_DRIVE_SYNC_REFACTOR.md`
