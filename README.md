# Sinan Note | سنان نوت

![Version](https://img.shields.io/badge/version-3.0.3-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)
![License](https://img.shields.io/badge/license-Proprietary-red.svg)

تطبيق تدوين ملاحظات آمن وسريع مبني بـ Flutter — متاح على Google Play.

---

## المميزات

| الميزة | التفاصيل |
|--------|---------|
| 🔐 خزنة ذكية | تشفير AES-256 + مصادقة بيومترية |
| 💻 محرر كود | 25+ لغة برمجية مع syntax highlighting تلقائي |
| 👁️ معاينة الكود | SVG كصورة حقيقية، JSON منسق، preview لكل اللغات |
| 📥 تحميل الكود | حفظ مباشر في التنزيلات بالامتداد الصحيح |
| 📝 أنواع الملاحظات | نص / كود / قائمة مهام / تذكير / rich text |
| 🌍 ثنائي اللغة | عربي وإنجليزي مع دعم RTL/LTR تلقائي |
| 🎨 Material You | ألوان ديناميكية + وضع ليلي/نهاري |
| 🔄 Google Drive | مزامنة تلقائية مع merge ذكي |
| �️ كتالوجات | تنظيم الملاحظات في مجموعات مع Drawer ذكي |
| �🖥️ سطح مكتب | تخطيط Master-Details للشاشات الكبيرة |
| 📱 Home Widget | عرض التذكيرات على الشاشة الرئيسية |
| 🕐 تاريخ الإصدارات | تتبع تعديلات كل ملاحظة |

---

## هيكل المشروع

```
lib/
├── controllers/          # إدارة الحالة (Provider)
│   ├── categories/
│   ├── notes/
│   └── settings/
├── core/                 # ثوابت، ثيمات، أدوات مشتركة
│   ├── constants/
│   ├── theme/
│   └── utils/
├── models/               # نماذج البيانات (Isar)
├── screens/              # الشاشات
│   ├── mobile/
│   ├── desktop/
│   ├── shared/
│   │   ├── note_editor/  # محرر الملاحظات (مقسّم)
│   │   ├── note_view/    # عارض الملاحظات
│   │   ├── settings/     # إعدادات (مقسّمة)
│   │   └── tabs/
│   └── other/
├── services/             # منطق الأعمال
│   ├── cloud/            # Google Drive
│   ├── security/         # تشفير + بيومتري
│   ├── storage/          # Isar + SQLite migration
│   └── note_services/
└── widgets/              # مكونات الواجهة
    ├── editor/
    ├── home/
    │   └── note_card/    # كاردات الملاحظات
    └── common/
```

---

## قاعدة البيانات

التطبيق يستخدم **Isar** كقاعدة بيانات رئيسية، مع مزامنة تلقائية لـ **SQLite** عند كل تشغيل:

```
Isar (رئيسية) ──sync──► SQLite (sinan_notes.db)
                          ├── notes
                          ├── categories
                          ├── note_versions
                          └── deleted_notes
```

SQLite جاهزة للانتقال لـ React Native بنفس الـ schema.

---

## التشغيل السريع

```bash
git clone https://github.com/apexflow/sinan-note.git
cd sinan-note
flutter pub get
flutter run
```

### متطلبات البناء
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android SDK (للأندرويد)

---

## التوثيق

| الملف | المحتوى |
|-------|---------|
| [`lib/README.md`](lib/README.md) | هيكل الكود والمعمارية |
| [`CHANGELOG.md`](CHANGELOG.md) | سجل التغييرات |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | دليل المساهمة |
| [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) | سياسة الخصوصية |

---

## الترخيص

```
Copyright © 2025 Apex Flow Group. All rights reserved.
```
