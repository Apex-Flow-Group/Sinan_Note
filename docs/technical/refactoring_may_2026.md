# Refactoring Session — May 2026
## إعادة هيكلة 5 ملفات كبيرة + نظام الدمعة

---

## الملخص التنفيذي

| الملف | قبل | بعد | النسبة |
|-------|-----|-----|--------|
| `settings_screen.dart` | 753 سطر | 85 سطر | ↓ 89% |
| `notes_grid_view.dart` | 697 سطر | 95 سطر | ↓ 86% |
| `version_history_screen.dart` | 914 سطر | 220 سطر | ↓ 76% |
| `date_indicator_bar.dart` | 737 سطر | 180 سطر | ↓ 76% |
| `quill_editor_widget.dart` | 666 سطر | 145 سطر | ↓ 78% |
| `cursor_tear_handle.dart` | 350 سطر | 4 سطر (re-export) | ↓ 99% |

---

## 1. نظام الدمعة (Cursor Tear Handle)

### قبل
```
widgets/editor/cursor_tear_handle.dart  ← 350 سطر
  - CursorTearHandle (منطق)
  - _TearHandleWidget + State (واجهة + سحب)
  - _TearPainter (رسم الدمعة)
  - _MagBgPainter (رسم المكبر)
  - منطق المكبر مدمج في الـ widget
```

### بعد
```
widgets/editor/cursor_tear_handle.dart  ← 4 سطر (re-export للتوافق)
widgets/editor/tear/
├── tear.dart                           ← barrel export
├── cursor_tear_handle.dart             ← CursorTearHandle (منطق فقط)
├── tear_handle_widget.dart             ← TearHandleWidget + State
├── tear_magnifier.dart                 ← TearMagnifier widget
└── tear_painters.dart                  ← TearPainter + MagBgPainter
```

### مشاكل تم حلها أثناء الجلسة

#### أ) القفز عند الضغط على الدمعة
**السبب:** أول `onPointerMove` يمرر موضع الإصبع (على الدمعة = أسفل الكرسر) لـ `getPositionForOffset` فيحسب السطر التالي.

**الحل:** منطق البلوكات — تقسيم المحرر لسطور بارتفاع `lineHeight` ثابت:
```dart
final scrollOffset = re.offset?.pixels ?? 0.0;
final viewportDy = local.dy - scrollOffset;
final lineIndex = (viewportDy / lineH).floor();
final targetLocal = Offset(local.dx, lineIndex * lineH + lineH / 2);
final pos = re.getPositionForOffset(targetLocal);
```

**الدرس:** `getPositionForOffset` في Quill يتوقع إحداثيات الـ viewport وليس المستند الكامل.

#### ب) الانزياح مع السكرول
**السبب:** `re.globalToLocal(fingerPos)` يعطي إحداثيات شاملة السكرول، لكن `getPositionForOffset` يتوقع viewport فقط.

**الحل:** طرح `scrollOffset` قبل الحساب:
```dart
final scrollOffset = re.offset?.pixels ?? 0.0;
final viewportDy = local.dy - scrollOffset;
```

#### ج) تجميد اللمس بعد السحب
**السبب:** `HitTestBehavior.opaque` يمنع الأحداث من الوصول للمحرر دائماً.

**الحل:** `opaque` أثناء السحب فقط:
```dart
behavior: _dragging ? HitTestBehavior.opaque : HitTestBehavior.translucent,
```

#### د) setState بعد dispose
**الحل:**
```dart
void _endDrag() {
  if (!mounted) return;
  setState(() => _dragging = false);
  widget.onDragEnd();
}
```

---

## 2. settings_screen.dart

### قبل
```
screens/shared/settings_screen.dart  ← 753 سطر
  - كل الـ sections مدمجة في ملف واحد
  - كود mobile و desktop مكرر
  - _buildSection مكررة 5 مرات
  - HeroAnimationInfoSheet مدمج
```

### بعد
```
screens/shared/settings_screen.dart          ← 85 سطر (orchestrator)
screens/shared/settings/sections/
├── general_section.dart                     ← GeneralSection + BetaSection
├── editor_section.dart                      ← EditorSection
├── security_section.dart                    ← SecuritySection
└── data_about_sections.dart                 ← DataSection + AboutSection
screens/shared/settings/widgets/
├── settings_section_card.dart               ← SettingsSectionCard مشترك
└── hero_animation_info_sheet.dart           ← HeroAnimationInfoSheet
```

### المشاكل المتوقعة عند الاختبار
- **SecuritySection:** `BiometricService.authenticate()` يحتاج جهاز حقيقي — اختبر على device
- **DataSection:** تأكد أن `BackupWizardScreen` يفتح بشكل صحيح
- **DesktopLayout:** اختبر على شاشة عريضة أن الأعمدة تظهر صحيحة

---

## 3. notes_grid_view.dart

### قبل
```
widgets/home/notes_grid_view.dart  ← 697 سطر
  - NotesGridView (state + منطق فلترة + pagination)
  - _NotesSliversView (UI)
  - _NoteCardWrapper (selection state)
  - _HeightRecorder
  - Levenshtein algorithm مدمج
```

### بعد
```
widgets/home/notes_grid_view.dart              ← 95 سطر (orchestrator)
widgets/home/notes_grid/
├── notes_filter_controller.dart              ← منطق الفلترة + pagination + levenshtein
├── notes_sliver_view.dart                    ← NotesSliverView (UI)
├── note_card_wrapper.dart                    ← NoteCardWrapper
└── height_recorder.dart                      ← HeightRecorder
```

### تغيير معماري مهم
`NotesFilterController` أصبح `ChangeNotifier` — يُنشأ في `initState` ويُدمَّر في `dispose`.

`syncFromProvider` يُستدعى من `didChangeDependencies` بدل listener مباشر — هذا يضمن تزامن التصنيف.

### المشاكل المتوقعة عند الاختبار
- **Pagination:** اختبر مع 200+ ملاحظة أن التحميل التدريجي يعمل
- **البحث:** اختبر البحث الضبابي (levenshtein) مع كلمات عربية
- **التصنيف:** اختبر تغيير الكتالوج أن القائمة تتحدث فوراً
- **الحذف:** اختبر حذف ملاحظة أن تختفي من القائمة بدون إعادة بناء كاملة

---

## 4. version_history_screen.dart

### قبل
```
screens/other/version_history_screen.dart  ← 914 سطر
  - كل المنطق + 3 panels + ResizableDivider في ملف واحد
  - _filterAndSortNotes مدمجة في الـ state
  - _getActionIcon/_getActionColor مكررتان
```

### بعد
```
screens/other/version_history_screen.dart          ← 220 سطر (orchestrator)
screens/other/version_history/
├── version_history_controller.dart                ← ChangeNotifier (منطق)
├── panels/
│   ├── notes_panel.dart                           ← عمود النوتات
│   ├── versions_panel.dart                        ← عمود الإصدارات
│   └── diff_panel.dart                            ← عمود المقارنة
└── widgets/
    └── resizable_divider.dart                     ← ResizableDivider
```

### تغيير معماري مهم
`VersionHistoryController extends ChangeNotifier` — الشاشة تستمع له بـ `addListener(() { if (mounted) setState(() {}); })`.

`getActionIcon` و `getActionColor` أصبحتا `static` في الـ controller — يمكن استخدامهما من أي panel بدون context.

### المشاكل المتوقعة عند الاختبار
- **Wide layout:** اختبر على tablet/desktop أن الأعمدة تتغير حجمها بالسحب
- **Narrow layout:** اختبر الـ PageView على mobile أن الانتقال بين الصفحات سلس
- **Restore:** اختبر استعادة إصدار قديم أن القائمة تتحدث
- **Back navigation:** اختبر زر الرجوع في كل حالة (diff → versions → notes → exit)

---

## 5. date_indicator_bar.dart

### قبل
```
widgets/home/date_indicator_bar.dart  ← 737 سطر
  - DateIndicatorBar (state + منطق السكرول)
  - _showDatePicker (bottom sheet مدمج)
  - _showCategoryPicker (bottom sheet مدمج)
  - _BarWithSyncProgress (sync UI مدمج)
  - DateIndicatorDelegate
```

### بعد
```
widgets/home/date_indicator_bar.dart              ← 180 سطر (orchestrator)
widgets/home/date_indicator/
├── sync_progress_bar.dart                        ← SyncProgressBar
├── date_picker_sheet.dart                        ← DatePickerSheet.show()
└── date_bar_category_picker.dart                 ← DateBarCategoryPickerSheet.show()
```

### ملاحظة
`DateIndicatorDelegate` بقي في الملف الرئيسي لأنه مرتبط مباشرة بالـ widget ولا معنى لفصله.

### المشاكل المتوقعة عند الاختبار
- **Sync progress:** اختبر أثناء مزامنة Google Drive أن الشريط يظهر
- **Pull to refresh:** اختبر السحب للأسفل أن الـ progress يظهر تدريجياً
- **Date picker:** اختبر الضغط على التاريخ أن الـ sheet يفتح ويقفز للتاريخ الصحيح
- **Category picker:** اختبر تغيير الكتالوج من الشريط

---

## 6. quill_editor_widget.dart

### قبل
```
widgets/editor/quill_editor_widget.dart  ← 666 سطر
  - كل المنطق في _QuillEditorWidgetState:
    RTL/LTR detection + تشكيل + لصق + keyboard + دمعة + selection bar
```

### بعد
```
widgets/editor/quill_editor_widget.dart    ← 145 سطر (build فقط)
widgets/editor/quill_editor_controller.dart ← 340 سطر (كل المنطق)
```

### لماذا Controller وليس Mixin
الـ mixin (`quill_editor_state_mixin.dart`) كان موجوداً لكن:
- يخفي `setState` داخله — صعب تتبع متى يحدث rebuild
- لا يمكن اختباره بدون widget
- التشابك بين الـ flags (`_isDraggingSelection`, `_isFormatting`, `_suppressBar`) يصعب تتبعه عبر ملفين

الـ Controller:
- `rebuild` callback صريح — تعرف بالضبط متى يحدث `setState`
- كل الـ flags في مكان واحد مرئي
- يمكن اختباره unit test بدون UI

### تغيير معماري مهم
```dart
// قبل: setState مباشر في الـ state
if (effectiveDir != _textDirection) {
  setState(() => _textDirection = effectiveDir);
}

// بعد: callback صريح
if (effectiveDir != textDirection) {
  textDirection = effectiveDir;
  rebuild(); // ← صريح ومرئي
}
```

### المشاكل المتوقعة عند الاختبار
- **RTL/LTR:** اختبر كتابة عربي ثم إنجليزي أن الاتجاه يتغير
- **التشكيل:** اختبر حذف حرف مشكّل أن يُحذف التشكيل وليس الحرف
- **اللصق:** اختبر لصق نص مختلط أن التنسيق يُزال
- **الدمعة:** اختبر ظهور الدمعة بعد الضغط وسحبها
- **Selection bar:** اختبر تحديد نص أن الشريط يظهر

---

## مشاكل Quill المكتشفة وتم patch-ها

### أ) Cannot add to a fixed-length list
**الملف:** `flutter_quill-11.5.0/lib/src/editor/widgets/text/text_line.dart`

**السبب:** عند تحديد نص يشمل سطراً فارغاً، يحاول إضافة عنصر لقائمة `growable: false`.

**الحل:**
```dart
// قبل
_selectedRects ??= _body!.getBoxesForSelection(local);

// بعد
_selectedRects ??= _body!.getBoxesForSelection(local).toList(growable: true);
```

### ب) مقابض التحديد في مكان خاطئ مع نص BiDi
**الملفات:**
- `flutter_quill-11.5.0/lib/src/editor/widgets/text/text_line.dart`
- `flutter_quill-11.5.0/lib/src/editor/widgets/text/text_selection.dart`

**التفاصيل الكاملة:** [`docs/known-issues/SELECTION_HANDLE_DIRECTION_FIX.md`](SELECTION_HANDLE_DIRECTION_FIX.md)

**ملاحظة مهمة:** هذه التعديلات في `packages/flutter_quill/` (path dependency). عند تحديث المكتبة يجب إعادة تطبيقها.

---

## اختبارات يجب تنفيذها قبل الإصدار

### اختبارات وظيفية أساسية
- [ ] فتح ملاحظة نصية وتحريرها
- [ ] فتح ملاحظة كود وتحريرها
- [ ] فتح ملاحظة checklist وتحريرها
- [ ] إنشاء ملاحظة جديدة من كل نوع
- [ ] البحث في الملاحظات (عربي + إنجليزي + ضبابي)
- [ ] تغيير الكتالوج من الشريط العلوي
- [ ] فتح الإعدادات وتغيير الثيم/اللغة/الخط
- [ ] فتح سجل التاريخ واستعادة إصدار
- [ ] مزامنة Google Drive

### اختبارات الدمعة
- [ ] ظهور الدمعة بعد الضغط على النص
- [ ] سحب الدمعة لأعلى وأسفل
- [ ] سحب الدمعة مع السكرول
- [ ] اختفاء الدمعة عند الكتابة
- [ ] اختفاء الدمعة عند تحديد نص

### اختبارات التحديد
- [ ] تحديد كلمة بـ double tap
- [ ] تحديد نص بالسحب (عربي)
- [ ] تحديد نص بالسحب (إنجليزي)
- [ ] تحديد نص مختلط (عربي + إنجليزي)
- [ ] مقابض التحديد في المكان الصحيح

### اختبارات الأداء
- [ ] فتح ملاحظة بـ 5000+ حرف
- [ ] قائمة بـ 200+ ملاحظة مع pagination
- [ ] السكرول السريع في القائمة

---

## ملفات لم تُعدَّل (مقصود)

| الملف | السبب |
|-------|-------|
| `quill_editor_state_mixin.dart` | موجود للتوافق مع كود قديم، لا يُستخدم من الـ widget الجديد |
| `apex_magnifier.dart` | مكبر التحديد (selection) — مختلف عن مكبر الدمعة |
| `editor_build_methods.dart` | 601 سطر static methods — يحتاج جلسة منفصلة |
| `home_screen.dart` | 511 سطر — يحتاج تحليل أعمق للتبعيات |

---

## التوصيات للجلسة القادمة

1. **`editor_build_methods.dart`** (601 سطر) — تقسيم الـ static methods لملفات منفصلة حسب النوع (header, toolbar, content)
2. **`home_screen.dart`** (511 سطر) — استخراج منطق الـ pull-to-refresh والـ drawer
3. **حذف `quill_editor_state_mixin.dart`** — بعد التأكد أن لا شيء يستخدمه
4. **إضافة unit tests** لـ `NotesFilterController` و `QuillEditorController`
