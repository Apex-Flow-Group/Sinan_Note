# 📋 Changelog - سنان نوت

---

## [3.0.5] - 2026-05 — تحسينات الأداء والتفاعل 🎯

> تحسينات جذرية في أداء الـ Checklist وتفاعل الـ Rich Note مع دعم ديناميكي لارتفاع الأسطر.

### ✨ ميزات جديدة
- **Checkbox تفاعلي في Rich Note** — الضغط على الـ checkbox يُبدّل حالته مباشرة في وضع التعديل
- **Checkbox مخصص بألوان النوتة** — شكل موحد في المحرر والعارض (أخضر عند الاكتمال)
- **ارتفاع سطر ديناميكي** — يتكيف تلقائياً مع حجم الخط ونوعه (Cairo/Tajawal أكبر)
- **فلتر وبحث في Import Sheet** — الخزنة تدعم الفلتر بالنوع والبحث عند استيراد النوتات
- **شريط فلتر في الخزنة** — فلتر بأنواع النوتات مع FilterChips
- **FAB لإضافة نوت في الخزنة** — bottom sheet نظيف بدل AddMenuWidget
- **تأثير active على أزرار التنسيق** — خلفية دائرية بلون النوت عند تفعيل Bold/Italic/H1/H2/List/Checklist

### 🔧 تحسينات
- **أداء Checklist** — `RepaintBoundary` + `AutomaticKeepAliveClientMixin` + تقليل rebuilds
- **Progress bar سلس** — `TweenAnimationBuilder` مع حفظ القيمة السابقة
- **تقليل rebuilds** — `onUndoRedoChanged` يُطلق فقط عند تغيير فعلي
- **`onChecklistTitleChanged` بدون setState** — يمنع إعادة بناء ChecklistEditor
- **`RepaintBoundary` حول content area** — يعزل الـ editor عن scroll progress rebuilds
- **Landscape padding** — حواف أصغر في وضع العرض الأفقي للـ checklist
- **إصلاح RTL cursor** — workaround لـ Flutter bug #107006 (cursor عند n-1)
- **Swipe defaults** — يمين = كاتالوج، يسار = مشاركة

### 🐛 إصلاحات
- إصلاح الـ checkbox الأسود في Rich Note (كان يستخدم theme colors)
- إصلاح التقاط الـ tap بالكامل على سطر checklist (الآن فقط منطقة الـ checkbox)
- إصلاح `ClampingScrollPhysics` + `keyboardDismissBehavior` في Checklist

---

## [3.0.4] - 2026-05 — آخر تحديث قبل الإطلاق النهائي 🚀

> أكثر نسخة مستقرة في مرحلة الوصول المبكر — النسخة النهائية في الطريق.

### ✨ ميزات جديدة
- **خيارات سحب مخصصة** — زر مخصص يفتح bottom sheet بخيارات قابلة للتخصيص (5 خيارات)
- **تذكير وكتالوج من السحب** — إضافة تذكير أو تصنيف مباشرة من سحب الكارد
- **دبلكيت من السحب** — نسخ الملاحظة بضغطة واحدة
- **فلتر بدون تصنيف** — عرض الملاحظات غير المصنفة من قائمة الفلتر
- **تصميم بتن شيت التذكير** — واجهة جديدة بألوان برتقالية وبطاقات واضحة
- **Key Debug** — قسم الإعدادات التجريبية يظهر فقط في وضع التطوير

### 🔧 تحسينات
- **المزامنة بعد الحفظ** — تستخدم `smartSyncOnStartup` بدل `uploadDatabase` لضمان merge ذكي
- **شريط الإشعارات** — لونه متطابق مع الأب بار في سلة المهملات
- **حجم الخط** — الافتراضي 1.0 ونطاق 0.8–1.3
- **أيقونات السحب** — أيقونة الاتجاه وأيقونة الخيار المختار في الإعدادات
- **سلة المهملات** — تفريغ السلة ببتن شيت بدل الديالوج

### 🐛 إصلاحات
- إصلاح عدم تطبيق الكتالوج عند السحب من الزر المخصص
- إصلاح Flexible داخل Flexible في AppBottomSheet
- إصلاح لون شريط الإشعارات في سلة المهملات
- إصلاح BuildContext across async gaps في editor_save_operations

### 🏗️ إعادة هيكلة
- تقسيم `editor_build_methods` لثلاثة ملفات: content و header و toolbar builders
- استخراج `ChecklistUndoRedoController` لملف مستقل
- استخراج `ReadOnlyChecklistView` و `DrawerModeBtn` و `CategoriesPanelWrapper`
- حذف `_buildChecklistPreview` المكررة من trash_screen
- نقل `TrashEmptySheet` لملف مستقل

---

## [3.0.3] - 2026-04

### ✨ ميزات جديدة
- **معاينة الكود** — زر تشغيل في المحرر يعرض SVG كصورة حقيقية، JSON منسق، وكل اللغات كـ preview منسق مع بحث ونسخ
- **تحميل الكود** — زر تحميل يحفظ الملف مباشرة في مجلد التنزيلات بالامتداد الصحيح لكل لغة
- **DB Inspector** — أداة فحص قواعد البيانات من داخل التطبيق (debug mode)
- **اختيار الخط** — sheet جديد مع معاينة فورية للخط قبل التطبيق
- **عرض اتجاه النص** — الكاردات في الصفحة الرئيسية تكتشف اتجاه النص تلقائياً (RTL/LTR)

### 🔧 تحسينات
- **Google Drive** — الـ subtitle في القائمة الجانبية يعكس حالة المزامنة التلقائية الفعلية
- **السحب للتحديث** — threshold أعلى (80px) مع progress bar تدريجي وتغذية بصرية واضحة
- **المزامنة عند السحب** — تمزامن مع Google Drive أولاً إذا كان المستخدم مسجلاً والإعداد مفعلاً
- **زر الإضافة** — ثابت في موضعه ولا يتحرك مع إخفاء شريط التنقل
- **الخط في المحرر** — تغيير الخط من الإعدادات ينعكس فوراً في محرر النصوص
- **فتح ملفات SVG** — يُفتح في المحرر بدل Rich Text
- **syntax highlighting** — يُطبق تلقائياً على كل اللغات في المحرر

### 🗄️ قاعدة البيانات
- **SQLite sync كامل** — مزامنة تلقائية عند كل تشغيل تشمل: notes, categories, note_versions, deleted_notes
- **جاهز للانتقال لـ React Native** — schema متطابق مع المسار الصحيح

### � إصلاحات
- إصلاح Floating SnackBar يظهر خارج الشاشة عند وجود bottom navigation bar
- إصلاح overflow في كاردات الصفحة الرئيسية
- إصلاح فتح ملفات SVG/YAML/TypeScript كـ Rich Text بدل المحرر
- إصلاح عدم تطبيق الخط على نص Quill editor

### 🏗️ إعادة هيكلة
- نقل `SlidableAutoCloser` و `HiddenCategoriesChip` لملفات منفصلة
- نقل `FontFamilySheet` لـ `settings/font_family_sheet.dart`
- إضافة `CodeExportService`, `CodePreviewService`, `SvgService` كخدمات مستقلة

---

## [3.0.2] - 2026-03

### ✨ ميزات
- نظام Google Drive sync كامل مع merge ذكي
- خزنة محمية بـ AES-256 + بيومتري
- محرر كود مع 25+ لغة و syntax highlighting
- نظام تذكيرات مع Exact Alarms
- كتالوجات مع Drawer ذكي
- Home Widget للشاشة الرئيسية
- تاريخ إصدارات الملاحظة
- Master-Details layout للشاشات الكبيرة
- Material You + ألوان ديناميكية

---

## [2.x] - 2025

- بناء الأساس: Clean Architecture مع Provider
- انتقال من ملف واحد 3000+ سطر إلى 50+ ملف
- نظام Toast موحد، بحث ذكي، Pagination
- دعم RTL/LTR كامل

---

## [1.0.0] - 2024

- إنشاء وتحرير الملاحظات
- الأرشيف وسلة المهملات
- البحث الأساسي
- الوضع الليلي
