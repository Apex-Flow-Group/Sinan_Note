# 🎯 Smart Import Feature

## ✨ الميزة الجديدة

تم دمج زرين الاستيراد (JSON و Database) في **زر واحد ذكي** يكتشف نوع الملف تلقائياً!

## 🔄 قبل وبعد

### ❌ قبل:
```
- زر "Restore" → لملفات .isar (Database)
- زر "Import JSON" → لملفات .json
```

### ✅ بعد:
```
- زر "Restore" واحد → يقبل .json و .isar تلقائياً
```

## 🧠 كيف يعمل؟

### 1. **اختيار الملف**
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['json', 'isar'], // ✅ يقبل النوعين
);
```

### 2. **الكشف التلقائي**
```dart
final isDatabase = fileName.endsWith('.isar') || fileName.contains('backup');

if (isDatabase) {
  await _handleDatabaseRestore(...);  // Database flow
} else {
  await _handleJSONImport(...);       // JSON flow
}
```

### 3. **معالجة الملفات المشفرة**
- إذا كان الملف يحتوي على `vault_data`
- يظهر Recovery Code Dialog تلقائياً
- بعد النجاح، يتم فك تشفير الملاحظات

### 4. **رسائل واضحة**
```
✅ تم استيراد 15 ملاحظة (10 عادية، 5 مشفرة)
✅ Imported 15 notes (10 normal, 5 encrypted)
```

## 📁 الملفات المعدلة

### 1. `lib/screens/settings/settings_backup_handlers.dart`
- ✅ إضافة `handleSmartImport()` - الدالة الذكية الرئيسية
- ✅ إضافة `_handleDatabaseRestore()` - معالجة ملفات .isar
- ✅ إضافة `_handleJSONImport()` - معالجة ملفات .json
- ✅ الاحتفاظ بـ `handleImportJSON()` للتوافق مع الكود القديم

### 2. `lib/screens/settings_screen.dart`
- ✅ حذف زر "Import JSON"
- ✅ تحديث زر "Restore" ليستخدم `handleSmartImport()`
- ✅ تحديث الوصف: "استيراد من JSON أو Database"

## 🎨 واجهة المستخدم

```
📦 Data
  ├─ 📤 Export Backup (Database)
  ├─ 📥 Restore (JSON or Database) ← الزر الذكي الجديد
  └─ 📄 Export JSON
```

## 🔐 دعم الملفات المشفرة

### السيناريو الكامل:
1. المستخدم يختار ملف backup (JSON أو Database)
2. النظام يفحص: هل يحتوي على `vault_data`?
3. إذا نعم → يطلب Recovery Code
4. المستخدم يدخل الكود
5. ✅ يتم فك تشفير Master Key
6. ✅ يتم استيراد الملاحظات
7. ✅ رسالة: "تم استيراد 15 ملاحظة (10 عادية، 5 مشفرة)"

## 🚀 الفوائد

1. **تجربة مستخدم أفضل** - زر واحد بدلاً من اثنين
2. **أقل تعقيداً** - لا حاجة لمعرفة نوع الملف
3. **ذكي** - يكتشف النوع تلقائياً
4. **آمن** - يدعم الملفات المشفرة بالكامل
5. **واضح** - رسائل مفصلة عن عدد الملاحظات

## 📝 ملاحظات تقنية

- الدالة `handleImportJSON()` لا تزال موجودة للتوافق
- يمكن حذفها لاحقاً إذا لم تكن مستخدمة في أماكن أخرى
- `handleSmartRestore()` القديمة تم استبدالها بـ `handleSmartImport()`
