# ✅ قائمة التحقق قبل رفع Google Play

## 🔴 خطوات أمنية إلزامية:

### 1. إزالة الملفات السرية من Git:
```bash
git rm --cached "client_secret_308129072326-2p8a46je0nl6sl7ljqe0mmrabc036a9k.apps.googleusercontent.com (1).json"
git rm --cached upload_certificate.pem
git commit -m "🔒 Remove sensitive files from repository"
```

### 2. تغيير كلمات المرور المكشوفة:
⚠️ **كلمة المرور الحالية مكشوفة: `tOOp_59376`**

يجب:
- إنشاء keystore جديد بكلمة مرور قوية
- تحديث Google Play Console بالمفتاح الجديد
- عدم رفع `key.properties` أبداً

### 3. حذف ملفات غير ضرورية:
```bash
# ملفات كبيرة غير مطلوبة
rm -rf build/                    # 1.5GB
rm سنان.tar.gz                   # 36MB
rm GOOGLE_ICO.png                # 256KB
rm libisar.so                    # 1.2MB (موجود في المكتبة)

# ملفات توثيق تطوير
rm *_SUMMARY.md *_REPORT.md *_GUIDE.md
rm MIGRATION_*.* REFACTORING_*.*
```

### 4. تنظيف assets:
```bash
cd assets
# احتفظ فقط بـ:
# - icon/icon.png
# - images/app_icon.png
# - legal/*.md
# احذف الباقي
```

## ✅ قبل البناء:

### 1. تحديث الإصدار:
```yaml
# pubspec.yaml
version: 2.2.0+3291  # ✅ جاهز
```

### 2. فحص الأذونات:
```xml
# android/app/src/main/AndroidManifest.xml
- تأكد من الأذونات الضرورية فقط
- احذف أي أذونات غير مستخدمة
```

### 3. تفعيل ProGuard (اختياري):
```gradle
# android/app/build.gradle
release {
    minifyEnabled true
    shrinkResources true
}
```

### 4. البناء النهائي:
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

## 📦 الملف النهائي:
```
build/app/outputs/bundle/release/app-release.aab
```

## 🔐 ملاحظات أمنية:

1. ✅ `.gitignore` محدّث
2. ❌ يجب إزالة الملفات السرية من Git
3. ❌ يجب تغيير كلمة المرور المكشوفة
4. ✅ التوقيع معد بشكل صحيح
5. ⚠️ راجع Google OAuth credentials

## 📋 مراجعة نهائية:

- [ ] إزالة ملفات سرية من Git
- [ ] تغيير كلمات المرور
- [ ] حذف ملفات غير ضرورية
- [ ] تنظيف assets
- [ ] فحص الأذونات
- [ ] بناء AAB نهائي
- [ ] اختبار التطبيق
- [ ] رفع على Google Play Console

---

## ⚠️ تحذير:
**لا ترفع أي ملف يحتوي على:**
- كلمات مرور
- مفاتيح API
- شهادات
- keystores
- client secrets
