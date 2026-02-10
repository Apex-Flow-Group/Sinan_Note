# ✅ تنفيذ: Master Key في ملف النسخ الاحتياطي

## 🎯 الهدف المحقق

**وضع Master Key المشفر داخل ملف JSON نفسه**

---

## 📦 البنية الجديدة

### ملف JSON الجديد:
```json
{
  "version": "2.0",
  "vault_data": {
    "encrypted_master_key": "iv:ciphertext",
    "recovery_hash": "sha256_hash",
    "created_at": "2026-02-10T12:00:00.000Z"
  },
  "notes": [
    {
      "id": 1,
      "title": "iv:encrypted_title",
      "content": "iv:encrypted_content",
      "isLocked": true,
      ...
    }
  ]
}
```

### ملف JSON القديم (متوافق):
```json
[
  {
    "id": 1,
    "title": "Note Title",
    "content": "Note Content",
    ...
  }
]
```

---

## 🔧 التعديلات المنفذة

### 1. VaultService - دوال جديدة ✅

**الملف**: `lib/services/security/vault_service.dart`

```dart
/// Get vault data for backup
static Future<Map<String, dynamic>?> getVaultDataForBackup()

/// Restore vault data from backup
static Future<bool> restoreVaultDataFromBackup(Map<String, dynamic> vaultData)
```

**الوظيفة**:
- `getVaultDataForBackup()`: يقرأ Master Key المشفر + Recovery Hash
- `restoreVaultDataFromBackup()`: يحفظ vault_data محلياً عند الاستيراد

---

### 2. BackupService - 5 دوال محدثة ✅

**الملف**: `lib/services/storage/backup_service.dart`

#### ✅ exportDatabase()
```dart
// إضافة vault_data إلى JSON
final vaultData = await VaultService.getVaultDataForBackup();
if (vaultData != null) {
  backupData['vault_data'] = vaultData;
}
```

#### ✅ exportDatabaseToPath()
```dart
// نفس الشيء - إضافة vault_data
```

#### ✅ shareDatabase()
```dart
// نفس الشيء - إضافة vault_data
```

#### ✅ replaceDatabase()
```dart
// قراءة vault_data واستعادته
if (jsonData is Map<String, dynamic>) {
  vaultData = jsonData['vault_data'];
  if (vaultData != null) {
    await VaultService.restoreVaultDataFromBackup(vaultData);
  }
}
```

#### ✅ mergeDatabase()
```dart
// نفس الشيء - قراءة واستعادة vault_data
```

---

### 3. StorageService - 4 دوال محدثة ✅

**الملف**: `lib/services/storage/storage_service.dart`

#### ✅ exportNotesToDevice()
```dart
// إضافة vault_data
final vaultData = await VaultService.getVaultDataForBackup();
if (vaultData != null) {
  exportData['vault_data'] = vaultData;
}
```

#### ✅ exportNotesToPath()
```dart
// نفس الشيء
```

#### ✅ shareNotesFile()
```dart
// نفس الشيء
```

#### ✅ importNotesFromDevice()
```dart
// قراءة واستعادة vault_data
if (jsonData is Map<String, dynamic>) {
  vaultData = jsonData['vault_data'];
  if (vaultData != null) {
    await VaultService.restoreVaultDataFromBackup(vaultData);
  }
}
```

---

## 🔄 كيف يعمل النظام

### السيناريو الكامل:

#### 📤 التصدير (الجهاز A):
```
1. المستخدم يضغط "Export Backup"
2. النظام يجمع الملاحظات
3. النظام يتحقق: هل توجد خزنة؟
   ✅ نعم → يقرأ Master Key المشفر + Recovery Hash
   ❌ لا → يتخطى vault_data
4. النظام يُنشئ JSON:
   {
     "version": "2.0",
     "vault_data": {...},  // ✅ هنا
     "notes": [...]
   }
5. حفظ/مشاركة الملف
```

#### 📥 الاستيراد (الجهاز B):
```
1. المستخدم يختار ملف JSON
2. النظام يقرأ الملف
3. النظام يتحقق: هل يحتوي على vault_data؟
   ✅ نعم → يحفظ vault_data محلياً
   ❌ لا → ملف قديم، يتخطى
4. النظام يستورد الملاحظات
5. الملاحظات المقفلة موجودة (مشفرة)
6. vault_data محفوظ محلياً
7. المستخدم يفتح الخزنة:
   - يدخل Recovery Code
   - النظام يفك تشفير Master Key
   - الآن يمكن فك تشفير الملاحظات! ✅
```

---

## 🔒 الأمان

### ✅ ما هو آمن:
1. **Master Key مشفر** بـ Recovery Code
2. **Recovery Code منفصل** (المستخدم يحفظه)
3. **حتى لو سُرق الملف**، لا يمكن فك التشفير بدون Recovery Code

### ⚠️ ما يجب على المستخدم فعله:
1. **حفظ Recovery Code** في مكان آمن
2. **عدم مشاركة Recovery Code** مع الملف
3. **استخدام Recovery Code** عند الاستيراد على جهاز جديد

---

## 📊 التوافق

### ✅ الملفات القديمة:
```json
[{"id": 1, "title": "..."}]
```
- ✅ تعمل بدون مشاكل
- ✅ لا vault_data = لا ملاحظات مقفلة

### ✅ الملفات الجديدة:
```json
{
  "version": "2.0",
  "vault_data": {...},
  "notes": [...]
}
```
- ✅ تعمل على الأجهزة القديمة (تتجاهل vault_data)
- ✅ تعمل على الأجهزة الجديدة (تستخدم vault_data)

---

## 🎯 الملفات المعدلة

| الملف | الدوال المعدلة | الحالة |
|------|----------------|--------|
| `vault_service.dart` | +2 دوال جديدة | ✅ |
| `backup_service.dart` | 5 دوال | ✅ |
| `storage_service.dart` | 4 دوال | ✅ |
| **المجموع** | **11 دالة** | ✅ |

---

## ✅ الاختبار

### اختبار التصدير:
```dart
1. إنشاء خزنة
2. إضافة ملاحظات مقفلة
3. تصدير Backup
4. فتح الملف JSON
5. التحقق من وجود vault_data ✅
```

### اختبار الاستيراد:
```dart
1. حذف التطبيق
2. إعادة تثبيت
3. استيراد Backup
4. إدخال Recovery Code
5. فتح الملاحظات المقفلة ✅
```

---

## 🚀 الخطوات التالية

### المرحلة التالية: Google Drive

الآن بعد أن أصبح vault_data جزءاً من JSON، سيتم رفعه تلقائياً إلى Google Drive!

```dart
// في GoogleDriveService
await uploadDatabase(context);
// سيرفع الملف الكامل مع vault_data ✅
```

**لا حاجة لتعديلات إضافية!** 🎉

---

## 📝 ملاحظات للمطورين

### كيفية الاستخدام:

```dart
// التصدير (تلقائي)
await BackupService().exportDatabase();
// vault_data يُضاف تلقائياً إذا كانت الخزنة موجودة

// الاستيراد (تلقائي)
await BackupService().replaceDatabase(backupPath);
// vault_data يُستعاد تلقائياً إذا كان موجوداً

// فتح الخزنة بعد الاستيراد
await VaultService.recoverWithCode(recoveryCode);
// الآن يمكن فك تشفير الملاحظات
```

---

## 🎉 النتيجة النهائية

✅ **Master Key محفوظ في الملف**  
✅ **آمن (مشفر بـ Recovery Code)**  
✅ **يعمل على جميع أنواع التصدير**  
✅ **متوافق مع الملفات القديمة**  
✅ **جاهز لـ Google Drive**  

---

**تم التنفيذ بواسطة**: Kiro AI  
**التاريخ**: 10 فبراير 2026  
**الحالة**: مكتمل ✅
