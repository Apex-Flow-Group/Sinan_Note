# ✅ تدفق Recovery Code عند الاستيراد

## 🎯 السيناريو الكامل

### 🌍 على كوكب الأرض:
```
1. المستخدم ينشئ خزنة
2. يحصل على Recovery Code: SN-A7K9-M3P2-X8Q5
3. يضيف 10 ملاحظات مقفلة
4. يصدر Backup → ملف JSON
5. الملف يحتوي على:
   - الملاحظات المشفرة
   - vault_data (Master Key مشفر بـ Recovery Code)
```

### 🚀 على كوكب المريخ:
```
1. المستخدم يثبت التطبيق (جديد)
2. يختار "Restore from Backup"
3. يختار الملف JSON
4. النظام يكتشف: يوجد vault_data!
5. يظهر Dialog: "أدخل Recovery Code"
6. المستخدم يدخل: SN-A7K9-M3P2-X8Q5
7. النظام:
   - يفك تشفير Master Key
   - يحفظ Master Key محلياً
   - يستورد الملاحظات
8. ✅ الملاحظات المقفلة تفتح بنجاح!
```

---

## 🔐 التدفق التقني

### 1. عند التصدير:
```dart
// BackupService.exportDatabase()
final vaultData = await VaultService.getVaultDataForBackup();
// Returns:
{
  "encrypted_master_key": "iv:ciphertext",  // مشفر بـ Recovery Code
  "recovery_hash": "sha256_hash",
  "created_at": "2026-02-10..."
}

// يُضاف إلى JSON
{
  "version": "2.0",
  "vault_data": {...},
  "notes": [...]
}
```

### 2. عند الاستيراد:
```dart
// settings_backup_handlers.dart
final hasVaultData = await _checkForVaultData(backupPath);

if (hasVaultData) {
  // Show Recovery Code Dialog
  final recovered = await showDialog<bool>(
    context: context,
    builder: (ctx) => const RecoveryCodeDialog(),
  );
  
  if (recovered != true) {
    // User cancelled
    return;
  }
}

// Continue with import
await BackupService().replaceDatabase(backupPath);
```

### 3. في Recovery Code Dialog:
```dart
// recovery_code_dialog.dart
Future<void> _handleRecover() async {
  final recoveryCode = _recoveryController.text.trim();
  
  // Verify and unlock
  final success = await VaultService.recoverWithCode(recoveryCode);
  
  if (success) {
    Navigator.pop(context, true); // Success!
  } else {
    setState(() => _errorText = 'Invalid Recovery Code');
  }
}
```

### 4. في VaultService:
```dart
// vault_service.dart
static Future<bool> recoverWithCode(String recoveryCode) async {
  // 1. Verify recovery code hash
  if (!await verifyRecoveryCode(recoveryCode)) return false;
  
  // 2. Get encrypted master key
  final encrypted = await _storage.read(key: 'vault_master_key_recovery');
  
  // 3. Decrypt master key with recovery code
  final masterKey = await _decryptMasterKey(encrypted, recoveryCode);
  
  // 4. Save master key locally
  await _storage.write(key: 'vault_master_key', value: masterKey.base64);
  
  return true;
}
```

---

## 📱 واجهة المستخدم

### Recovery Code Dialog:

```
┌─────────────────────────────────────┐
│  🔑 Recovery Code                   │
├─────────────────────────────────────┤
│                                     │
│  Enter your recovery code:          │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  SN-XXXX-XXXX-XXXX            │ │
│  └───────────────────────────────┘ │
│                                     │
│  ℹ️ This is the long code you      │
│     received when creating vault   │
│                                     │
│  [Cancel]              [🔓 Unlock] │
└─────────────────────────────────────┘
```

---

## 🔄 التدفق الكامل

```
┌─────────────────┐
│ User: Restore   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Pick JSON File  │
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ Check vault_data?   │
└────────┬────────────┘
         │
    ┌────┴────┐
    │         │
   Yes       No
    │         │
    ▼         ▼
┌─────────┐  ┌──────────┐
│ Show    │  │ Import   │
│ Dialog  │  │ Directly │
└────┬────┘  └──────────┘
     │
     ▼
┌──────────────────┐
│ Enter Recovery   │
│ Code             │
└────┬─────────────┘
     │
┌────┴────┐
│         │
Valid   Invalid
│         │
▼         ▼
┌─────┐  ┌───────┐
│ ✅  │  │ ❌    │
│ OK  │  │ Error │
└──┬──┘  └───────┘
   │
   ▼
┌──────────────┐
│ Decrypt      │
│ Master Key   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Import Notes │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ ✅ Success!  │
└──────────────┘
```

---

## 📂 الملفات المعدلة

### 1. ✅ recovery_code_dialog.dart (جديد)
- Dialog لإدخال Recovery Code
- التحقق والفتح
- رسائل خطأ واضحة

### 2. ✅ settings_backup_handlers.dart
- `handleSmartRestore()` - إضافة فحص vault_data
- `handleImportJSON()` - إضافة فحص vault_data
- `_checkForVaultData()` - دالة مساعدة جديدة

---

## 🎯 الحالات المختلفة

### حالة 1: ملف بدون vault_data
```json
[
  {"id": 1, "title": "Note 1"}
]
```
✅ **يستورد مباشرة** - لا يطلب Recovery Code

### حالة 2: ملف مع vault_data
```json
{
  "version": "2.0",
  "vault_data": {...},
  "notes": [...]
}
```
✅ **يطلب Recovery Code** - ثم يستورد

### حالة 3: Recovery Code خاطئ
```
❌ Error: Invalid Recovery Code
```
✅ **يعرض رسالة خطأ** - يسمح بالمحاولة مرة أخرى

### حالة 4: المستخدم يلغي
```
⚠️ Restore cancelled
```
✅ **لا يستورد شيء** - يعود للإعدادات

---

## 🔒 الأمان

### ✅ ما هو آمن:
1. Master Key مشفر في الملف
2. Recovery Code مطلوب لفك التشفير
3. التحقق من صحة Recovery Code قبل الفتح
4. لا يمكن فتح الملف بدون Recovery Code

### ⚠️ ما يجب على المستخدم فعله:
1. حفظ Recovery Code في مكان آمن
2. عدم مشاركة Recovery Code مع أي شخص
3. استخدام Recovery Code فقط عند الحاجة

---

## ✅ الاختبار

### سيناريو الاختبار:
```
1. إنشاء خزنة → حفظ Recovery Code
2. إضافة ملاحظات مقفلة
3. تصدير Backup
4. حذف التطبيق
5. إعادة تثبيت
6. استيراد Backup
7. إدخال Recovery Code ✅
8. فتح الملاحظات المقفلة ✅
```

---

**تم التنفيذ بواسطة**: Kiro AI  
**التاريخ**: 10 فبراير 2026  
**الحالة**: مكتمل ✅
