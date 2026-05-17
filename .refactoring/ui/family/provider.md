# 🏰 سيد القصر — NotesProvider

**الملف:** `lib/controllers/notes/notes_provider.dart`
**الدور:** يجهّز الخدمات، يُلبّي أوامر السيد، يُشعر الـ UI

---

## التبعيات (5 services)

```dart
NoteStateService        _stateService    // السيد
SqliteDatabaseService   _dbService       // قاعدة البيانات
NoteSecurityService     _securityService // أمان الخزنة
NoteSideEffectService   _sideEffectService // التذكيرات + Widget
NoteBatchOperationsService _batchService // عمليات الجملة
```

---

## الـ Public API

### قراءة (Getters)
| Getter | المصدر |
|--------|--------|
| `activeNotes` / `notes` | `_stateService` |
| `archivedNotes` | `_stateService` |
| `trashedNotes` | `_stateService` |
| `reminderNotes` | `_stateService` |
| `lockedNotes` | `_stateService` |
| `isVaultUnlocked` | `_securityService` |
| `isLoading` | local `_isLoading` |
| `refreshStamp` | local `_refreshStamp` |

### كتابة (Commands)
| الدالة | DB؟ | State؟ | Notify؟ |
|--------|-----|--------|---------|
| `addNote()` | ✅ | ✅ | ✅ |
| `updateNote()` | ✅ | ✅ | ✅ (إلا silent) |
| `deleteNote()` | ✅ | ✅ | ✅ |
| `archiveNote()` | ✅ | ✅ | ✅ |
| `unarchiveNote()` | ✅ | ✅ | ✅ |
| `trashNote()` | ✅ | ✅ | ✅ |
| `restoreNote()` | ✅ | ✅ | ✅ |
| `convertNoteType()` | ✅ | ✅ | ✅ |
| `duplicateNote()` | ✅ | ✅ | ✅ |
| `toggleLockStatus()` | ✅ | ✅ | ✅ |

---

## المشاكل المكتشفة

### 🔴 P1 — `convertNoteType()` تحديث مزدوج
```dart
Future<void> convertNoteType(...) async {
  await _dbService.updateNote(updated);
  _stateService.updateNote(updated);
  _refreshStamp++;
  notifyListeners();       // ← إشعار أول
  await refreshAllNotes(); // ← يُشعر مرة ثانية!
}
```
**الأثر:** الـ UI يُعاد بناؤه مرتين — flutter rebuild مزدوج.
**الحل:** حذف `await refreshAllNotes()` — `_stateService.updateNote()` كافية.

### 🟠 P2 — `archiveNote/unarchiveNote/trashNote/restoreNote` نمط متكرر
```dart
// نفس النمط في 4 دوال:
final result = await _dbService.archiveNote(id);
final note = await _dbService.getNoteById(id);  // قراءة إضافية من DB
if (note != null) _stateService.updateNote(note);
notifyListeners();
```
**الأثر:** قراءة إضافية من DB بعد كل عملية — يمكن تجنبها.
**الحل:** استخدام `copyWith` على الملاحظة الموجودة في الـ state بدلاً من إعادة القراءة.

### 🟡 P3 — `loadNotes()` و `refreshAllNotes()` متداخلتان
```dart
Future<void> loadNotes({bool force = false}) async {
  if (_isLoading) return;
  if (!force && _stateService.isInitialDataLoaded) return;
  refreshAllNotes().then((_) {}).catchError((e) {}); // fire-and-forget
}

Future<void> getNotes() async {
  await refreshAllNotes(); // تنتظر
  return activeNotes;
}
```
**الأثر:** `loadNotes` تُطلق `refreshAllNotes` بدون انتظار — صعوبة في التتبع.

### 🟡 P4 — `insertNote` alias غير ضروري
```dart
Future<int> insertNote(Note note) async => addNote(note);
```
**الأثر:** alias بلا قيمة — يُربك القارئ.

---

## التقييم

| المعيار | الدرجة |
|---------|--------|
| وضوح المسؤولية | 8/10 |
| نظافة الكود | 7/10 |
| الأداء | 7/10 |
| **الإجمالي** | **7.5/10** |

**الحكم:** P1 إصلاح فوري — P2 تحسين مهم — P3/P4 تنظيف.
