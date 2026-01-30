# 🚀 دليل سريع: رفع على Google Play

## ⚡ خطوات سريعة (5 دقائق)

### 1️⃣ إزالة الملفات السرية من Git (إلزامي):
```bash
git rm --cached "client_secret_308129072326-2p8a46je0nl6sl7ljqe0mmrabc036a9k.apps.googleusercontent.com (1).json"
git rm --cached upload_certificate.pem
git commit -m "🔒 Remove sensitive credentials"
git push
```

### 2️⃣ تنظيف المشروع:
```bash
./clean_for_release.sh
```

### 3️⃣ بناء AAB:
```bash
./build_secure.sh
```

### 4️⃣ رفع على Google Play:
1. افتح [Google Play Console](https://play.google.com/console)
2. اختر التطبيق
3. Production → Create new release
4. ارفع: `build/app/outputs/bundle/release/app-release.aab`
5. املأ Release notes
6. Review → Start rollout

---

## 📋 ملفات مهمة:

- 📄 **SECURITY_AUDIT_REPORT.md** - تقرير أمان شامل
- 📄 **GOOGLE_PLAY_CHECKLIST.md** - قائمة تحقق كاملة
- 🔧 **clean_for_release.sh** - تنظيف المشروع
- 🔧 **build_secure.sh** - بناء آمن

---

## ⚠️ تحذيرات:

### 🔴 يجب حلها فوراً:
1. ❌ ملفات سرية في Git (client_secret, upload_certificate)
2. ⚠️ كلمة مرور مكشوفة في key.properties

### 🟡 اختياري (لكن موصى به):
1. تفعيل ProGuard (minifyEnabled)
2. إزالة sqflite بعد الترحيل الكامل
3. تحديث client_secret

---

## ✅ الحالة الحالية:

- ✅ الأذونات نظيفة
- ✅ التوقيع معد
- ✅ الإصدار محدث (2.2.0+3291)
- ❌ ملفات سرية في Git
- ⚠️ كلمة مرور مكشوفة

---

## 🆘 مشاكل؟

راجع:
- `SECURITY_AUDIT_REPORT.md` - تفاصيل الأمان
- `BUILD_GUIDE.md` - دليل البناء
- `GOOGLE_PLAY_CHECKLIST.md` - قائمة كاملة
