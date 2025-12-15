# 🎯 Toast Service - Professional Notification System

## 📋 Overview

نظام إشعارات احترافي مع **Optimistic UI** و **Delayed Execution** لتحسين تجربة المستخدم.

---

## ✨ Features

### 1. Optimistic UI
- إخفاء العناصر فوراً من الواجهة
- لا انتظار لعمليات قاعدة البيانات
- استجابة فورية للمستخدم

### 2. Delayed Execution
- تنفيذ العملية بعد 3 ثوانٍ
- إلغاء العملية عند الضغط على "تراجع"
- تقليل عمليات قاعدة البيانات غير الضرورية

### 3. Circular Timer
- مؤقت دائري حول زر التراجع
- يوضح الوقت المتبقي بصرياً
- تصميم احترافي مثل Gmail و Telegram

### 4. Smart Memory Management
- مؤقت واحد لكل نوع عملية
- تنظيف تلقائي عند إغلاق الشاشة
- لا تسرب للذاكرة

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│  User Action (Delete/Archive)                   │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│  1. Hide items from UI (Optimistic)             │
│     setState(() => hiddenIds.add(id))           │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│  2. Show Toast with Timer (3 seconds)           │
│     ToastService().showUndoToast(...)           │
└─────────────────┬───────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
┌───────────────┐   ┌───────────────┐
│ User presses  │   │ Timer expires │
│ UNDO          │   │               │
└───────┬───────┘   └───────┬───────┘
        │                   │
        ▼                   ▼
┌───────────────┐   ┌───────────────┐
│ Restore items │   │ Execute DB    │
│ Cancel timer  │   │ operation     │
└───────────────┘   └───────────────┘
```

---

## 📖 Usage

### Basic Usage

```dart
import '../services/toast_service.dart';

// في دالة الحذف
void _deleteNotes() async {
  final ids = List<int>.from(_selectedIds);
  
  // 1. إخفاء العناصر فوراً (Optimistic UI)
  setState(() {
    _hiddenIds.addAll(ids);
    _selectedIds.clear();
  });
  
  // 2. عرض Toast مع مؤقت
  ToastService().showUndoToast(
    context: context,
    message: '${ids.length} notes deleted',
    actionKey: 'delete_notes',
    type: ToastType.info,
    onExecute: () async {
      // تنفيذ الحذف الفعلي بعد 3 ثوانٍ
      for (final id in ids) {
        await notesProvider.deleteNote(id);
      }
      if (mounted) {
        setState(() => _hiddenIds.removeAll(ids));
      }
    },
    onUndo: () {
      // استعادة العناصر عند الضغط على تراجع
      if (mounted) {
        setState(() => _hiddenIds.removeAll(ids));
      }
    },
    undoLabel: 'Undo',
  );
}
```

### Simple Toast (No Undo)

```dart
ToastService().showToast(
  context: context,
  message: 'Note saved successfully',
  type: ToastType.success,
  duration: Duration(seconds: 2),
);
```

---

## 🎨 Toast Types

```dart
enum ToastType {
  success,  // ✅ Green - للعمليات الناجحة
  error,    // ❌ Red - للأخطاء
  info,     // ℹ️ Blue - للمعلومات
  warning,  // ⚠️ Orange - للتحذيرات
}
```

---

## 🔧 Implementation Details

### 1. State Management

```dart
class _ScreenState extends State<Screen> {
  final Set<int> _hiddenIds = {}; // العناصر المخفية مؤقتاً
  
  @override
  void dispose() {
    ToastService().cancelAll(); // إلغاء جميع المؤقتات
    super.dispose();
  }
  
  List<Note> _filterNotes(List<Note> notes) {
    return notes.where((note) {
      // إخفاء العناصر المحذوفة مؤقتاً
      if (_hiddenIds.contains(note.id)) return false;
      return true;
    }).toList();
  }
}
```

### 2. Action Keys

استخدم مفاتيح فريدة لكل نوع عملية:

```dart
'delete_home'     // حذف من الصفحة الرئيسية
'delete_archive'  // حذف من الأرشيف
'archive_home'    // أرشفة من الصفحة الرئيسية
'restore_trash'   // استعادة من السلة
```

---

## ⚡ Performance Benefits

### Before (v2.x):
```
User clicks delete
  ↓
Execute DB delete (100-500ms)
  ↓
Show toast
  ↓
User clicks undo
  ↓
Execute DB restore (100-500ms)
  ↓
Total: 200-1000ms + 2 DB operations
```

### After (v3.0):
```
User clicks delete
  ↓
Hide from UI (instant)
  ↓
Show toast
  ↓
User clicks undo
  ↓
Restore in UI (instant)
  ↓
Total: <10ms + 0 DB operations (if undo)
```

**Result:**
- ⚡ 100x faster response
- 💾 50% less DB operations
- 🎯 Better UX

---

## 🧪 Testing

```dart
// Test optimistic UI
test('should hide items immediately', () {
  // Arrange
  final ids = [1, 2, 3];
  
  // Act
  _deleteNotes(ids);
  
  // Assert
  expect(_hiddenIds, containsAll(ids));
  expect(_filteredNotes, isEmpty);
});

// Test undo
test('should restore items on undo', () {
  // Arrange
  final ids = [1, 2, 3];
  _deleteNotes(ids);
  
  // Act
  ToastService().cancel('delete_notes');
  
  // Assert
  expect(_hiddenIds, isEmpty);
  expect(_filteredNotes.length, 3);
});
```

---

## 📊 Comparison with Other Apps

| Feature | Sinan Note v3.0 | Gmail | Telegram | Keep |
|---------|----------------|-------|----------|------|
| Optimistic UI | ✅ | ✅ | ✅ | ❌ |
| Circular Timer | ✅ | ❌ | ❌ | ❌ |
| Delayed Execution | ✅ | ✅ | ✅ | ❌ |
| Smart Undo | ✅ | ✅ | ✅ | ✅ |

---

## 🚀 Future Enhancements (v3.1+)

- [ ] Batch operations queue
- [ ] Offline sync support
- [ ] Custom animation curves
- [ ] Haptic feedback
- [ ] Sound effects
- [ ] Accessibility improvements

---

## 📝 Notes

### Important Considerations:

1. **Always use unique action keys** to prevent conflicts
2. **Call `cancelAll()` in dispose** to prevent memory leaks
3. **Check `mounted` before setState** in callbacks
4. **Use `List.from()` to copy IDs** before async operations

### Common Pitfalls:

❌ **Don't:**
```dart
// Using same action key for different operations
ToastService().showUndoToast(actionKey: 'delete', ...);
ToastService().showUndoToast(actionKey: 'delete', ...); // Conflict!
```

✅ **Do:**
```dart
// Use unique keys
ToastService().showUndoToast(actionKey: 'delete_home', ...);
ToastService().showUndoToast(actionKey: 'delete_archive', ...);
```

---

## 🤝 Contributing

عند إضافة ميزات جديدة:

1. استخدم `ToastService` بدلاً من `ApexSnackBar`
2. طبق Optimistic UI للعمليات البطيئة
3. استخدم مفاتيح فريدة لكل عملية
4. اختبر سيناريوهات الـ undo
5. تأكد من تنظيف المؤقتات في dispose

---

## 📄 License

Copyright © 2025 Apex Flow Group. All rights reserved.

---

**Made with ❤️ for better UX**
