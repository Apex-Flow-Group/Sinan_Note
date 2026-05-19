# Changelog — سنان نوت

جميع التغييرات الجوهرية موثقة هنا. الصيغة مبنية على [Keep a Changelog](https://keepachangelog.com/ar/1.0.0/).

---

## [3.2.0] — 2026-05 | إعادة هيكلة شاملة + تحسينات الأمان

> 50+ تعديل، 8 جولات refactoring، 469/469 اختبار نجح.

### ✨ ميزات جديدة
- **Checklist محسّن** — سحب يساراً للحذف مع Undo، زر + واحد في الأسفل، gestures بدل أزرار
- **Vault Import Sheet** — ملف مستقل بواجهة محسّنة مع فلتر بالنوع والبحث
- **Cloud Sync Gateway** — طبقة مزامنة مستقلة (SyncEngine + SyncTransport)
- **createDefaultNote / createDefaultLockedNote / createSharedNote** — في Provider مباشرة

### 🔒 تحسينات الأمان
- **PBKDF2** رُفع من 10,000 إلى **100,000 iterations** مع migration تلقائي
- **`setPasswordAfterRecovery()`** منفصلة عن `changePassword()`
- **`isEncrypted()`** يفحص طول IV = 24 chars base64 (بدل فحص الطول البسيط)
- **`validateVaultPassword()`** توحيد 3 دوال تحقق في دالة واحدة

### 🔧 إصلاحات
- أول ملاحظة في الخزنة تظهر فوراً (إضافة `_onProviderChanged` listener)
- الخزنة تُفتح تلقائياً بعد الإعداد الأولي
- Desktop لا يعرض ملاحظات مشفرة (يقرأ `lockedNotes` بدل `activeNotes`)
- ترجمة وقت المزامنة تعمل بالعربية والإنجليزية
- نص hardcoded `'No notes'` → `l10n.noNotes`

### ⚡ أداء
- حذف الظل الملون (`blurRadius: 18`) من كل بطاقة — تحسين ملحوظ في السكرول
- `listen: false` في `PremiumCardEffect`
- `convertNoteType` حذف rebuild مزدوج
- cache لـ `reminderNotes` مع invalidation

### 🏗️ إعادة هيكلة
- `note_readonly_view.dart` من 944 سطر → ~320 سطر (استخراج `TrashFloatingSheet` + `ReadOnlyContent`)
- `VaultNavigator` — مركز تنقل الخزنة الوحيد
- `SqliteDatabaseService.getDbPath()` static — توحيد مسار DB في 3 ملفات
- `settings_provider.dart` — `_savePref()` helper يحذف 15+ استدعاء مكرر
- حذف 10 حالات كود ميت (ValueNotifiers، listeners فارغة، دوال غير مستخدمة)

---

## [3.0.5] — 2026-05 | تحسينات الأداء والتفاعل

### ✨ ميزات جديدة
- **Checkbox تفاعلي في Rich Note** — الضغط يبدّل الحالة مباشرة في وضع التعديل
- **Checkbox مخصص بألوان النوتة** — شكل موحد في المحرر والعارض
- **ارتفاع سطر ديناميكي** — يتكيف تلقائياً مع حجم الخط ونوعه
- **فلتر وبحث في Import Sheet** — الخزنة تدعم الفلتر بالنوع والبحث عند الاستيراد
- **شريط فلتر في الخزنة** — فلتر بأنواع الملاحظات مع FilterChips
- **FAB لإضافة نوت في الخزنة** — bottom sheet نظيف بدل AddMenuWidget
- **تأثير active على أزرار التنسيق** — خلفية دائرية بلون النوتة عند تفعيل Bold/Italic/H1/H2

### 🔧 إصلاحات
- إصلاح الـ checkbox الأسود في Rich Note (كان يستخدم theme colors)
- إصلاح التقاط الـ tap بالكامل على سطر checklist (الآن فقط منطقة الـ checkbox)
- إصلاح `ClampingScrollPhysics` + `keyboardDismissBehavior` في Checklist

---

## [3.0.4] — 2026-05 | آخر تحديث قبل الإطلاق النهائي

### ✨ ميزات جديدة
- **خيارات سحب مخصصة** — زر مخصص يفتح bottom sheet بخيارات قابلة للتخصيص (5 خيارات)
- **تذكير وكتالوج من السحب** — إضافة تذكير أو تصنيف مباشرة من سحب الكارد
- **دبلكيت من السحب** — نسخ الملاحظة بضغطة واحدة
- **فلتر بدون تصنيف** — عرض الملاحظات غير المصنفة من قائمة الفلتر
- **Key Debug** — قسم الإعدادات التجريبية يظهر فقط في وضع التطوير

### 🔧 إصلاحات
- إصلاح عدم تطبيق الكتالوج عند السحب من الزر المخصص
- إصلاح `BuildContext across async gaps` في editor_save_operations

---

## [3.0.3] — 2026-04 | محرر الكود + قاعدة البيانات

### ✨ ميزات جديدة
- **معاينة الكود** — زر تشغيل في المحرر يعرض SVG كصورة حقيقية، JSON منسق، وكل اللغات كـ preview
- **تحميل الكود** — زر تحميل يحفظ الملف مباشرة في التنزيلات بالامتداد الصحيح
- **DB Inspector** — أداة فحص قواعد البيانات من داخل التطبيق (debug mode)
- **اختيار الخط** — sheet جديد مع معاينة فورية للخط قبل التطبيق
- **عرض اتجاه النص** — الكاردات في الصفحة الرئيسية تكتشف اتجاه النص تلقائياً (RTL/LTR)

### 🗄️ قاعدة البيانات
- **SQLite sync كامل** — مزامنة تلقائية عند كل تشغيل تشمل: notes, categories, note_versions, deleted_notes
- **جاهز للانتقال لـ React Native** — schema متطابق مع المسار الصحيح

### 🔧 إصلاحات
- إصلاح Floating SnackBar يظهر خارج الشاشة عند وجود bottom navigation bar
- إصلاح overflow في كاردات الصفحة الرئيسية
- إصلاح فتح ملفات SVG/YAML/TypeScript كـ Rich Text بدل المحرر

---

## [3.0.2] — 2026-03 | الميزات الأساسية

### ✨ ميزات رئيسية
- نظام Google Drive sync كامل مع merge ذكي وحل التعارضات
- خزنة محمية بـ AES-256 + بيومتري + Rate Limiter
- محرر كود مع 25+ لغة وsyntax highlighting
- نظام تذكيرات مع Exact Alarms
- كتالوجات مع Drawer ذكي
- Home Widget للشاشة الرئيسية
- تاريخ إصدارات الملاحظة
- Master-Details layout للشاشات الكبيرة
- Material You + ألوان ديناميكية

---

## [2.x] — 2025 | البنية الأساسية

- بناء Clean Architecture مع Provider
- انتقال من ملف واحد 3000+ سطر إلى 50+ ملف
- نظام Toast موحد، بحث ذكي، Pagination
- دعم RTL/LTR كامل

---

## [1.0.0] — 2024 | الإصدار الأول

- إنشاء وتحرير الملاحظات
- الأرشيف وسلة المهملات
- البحث الأساسي
- الوضع الليلي

---

*Copyright © 2025–2026 Apex Flow Group. All rights reserved.*
