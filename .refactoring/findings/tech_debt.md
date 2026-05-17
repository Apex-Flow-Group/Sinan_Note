# ديون تقنية

_(سيُملأ أثناء التحليل)_

## 1. searchNotes لا تستخدم النص المطبّع

**تاريخ الاكتشاف:** 2026-05-15
**الحالة:** ✅ تم الإصلاح

### الملف
`lib/services/note_services/note_state_service.dart`

### المشكلة
البحث كان يستخدم `title.toLowerCase()` بدلاً من `normalizedTitle` — يفشل مع التشكيل وتنويعات الألف.

### الحل
استبدال `title.toLowerCase().contains(lowerQuery)` بـ `normalizedTitle.contains(Note.normalize(query))`.

### التحقق: ✅ 29 اختبار نجح (4 اختبارات جديدة للبحث العربي)

## 2. مسار DB خاطئ في VaultResetService (بق حقيقي)

**تاريخ الاكتشاف:** 2026-05-15
**الحالة:** ✅ تم الإصلاح

### الملف
`lib/services/security/vault_reset_service.dart`

### المشكلة
`_getDbPath()` كانت تبحث عن `sinan_notes.isar` (قاعدة Isar القديمة) بينما التطبيق يستخدم `sinan_notes.db` (SQLite). النسخ الاحتياطي والاستعادة كانا معطلين تماماً.

### الحل
تصحيح المسار ليستخدم `getDatabasesPath()` على Android و `getApplicationDocumentsDirectory()` على باقي المنصات مع الاسم الصحيح `.db`.

### التحقق: ✅ 331 اختبار نجح

## 3. checkForRemoteUpdates كود ميت في GoogleDriveService

**تاريخ الاكتشاف:** 2026-05-15
**الحالة:** ✅ تم الإصلاح

### الملف
`lib/services/cloud/google_drive_service.dart`

### المشكلة
`checkForRemoteUpdates()` كانت instance method على class ثابت بالكامل (كل الدوال الأخرى `static`). لم تُستدعَ في أي مكان في المشروع.

### الحل
حذف الدالة كلياً.

### التحقق: ✅ 330/330 unit

## 4. تسميات Isar مضللة في DbInspectorService

**تاريخ الاكتشاف:** 2026-05-15
**الحالة:** ✅ تم الإصلاح

### الملف
`lib/services/storage/db_inspector_service.dart`

### المشكلة
بعد migration من Isar إلى SQLite، بقيت التسميات القديمة: التعليق في الكود `// ── Isar ──`، مفتاح `result['isar']`، وعنوان التقرير `── ISAR ──` — كلها تشير إلى `SqliteDatabaseService` فعلياً.

### الحل
تحديث جميع التسميات لتعكس الواقع: `notes_summary` بدلاً من `isar`، و`── NOTES SUMMARY ──` في التقرير.

### التحقق: ✅ 330/330 unit


## 5. تقطيع السكرول في محرر الـ Checklist — scrollProgress يُعيد بناء الـ header

**تاريخ الاكتشاف:** 2026-05-17
**الحالة:** ⚠️ مشكلة معروفة — إصلاح جزئي مُطبَّق

### الملفات المتأثرة
- `lib/screens/shared/note_editor.dart` — `NotificationListener` يُحدّث `scrollProgress`
- `lib/screens/shared/note_editor/core/editor_header_builder.dart` — `ValueListenableBuilder` يُعيد بناء الـ header
- `lib/widgets/editor/apex_editor_header.dart` — كان يحتوي 4-5 `TweenAnimationBuilder`

### المشكلة
عند السكرول في محرر الـ Checklist، أول ~120px (3 عناصر تقريباً) تُسبب تقطيع فظيع:

1. `NotificationListener<ScrollNotification>` يُطلق في كل scroll frame (~60/ثانية)
2. يُحدّث `scrollProgress.value` (ValueNotifier)
3. `ValueListenableBuilder` في `EditorHeaderBuilder` يُعيد بناء الـ header بالكامل
4. `ApexEditorHeader` كان يحتوي 4-5 `TweenAnimationBuilder` — كل واحد يُعاد إنشاؤه مع كل rebuild
5. بعد 120px يثبت `scrollProgress` على 1.0 ولا يُطلق rebuilds → السكرول يصبح سلس

### الإصلاح الجزئي المُطبَّق
1. **`note_editor.dart`**: quantize `scrollProgress` إلى 5 خطوات فقط (0.0, 0.2, 0.4, 0.6, 0.8, 1.0) بدلاً من قيمة مستمرة — يقلل الـ rebuilds من ~60 إلى ~5 أثناء السكرول
2. **`apex_editor_header.dart`**: حذف 4-5 `TweenAnimationBuilder` (كانت fade-in لمرة واحدة) — يجعل كل rebuild رخيص

### الأثر الجانبي
تأثير تغيير لون الـ header أصبح متقطع (5 خطوات) بدلاً من تدريجي سلس.

### الحل المثالي (لم يُنفَّذ)
فصل طبقة اللون عن محتوى الـ header:
- `ColoredBox` يتغير مع `scrollProgress` (repaint فقط — رخيص)
- محتوى الـ header (أيقونات، عنوان) يُبنى مرة واحدة ولا يُعاد بناؤه

هذا يتطلب إعادة هيكلة `ApexEditorHeader` ليقبل `backgroundColor` كـ `ValueNotifier<Color>` أو فصل الخلفية عن المحتوى في `EditorHeaderBuilder`.

**التقييم: 5** — قابل للتنفيذ لكن يحتاج تغيير في بنية الـ header.
