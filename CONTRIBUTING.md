<div dir="rtl">

# دليل المساهمة

نرحب بجميع المساهمات — إصلاح أخطاء، إضافة ميزات، تحسين التوثيق، أو اقتراحات.

---

## إعداد بيئة التطوير

### المتطلبات

| المتطلب | الإصدار |
|---------|---------|
| Flutter SDK | 3.0.0+ |
| Dart SDK | 3.0.0+ |
| Android Studio / VS Code | أحدث إصدار |
| Git | أي إصدار |

### خطوات الإعداد

```bash
# 1. Fork المشروع من GitHub ثم Clone
git clone https://github.com/YOUR_USERNAME/Sinan_Note.git
cd Sinan_Note

# 2. إضافة Remote للمشروع الأصلي
git remote add upstream https://github.com/Apex-Flow-Group/Sinan_Note.git

# 3. تثبيت الاعتماديات
flutter pub get

# 4. التحقق من عدم وجود أخطاء
flutter analyze
flutter test
```

---

## معايير الكود

### Dart Style

- اتبع [Effective Dart](https://dart.dev/guides/language/effective-dart)
- استخدم `Theme.of(context).colorScheme` بدل الألوان الثابتة
- استخدم `EdgeInsetsDirectional` لدعم RTL
- كل `try/catch` يجب أن يعالج الخطأ أو يعيد رميه — لا ابتلاع صامت
- الملفات الجديدة لا تتجاوز 400 سطر — قسّم إذا احتجت

### Error Handling

```dart
// ✅ صحيح
try {
  await riskyOperation();
} catch (e, stack) {
  AppLogger.error('RiskyOp', e, stack);
  rethrow;
}

// ❌ خطأ — ابتلاع صامت
try {
  await riskyOperation();
} catch (_) {}
```

### RTL Support

```dart
// ✅ صحيح
Padding(padding: EdgeInsetsDirectional.only(start: 16))

// ❌ خطأ — لن يعمل مع RTL
Padding(padding: EdgeInsets.only(left: 16))
```

### Commit Messages

```
feat: إضافة ميزة جديدة
fix: إصلاح خطأ
refactor: إعادة هيكلة
docs: تحديث توثيق
style: تحسين التنسيق (لا يؤثر على الكود)
test: إضافة اختبارات
chore: مهام صيانة
```

### Responsive Layout

- **لا تستخدم** `MediaQuery.of(context).size.width >= 600` مباشرة لتحديد نوع الشاشة
- استخدم `PlatformHelper` دائماً:
  ```dart
  // ✅ صحيح
  final isWide = PlatformHelper.isWideDisplay(context);
  final mode = PlatformHelper.getDisplayMode(context);

  // ❌ خطأ — لا يفرّق بين المطويات والتابلت والنوافذ المصغرة
  final isWide = MediaQuery.of(context).size.width >= 600;
  ```
- `DisplayMode.phone` — هاتف عادي أو نافذة مصغرة
- `DisplayMode.foldableOpen` — هاتف مطوي (شاشة داخلية)
- `DisplayMode.tablet` — تابلت أفقي
- `DisplayMode.desktop` — Windows/Mac/Linux

---

## عملية Pull Request

```bash
# 1. أنشئ فرع جديد
git checkout -b feat/amazing-feature

# 2. اكتب الكود + الاختبارات

# 3. تحقق
flutter analyze
flutter test

# 4. Commit
git commit -m "feat: Add amazing feature"

# 5. Push
git push origin feat/amazing-feature
```

ثم افتح Pull Request على GitHub مع وصف واضح للتغييرات.

---

## الإبلاغ عن الأخطاء

افتح Issue مع:
- خطوات إعادة الإنتاج
- السلوك المتوقع vs الفعلي
- الجهاز ونسخة Android
- Screenshot إن أمكن

---

## التواصل

- **Email:** contact.apex.flow@gmail.com

</div>
