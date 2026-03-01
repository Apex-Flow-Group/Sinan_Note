# Sinan Note | سنان نوت

![Version](https://img.shields.io/badge/version-2.2.1-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B.svg?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Linux%20%7C%20Windows-lightgrey.svg)
![License](https://img.shields.io/badge/license-Proprietary-red.svg)

تطبيق تدوين ملاحظات آمن وسريع مبني بـ Flutter — متاح على Google Play.

---

## المميزات

| الميزة | التفاصيل |
|--------|---------|
| 🔐 خزنة ذكية | تشفير AES-256 + مصادقة بيومترية |
| 💻 محرر كود | 25+ لغة برمجية مع تلوين تلقائي |
| 📝 أنواع الملاحظات | نص / كود / قائمة مهام / تذكير |
| 🌍 ثنائي اللغة | عربي وإنجليزي مع دعم RTL/LTR |
| 🎨 Material You | ألوان ديناميكية + وضع ليلي/نهاري |
| 🔄 نسخ احتياطي | JSON محلي + Google Drive |
| 🖥️ سطح مكتب | تخطيط Master-Details للشاشات الكبيرة |

---

## هيكل المشروع

```
lib/
├── controllers/     # إدارة الحالة (Provider)
├── core/            # ثوابت، ثيمات، أدوات مشتركة
├── models/          # نماذج البيانات (Isar)
├── screens/         # الشاشات
├── services/        # منطق الأعمال
└── widgets/         # مكونات الواجهة
```

> راجع [`lib/README.md`](lib/README.md) للتفاصيل التقنية.

---

## التشغيل السريع

```bash
git clone https://github.com/apexflow/sinan-note.git
cd sinan-note
flutter pub get
flutter run
```

---

## التوثيق

| الملف | المحتوى |
|-------|---------|
| [`lib/README.md`](lib/README.md) | هيكل الكود والمعمارية |
| [`lib/services/README.md`](lib/services/README.md) | الخدمات والمنطق |
| [`lib/screens/README.md`](lib/screens/README.md) | الشاشات والتنقل |
| [`CHANGELOG.md`](CHANGELOG.md) | سجل التغييرات |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | دليل المساهمة |

---

## الترخيص

```
Copyright © 2025 Apex Flow Group. All rights reserved.
```
