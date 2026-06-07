<div align="right">

[🇬🇧 English](README.md)

</div>

<div align="center">

<img src="assets/images/app_icon.png" width="100" alt="Sinan Note Icon"/>

# Sinan Note | سنان نوت

**تطبيق تدوين ملاحظات آمن وسريع — مبني بـ Flutter**

[![Version](https://img.shields.io/badge/version-3.2.0-blue.svg)](https://github.com/Apex-Flow-Group/Sinan_Note/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)](#)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](#الترخيص)
[![SinanAi](https://img.shields.io/badge/SinanAi.net-التطبيقات%20المبتكرة-orange.svg)](https://sinanai.net/en)
[![Apex Flow](https://img.shields.io/badge/Apex%20Flow%20Group-الرسمي-blueviolet.svg)](https://apexflow.now/en)

[Google Play](https://play.google.com/store/apps/dev?id=5409981776310932919) · [الميزات](#الميزات) · [هيكل المشروع](#هيكل-المشروع) · [التشغيل](#التشغيل-السريع)

</div>

---

## الميزات

| الميزة | التفاصيل |
|--------|---------|
| 🔐 خزنة ذكية | تشفير AES-256 + مصادقة بيومترية + PBKDF2 (100,000 iterations) |
| 💻 محرر كود | 26 لغة برمجية مع syntax highlighting تلقائي |
| 👁️ معاينة الكود | SVG كصورة حقيقية، JSON منسق، preview لكل اللغات |
| 📥 تحميل الكود | حفظ مباشر في التنزيلات بالامتداد الصحيح |
| 📝 أنواع الملاحظات | نص / كود / قائمة مهام / تذكير / rich text |
| 🌍 ثنائي اللغة | عربي وإنجليزي مع دعم RTL/LTR تلقائي |
| 🎨 Material You | ألوان ديناميكية + وضع ليلي/نهاري |
| 🔄 Google Drive | مزامنة تلقائية مع merge ذكي وحل التعارضات |
| 🗂️ كتالوجات | تنظيم الملاحظات في مجموعات مع Drawer ذكي |
| 🖥️ سطح مكتب | تخطيط Master-Details للشاشات الكبيرة |
| 📱 Home Widget | عرض التذكيرات على الشاشة الرئيسية |
| 🕐 تاريخ الإصدارات | تتبع تعديلات كل ملاحظة (حتى 5 نسخ) |

---

## هيكل المشروع

```
lib/
├── controllers/          # إدارة الحالة (Provider)
│   ├── categories/       # CategoriesProvider
│   ├── editor/           # EditorStateManager
│   ├── notes/            # NotesProvider
│   └── settings/         # SettingsProvider
├── core/                 # ثوابت، ثيمات، أدوات مشتركة
│   ├── constants/
│   ├── shortcuts/        # اختصارات لوحة المفاتيح
│   ├── theme/
│   └── utils/            # NoteContentUtils, VaultNavigator, ...
├── models/               # نماذج البيانات (SQLite)
├── screens/
│   ├── auth/             # الخزنة: دخول، إعادة تعيين، بيومتري
│   ├── desktop/          # تخطيطات Responsive للشاشات الكبيرة
│   ├── mobile/           # الشاشات الرئيسية للموبايل
│   ├── onboarding/       # Splash، Tour، What's New
│   ├── shared/
│   │   ├── note_editor/  # محرر الملاحظات (مقسّم لـ 9 مجلدات)
│   │   ├── settings/     # الإعدادات (مقسّمة)
│   │   └── tabs/         # Code Tab، Reminder Dashboard
│   └── sync/             # Google Drive
├── services/             # منطق الأعمال
│   ├── cloud/            # Google Drive Auth + Merge
│   ├── security/         # تشفير + بيومتري + Rate Limiter
│   ├── storage/          # SQLite + Backup + DB Inspector
│   ├── sync/             # Cloud Sync Gateway
│   └── note_services/    # CRUD + Security + Side Effects
└── widgets/              # مكونات الواجهة
    ├── editor/           # Toolbar، CodeEditor، ChecklistEditor
    ├── home/             # NoteCard، Grid، Drawer، SmartHeader
    └── common/           # مكونات مشتركة
```

---

## قاعدة البيانات

التطبيق يستخدم **SQLite** (sqflite) كقاعدة بيانات رئيسية:

```
SQLite (sinan_notes.db)
├── notes              — الملاحظات الرئيسية
├── categories         — الكتالوجات
├── note_versions      — تاريخ الإصدارات
└── deleted_notes      — سجل الحذف للمزامنة الذكية
```

> قاعدة البيانات جاهزة للانتقال لـ React Native بنفس الـ schema.

---

## التشغيل السريع

```bash
git clone https://github.com/Apex-Flow-Group/Sinan_Note.git
cd Sinan_Note
flutter pub get
flutter run
```

### متطلبات البناء

| المتطلب | الإصدار |
|---------|---------|
| Flutter SDK | 3.0+ |
| Dart SDK | 3.0+ |
| Android SDK | compileSdk 36 / targetSdk 35 |

### تشغيل الاختبارات

```bash
flutter test
flutter analyze
```

> **469 اختبار** — 100% نجاح ✅

---

## الأمان

بنية التشفير في الخزنة:

```
طبقة 1 — كلمة المرور
    PBKDF2-SHA256 (100,000 iterations) → مفتاح مشتق (32 bytes)

طبقة 2 — Master Key
    AES-256-CBC → مخزّن في FlutterSecureStorage (Android Keystore)

طبقة 3 — محتوى الملاحظة
    AES-256-CBC + IV عشوائي → "iv_base64:ciphertext_base64"
```

- Rate Limiter تصاعدي: 5 محاولات → قفل 15 دقيقة → 60 دقيقة
- الخزنة لا تُرفع إلى Google Drive أبداً
- Clipboard Guard يمنع نسخ المحتوى المشفر

---

## الإحصاءات

| المقياس | القيمة |
|---------|--------|
| ملفات Dart | 244 ملف |
| أسطر الكود | ~53,144 سطر |
| Widgets | 187 (97 Stateful + 90 Stateless) |
| اختبارات | 469 اختبار |
| مفاتيح الترجمة | ~695 مفتاح (AR + EN) |
| التبعيات | 33 حزمة |
| Commits | 162+ commit |

---

## الترخيص

```
Copyright © 2025–2026 Apex Flow Group. All rights reserved.
```

هذا المشروع مرخص بشكل خاص. جميع الحقوق محفوظة لـ Apex Flow Group.

---

<div align="center">

**[SinanAi.net](https://sinanai.net/en) — التطبيقات المبتكرة &nbsp;·&nbsp; [Apex Flow Group](https://apexflow.now/en) — الرسمي**

</div>
