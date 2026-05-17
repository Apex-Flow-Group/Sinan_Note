# 👑 السيد — NoteStateService

**الملف:** `lib/services/note_services/note_state_service.dart`
**الدور:** يملك الحقيقة الوحيدة لحالة الملاحظات في الذاكرة

---

## ما يملكه

| الحقل | النوع | الوصف |
|-------|-------|-------|
| `_allNotes` | `List<Note>` | كل الملاحظات (نشطة + أرشيف + سلة) |
| `_lockedNotes` | `List<Note>` | ملاحظات الخزنة (مفصولة) |
| `_isInitialDataLoaded` | `bool` | هل تم التحميل الأول؟ |
| `_sortDebounce` | `Timer?` | debounce للترتيب |
| `_syncDebounce` | `Timer?` | debounce للمزامنة (5 ثوانٍ) |
| `_isSyncing` | `bool` | حماية من التزامن المتوازي |

## الـ Cache

| الحقل | يُبطَل عند |
|-------|-----------|
| `_cachedActiveNotes` | أي تغيير في `_allNotes` |
| `_cachedArchivedNotes` | أي تغيير في `_allNotes` |
| `_cachedTrashedNotes` | أي تغيير في `_allNotes` |

**ملاحظة:** `reminderNotes` لا يُخزَّن في cache — يُحسب في كل مرة.

---

## الأوامر (Public API)

| الدالة | تُبطل Cache؟ | تُزامن؟ | تُرتّب؟ |
|--------|-------------|---------|---------|
| `updateAllNotes()` | ✅ | ❌ | ✅ فوري |
| `updateNote()` | ✅ | ✅ | ✅ فوري |
| `addNote()` | ✅ | ✅ | ✅ فوري |
| `removeNote()` | ✅ | ✅ | ❌ |
| `batchUpdateNotes()` | ✅ | ✅ | ❌ |
| `updateLockedNotes()` | ❌ | ❌ | ❌ |
| `clearLockedNotes()` | ❌ | ❌ | ❌ |

---

## Callbacks (تواصل مع الخارج)

```dart
Future<void> Function()? onSyncCompleted;         // → NotesProvider._refreshAfterSync()
Future<void> Function()? onCategoriesRefreshNeeded; // → CategoriesProvider.refreshCategories()
```

يُسجَّلان في `MainLayoutScreen.initState()` — بعد أول frame.

---

## المشاكل المكتشفة

### 🟡 M1 — `reminderNotes` بلا cache
```dart
// يُحسب من صفر في كل استدعاء
List<Note> get reminderNotes {
  return _allNotes.where((n) =>
    n.reminderDateTime != null && !n.isLocked && !n.isTrashed &&
    n.reminderDateTime!.isAfter(DateTime.now())).toList();
}
```
**الأثر:** إذا كان هناك 1000 ملاحظة وتُستدعى كثيراً → O(n) في كل مرة.
**الحل:** إضافة `_cachedReminderNotes` مع invalidation.

### 🟡 M2 — `updateNote()` يُرتّب ثم يعمل `List.from` بشكل منفصل
```dart
void updateNote(Note note) {
  // ...
  sortNotes(immediate: true);   // يُرتّب _allNotes
  _allNotes = List.from(_allNotes); // نسخة جديدة — لماذا؟
  _invalidateCache();
  _silentSync();
}
```
**الأثر:** `List.from` بعد الترتيب مباشرة — لا قيمة منها.
**الحل:** حذف `_allNotes = List.from(_allNotes)`.

### 🟢 M3 — `_silentSync` يستدعي `CloudSyncGateway.markDirty()` مرتين
في `removeNote()`:
```dart
CloudSyncGateway.markDirty(); // مرة صريحة
_silentSync();                // و_silentSync تستدعيها أيضاً
```

---

## التقييم

| المعيار | الدرجة |
|---------|--------|
| وضوح المسؤولية | 9/10 |
| نظافة الكود | 8/10 |
| الأداء | 7/10 |
| **الإجمالي** | **8/10** |

**الحكم:** نظيف بشكل عام — M2 و M3 إصلاحات صغيرة.
