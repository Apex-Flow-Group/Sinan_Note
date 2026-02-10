# ⚙️ تعليمات الإعداد - Setup Instructions

## للجهاز الجديد (بعد نسخ الملفات)

### 1. تثبيت الاعتماديات وتوليد ملفات الترجمة:
```bash
flutter pub get
```

**هذا الأمر سيقوم بـ:**
- ✅ تحميل جميع المكتبات
- ✅ توليد ملفات الترجمة من `lib/l10n/*.arb`
- ✅ إنشاء المجلد `.dart_tool/flutter_gen/gen_l10n/`

### 2. تشغيل التطبيق:
```bash
flutter run
```

---

## ⚠️ ملاحظة مهمة:

المجلد `.dart_tool/` **لا يُنسخ** لأنه في `.gitignore`  
لذلك يجب تشغيل `flutter pub get` على كل جهاز جديد.

---

## 🔧 إذا ظهرت أخطاء:

```bash
# نظف المشروع
flutter clean

# أعد التثبيت
flutter pub get

# شغّل
flutter run
```
