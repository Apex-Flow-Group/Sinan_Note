# Changelog — سنان نوت

جميع التغييرات الجوهرية موثقة هنا. الصيغة مبنية على [Keep a Changelog](https://keepachangelog.com/ar/1.0.0/).

---

## [3.2.4] — 2026-06 | إعادة هيكلة وبنية

### 🏗️ إعادة هيكلة

**إصلاح فتح الويدجت عند إغلاق التطبيق (cold start)**
- `_openNoteById()` تنتظر الآن `settings.isInitialized` + 500ms قبل التنقل، بنفس النمط المستخدم في `_openEditorWithSharedText`. يُصلح race condition كان يُسبب كتابة `pushReplacement` من `SplashScreen` فوق الـ route المدفوع من ضغطة الويدجت.

**إصلاح وميض Hero Animation**
- تهيئة Quill غير المتزامنة (`initializeQuillAsync`) تُؤجَّل الآن في وضع القراءة ولا تُنفَّذ حتى يدخل المستخدم وضع التعديل عبر `_initQuillForEdit()`.
- `readonly_content.dart`: استخراج النص النقي نُقل من `addPostFrameCallback` إلى `initState` بشكل متزامن، مما يُلغي وميض `CircularProgressIndicator` لفريم واحد.
- `note_readonly_view.dart`: `listen: true` → `listen: false` لقراءة `heroAnimationEnabled`.

**إصلاح عدم حفظ إعداد Hero Animation**
- `settings_provider.dart`: كانت `_heroAnimationEnabled` مُضبوطة على `false` ثابتاً عند كل تحميل متجاهلةً SharedPreferences. أصبحت تقرأ `prefs.getBool('heroAnimationEnabled') ?? false`.

**قسم "الحركة والتنقل" في الإعدادات**
- استخراج إعدادات Hero Animation وسحب للتحديث والضغط المزدوج للتعديل من `GeneralSection` إلى `MotionNavigationSection` مستقل (`motion_navigation_section.dart`).
- تحديث `settings_screen.dart` لإدراج القسم الجديد بين General وBeta.

**تقسيم الملفات — مبدأ المسؤولية الواحدة**
- `note_editor.dart` (1235 → ~1095 سطر): methods إجراءات القائمة استُخرجت إلى `EditorMenuHandlersMixin` (`editor_menu_handlers.dart`) وأُدمجت عبر `with`.
- `pin_lock_screen.dart` (829 → ~730 سطر): `_numpadKey` و`_numRow` استُخرجا إلى `PinNumpadKey` / `PinNumpadRow` (`pin_numpad_key.dart`).
- `backup_wizard_screen.dart` (717 → ~483 سطر): الكلاسات المساعدة `_FlowCard` وغيرها نُقلت إلى `backup_wizard_widgets.dart` بأسماء عامة.
- `unified_notification_service.dart`: methods بناء الـ widget (`_buildContent`، `_buildActionButton`، `_buildProgressWithUndo`، `_getBackgroundColor`، `_getIcon`) استُخرجت إلى كلاس `NotificationSnackBar` (`notification_snack_bar.dart`). الـ service أصبح orchestration بحت بدون أي Flutter widget building.
- `note_card_actions.dart`: `_PermanentDeleteSheet` استُخرجت إلى `permanent_delete_sheet.dart` (`widgets/common/`).
- `categories_panel.dart`: `_ProCategoryTile` (StatefulWidget مستقل) استُخرج إلى `pro_category_tile.dart` (`widgets/home/`).

---

## [3.2.3] — 2026-06 | أداء اللصق + مشاركة عبر Apex

### ✨ ميزات جديدة
- **مشاركة الملاحظات عبر Apex Transfer** — زر جديد في sheet المشاركة يرسل الملاحظة لأجهزة قريبة عبر الشبكة المحلية بدون إنترنت

### ⚡ أداء
- **إصلاح تجمد التطبيق عند لصق نصوص كبيرة** — اعتراض حدث اللصق وبناء Delta في Isolate منفصل عبر Document وهمي، ثم تسليمه لـ Quill مرة واحدة. يُلغي رسائل عدم الاستجابة (ANR) على جميع الأجهزة
- **إصلاح تجمد التطبيق عند الشير من خارج التطبيق** — النص المشارك يبني Delta في Isolate قبل فتح المحرر بنفس آلية اللصق
- **إزالة QuillEditor من وضع العرض** — استبدال QuillEditor بـ SelectableText مع ListView.builder لكل فقرة. يحل مشاكل التمرير والضغط على المؤشر في النصوص الطويلة
- **إصلاح رسالة إنشاء نسخة** — استبدال رسالة «تم نسخ الملاحظة» ب«تم إنشاء نسخة من الملاحظة»
- **إعادة تسمية وضع القراءة** — تحويل reading_mode_view.dart إلى book_mode_view.dart وتحديث كل المراجع

---

## [3.2.2] — 2026-06 | إصلاحات المحرر والتجربة

### ✨ ميزات جديدة
- **زر الكتالوج في شريط التحديد المتعدد** — تعيين النوتات لكتالوجات مباشرةً من شريط التحديد (الرئيسية، تب الكود، تب التذكيرات)
- **منطق كتالوج ذكي عند التحديد المتعدد** — نوتة واحدة تفتح حالتها الفعلية، عدة نوتات تفتح فارغةً وتُضيف فقط دون استبدال الكتالوجات الموجودة
- **وضع القراءة** — زر في شريط العارض يفتح شاشة قراءة مريحة للنوتات الطويلة (أكثر من 600 حرف، يدعم Markdown)

### 🔧 إصلاحات
- **إصلاح المشاركة تقطع محتوى النوتة** — جميع مسارات الشير تُرسل المحتوى كاملاً بدون حد 300 حرف
- **إصلاح زر الكتالوج في العارض لا يعكس الحالة المحفوظة** — `_currentNote` يتحدّث عند التحديث ليعكس الكتالوج الصحيح
- **إصلاح كراش dispose في الجيك لست** — حذف `controller.clear()` التي كانت تُطلق listeners محذوفة وتُسبب `NoSuchMethodError`
- **إصلاح عدم تغيير أيقونة زر اللصق** — `SmartEditorToolbar` (وضع rich/reminder) يتبدّل بين أيقونة اللصق والإغلاق عند فتح شريط التحديد
- **إصلاح عودة اتجاه النص لليسار بعد الحفظ** — `fixDeltaDirections` لم يعد يُعيد حساب اتجاهات الفقرات، يُنظّف فقط `align:right` القديم
- **إصلاح توقف اتجاه اللصق في منتصف النص** — `isPasting` يُعيّن في `addPostFrameCallback` حتى لا يتدخل `onChanged` أثناء عمليات التنسيق
- **إصلاح اتجاه سطور الجيك لست** — حذف `textDirection` الثابت من `TextField` ليكتشف Flutter اتجاه كل سطر تلقائياً
- **إصلاح ظهور JSON الخام في كارد الجيك لست الفارغة** — `toDisplayText` يرجع نصاً فارغاً بدل محتوى JSON عند عدم وجود عناصر
- **إصلاح الويدجت يفتح شاشة اختيار بدل النوت** — `NoteWidgetProvider` و`ChecklistWidgetProvider` يفتحان النوت مباشرة عند وجود `noteId > 0`، وكانت المشكلة أن الـ keys تُقرأ بدون `flutter.` prefix الصحيح
- **إصلاح موضع دمعة المؤشر عند الانتقال لسطر جديد** — تأخير `_showAtCaret` بـ `addPostFrameCallback` حتى يكتمل الـ layout
- **إصلاح وضع القراءة يعرض نصاً خاماً بدون تنسيق** — تمرير Delta JSON كامل للحفاظ على التنسيق (bold، lists، headers)
- **إصلاح كشف اتجاه النص مع النصوص المرقمة** — استخدام `Bidi.detectRtlDirectionality` بدل regex يدوي يتجاهل الأرقام والرموز
- **إصلاح اتجاه القوائم المرقمة** — القوائم تحتفظ باتجاه أول بند طوال القائمة، لا يتغير بين البنود
- **إصلاح موضع رقم القائمة في flutter_quill** — الـ leading يستخدم اتجاه الـ block بدل اتجاه الأب
- **إصلاح تنسيق رقم القائمة** — LTR: `1.` على اليسار، RTL: `.1` على اليمين
- **إصلاح عرض المحتوى في وضع العارض يظهر خاماً** — `_openReadingMode` يستخدم `quillController` مباشرة بدل `contentController.text`
- **تصحيح اتجاهات Delta المحفوظة** — `fixDeltaDirections` يُصحح direction كل block بناءً على محتواه عند التحميل

### ⚡ أداء
- **Debounce على `onChanged` (50ms)** — منطق الاتجاه لا يعمل عند كل ضغطة، يُجمّع بعد توقف الكتابة
- **مقارنة hash سريعة قبل مقارنة النص كاملاً** — تقلل العمليات الثقيلة على المستندات الطويلة
- **إعادة كتابة `getPrevNonEmptyLineDirection`** — استبدال `substring + split('\n')` بمسح للخلف بـ `lastIndexOf`، حرج للروايات والنصوص الطويلة
- **إعادة كتابة دمعة المؤشر بـ `ValueNotifier`** — استبدال `setState` بـ `ValueNotifier` + throttle 16ms يُقلل إعادة البناء أثناء السحب
- **حذف طباعات الأداء من المحرر** — إزالة `debugPrint` و`Stopwatch` من `QuillEditorController` و`CursorTearHandle`

### 📖 وضع القراءة
- **تقسيم بالأحرف مع مراعاة الكلمات** — 900 حرف لكل صفحة، يقطع عند أقرب مسافة
- **تحسين حساسية السحب** — `ClampingScrollPhysics` يحرر السحب العمودي فوراً
- **سحب أقوى للانتقال بين الصفحات** — `minFlingVelocity` رُفع لتجنب التنقل العرضي

### 🔔 عارض التذكير
- **badge التذكير في وضع العرض** — يظهر في أسفل النوتة عند وجود تذكير (ماضٍ أو مستقبل)
- **تصميم ثلاثي الأقسام** — فريم التذكير | زر التعديل | زر الحذف
- **وقت نسبي ذكي** — "خلال X دقيقة / غداً / منذ X يوم..."
- **المحتوى لا يختبئ** — padding تلقائي يحمي النص من الاختباء تحت الـ badge

---

## [3.2.1] — 2026-05 | مفتوح المصدر + إصلاحات دقيقة

> انطلاقة جديدة — الكود الآن متاح للجميع على GitHub.

### 🌍 مفتوح المصدر
- **سنان نوت أصبح مفتوح المصدر** — الكود متاح على [GitHub](https://github.com/Apex-Flow-Group/Sinan_Note) للاستكشاف والتعلم والمساهمة

### 🔧 إصلاحات
- **إصلاح خيار الإخفاء عند إلغاء الكتالوج** — إلغاء آخر كتالوج يُعيد خيار الإخفاء إلى false تلقائياً
- **إصلاح النوتات المخفية بكتالوج فارغ** — migration تلقائي (v5) يُصلح النوتات القديمة المتضررة عند أول تشغيل
- **إصلاح موضع المؤشر بعد اللصق** — المؤشر ينتقل لنهاية النص الملصق بدلاً من الإبقاء على التحديد القديم
- **إصلاح مزامنة فورية عند تفعيل المزامنة التلقائية** — التطبيق يُزامن مباشرة بعد تفعيل الخيار

---

## [3.2.0] — 2026-05 | إعادة هيكلة شاملة + تحسينات الأمان

> 50+ تعديل، 8 جولات refactoring، 469/469 اختبار نجح.

### ✨ ميزات جديدة
- **زر إضافة عنصر بالشريط السفلي** — إضافة سريعة للجيك لست بدون سكرول لآخر القائمة
- **سحب لإخفاء الإشعارات** — جميع الإشعارات (SnackBar) تدعم السحب لأسفل للإخفاء
- **تنفيذ فوري عند سحب إشعار Undo** — الإجراء ينفذ مباشرة بدل انتظار الدوّار
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
- **إصلاح ضياع التعديلات عند القفل** — المحرر يحفظ المحتوى فوراً عند الذهاب للخلفية بدل انتظار الـ autosave timer
- **إصلاح تدمير المحرر عند تفعيل القفل** — شاشة القفل تُعرض فوق الـ stack بدل استبدال كل شيء بـ SplashScreen
- **إصلاح طلب البصمة 3 مرات** — توحيد مسار المصادقة عبر `forceUnlock()` مباشرة بعد نجاح `PinLockScreen`
- **إصلاح زر البصمة في الإعدادات** — يظهر فقط إذا كانت بصمة مسجّلة فعلاً على الجهاز (لا يكفي وجود الـ hardware)
- **إصلاح النسخة المكررة بالـ Recent Apps** — إزالة `taskAffinity=""` من AndroidManifest
- **إصلاح سكرول الجيك لست مع الكيبورد** — السطر الجديد وزر الإضافة يظهران فوق الشريط السفلي
- **سكرول ذكي عند إضافة عنصر** — محاولات متعددة (200/500/800ms) لانتظار ظهور الكيبورد بالكامل
- أول ملاحظة في الخزنة تظهر فوراً (إضافة `_onProviderChanged` listener)
- الخزنة تُفتح تلقائياً بعد الإعداد الأولي
- Desktop لا يعرض ملاحظات مشفرة (يقرأ `lockedNotes` بدل `activeNotes`)
- ترجمة وقت المزامنة تعمل بالعربية والإنجليزية
- نص hardcoded `'No notes'` → `l10n.noNotes`
- **إصلاح تكبّر النافذة تلقائياً على Windows** — مشكلة DPI scaling كانت تضاعف الحجم كل فتح/إغلاق
- **إصلاح اتجاه أقواس أزرار التبديل بالعربية** — الأقواس الآن تتبع اتجاه اللغة (RTL/LTR)

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
- **تاريخ الإصدارات** — رُفع الحد من 5 إلى 20 إصداراً لكل ملاحظة
- **`SecurityController.forceUnlock()`** — فتح القفل مباشرة بدون إعادة استدعاء المصادقة

### 🧪 اختبارات
- 127 اختبار جديد يغطي: `EditorSaveManager`، `VersionControlService` (حالات الحافة)، `EditorStateManager` (تسلسل autosave)

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
