# 📋 مهام إعادة هيكلة UI — نموذج العائلة السعيدة

**آخر تحديث:** 2026-05-17
**المصدر:** تقرير الفحص الشامل (سطر بسطر، حرف بحرف)

---

## الحالة العامة

| العضو | الدرجة | الحالة |
|-------|--------|--------|
| 👑 السيد — NoteStateService | 10/10 | ✅ مكتمل |
| 🏰 سيد القصر — NotesProvider | 9/10 | 🔴 P4 متبقي |
| 🧭 الابن المطيع — Navigation | 10/10 | ✅ مكتمل |
| 👸 الأميرة — UI | 6-8/10 | 🔴 7 مشاكل |
| 🛎️ الخادم — Services | 10/10 | ✅ مكتمل |

---

## المهام — مرتبة بالأولوية

---

### ✅ P4 — حذف `insertNote` alias
**الملف:** `lib/controllers/notes/notes_provider.dart`
**المشكلة:**
```dart
Future<int> insertNote(Note note) async => addNote(note);
```
- [x] حذف `insertNote` — لا يوجد استدعاء لها في `lib/`
- [x] التحقق من عدم وجود استدعاءات لها في الكود

---

### ✅ ASYNC — `vault_entry_screen` context بعد async
**الملف:** `lib/screens/auth/vault_entry_screen.dart`
- [x] إصلاح `_checkVaultStatus` — إضافة `if (!mounted) return` بعد كل await
- [x] إصلاح `_authenticateWithBiometric` — إضافة mounted checks
- [x] التحقق: صفر تحذيرات من المحلل ✅

---

### ✅ UI-NOTE — الأميرة تبني `Note` كامل (4 شاشات)
**المشكلة:** منطق أعمال (بناء الملاحظة الافتراضية) في الـ UI بدل Provider.

**الحل:** إضافة `createDefaultNote` و `createDefaultLockedNote` في `NotesProvider` — مصدر واحد للحقيقة.

#### UI-NOTE-1: `home_screen.dart`
- [x] `_navigateToEditor` يستدعي `notesProvider.createDefaultNote(...)` ✅

#### UI-NOTE-2: `reminder_dashboard.dart`
- [x] `onModeSelected` يستدعي `notesProvider.createDefaultNote(...)` ✅

#### UI-NOTE-3: `locked_notes_screen.dart`
- [x] `_createLockedNote` يستدعي `notesProvider.createDefaultLockedNote(...)` ✅

#### UI-NOTE-4: `home_screen_responsive.dart` (desktop)
- [x] `_navigateToNewNote` يستدعي `notesProvider.createDefaultNote(...)` ✅

**الملف المُضاف إليه:**
```dart
// NotesProvider — مصدر واحد لبناء الملاحظات الافتراضية
Note createDefaultNote({required NoteMode mode, required int colorIndex, List<int>? categoryIds})
Note createDefaultLockedNote({required NoteMode mode})
```

---

### ✅ UI1 — `_ImportSheet` في نفس ملف `locked_notes_screen`
**الملف:** `lib/screens/mobile/locked_notes_screen.dart`
- [x] إنشاء `vault_import_sheet.dart` — `VaultImportSheet` widget مستقل
- [x] نقل كل الكود (300+ سطر) للملف الجديد
- [x] تحديث import في `locked_notes_screen.dart`
- [x] حذف `dart:convert` الذي لم يعد مستخدماً
- [x] صفر تشخيصات ✅

---

### ✅ TRASH — `trash_screen` تبني Card يدوياً
**الملف:** `lib/screens/mobile/trash_screen.dart`
- [x] استبدال Card اليدوية بـ `NoteCardWidget` مع `source: 'trash'`
- [x] إضافة `_closeAllSlidables` في state field + dispose
- [x] حذف `_getTextColor` — لم تعد مستخدمة
- [x] حذف imports غير مستخدمة: `adaptive_color`, `checklist_formatter`, `note_editor`, `selected_note_provider`, `note_card_utils`
- [x] إضافة import لـ `ViewType` و `NoteCardWidget`
- [x] صفر تشخيصات ✅

---

### ✅ REMINDER-COLOR — `colorIndex: 0` hardcoded
**الملف:** `lib/screens/shared/tabs/reminder_dashboard.dart`
- [x] استبدال `colorIndex: 0` بـ `settings.getDefaultColorIndex(colorMode)` ✅

---

### ✅ DEAD — `_onSearchChanged` جسم فارغ
**الملف:** `lib/screens/mobile/home_screen.dart`
- [x] حذف `_onSearchChanged`
- [x] حذف `_searchController.addListener(_onSearchChanged)` من `initState`

---

### ✅ ARCHIVE-NOTIFIER — `ValueNotifier` في `itemBuilder`
**الملف:** `lib/screens/mobile/archive_screen.dart`
- [x] نقل `ValueNotifier` لـ state field `_closeAllSlidables`
- [x] dispose في `dispose()`

---

## سجل التقدم

| التاريخ | المهمة | الحالة | الاختبارات |
|---------|--------|--------|-----------|
| 2026-05-17 | إنشاء ملف المهام | ✅ | — |
| 2026-05-17 | P4: حذف `insertNote` alias | ✅ | 469/469 ✅ |
| 2026-05-17 | ASYNC: vault_entry mounted checks | ✅ | 469/469 ✅ |
| 2026-05-17 | DEAD: حذف `_onSearchChanged` | ✅ | 469/469 ✅ |
| 2026-05-17 | REMINDER-COLOR: colorIndex hardcoded | ✅ | 469/469 ✅ |
| 2026-05-17 | ARCHIVE-NOTIFIER: ValueNotifier في state | ✅ | 469/469 ✅ |

| 2026-05-17 | UI-NOTE: createDefaultNote/createDefaultLockedNote في Provider | ✅ | 469/469 ✅ |
| 2026-05-17 | DRAWER-VAULT: closeVaultIfOpen في Provider | ✅ | 469/469 ✅ |

---

## إحصائيات

| | |
|---|---|
| **إجمالي المهام** | 7 مشاكل، 15 مهمة فرعية |
| **مكتملة** | 7 مشاكل (15 مهمة فرعية) ✅ |
| **متبقية** | 0 |
| **الاختبارات الحالية** | 469/469 ✅ |

---

### ✅ DRAWER-VAULT — زر "حول وتواصل" يُغلق الخزنة قسراً
**الملفات:** `lib/widgets/home/home_drawer_widget.dart` + `lib/controllers/notes/notes_provider.dart`

**المشكلة:**
```dart
// الـ drawer كان يعرف كيف يُغلق الخزنة بنفسه
Navigator.of(context, rootNavigator: true).popUntil(...); // ← يُغلق الخزنة قسراً
AppDialog.show(context, const AboutScreen());
```

**الحل:**
- أُضيف `closeVaultIfOpen(BuildContext context)` في `NotesProvider`
- الـ drawer يطلب من Provider — لا يعرف شيئاً عن الخزنة
- إذا الخزنة مفتوحة → Provider يُغلقها ويُعيد المستخدم لشاشة البصمة عبر `VaultNavigator.exitVault`
- إذا الخزنة مغلقة → لا شيء يحدث

```dart
// NotesProvider — السيد يقرر
void closeVaultIfOpen(BuildContext context) {
  if (!_securityService.isVaultUnlocked) return;
  clearLockedSession(notify: true);
  VaultNavigator.exitVault(context);
}

// home_drawer_widget — الـ drawer يطلب فقط
Provider.of<NotesProvider>(context, listen: false).closeVaultIfOpen(context);
AppDialog.show(context, const AboutScreen());
```

- [x] إضافة `closeVaultIfOpen` في `NotesProvider`
- [x] حذف `popUntil` من زر "حول"
- [x] حذف `popUntil` من زر "تواصل"
- [x] إضافة import `NotesProvider` في `home_drawer_widget`
- [x] صفر تشخيصات ✅ | 469/469 ✅

جميع مشاكل نموذج العائلة السعيدة المكتشفة في الفحص الشامل تم إصلاحها.

### الملفات المُعدَّلة (الجولة الكاملة)
| الملف | التغيير |
|-------|---------|
| `lib/controllers/notes/notes_provider.dart` | حذف `insertNote` alias + إضافة `createDefaultNote` + `createDefaultLockedNote` |
| `lib/screens/auth/vault_entry_screen.dart` | mounted checks بعد كل await |
| `lib/screens/mobile/home_screen.dart` | حذف `_onSearchChanged` + الأميرة تطلب من Provider |
| `lib/screens/shared/tabs/reminder_dashboard.dart` | colorIndex hardcoded → settings + الأميرة تطلب من Provider |
| `lib/screens/mobile/archive_screen.dart` | ValueNotifier في state field |
| `lib/screens/mobile/locked_notes_screen.dart` | نقل ImportSheet + الأميرة تطلب من Provider |
| `lib/screens/mobile/vault_import_sheet.dart` | **ملف جديد** — VaultImportSheet widget |
| `lib/screens/mobile/trash_screen.dart` | Card يدوية → NoteCardWidget |
| `lib/screens/desktop/home_screen_responsive.dart` | الأميرة تطلب من Provider |

### درجات العائلة بعد الإصلاح
| العضو | قبل | بعد |
|-------|-----|-----|
| 👑 السيد | 10/10 | 10/10 |
| 🏰 سيد القصر | 9/10 | **10/10** |
| 🧭 الابن المطيع | 9/10 | **10/10** |
| 👸 الأميرة | 6-8/10 | **9/10** |
| 🛎️ الخادم | 10/10 | 10/10 |
