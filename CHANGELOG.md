# 📋 Changelog - سنان نوت

---

## [2.3.0] - 2025-04 (قيد التطوير)

### ✨ ميزات جديدة

#### 🗂️ نظام الكتالوجات
- اختيار كتالوج من شريط التاريخ مباشرة (bottom sheet)
- كتالوج افتراضي للملاحظات المحترفة (`kProCategoryId = -1`)
- عرض اسم الكتالوج المختار مع زر إغلاق سريع

#### 🎨 تحسينات الواجهة
- إصلاح لون شريط البحث في Dark Mode (كان يظهر داكناً عند أول فتح)
- إصلاح خلفية `SmoothSearchHeaderDelegate` عند تحميل الثيم
- تكبير مساحة النقر على زر X في شريط الكتالوج
- إعادة تصميم شريط الاستعادة في السلة (زران متساويان محترفان)
- إصلاح عرض النص الخام في السلة (كان يظهر Delta JSON)

#### ⚡ تحسينات الأداء
- رفع `cacheExtent` من 200 إلى 1500 لتقليل التقطيع مع 600+ نوت
- `BouncingScrollPhysics` مع `ScrollDecelerationRate.fast`
- شريط التمرير يعرف الإجمالي الحقيقي للنوتات (بدل الـ pagination فقط)
- animation ناعم للشريط عند تحميل batch جديد

### 🔧 تحسينات تقنية

#### NoteContentUtils — ملف موحد جديد
```
lib/core/utils/note_content_utils.dart
```
يحل مشكلة تكرار منطق تحويل Delta JSON في 7 ملفات مختلفة.
كل الملفات الآن تستخدم:
```dart
NoteContentUtils.toDisplayText(content)
```

#### الملفات المحدّثة:
- `note_card_utils.dart` — يستخدم NoteContentUtils
- `note_view_widgets.dart` — يستخدم NoteContentUtils
- `trash_screen.dart` — إصلاح عرض النص الخام
- `version_history_screen.dart` — يستخدم NoteContentUtils
- `note_history_sheet.dart` — يستخدم NoteContentUtils
- `versions_bottom_sheet.dart` — يستخدم NoteContentUtils
- `widget_selection_screen.dart` — يستخدم NoteContentUtils
- `isar_database_service.dart` — يستخدم NoteContentUtils

### 🗑️ إزالة
- حذف زر "تأثير اللمعة" من الإعدادات (`cardMotionEnabled`)
- حذف كل الكود المتعلق به من `settings_provider.dart`، `note_card_widget.dart`، `notes_grid.dart`

### 🐛 إصلاحات
- شريط الأرشيف: الأزرار تبقى ظاهرة عند إلغاء تحديد الكل (تُعطَّل بدل الاختفاء)
- صفحة التراخيص: تعرض أيقونة التطبيق الصحيحة
- كتالوج المحترف: يعرض الاسم الصحيح بدل فراغ
- `note_view_screen.dart`: عرض النوت حسب نوعها (كود/checklist/عادي)

---

## [2.2.1] - 2025-03

### ✨ ميزات
- نظام كتالوجات كامل مع Drawer
- Home Widget للشاشة الرئيسية
- تاريخ إصدارات الملاحظة (Version History)
- شريط تمرير مخصص مع fade animation
- شريط تاريخ ذكي مع القفز لتاريخ محدد

### 🔧 تحسينات
- Pagination للقائمة الرئيسية (100 نوت/صفحة)
- بحث ذكي مع Levenshtein distance
- Master-Details layout للشاشات الكبيرة

---

## [2.2.0] - 2025-01

### ✨ ميزات
- نسخ الملاحظة (Make a Copy)
- حفظ باسم (Save As)
- فتح ملفات برمجية مباشرة
- Google Drive sync

### 🔧 تحسينات
- انتقال كامل لـ Flutter ARB للترجمة
- نظام Toast موحد (`UnifiedNotificationService`)

---

## [2.1.1] - 2025-01 (النسخة الذهبية)

### ✨ ميزات
- خزنة ذكية AES-256 + بيومتري
- محرر كود مع Syntax Highlighting (25+ لغة)
- نظام تذكيرات مع Exact Alarms
- Material You + ألوان ديناميكية
- دعم RTL/LTR كامل

### 🏗️ إعادة هيكلة
- من ملف واحد 3000+ سطر إلى 50+ ملف
- Clean Architecture مع Provider
- Slivers + Lazy Loading

---

## [2.0.0] - 2024-12

- نظام الخزنة الأساسي
- محرر الكود
- نظام التذكيرات
- إعادة تصميم الواجهة

---

## [1.0.0] - 2024

- إنشاء وتحرير الملاحظات
- الأرشيف وسلة المهملات
- البحث الأساسي
- الوضع الليلي
