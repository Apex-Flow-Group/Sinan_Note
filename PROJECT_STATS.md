# 📊 تقرير إحصاءات المشروع — Sinan Note
> تاريخ التقرير: مايو 2026 | الإصدار: 3.0.4+3355

---

## 🏷️ معلومات المشروع

| الحقل | القيمة |
|-------|--------|
| اسم المشروع | Sinan Note (apex_note) |
| الإصدار | 3.0.4+3355 |
| إطار العمل | Flutter 3.0+ / Dart 3.0+ |
| المنصات | Android · Linux · Windows |
| compileSdk | 36 |
| targetSdk | 35 |
| تاريخ أول commit | ديسمبر 2025 |
| تاريخ آخر commit | مايو 2026 |
| إجمالي الـ commits | 130 commit |

---

## 📁 هيكل المجلدات

| المجلد | عدد المجلدات الفرعية | عدد الملفات | الأسطر |
|--------|---------------------|-------------|--------|
| `lib/screens/` | 20 | 91 | 20,477 |
| `lib/widgets/` | 10 | 77 | 15,930 |
| `lib/services/` | 7 | 34 | 6,724 |
| `lib/core/` | 4 | 14 | 1,050 |
| `lib/controllers/` | 4 | 4 | 1,040 |
| `lib/models/` | — | 6 | 344 |
| `lib/providers/` | — | 1 | — |
| **المجموع** | **64 مجلد** | **228 ملف** | **~46,000** |

---

## 📄 إحصاءات الملفات

### حسب النوع

| النوع | العدد | الأسطر |
|-------|-------|--------|
| Dart (مكتوب يدوياً) | 228 | 46,046 |
| Dart (مولّد `.g.dart`) | 3 | 5,414 |
| Dart (ترجمات `l10n`) | 3 | 7,583 |
| ARB (ملفات الترجمة) | 2 | 1,278 |
| **إجمالي Dart** | **234** | **59,043** |

### أكبر 15 ملفاً (مكتوب يدوياً)

| الملف | الأسطر |
|-------|--------|
| `screens/mobile/locked_notes_screen.dart` | 721 |
| `screens/shared/note_editor.dart` | 697 |
| `widgets/editor/checklist_editor.dart` | 644 |
| `widgets/home/note_card_widget.dart` | 591 |
| `screens/shared/tabs/reminder_dashboard.dart` | 585 |
| `widgets/home/home_drawer_widget.dart` | 564 |
| `widgets/home/categories_panel.dart` | 538 |
| `screens/onboarding/tour_screen.dart` | 537 |
| `screens/other/support_form_screen.dart` | 536 |
| `screens/shared/backup_wizard_screen.dart` | 535 |
| `screens/desktop/home_screen_responsive.dart` | 531 |
| `services/unified_notification_service.dart` | 521 |
| `widgets/editor/reminder_picker_sheet.dart` | 509 |
| `screens/shared/tabs/code_tab.dart` | 496 |
| `screens/shared/note_editor/view/note_readonly_view.dart` | 494 |

---

## 🧩 إحصاءات الكود

| المقياس | القيمة |
|---------|--------|
| StatefulWidget | 84 |
| StatelessWidget | 61 |
| إجمالي الـ Widgets | 145 |
| ملفات تستخدم Provider | 82 |
| مفاتيح الترجمة (AR + EN) | ~312 مفتاح |

---

## 🗂️ تصنيف الشاشات

| التصنيف | الملفات |
|---------|---------|
| `screens/shared/` | محرر الملاحظات، الإعدادات، التبويبات، العارض |
| `screens/mobile/` | الرئيسية، الخزنة، المهملات، الأرشيف |
| `screens/desktop/` | تخطيط Master-Details |
| `screens/auth/` | فتح الخزنة، المقدمة |
| `screens/onboarding/` | جولة التعريف، الشاشة السينمائية |
| `screens/sync/` | Google Drive |
| `screens/other/` | الدعم، سجل الإصدارات |

---

## 📦 التبعيات (Dependencies)

### الرئيسية
| الحزمة | الغرض |
|--------|--------|
| `flutter_quill` | محرر Rich Text |
| `isar` | قاعدة البيانات الرئيسية |
| `sqflite` | قاعدة SQLite للمزامنة |
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
| `isar_generator` + `build_runner` | توليد كود Isar |
| `flutter_launcher_icons` | أيقونة التطبيق |
| `flutter_lints` | جودة الكود |

**إجمالي التبعيات: 35 حزمة**

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
| العربية | `intl_ar.arb` | ~639 |
| الإنجليزية | `intl_en.arb` | ~639 |
| **إجمالي المفاتيح** | | **~312 مفتاح** |

---

## 🧪 الاختبارات

### إحصاءات

| المقياس | القيمة |
|---------|--------|
| ملفات الاختبار | 24 ملف |
| إجمالي أسطر الاختبارات | 5,099 سطر |
| نسبة الاختبارات للكود | ~11% |
| إجمالي الاختبارات | 364 |
| ناجح | 268 |
| فاشل (بيئة Linux) | 77 |
| فاشل (اختبارات قديمة) | 19 |

### أكبر ملفات الاختبار

| الملف | الأسطر |
|-------|--------|
| `unit/services/google_drive_service_test.dart` | 480 |
| `unit/services/note_batch_operations_service_test.dart` | 477 |
| `unit/controllers/editor_state_manager_test.dart` | 434 |
| `unit/services/smart_analyzer_test.dart` | 380 |
| `integration/note_editor_integration_test.dart` | 378 |
| `integration/notes_provider_integration_test.dart` | 347 |
| `unit/services/isar_database_service_test.dart` | 343 |
| `services/vault_service_test.dart` | 339 |
| `unit/services/note_state_service_test.dart` | 313 |
| `unit/services/note_side_effect_service_test.dart` | 276 |

### تصنيف الاختبارات

| النوع | الملفات | الأسطر |
|-------|---------|--------|
| Unit (services) | 14 | 2,927 |
| Unit (controllers) | 1 | 434 |
| Integration | 2 | 725 |
| Widget | 1 | 40 |
| Performance | 1 | 119 |
| Property | 1 | 72 |
| Stress (integration_test) | 1 | 60 |
| Memory | 1 | 205 |
| Setup + Vault | 2 | 419 |
| **المجموع** | **24** | **5,099** |

---

## ✅ ملخص للإطلاق

```
الكود المكتوب يدوياً  : 46,046 سطر في 228 ملف
إجمالي كود Dart       : 59,043 سطر في 234 ملف
المجلدات              : 64 مجلد
الـ Widgets           : 145 (84 Stateful + 61 Stateless)
التبعيات              : 35 حزمة
الأصول               : 9 ملفات (5 خطوط + 2 أيقونة + 2 متجر)
الترجمة               : عربي + إنجليزي (~312 مفتاح)
الـ commits           : 130 commit (ديسمبر 2025 → مايو 2026)
الإصدار               : 3.0.4+3355
الاختبارات            : 364 اختبار في 5,099 سطر (268 ناجح)
```

---

*Copyright © 2025–2026 Apex Flow Group. All rights reserved.*
