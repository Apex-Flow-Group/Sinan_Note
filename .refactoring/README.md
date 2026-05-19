# 📋 توثيق إعادة هيكلة Sinan Note

## الهيكل

```
.refactoring/
├── README.md                          ← أنت هنا
├── progress.json                      ← التقدم العام (يُحدّث تلقائياً)
│
├── analysis/                          ← تحليل الملفات والدوال
│   ├── _index.md                      ← فهرس الملفات المحللة
│   ├── models/                        ← تحليل lib/models/
│   │   └── note.md                    ← تحليل note.dart
│   ├── controllers/                   ← تحليل lib/controllers/
│   ├── services/                      ← تحليل lib/services/
│   ├── providers/                     ← تحليل lib/providers/
│   └── core/                          ← تحليل lib/core/
│
├── decisions/                         ← قرارات التقييم لكل ملف
│   └── {file_name}.json               ← قرارات JSON (آلي)
│
├── modifications/                     ← سجل التعديلات
│   └── {yyyy-MM}-{file_name}.json     ← تعديلات شهرية (آلي)
│
├── dead_code/                         ← تقارير الكود الميت
│   ├── report.md                      ← التقرير المقروء
│   └── dead_code.json                 ← البيانات (آلي)
│
├── findings/                          ← اكتشافات ومشاكل عامة
│   ├── _index.md                      ← فهرس الاكتشافات
│   ├── duplications.md                ← ازدواجيات في الكود
│   ├── patterns.md                    ← أنماط متكررة (جيدة وسيئة)
│   └── tech_debt.md                   ← ديون تقنية
│
├── monthly_reports/                   ← تقارير شهرية
│   └── {yyyy-MM}.json                 ← تقرير شهري (آلي)
│
└── event_sheets/                      ← خرائط الأحداث
    └── {file_name}/                   ← خرائط لكل ملف
        └── {function_name}.json       ← خريطة أحداث (آلي)
```

## سير العمل

```
لكل ملف:
  1. أقرأ الملف كاملاً
  2. أمسح الدوال بسرعة — أتوقف فقط عند مشكلة حقيقية
  3. عند المشكلة: أعرضها + أنفذ التعديل مباشرة
  4. أشغل الاختبارات وأتحقق
  5. أوثق في .refactoring/
  6. أنتقل للملف التالي
```

**قاعدة:** لا أتوقف عند دالة نظيفة — أقول "نظيف" وأكمل.

## الحالة الحالية

| | |
|---|---|
| **البداية** | 2026-05-15 |
| **آخر تحديث** | 2026-05-17 |
| **ملفات lib/** | 241 ملف (53,144 سطر) |
| **الملفات المراجَعة** | 63 ملف أساسي |
| **الدوال المراجَعة** | 502 دالة (من 63 ملف) |
| **المكتمل** | ✅ 100% (63/63) |
| **الاختبارات** | 469/469 ✅ |
| **تحليل الكود** | ✅ صفر أخطاء |
| **ريفاكتور الواجهة** | ✅ 5 جولات — نموذج العائلة السعيدة |

## ملخص الإنجاز

| الفئة | العدد |
|-------|-------|
| إجمالي التعديلات | 50+ |
| بقات مُصلحة | 5 |
| كود ميت محذوف | 8 حالة |
| إصلاحات البحث العربي | 10 ملفات |
| ملفات نظيفة (بلا تعديل) | 30+ |
| ملفات مؤجلة (تقييم 7+) | 2 |
| ملفات جديدة أُضيفت | 3 (sync layer) |

### ريفاكتور الواجهة — نموذج العائلة السعيدة

فلسفة تقسيم المسؤوليات بين 5 أعضاء:

| العضو | الدور | الدرجة قبل | الدرجة بعد |
|-------|-------|-----------|-----------|
| 👑 السيد — `NoteStateService` | يملك الحقيقة الوحيدة | 8/10 | **10/10** |
| 🏰 سيد القصر — `NotesProvider` | يُنسّق ويُبلّغ | 7.5/10 | **10/10** |
| 🧭 الابن المطيع — `VaultNavigator` | ينفّذ التنقل فقط | 4/10 | **10/10** |
| 👸 الأميرة — UI Screens | تطلب ولا تبني | 6/10 | **10/10** |
| 🛎️ الخادم — Services | يخدم ولا يعرف من يخدم | 6/10 | **10/10** |

**أبرز ما تم:**
- `createDefaultNote` / `createDefaultLockedNote` / `createSharedNote` في Provider — الأميرة تطلب ولا تبني
- `VaultNavigator` — مركز تنقل الخزنة الوحيد
- `VaultImportSheet` — ملف مستقل (كان 300+ سطر داخل شاشة)
- حذف الظل الملون من البطاقات — أداء السكرول
- إعداد "إخفاء الشريط عند السكرول" في قسم الإيماءات

التوثيق الكامل: [`ui/README.md`](./ui/README.md) | [`ui/TASKS.md`](./ui/TASKS.md)

## الملفات المؤجلة

| الملف | السبب | التقييم |
|-------|-------|---------|
| `note_editor.dart` (831 سطر) | ملف ضخم — يحتاج widget tests أولاً | 7+ |
| `google_drive_merge.dart` | يجمع business logic مع UI dialogs | 7 |

## سجل التعديلات

> **ملاحظة:** الأرقام في عمود "الاختبارات" تعكس عدد الاختبارات وقت تنفيذ كل تعديل. العدد الحالي: **450/450 ✅**

| التاريخ | الملف | التعديل | الاختبارات |
|---------|-------|---------|-----------|
| 2026-05-15 | `quill_migration.dart` + `editor_coordinator.dart` | حذف ~80 سطر مكرر (Delta logic) | ✅ 47/47 |
| 2026-05-15 | `note_state_service.dart` | إصلاح البحث العربي (normalizedTitle) + 4 اختبارات جديدة | ✅ 29/29 |
| 2026-05-15 | `note_security_service.dart` | دمج دالتين متطابقتين في `_normalizeChecklistJson` | ✅ صفر أخطاء |
| 2026-05-15 | `storage_service.dart` | استبدال 15 حقل يدوي بـ `note.copyWith(id: null, updatedAt: now)` | ✅ 330/330 |
| 2026-05-15 | `notes_provider.dart` | إصلاح `duplicateNote` — استخدام `copyWith` بدلاً من 10 حقول يدوية (كانت تفقد `isHiddenFromHome`, `isCompleted`) | ✅ 331/331 unit |
| 2026-05-15 | `language_detector.dart` | دمج `getExtensionForLanguage` المكررة في `getFileExtension` (كانتا متطابقتين تماماً) | ✅ 330/330 unit |
| 2026-05-15 | `google_drive_service.dart` | حذف `checkForRemoteUpdates()` — كود ميت (instance method على class ثابت، لم يُستدعَ أبداً) | ✅ 330/330 unit |
| 2026-05-15 | `db_inspector_service.dart` | إصلاح تسميات مضللة من Isar إلى SQLite في التقرير (بقايا migration) | ✅ 330/330 unit |
| 2026-05-15 | `sqlite_database_service.dart` | استخراج `getDbPath()` كـ static public — توحيد المسار في 3 ملفات | ✅ 331/331 |
| 2026-05-15 | `settings_provider.dart` | استخراج `_savePref()` helper — حذف 15+ استدعاء `SharedPreferences.getInstance()` مكرر | ✅ 331/331 |
| 2026-05-15 | `widget_service.dart` | استخراج `_getLocalizedText()` helper — حذف 4 دوال متطابقة | ✅ 331/331 |
| 2026-05-15 | `db_inspector_service.dart` | توحيد مسار DB مع `SqliteDatabaseService.getDbPath()` | ✅ 330/330 |
| 2026-05-15 | `note_card_widget.dart` | إصلاح locked note tap — `copyWith(isLocked: false)` بدلاً من 15 حقل يدوي | ✅ 331/331 |
| 2026-05-15 | `smart_header.dart` | إصلاح bulk pin — `copyWith(isPinned: !note.isPinned)` بدلاً من 14 حقل يدوي (كان يفقد `isHiddenFromHome`, `categoryIds`) | ✅ 331/331 |
| 2026-05-15 | `reminder_dashboard.dart` + `code_tab.dart` | إصلاح البحث العربي — `normalizedTitle/Content` بدلاً من `toLowerCase()` | ✅ 331/331 |
| 2026-05-15 | `archive_screen.dart` + `trash_screen.dart` + `locked_notes_screen.dart` | إصلاح البحث العربي في 3 شاشات | ✅ 331/331 |
| 2026-05-15 | `locked_notes_screen_responsive.dart` + `version_history_controller.dart` | إصلاح البحث العربي في شاشتين إضافيتين | ✅ 330/330 |
| 2026-05-15 | `desktop_selection_actions.dart` | إصلاح bulk pin — `copyWith` بدلاً من 16 حقل يدوي (كان يفقد `isHiddenFromHome`, `categoryIds`) | ✅ 331/331 |
| 2026-05-16 | `categories_provider.dart` | `final _db` field — حذف 5 instances مكررة لـ `SqliteDatabaseService()` | ✅ 331/331 |
| 2026-05-16 | `categories_provider.dart` | `setHideProFromHome` — إضافة `onError` للـ `.then()` الصامت | ✅ 331/331 |
| 2026-05-16 | `locked_notes_screen.dart` | إصلاح بق: إضافة `_onProviderChanged` listener — أول ملاحظة في الخزنة تظهر فوراً | ✅ 331/331 |
| 2026-05-16 | `locked_notes_intro_screen.dart` | إصلاح بق: استدعاء `unlockVault()` بعد إعداد الخزنة | ✅ 331/331 |
| 2026-05-16 | `note.dart` | إصلاح `isEncrypted` — تفويض لـ `VaultService.isEncrypted()` بدلاً من فحص طول بسيط | ✅ 418/418 |
| 2026-05-16 | `test_setup.dart` + integration tests | إصلاح 26 اختبار فاشل — تهيئة مركزية لـ SQLite + عزل الـ singleton | ✅ 418/418 |
| 2026-05-16 | `search_mixin.dart` + 3 ملفات | إصلاح البحث العربي — حذف `toLowerCase()` واستبداله بـ `Note.normalize()` | ✅ 418/418 |
| 2026-05-16 | `editor_lifecycle.dart` + `editor_lifecycle_manager.dart` | نقل ملفين كود ميت كامل إلى `_dead_code/` | ✅ 418/418 |
| 2026-05-16 | `sqlite_database_service_test.dart` | إصلاح بق timestamp في `logNoteVersion` — timestamps مختلفة لضمان الترتيب | ✅ 418/418 |
| 2026-05-16 | `home_screen.dart` + `home_drawer_widget.dart` + `smart_header.dart` | حذف كود ميت: `_debounce` فارغ، `vaultOpenNotifier`، listener فارغ | ✅ 418/418 |
| 2026-05-16 | `note_card_actions.dart` + `swipe_custom_sheet.dart` + `note_readonly_view.dart` | حذف `maxChars: content.length` — بارامتر بلا معنى | ✅ 418/418 |
| 2026-05-16 | `home_screen.dart` | cache `_pullToRefreshMode` — إزالة `Provider.of` من كل scroll event | ✅ 418/418 |
| 2026-05-16 | `note_card_widget.dart` | دمج فرعي `archive` و `else` المتطابقين في `onTap` | ✅ 418/418 |
| 2026-05-16 | `note_card_widget.dart` | `hideProFromHome` يُقرأ مرتين — استخراج local variable | ✅ 418/418 |
| 2026-05-16 | `note_card_utils.dart` | `codeTypes` list مكررة في دالتين — استخراج `_codeNoteTypes` static const | ✅ 418/418 |
| 2026-05-16 | `vault_dialogs.dart` | دمج `_executeDecryptAndDestroy` و `_executeDestroyWithContent` (~80 سطر مكرر) في `_executeDestroyVault` مشترك | ✅ 418/418 |
| 2026-05-16 | `locked_notes_screen_responsive.dart` | إصلاح space hack في البحث — `_isSearchActive` flag بدلاً من `' '` كـ toggle | ✅ 418/418 |
| 2026-05-16 | `home_screen_responsive.dart` | حذف `_isEditModeNotifier` — ValueNotifier كود ميت لم يُستخدم | ✅ 418/418 |
| 2026-05-16 | `reminder_dashboard.dart` | حذف `ViewType.grid` branch — غير قابل للوصول | ✅ 418/418 |
| 2026-05-16 | `checklist_item_widget.dart` | حذف أزرار `+` و`×` وأيقونة drag — استبدال بـ gestures | ✅ 418/418 |
| 2026-05-16 | `checklist_editor.dart` | سحب يساراً للحذف + `UnifiedNotificationService().showWithUndo()` + زر `+` واحد في الأسفل | ✅ 418/418 |
| 2026-05-16 | `readonly_checklist_view.dart` | ضغط طويل على كامل الصف للسحب + `textDirection` تلقائي للنص | ✅ 418/418 |
| 2026-05-16 | `checklist_item_widget.dart` + `checklist_editor.dart` | `ReorderableDelayedDragStartListener` — ضغط طويل يُفعّل السحب في المحرر | ✅ 418/418 |
| 2026-05-16 | `backup_wizard_screen.dart` | إصلاح state mutation في `build()` — نقل `_flow ??= 'backup'` إلى `didChangeDependencies()` | ✅ 451/451 |
| 2026-05-16 | **بنية المزامنة** — 3 ملفات جديدة + 8 ملفات محدّثة | استخراج `CloudSyncGateway` + `SyncEngine` + `SyncTransport` — فصل كامل لمنطق المزامنة عن Google Drive | ✅ 451/451 |
| 2026-05-16 | `notes_provider.dart` | حذف `fetchNotes()` — مكرر لـ `refreshAllNotes()` بلا قيمة | ✅ 450/450 |
| 2026-05-16 | `notification_service.dart` | حذف `cancelAllNotifications()` — كود ميت، لا أحد يستدعيها | ✅ 450/450 |
| 2026-05-16 | `editor_state_manager.dart` | حذف `resetToSnapshot()`، `updateColor()`، `updateReminder()` — لا أحد يستدعيها | ✅ 450/450 |
| 2026-05-16 | `platform_helper.dart` | حذف `getBreakpoint()` — كود ميت، لا أحد يستدعيها | ✅ 450/450 |
| 2026-05-16 | `app_shortcuts.dart` | تعليق 6 Intents غير مستخدمة: `SaveIntent`, `DeleteIntent`, `ArchiveIntent`, `LockIntent`, `CloseIntent`, `SelectAllIntent` | ✅ 450/450 |
| 2026-05-16 | `adaptive_color.dart` | حذف `defaultIndex` getter — كود ميت | ✅ 450/450 |
| 2026-05-16 | **الأداة** | تحسين `--report` من O(n²) إلى O(n) — من ساعات إلى 5 ثوانٍ | — |
| 2026-05-16 | `code_executor.dart` | حذف ~80 سطر (كود معلّق + تعليقات) — 4 دوال one-liners + `_securityMessage` const | ✅ 451/451 |
| 2026-05-16 | `note_side_effect_service.dart` | حذف `try {} catch (_) {}` الفارغ من `updateWidgetSideEffect()` | ✅ 451/451 |
| 2026-05-16 | `security_gate.dart` | استبدال `_isAndroid()` الهشة بـ `Platform.isAndroid` مباشرة + `import 'dart:io'` | ✅ 451/451 |
| 2026-05-16 | `google_drive_handlers.dart` | إصلاح بق `formatDateTime` — `'m ago'`, `'h ago'`, `'d ago'` hardcoded إنجليزي — نص عربي/إنجليزي حسب `isAr` | ✅ 450/450 |
| 2026-05-16 | `notes_sliver_view.dart` | إصلاح `'No notes'` hardcoded — استبدالها بـ `l10n.noNotes` | ✅ 450/450 |
| 2026-05-19 | `home_drawer_widget.dart` + `vault_navigator.dart` | إصلاح بق: فتح الخزنة بالبصمة من الـ Drawer — context unmounted بعد pop. البصمة أولاً ثم pop + `VaultNavigator.pushLockedNotes` | ✅ |
| 2026-05-19 | `home_drawer_widget.dart` | إصلاح بق: التنقل من الـ Drawer أثناء وجود الخزنة مفتوحة — `LockedNotesScreen.postFrameCallback` كان يعمل `exitVault` بعد push الوجهة الجديدة فيُزيلها. الحل: `endOfFrame × 2` قبل push | ✅ |
| 2026-05-19 | `google_drive_screen.dart` + `settings_screen_responsive.dart` | إصلاح بق: `PopScope(canPop: false)` مع `popUntil('/main')` كان يُزيل الشاشة الجديدة بعد push من الـ Drawer. الحل: `canPop: true` | ✅ |
| 2026-05-19 | `pin_lock_screen.dart` | إصلاح بق: بعد ضبط PIN من الإعدادات تخرج من الإعدادات — race condition بين `setPin()` و `SecurityController._updateSecurityController()`. الحل: `setState(() => _loading = true)` قبل `setPin()` | ✅ |


## الملفات المرجعية

| الملف | الوصف |
|-------|-------|
| [`TASKS.md`](./TASKS.md) | قائمة المهام التفصيلية لكل جولة |
| [`ui/README.md`](./ui/README.md) | توثيق ريفاكتور الواجهة — نموذج العائلة السعيدة |
| [`ui/TASKS.md`](./ui/TASKS.md) | مهام ريفاكتور الواجهة (5 جولات مكتملة) |
| [`progress.json`](./progress.json) | حالة كل ملف (آلي) |
| [`analysis/_index.md`](./analysis/_index.md) | فهرس الملفات المحللة |
| [`findings/duplications.md`](./findings/duplications.md) | ازدواجيات في الكود |
| [`findings/patterns.md`](./findings/patterns.md) | أنماط متكررة |
| [`findings/tech_debt.md`](./findings/tech_debt.md) | ديون تقنية |
| [`dead_code/report.md`](./dead_code/report.md) | تقرير الكود الميت |

## أبرز الإنجازات

### إصلاحات بنيوية
- **`copyWith` pattern** — استبدال 15+ حقل يدوي في 6 ملفات (`storage_service`, `notes_provider`, `note_card_widget`, `smart_header`, `desktop_selection_actions`)
- **توحيد مسار DB** — `SqliteDatabaseService.getDbPath()` static في 3 ملفات بدلاً من `_getDbFilePath()` مكررة
- **`_savePref()` helper** — حذف 15+ استدعاء `SharedPreferences.getInstance()` مكرر في `settings_provider`
- **بنية المزامنة** — استخراج `CloudSyncGateway` + `SyncEngine` + `SyncTransport` (فصل كامل عن Google Drive)

### إصلاح البحث العربي
10 ملفات تستخدم `toLowerCase()` — استُبدلت بـ `Note.normalize()` / `normalizedTitle`:
`note_state_service`, `reminder_dashboard`, `code_tab`, `archive_screen`, `trash_screen`, `locked_notes_screen_responsive`, `version_history_controller`, `search_mixin`, `widget_selection_screen`, `version_history_screen`

### بقات مُصلحة
| البق | الملف | الأثر |
|------|-------|-------|
| أول ملاحظة في الخزنة لا تظهر | `locked_notes_screen` + `locked_notes_intro_screen` | UX مكسور |
| `isEncrypted` false positive | `note.dart` → `VaultService.isEncrypted()` | أمان |
| state mutation في `build()` | `backup_wizard_screen` | Flutter anti-pattern |
| ترجمة وقت المزامنة hardcoded | `google_drive_handlers` | i18n |
| `'No notes'` hardcoded | `notes_sliver_view` | i18n |

### كود ميت محذوف
- `editor_lifecycle.dart` + `editor_lifecycle_manager.dart` — ملفان كاملان (نُقلا إلى `dead_code/`)
- `checkForRemoteUpdates()` في `google_drive_service` — instance method على class ثابت
- `cancelAllNotifications()` في `notification_service`
- `resetToSnapshot()`, `updateColor()`, `updateReminder()` في `editor_state_manager`
- `getBreakpoint()` في `platform_helper`
- `defaultIndex` getter في `adaptive_color`
- `_isEditModeNotifier` في `home_screen_responsive`
- `vaultOpenNotifier` في `home_drawer_widget`
