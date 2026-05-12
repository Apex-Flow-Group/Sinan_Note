# 📊 تقرير إحصاءات المشروع — Sinan Note
> تاريخ التقرير: مايو 2026 | الإصدار: 3.1.0+3369

---

## 🏷️ معلومات المشروع

| الحقل | القيمة |
|-------|--------|
| اسم المشروع | Sinan Note (apex_note) |
| الإصدار | 3.1.0+3369 |
| إطار العمل | Flutter 3.0+ / Dart 3.0+ |
| المنصات | Android · Linux · Windows |
| compileSdk | 36 |
| targetSdk | 35 |
| تاريخ أول commit | ديسمبر 2025 |
| تاريخ آخر commit | مايو 2026 |
| إجمالي الـ commits | 148+ commit |

---

## 📁 هيكل المجلدات

| المجلد | عدد الملفات | الأسطر |
|--------|-------------|--------|
| `lib/screens/` | 93 | 21,134 |
| `lib/widgets/` | 78 | 15,419 |
| `lib/services/` | 37 | 6,563 |
| `lib/controllers/` | 4 | 1,041 |
| `lib/core/` | 14 | 935 |
| `lib/models/` | 6 | 309 |
| `lib/providers/` | 1 | — |
| **المجموع** | **~233 ملف** | **~46,000** |

---

## 📄 إحصاءات الملفات

### حسب النوع

| النوع | العدد | الأسطر |
|-------|-------|--------|
| Dart (مكتوب يدوياً) | 237 | 52,328 |
| Dart (مولّد `.g.dart`) | 0 | 0 |
| Dart (ترجمات `l10n`) | — | 1,400 |
| ARB (ملفات الترجمة) | 2 | 1,400 |
| **إجمالي Dart** | **237** | **~53,728** |

### أكبر 15 ملفاً (مكتوب يدوياً)

| الملف | الأسطر |
|-------|--------|
| `screens/shared/note_editor.dart` | 699 |
| `screens/mobile/locked_notes_screen.dart` | 684 |
| `screens/shared/note_editor/view/note_readonly_view.dart` | 682 |
| `screens/auth/pin_lock_screen.dart` | 635 |
| `screens/auth/vault_reset_screen.dart` | 590 |
| `widgets/editor/checklist_editor.dart` | 582 |
| `widgets/home/note_card_widget.dart` | 572 |
| `widgets/home/dialogs/vault_dialogs.dart` | 564 |
| `widgets/home/home_drawer_widget.dart` | 558 |
| `screens/shared/tabs/reminder_dashboard.dart` | 549 |
| `screens/onboarding/tour_screen.dart` | 508 |
| `widgets/home/categories_panel.dart` | 508 |
| `screens/shared/backup_wizard_screen.dart` | 508 |
| `screens/other/support_form_screen.dart` | 504 |
| `screens/shared/note_editor/core/editor_toolbar_builder.dart` | 502 |

---

## 🧩 إحصاءات الكود

| المقياس | القيمة |
|---------|--------|
| StatefulWidget | 95 |
| StatelessWidget | 88 |
| إجمالي الـ Widgets | 183 |
| ملفات تستخدم Provider | 59 |
| مفاتيح الترجمة (AR + EN) | ~679 مفتاح |

---

## 🗂️ تصنيف الشاشات

| التصنيف | الملفات |
|---------|---------|
| `screens/shared/` | محرر الملاحظات، الإعدادات، التبويبات، العارض |
| `screens/mobile/` | الرئيسية، الخزنة، المهملات، الأرشيف |
| `screens/desktop/` | تخطيط Master-Details |
| `screens/auth/` | فتح الخزنة، إعادة التعيين، المقدمة |
| `screens/onboarding/` | جولة التعريف، الشاشة السينمائية |
| `screens/sync/` | Google Drive |
| `screens/other/` | الدعم، سجل الإصدارات |

---

## 📦 التبعيات (Dependencies)

### الرئيسية
| الحزمة | الغرض |
|--------|--------|
| `flutter_quill` | محرر Rich Text |
| `isar` | ~~قاعدة البيانات~~ — **حُذف (ترحيل لـ SQLite)** |
| `sqflite` | قاعدة البيانات الرئيسية (SQLite) |
| `provider` | إدارة الحالة |
| `google_sign_in` + `googleapis` | Google Drive |
| `local_auth` | المصادقة البيومترية |
| `encrypt` + `crypto` | تشفير AES-256 |
| `flutter_local_notifications` | التذكيرات |
| `home_widget` | ويدجت الشاشة الرئيسية |
| `flutter_code_editor` | محرر الكود |
| `dynamic_color` | Material You |
| `flutter_secure_storage` | تخزين آمن |
| `flutter_slidable` | إجراءات السحب |
| `flutter_svg` | عرض SVG |
| `flutter_markdown_plus` | عرض Markdown |
| `share_plus` | المشاركة |
| `in_app_update` | التحديث التلقائي |

### Dev
| الحزمة | الغرض |
|--------|--------|
| `isar_generator` + `build_runner` | ~~توليد كود Isar~~ — **حُذف** |
| `flutter_launcher_icons` | أيقونة التطبيق |
| `flutter_lints` | جودة الكود |

**إجمالي التبعيات: 33 حزمة**

---

## 🎨 الأصول (Assets)

| الملف | النوع |
|-------|-------|
| `assets/icon/icon.png` | أيقونة التطبيق |
| `assets/images/app_icon.png` | صورة التطبيق |
| `assets/fonts/Cairo-Variable.ttf` | خط Cairo |
| `assets/fonts/Tajawal-Bold.ttf` | خط Tajawal Bold |
| `assets/fonts/Tajawal-Medium.ttf` | خط Tajawal Medium |
| `assets/fonts/Tajawal-Regular.ttf` | خط Tajawal Regular |
| `assets/fonts/Vazirmatn-Variable.ttf` | خط Vazirmatn |
| `assets/store/GOOGLE_PLAY_DESCRIPTION_AR.txt` | وصف المتجر AR |
| `assets/store/GOOGLE_PLAY_DESCRIPTION_EN.txt` | وصف المتجر EN |

**إجمالي الأصول: 9 ملفات**

---

## 💾 أحجام المجلدات

| المجلد | الحجم |
|--------|-------|
| `lib/` | 2.5 MB |
| `assets/` | 1.1 MB |
| `packages/` (flutter_quill محلي) | 7.2 MB |
| `android/` | 82 MB |

---

## 🌍 الترجمة

| اللغة | الملف | الأسطر |
|-------|-------|--------|
| العربية | `app_ar.arb` | 700 |
| الإنجليزية | `app_en.arb` | 700 |
| **إجمالي المفاتيح** | | **~679 مفتاح** |

---

## 🧪 الاختبارات

### إحصاءات

| المقياس | القيمة |
|---------|--------|
| ملفات الاختبار | 25 ملف |
| إجمالي أسطر الاختبارات | 4,605 سطر |
| نسبة الاختبارات للكود | ~9% |
| إجمالي الاختبارات | 359 |

### أكبر ملفات الاختبار

| الملف | الأسطر |
|-------|--------|
| `unit/services/google_drive_service_test.dart` | 406 |
| `unit/services/note_batch_operations_service_test.dart` | 398 |
| `unit/controllers/editor_state_manager_test.dart` | 349 |
| `unit/services/smart_analyzer_test.dart` | 319 |
| `integration/note_editor_integration_test.dart` | 302 |
| `integration/notes_provider_integration_test.dart` | 296 |
| `services/vault_service_test.dart` | 291 |
| `unit/services/isar_database_service_test.dart` | 279 |
| `unit/services/note_state_service_test.dart` | 272 |
| `unit/services/note_side_effect_service_test.dart` | 238 |

### تصنيف الاختبارات

| النوع | الملفات | الأسطر |
|-------|---------|--------|
| Unit (services) | 14 | 2,682 |
| Unit (controllers) | 1 | 349 |
| Integration | 2 | 598 |
| Security | 2 | 396 |
| Widget | 1 | 35 |
| Performance | 1 | 96 |
| Property | 1 | 60 |
| Memory | 1 | 170 |
| Setup + Vault | 2 | 219 |
| **المجموع** | **25** | **4,605** |

---

## ✅ ملخص للإطلاق

```
الكود المكتوب يدوياً  : 52,328 سطر في 237 ملف
إجمالي كود Dart       : ~53,728 سطر في 237 ملف
المجلدات              : 62 مجلد
الـ Widgets           : 183 (95 Stateful + 88 Stateless)
التبعيات              : 33 حزمة
الأصول               : 9 ملفات (5 خطوط + 2 أيقونة + 2 متجر)
الترجمة               : عربي + إنجليزي (~679 مفتاح)
الـ commits           : 148+ commit (ديسمبر 2025 → مايو 2026)
الإصدار               : 3.1.0+3369
الاختبارات            : 359 اختبار في 4,605 سطر
```

---

*Copyright © 2025–2026 Apex Flow Group. All rights reserved.*
