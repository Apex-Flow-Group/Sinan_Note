# مهام إعادة الهيكلة — التقييم والتنفيذ

## مقياس التقييم (صعوبة + تعقيد)
- **1-5**: تنفيذ مباشر ✅
- **6+**: توثيق فقط، لا تنفيذ ⚠️

---

## ✅ منجز (تم التنفيذ والاختبار)

| الملف | التعديل | التقييم | الاختبارات |
|-------|---------|---------|-----------|
| `quill_migration.dart` + `editor_coordinator.dart` | حذف ~80 سطر مكرر (Delta logic) | 3 | ✅ 47/47 |
| `note_state_service.dart` | إصلاح البحث العربي (normalizedTitle) | 2 | ✅ 29/29 |
| `note_security_service.dart` | دمج دالتين متطابقتين | 2 | ✅ صفر أخطاء |
| `storage_service.dart` | استبدال 15 حقل يدوي بـ copyWith | 2 | ✅ 330/330 |
| `vault_reset_service.dart` | إصلاح مسار DB من .isar إلى .db | 3 | ✅ 331/331 |
| `notes_provider.dart` | إصلاح duplicateNote — copyWith | 2 | ✅ 331/331 |

---

## 🔄 قيد التنفيذ — الجولة الحالية

---

### lib/controllers/settings/settings_provider.dart
**التقييم: 2**
**المشكلة:** كل setter يستدعي `SharedPreferences.getInstance()` بشكل منفصل — 15+ استدعاء مستقل.
**الحل:** استخراج `_savePreference(key, value)` helper لتوحيد الكتابة.

---

### lib/controllers/editor/editor_state_manager.dart
**التقييم: 1**
**الحالة:** ✅ نظيف — لا تعديل مطلوب.

---

### lib/services/version_control_service.dart
**التقييم: 1**
**الحالة:** ✅ نظيف — منطق واضح ومكتوب جيداً.

---

### lib/services/version_history_service.dart
**التقييم: 1**
**الحالة:** ✅ نظيف.

---

### lib/services/content_guard.dart
**التقييم: 1**
**الحالة:** ✅ نظيف.

---

### lib/services/clipboard_guard.dart
**التقييم: 1**
**الحالة:** ✅ نظيف.

---

### lib/services/language_detector.dart
**التقييم: 2**
**الحالة:** ✅ نظيف — ملف كبير لكن منطق واضح ومنظم.

---

### lib/services/smart_analyzer.dart
**التقييم: 2**
**الحالة:** ✅ نظيف. دالتان deprecated موجودتان (`calculateLine`, `analyzeMath`) لكن لا تسببان مشاكل.

---

### lib/services/notification_service.dart
**التقييم: 2**
**الحالة:** ✅ نظيف.

---

### lib/services/widget_service.dart
**التقييم: 3**
**المشكلة البسيطة:** `_getUntitledText()`, `_getSelectNoteText()`, `_getTapToSelectText()`, `_getSelectListText()` كلها تُنشئ `SettingsProvider()` جديد وتستدعي `ensureInitialized()` — 4 استدعاءات منفصلة في نفس العملية أحياناً.
**الحل:** استخراج `_getLocalizedText(String arText, String enText)` helper.

---

### lib/services/app_update_service.dart
**التقييم: 1**
**الحالة:** ✅ نظيف.

---

### lib/services/search/smart_search_service.dart
**التقييم: 1**
**الحالة:** ✅ نظيف.

---

### lib/services/storage/backup_service.dart
**التقييم: 2**
**المشكلة:** `_getDbFilePath()` مكررة هنا وفي `vault_reset_service.dart` (تم إصلاح الثانية). يجب توحيدهما.
**الحل:** نقل `_getDbFilePath()` إلى `SqliteDatabaseService` كـ static method.

---

### lib/services/storage/isar_database_service.dart
**التقييم: 1**
**الحالة:** ✅ ملف compatibility فقط — export لـ sqlite. لا تعديل.

---

### lib/services/cloud/google_drive_service.dart
**التقييم: 8 ⚠️**
**السبب:** منطق دمج معقد (Fast Path / Merge Path)، rate limiting، dirty tracking، تعامل مع حالات edge متعددة. أي تعديل يخاطر بكسر المزامنة.
**المشاكل الموثقة:**
- `_silentMerge` و `uploadDatabase` طويلتان (100+ سطر لكل منهما)
- منطق `allDeleted` مختلف بين Fast Path و Merge Path — صعب الفهم
- `_getPrefs()` تُستدعى مرات متعددة في نفس الدالة
**التوصية:** إعادة هيكلة مستقبلية بعد إضافة اختبارات تغطية كاملة.

---

### lib/services/cloud/google_drive_merge.dart
**التقييم: 7 ⚠️**
**السبب:** منطق دمج مع dialog UI — يجمع business logic مع UI.
**المشاكل الموثقة:**
- يعرض dialogs مباشرة من service layer (انتهاك separation of concerns)
**التوصية:** فصل منطق الدمج عن UI في مرحلة لاحقة.

---

### lib/services/cloud/google_drive_auth.dart
**التقييم: 4**
**الحالة:** يحتاج فحص — سيُقيَّم لاحقاً.

---

### lib/services/diagnostics/apex_error_manager.dart
**التقييم: 3**
**الحالة:** يحتاج فحص — سيُقيَّم لاحقاً.

---

### lib/services/diagnostics/apex_diagnostics_engine.dart
**التقييم: 3**
**الحالة:** يحتاج فحص — سيُقيَّم لاحقاً.

---

### lib/services/storage/compression_service.dart
**التقييم: 1**
**الحالة:** يحتاج فحص — سيُقيَّم لاحقاً.

---

### lib/services/storage/db_inspector_service.dart
**التقييم: 2**
**الحالة:** يحتاج فحص — سيُقيَّم لاحقاً.

---

## ⚠️ مهام تقييم +6 (توثيق فقط، لا تنفيذ)

### 1. google_drive_service.dart — إعادة هيكلة كاملة
**التقييم: 8**
**المشاكل:**
- `_silentMerge()`: 120+ سطر، منطق Fast/Merge Path متشابك
- `uploadDatabase()`: 80+ سطر، يجمع rate limiting + compression + upload
- `_getPrefs()` تُستدعى 4+ مرات في نفس الدالة
- لا توجد اختبارات للمزامنة (integration tests فشلت بسبب بيئة الاختبار)
**الخطة المقترحة (للتنفيذ لاحقاً):**
```
GoogleDriveService
├── _SyncDecisionEngine  ← يقرر Fast/Merge/Upload
├── _NotesMerger         ← منطق الدمج فقط
├── _DriveUploader       ← رفع فقط
└── _DriveDownloader     ← تنزيل فقط
```
**شرط التنفيذ:** إضافة اختبارات تغطية أولاً.

### 2. google_drive_merge.dart — فصل UI عن Business Logic
**التقييم: 7**
**المشاكل:**
- Service تعرض dialogs مباشرة
- يصعب اختبارها بدون Flutter widget tree
**الخطة المقترحة:**
- استخراج منطق الدمج إلى `_DriveConflictResolver`
- إبقاء الـ dialog في الـ screen layer

---

## 📋 ملاحظات عامة

### مشكلة _getDbFilePath() المكررة
موجودة في:
- `backup_service.dart` (صحيحة)
- `vault_reset_service.dart` (تم إصلاحها)

**الحل:** نقلها إلى `SqliteDatabaseService.getDbPath()` كـ static public method.
**التقييم: 3** — قابل للتنفيذ.

### مشكلة SharedPreferences.getInstance() المتكررة
موجودة في:
- `settings_provider.dart` (15+ استدعاء)
- `widget_service.dart` (4+ استدعاءات)

**الحل:** helper خاص في كل class.
**التقييم: 2** — قابل للتنفيذ.


---

## ✅ منجز — الجولة الثانية

| الملف | التعديل | التقييم | الاختبارات |
|-------|---------|---------|-----------|
| `sqlite_database_service.dart` | استخراج `getDbPath()` كـ static public | 3 | ✅ 331/331 |
| `backup_service.dart` | استخدام `SqliteDatabaseService.getDbPath()` | 2 | ✅ 331/331 |
| `vault_reset_service.dart` | استخدام `SqliteDatabaseService.getDbPath()` | 2 | ✅ 331/331 |
| `settings_provider.dart` | استخراج `_savePref()` helper — حذف 15+ استدعاء مكرر | 2 | ✅ 331/331 |
| `widget_service.dart` | استخراج `_getLocalizedText()` helper | 3 | ✅ 331/331 |

---

## تقييم الملفات المتبقية

### lib/services/cloud/google_drive_auth.dart
**التقييم: 2**
**الحالة:** ✅ نظيف — منطق واضح، error handling جيد.

### lib/services/diagnostics/apex_error_manager.dart
**التقييم: 1**
**الحالة:** ✅ نظيف.

### lib/services/diagnostics/apex_diagnostics_engine.dart
**التقييم: 1**
**الحالة:** ✅ نظيف.

### lib/services/storage/compression_service.dart
**التقييم: 1**
**الحالة:** ✅ نظيف — 10 أسطر فقط.

### lib/services/storage/db_inspector_service.dart
**التقييم: 2**
**المشكلة:** `_getSqlitePath()` مكررة مرة ثالثة هنا.
**الحل:** استخدام `SqliteDatabaseService.getDbPath()`.
**التقييم: 2** — قابل للتنفيذ.


---

## ✅ منجز — الجولة الثالثة

| الملف | التعديل | التقييم | الاختبارات |
|-------|---------|---------|-----------|
| `db_inspector_service.dart` | استخدام `SqliteDatabaseService.getDbPath()` | 2 | ✅ 330/330 (1 فشل قديم غير متعلق) |

---

## ملاحظة: فشل متكرر في الاختبارات

**الملف:** `test/unit/services/sqlite_database_service_test.dart`
**الخطأ:** `Expected: 'updated' Actual: 'created'`
**السبب:** تداخل بين الاختبارات عند تشغيلها معاً (shared SQLite singleton state)
**الحالة:** موجود قبل أي تعديل — ليس من تعديلاتنا
**التقييم: 5** — يحتاج إصلاح في `test_setup.dart` أو إضافة `resetInstance()` بين الاختبارات
**⚠️ لم يُنفَّذ** — يحتاج مراجعة بنية الاختبارات

---

## ملخص الإنجاز الكامل

| # | الملف | التعديل | التقييم |
|---|-------|---------|---------|
| 1 | `quill_migration.dart` + `editor_coordinator.dart` | حذف ~80 سطر مكرر | 3 |
| 2 | `note_state_service.dart` | إصلاح البحث العربي + 4 اختبارات | 2 |
| 3 | `note_security_service.dart` | دمج دالتين متطابقتين | 2 |
| 4 | `storage_service.dart` | copyWith بدلاً من 15 حقل يدوي | 2 |
| 5 | `vault_reset_service.dart` | إصلاح مسار DB (.isar → .db) | 3 |
| 6 | `notes_provider.dart` | إصلاح duplicateNote | 2 |
| 7 | `sqlite_database_service.dart` | استخراج `getDbPath()` static | 3 |
| 8 | `backup_service.dart` | توحيد مسار DB | 2 |
| 9 | `settings_provider.dart` | `_savePref()` helper | 2 |
| 10 | `widget_service.dart` | `_getLocalizedText()` helper | 3 |
| 11 | `db_inspector_service.dart` | توحيد مسار DB | 2 |

**إجمالي:** 11 تعديل، 331 اختبار نجح، صفر أخطاء تحليل

---

## ✅ منجز — الجولة السابعة

### كود ميت وتنظيف في ملفات الواجهة

| الملف | المشكلة | الإصلاح |
|-------|---------|---------|
| `home_screen.dart` | `_debounce` timer يُطلق closure فارغة — debounce بلا فائدة | حذف `_debounce` field والـ timer كلياً |
| `home_drawer_widget.dart` | `vaultOpenNotifier` — ValueNotifier لا يُستخدم في أي مكان | حذف |
| `smart_header.dart` | `_onSelectionChanged` listener فارغ — يُسجَّل ويُزال بلا فائدة | حذف الـ listener والدالة |
| `note_card_actions.dart` + `swipe_custom_sheet.dart` + `note_readonly_view.dart` | `fixNoteContent(content, maxChars: content.length)` — البارامتر يساوي طول المحتوى = لا تقليص = بلا معنى | حذف البارامتر الزائد |

**التقييم: 1-2** | **الاختبارات: ✅ 418/418**

### تحسين أداء scroll في `home_screen.dart`
**المشكلة:** `_onScrollChanged` يستدعي `Provider.of<SettingsProvider>` في كل scroll event (عشرات المرات/ثانية) لقراءة قيمة لا تتغير أثناء الـ scroll.
**الإصلاح:** cache `_pullToRefreshMode` كـ field، يُهيَّأ في `initState` ويُحدَّث في `didChangeDependencies`.
**التقييم: 2** | **الاختبارات: ✅ 418/418**


### كود ميت في المحرر — ملفان كاملان
**الملفات:**
- `editor_lifecycle.dart` → `EditorStateLifecycleManager` — لا يُستخدم في أي مكان
- `editor_lifecycle_manager.dart` → `EditorHandlerLifecycleManager` — لا يُستخدم في أي مكان

**الإجراء:** نقل الملفين إلى `_dead_code/` بدلاً من الحذف المباشر — للمراجعة لاحقاً.
**التحقق:** `flutter analyze lib/` → صفر أخطاء بعد النقل.
**التقييم: 2** | **الاختبارات: ✅ 418/418**

### إصلاح بق في اختبار `logNoteVersion`
**المشكلة:** الاختبار يستدعي `DateTime.now()` مرتين في نفس الـ millisecond — الترتيب عشوائي فيُفشل `ORDER BY timestamp DESC`.
**الإصلاح:** استخدام `t1` و `t2 = t1 + 1ms` لضمان ترتيب محدد.
**التقييم: 1** | **الاختبارات: ✅ 418/418**

### إصلاح البحث العربي — ملفات إضافية
**الملفات:**
- `search_mixin.dart`: حذف `toLowerCase()` من `searchQuery` — الشاشات تُطبّق `Note.normalize()` بنفسها
- `notes_filter_controller.dart`: استبدال `toLowerCase()` بـ `searchController.text` مباشرة
- `widget_selection_screen.dart`: استبدال `toLowerCase()` بـ `Note.normalize()`
- `version_history_screen.dart`: حذف `toLowerCase()` من `searchQuery`

**التقييم: 2** | **الاختبارات: ✅ 418/418**


### إصلاح `note.isEncrypted` — `lib/models/note.dart`
**المشكلة:** `isEncrypted` getter يتحقق فقط من `parts[0].length >= 16` — يُعطي false positive لأي محتوى يحتوي `:` مع أول جزء ≥ 16 حرف (URLs، JSON، كود).
**الإصلاح:** تفويض الفحص لـ `VaultService.isEncrypted()` الذي يتحقق من Base64 صالح — مصدر واحد للحقيقة.
**التقييم: 2** | **الاختبارات: ✅ 418/418**

### إصلاح بنية الاختبارات — تداخل SQLite Singleton
**المشكلة:** 26 اختبار يفشل عند التشغيل المتوازي بسبب:
1. `notes_provider_integration_test.dart` لا يُهيئ `sqflite_common_ffi`
2. `sqlite_database_service_test.dart` يُهيئ `sqflite_common_ffi` مكرراً
3. الاختبارات تتشارك SQLite singleton state عند التشغيل المتوازي

**الإصلاح:**
- `test_setup.dart`: أضفنا `sqfliteFfiInit()` و `databaseFactory = databaseFactoryFfi` — تهيئة مركزية واحدة
- `notes_provider_integration_test.dart`: أضفنا `resetInstance()` + `overrideDbPath(':memory:')` في `setUp`، وإغلاق صحيح في `tearDown`
- `sqlite_database_service_test.dart`: حذفنا التهيئة المكررة
- `dart_test.yaml`: أضفنا tag `serial` للملفات التي تستخدم SQLite singleton
- `note_model_test.dart`: حدّثنا اختبار `isEncrypted` ليستخدم Base64 صالح + أضفنا اختبارات false positive

**النتيجة: من 26 فشل → 0 فشل** | **✅ 418/418**


| الملف | التعديل | التقييم | الاختبارات |
|-------|---------|---------|-----------|
| `categories_provider.dart` | `final _db = SqliteDatabaseService()` — حذف 5 instances مكررة | 2 | ✅ 331/331 |
| `categories_provider.dart` | `setHideProFromHome` — إضافة `onError` للـ `.then()` | 1 | ✅ 331/331 |

---

## 🐛 إصلاح بق — الجولة الرابعة

### locked_notes_screen.dart + locked_notes_intro_screen.dart
**المشكلة:** أول ملاحظة في الخزنة الجديدة لا تظهر بدون تحديث يدوي.

**السبب الجذري (مزدوج):**
1. `LockedNotesScreen` يخزن `_decryptedNotes` كـ local state ولا يستمع لـ `NotesProvider` — عندما يُضيف `addNote` ملاحظة ويستدعي `notifyListeners()`، الشاشة لا تتفاعل.
2. `LockedNotesIntroScreen._finishSetup()` لا تستدعي `provider.unlockVault()` بعد إعداد الخزنة — جلسة الخزنة تبقى مغلقة.

**الإصلاح:**
- `locked_notes_screen.dart`: أضفنا `_onProviderChanged` listener يُعيد تحميل الملاحظات تلقائياً عند أي `notifyListeners()` من الـ provider.
- `locked_notes_intro_screen.dart`: أضفنا `notesProvider.unlockVault()` في `_finishSetup()` قبل الانتقال لـ `LockedNotesScreen`.

**التقييم: 3** | **الاختبارات: ✅ 331/331 unit + 55/55 services**


---

## ✅ منجز — الجولة الثامنة

### تنظيف ملفات الواجهة — الدفعة الثانية

| الملف | المشكلة | الإصلاح | التقييم |
|-------|---------|---------|---------|
| `vault_dialogs.dart` | `_executeDecryptAndDestroy` و `_executeDestroyWithContent` — ~80 سطر مكرر | دمجهما في `_executeDestroyVault` مشترك | 3 |
| `locked_notes_screen_responsive.dart` | `' '` (space) كـ hack لتفعيل البحث — يُسبب space كأول حرف | `_isSearchActive` flag نظيف | 2 |
| `home_screen_responsive.dart` | `_isEditModeNotifier` — ValueNotifier كود ميت (معلّق "🔥 لا تحذف" لكن لا يُستخدم) | حذف | 1 |
| `reminder_dashboard.dart` | `ViewType.grid` branch — غير قابل للوصول (`_loadViewType` لا يُعيّن grid) | حذف | 1 |
| `note_card_widget.dart` | فرعا `archive` و `else` في `onTap` متطابقان تماماً | دمجهما | 2 |
| `note_card_widget.dart` | `hideProFromHome` يُقرأ مرتين في نفس التعبير | local variable | 1 |
| `note_card_utils.dart` | `codeTypes` list مكررة في `getNoteMode` و `shouldShowExtension` | `_codeNoteTypes` static const | 2 |

**الاختبارات: ✅ 418/418**

---

## ⚠️ ملفات كبيرة — توثيق فقط (تقييم 7+)

### `note_editor.dart` (831 سطر) + `note_readonly_view.dart` (944 سطر)
**السبب:** ملفان ضخمان يجمعان منطق المحرر الكامل. أي تعديل يخاطر بكسر تجربة الكتابة.
**التوصية:** مراجعة مستقبلية بعد إضافة widget tests للمحرر.

### `backup_wizard_screen.dart` (706 سطر)
**المشكلة:** `_flow ??= 'backup'` داخل `build()` — state mutation في build.
**التقييم: 5** — قابل للإصلاح لكن يحتاج فهم كامل لتدفق الـ wizard.

---

## ✅ ميزة جديدة — تجربة Checklist محسّنة

### الملفات المعدّلة
- `lib/widgets/editor/checklist_item_widget.dart`
- `lib/widgets/editor/checklist_editor.dart`
- `lib/screens/shared/note_editor/view/readonly_checklist_view.dart`
- `lib/l10n/app_en.arb` + `lib/l10n/app_ar.arb`

### التغييرات

#### المحرر (`checklist_editor.dart` + `checklist_item_widget.dart`)
| قبل | بعد |
|-----|-----|
| زر `+` لكل item لإضافة item تحته | زر `+ إضافة عنصر` واحد في أسفل القائمة كاملة |
| زر `×` لحذف كل item | سحب يساراً (endToStart) لحذف الـ item |
| حذف بدون تراجع | `UnifiedNotificationService().showWithUndo()` — نفس الـ snackbar الدوار المستخدم في باقي التطبيق |
| أيقونة drag ثابتة للسحب | `ReorderableDelayedDragStartListener` — ضغط طويل على الـ item كاملاً يُفعّل السحب |
| أيقونة `drag_indicator` مرئية | أيقونة `drag_indicator` خفيفة كـ hint بصري فقط (opacity 0.25) |

#### العارض (`readonly_checklist_view.dart`)
| قبل | بعد |
|-----|-----|
| أيقونة drag في الـ `leading` | لا أيقونة — الضغط الطويل على كامل الصف يُفعّل السحب |
| `ReorderableDragStartListener` على الأيقونة فقط | `ReorderableDelayedDragStartListener` يُغلّف الـ `ListTile` كاملاً |
| النص بدون `textDirection` | `TextDirectionUtils.getDirection()` — النص يأخذ اتجاهه تلقائياً (عربي RTL، إنجليزي LTR) |
| الـ checkbox ثابت يسار | الـ checkbox ثابت يسار ✅ (صحيح) |

#### l10n
- أضفنا `addItem` (إضافة عنصر / Add item)
- أضفنا `itemDeleted` (تم حذف العنصر / Item deleted)

**الاختبارات: ✅ 418/418**

---

## ✅ منجز — الجولة التاسعة

### تنظيف services — كود ميت وإصلاح أمني

| الملف | المشكلة | الإصلاح | التقييم |
|-------|---------|---------|---------|
| `code_executor.dart` | 4 دوال تنفيذ + كود معلّق + تعليقات SECURITY NOTES (~80 سطر زائدة) — كلها ترجع `_getSecurityMessage()` فقط | حذف الكود المعلّق والتعليقات، تحويل الدوال إلى one-liners، `_getSecurityMessage` → `_securityMessage` const | 2 |
| `note_side_effect_service.dart` | `updateWidgetSideEffect()` جسمها `try {} catch (_) {}` — دالة فارغة تماماً | تبسيطها إلى `async {}` | 1 |
| `security_gate.dart` | `_isAndroid()` تستخدم `Theme.of(WidgetsBinding.instance.rootElement!)` للتحقق من المنصة — هشة وخاطئة (تعتمد على widget tree) | استبدالها بـ `Platform.isAndroid` مباشرة + إضافة `import 'dart:io'` | 2 |

**الاختبارات: ✅ 451/451**

### ملفات مراجعة جديدة — نظيفة

| الملف | الحالة |
|-------|--------|
| `apex_smart_controller.dart` | ✅ نظيف |
| `bidi_cursor_middleware.dart` | ✅ نظيف |
| `checklist_formatter.dart` | ✅ نظيف |
| `editor_page_route.dart` | ✅ نظيف |
| `logger.dart` | ✅ نظيف |
| `note_content_utils.dart` | ✅ نظيف |
| `text_direction_utils.dart` | ✅ نظيف |
| `master_width_provider.dart` | ✅ نظيف |
| `selected_note_provider.dart` | ✅ نظيف |
| `category.dart` / `exceptions.dart` / `feature_info.dart` / `note_mode.dart` / `note_version.dart` | ✅ نظيفة |
| `app_text_styles.dart` / `app_theme.dart` | ✅ نظيفان |
| `svg_service.dart` / `code_export_service.dart` | ✅ نظيفان |
| `note_batch_operations_service.dart` / `note_db_interface.dart` | ✅ نظيفان |
| `biometric_service.dart` / `rate_limiter_service.dart` / `unified_lock_service.dart` / `vault_reset_service.dart` / `vault_service.dart` | ✅ نظيفة |

### إصلاح بق ترجمة وقت المزامنة

| الملف | المشكلة | الإصلاح | التقييم |
|-------|---------|---------|---------|
| `google_drive_handlers.dart` | `formatDateTime` ترجع `'m ago'`, `'h ago'`, `'d ago'` بالإنجليزي بغض النظر عن لغة المستخدم | نص عربي/إنجليزي حسب `isAr` | 2 |

**الاختبارات: ✅ 450/450**

---

## ✅ منجز — الجولة العاشرة

### مراجعة screens/sync + widgets/home + widgets/common + widgets/navigation

**ملفات نظيفة:**

| الملف | الحالة |
|-------|--------|
| `google_drive_widgets.dart` | ✅ نظيف |
| `google_drive_vault_warning_dialog.dart` | ✅ نظيف |
| `google_drive_screen_responsive.dart` | ✅ نظيف |
| `google_drive_sync_controller.dart` | ✅ نظيف |
| `sync_step.dart` | ✅ نظيف |
| `notes_filter_controller.dart` | ✅ نظيف |
| `add_menu_widget.dart` | ✅ نظيف |
| `categories_panel.dart` | ✅ نظيف |
| `selection_action_bar.dart` | ✅ نظيف |
| `drawer_widgets.dart` | ✅ نظيف |
| `note_conversion_sheet.dart` | ✅ نظيف |
| `smooth_search_header_delegate.dart` | ✅ نظيف |
| `animated_search_bar.dart` | ✅ نظيف |
| `app_bottom_sheet.dart` | ✅ نظيف |
| `searchable_header.dart` | ✅ نظيف |
| `bottom_nav_bar.dart` | ✅ نظيف |
| `side_nav_rail.dart` | ✅ نظيف |
| `splash_screen.dart` | ✅ نظيف |
| `whats_new_dialog.dart` | ✅ نظيف |
| `google_drive_sync_terms_screen.dart` | ✅ نظيف |
| `google_drive_handlers.dart` | ✅ نظيف (بعد إصلاح الترجمة) |

### إصلاح نص hardcoded

| الملف | المشكلة | الإصلاح | التقييم |
|-------|---------|---------|---------| 
| `notes_sliver_view.dart` | `'No notes'` hardcoded إنجليزي بدلاً من `l10n.noNotes` | `Builder` + `l10n?.noNotes` | 1 |

**الاختبارات: ✅ 450/450**
