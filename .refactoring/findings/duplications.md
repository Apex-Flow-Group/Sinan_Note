# ازدواجيات في الكود

---

## 1. isEncrypted

**تاريخ الاكتشاف:** 2026-05-15
**الأولوية:** منخفضة
**الملفات المتأثرة:**
- `lib/models/note.dart` — `bool get isEncrypted`
- `lib/services/security/vault_service.dart` — `static bool isEncrypted(String text)`

### الوصف
نفس المنطق (التحقق من نمط `iv:ciphertext`) موجود في مكانين:
- كـ getter في Note model
- كـ static method في VaultService

كود الإنتاج يستخدم `VaultService.isEncrypted()` حصرياً.
`Note.isEncrypted` يُستخدم في الاختبارات فقط.

### التأثير
- لا مشكلة وظيفية حالياً
- إذا تغير منطق التشفير، يجب تحديث مكانين
- ارتباك محتمل للمطور: أيهما يستخدم؟

### القرار
⏳ ينتظر

---

## 2. منطق Delta مكرر في editor_coordinator

**تاريخ الاكتشاف:** 2026-05-15
**الأولوية:** متوسطة
**الحالة:** ✅ تم الإصلاح

### الملفات المتأثرة
- `lib/core/utils/quill_migration.dart`
- `lib/screens/shared/note_editor/core/editor_coordinator.dart`

### الوصف
نفس منطق `_fixDeltaDirections` و `_buildDeltaWithDirections` كان موجوداً مرتين (~80 سطر مكررة).

### الحل
- جعلنا الدالتين public في `QuillMigration`
- أضفنا `buildDeltaJsonForIsolate` كـ top-level function في `quill_migration.dart`
- حذفنا الكود المكرر من `editor_coordinator.dart`

### التحقق: ✅ 47 اختبار نجح، صفر أخطاء

## 3. دالتان متطابقتان في NoteSecurityService**تاريخ الاكتشاف:** 2026-05-15
**الحالة:** ✅ تم الإصلاح

### الملف
`lib/services/note_services/note_security_service.dart`

### الوصف
`_prepareChecklistForEncryption` و `_cleanChecklistAfterDecryption` متطابقتان تقريباً — الفرق الوحيد `trim()`.

### الحل
دمجهما في `_normalizeChecklistJson(String content)`.

### التحقق: ✅ صفر أخطاء

## 4. getExtensionForLanguage مكررة في LanguageDetector

**تاريخ الاكتشاف:** 2026-05-15
**الحالة:** ✅ تم الإصلاح

### الملف
`lib/services/language_detector.dart`

### الوصف
`getFileExtension` و `getExtensionForLanguage` كانتا متطابقتين تماماً — نفس السطر الواحد.

### الحل
جعلنا `getExtensionForLanguage` تستدعي `getFileExtension` مباشرة.

### التحقق: ✅ 330/330 unit
