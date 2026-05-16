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
