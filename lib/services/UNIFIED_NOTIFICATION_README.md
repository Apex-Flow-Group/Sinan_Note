# 🔔 Unified Notification Service

## نظام الإشعارات الموحد والشامل

نظام إشعارات احترافي موحد يدعم جميع أحجام الشاشات (موبايل، تابلت، ديسكتوب) مع تموضع ذكي وتجربة مستخدم محسّنة.

---

## ✨ المميزات

### 1. تموضع ذكي حسب حجم الشاشة
- **موبايل**: أسفل الشاشة على امتداد العرض الكامل
- **تابلت**: وسط أسفل الشاشة بعرض 500px
- **ديسكتوب**: وسط أسفل الشاشة بعرض 400px

### 2. أنواع متعددة من الإشعارات
- ✅ **Success**: للعمليات الناجحة (أخضر)
- ❌ **Error**: للأخطاء (أحمر)
- ⚠️ **Warning**: للتحذيرات (برتقالي)
- ℹ️ **Info**: للمعلومات (أزرق)

### 3. وظائف متقدمة
- زر تراجع (Undo) مع مؤقت دائري
- Optimistic UI Support
- إدارة الإجراءات المعلقة
- إلغاء تلقائي للإشعارات المتعارضة
- دعم الإجراءات المخصصة

### 4. تصميم متجاوب
- تكيف تلقائي مع حجم الشاشة
- هوامش وعرض ديناميكي
- دعم الوضع الليلي والنهاري

---

## 📖 الاستخدام

### 1. إشعار بسيط

```dart
import 'package:sinan_note/services/unified_notification_service.dart';

// إشعار نجاح
UnifiedNotificationService().show(
  context: context,
  message: 'تم الحفظ بنجاح',
  type: NotificationType.success,
);

// إشعار خطأ
UnifiedNotificationService().show(
  context: context,
  message: 'فشل في الحفظ',
  type: NotificationType.error,
  duration: Duration(seconds: 5),
);

// إشعار معلومات
UnifiedNotificationService().show(
  context: context,
  message: 'جاري المزامنة...',
  type: NotificationType.info,
);

// إشعار تحذير
UnifiedNotificationService().show(
  context: context,
  message: 'يرجى تسجيل الدخول أولاً',
  type: NotificationType.warning,
);
```

### 2. إشعار مع زر تراجع (Undo)

```dart
// حذف ملاحظات مع إمكانية التراجع
void _deleteNotes(List<int> ids) {
  // 1. إخفاء العناصر فوراً (Optimistic UI)
  setState(() {
    _hiddenIds.addAll(ids);
    _selectedIds.clear();
  });
  
  // 2. عرض إشعار مع زر تراجع
  UnifiedNotificationService().showWithUndo(
    context: context,
    message: 'تم حذف ${ids.length} ملاحظة',
    actionKey: 'delete_notes_home',
    type: NotificationType.info,
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
  );
}

// أرشفة ملاحظات
void _archiveNotes(List<int> ids) {
  setState(() => _hiddenIds.addAll(ids));
  
  UnifiedNotificationService().showWithUndo(
    context: context,
    message: 'تم أرشفة ${ids.length} ملاحظة',
    actionKey: 'archive_notes',
    type: NotificationType.info,
    onExecute: () async {
      for (final id in ids) {
        await notesProvider.archiveNote(id);
      }
      if (mounted) {
        setState(() => _hiddenIds.removeAll(ids));
      }
    },
    onUndo: () {
      if (mounted) {
        setState(() => _hiddenIds.removeAll(ids));
      }
    },
  );
}
```

### 3. إشعار مع إجراء مخصص

```dart
UnifiedNotificationService().showWithAction(
  context: context,
  message: 'تحديث جديد متوفر',
  actionLabel: 'تحديث',
  type: NotificationType.info,
  duration: Duration(seconds: 5),
  onAction: () {
    // فتح صفحة التحديث
    Navigator.push(context, ...);
  },
);
```

### 4. تموضع مخصص

```dart
// إشعار في الأعلى
UnifiedNotificationService().show(
  context: context,
  message: 'رسالة مهمة',
  type: NotificationType.warning,
  position: NotificationPosition.top,
);

// إشعار في الأعلى بالوسط
UnifiedNotificationService().show(
  context: context,
  message: 'تنبيه',
  type: NotificationType.error,
  position: NotificationPosition.topCenter,
);
```

---

## 🎯 أفضل الممارسات

### 1. استخدام مفاتيح فريدة (Action Keys)

```dart
// ✅ صحيح: مفاتيح فريدة لكل عملية
'delete_notes_home'
'delete_notes_archive'
'archive_notes_home'
'restore_notes_trash'

// ❌ خطأ: نفس المفتاح لعمليات مختلفة
'delete_notes'
'delete_notes'  // تعارض!
```

### 2. إلغاء الإجراءات عند الخروج

```dart
class _MyScreenState extends State<MyScreen> {
  final Set<int> _hiddenIds = {};
  
  @override
  void dispose() {
    // إلغاء جميع الإجراءات المعلقة
    UnifiedNotificationService().cancelAll();
    super.dispose();
  }
}
```

### 3. التحقق من mounted قبل setState

```dart
UnifiedNotificationService().showWithUndo(
  context: context,
  message: 'تم الحذف',
  actionKey: 'delete',
  onExecute: () async {
    await deleteOperation();
    // ✅ التحقق من mounted
    if (mounted) {
      setState(() => _hiddenIds.clear());
    }
  },
  onUndo: () {
    // ✅ التحقق من mounted
    if (mounted) {
      setState(() => _hiddenIds.clear());
    }
  },
);
```

### 4. نسخ القوائم قبل العمليات غير المتزامنة

```dart
// ✅ صحيح: نسخ القائمة
final ids = List<int>.from(_selectedIds);
UnifiedNotificationService().showWithUndo(...);

// ❌ خطأ: استخدام المرجع مباشرة
UnifiedNotificationService().showWithUndo(
  onExecute: () async {
    for (final id in _selectedIds) { // قد تتغير أثناء التنفيذ!
      await delete(id);
    }
  },
);
```

---

## 🔄 الترحيل من الأنظمة القديمة

### من ApexSnackBar

```dart
// قديم
ApexSnackBar.show(
  context,
  'تم الحفظ',
  type: SnackBarType.success,
);

// جديد
UnifiedNotificationService().show(
  context: context,
  message: 'تم الحفظ',
  type: NotificationType.success,
);
```

### من ToastService

```dart
// قديم
ToastService().showUndoToast(
  context: context,
  message: 'تم الحذف',
  actionKey: 'delete',
  onExecute: () => delete(),
  onUndo: () => restore(),
);

// جديد
UnifiedNotificationService().showWithUndo(
  context: context,
  message: 'تم الحذف',
  actionKey: 'delete',
  onExecute: () => delete(),
  onUndo: () => restore(),
);
```

### من ScaffoldMessenger مباشرة

```dart
// قديم
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('رسالة'),
    backgroundColor: Colors.green,
  ),
);

// جديد
UnifiedNotificationService().show(
  context: context,
  message: 'رسالة',
  type: NotificationType.success,
);
```

---

## 📱 التموضع حسب حجم الشاشة

### موبايل (< 600px)
```
┌─────────────────────┐
│                     │
│                     │
│      Content        │
│                     │
│                     │
├─────────────────────┤
│ ✓ Message    [Undo] │ ← أسفل الشاشة (عرض كامل)
└─────────────────────┘
```

### تابلت (600-1024px)
```
┌─────────────────────────────┐
│                             │
│         Content             │
│                             │
│                             │
│  ┌───────────────────┐      │
│  │ ✓ Message  [Undo] │      │ ← وسط أسفل (500px)
│  └───────────────────┘      │
└─────────────────────────────┘
```

### ديسكتوب (> 1024px)
```
┌─────────────────────────────────┐
│                                 │
│           Content               │
│                                 │
│                                 │
│    ┌─────────────────┐          │
│    │ ✓ Message [Undo]│          │ ← وسط أسفل (400px)
│    └─────────────────┘          │
└─────────────────────────────────┘
```

---

## 🎨 الألوان

### الوضع النهاري
- Success: `#43A047` (أخضر)
- Error: `#E53935` (أحمر)
- Warning: `#FB8C00` (برتقالي)
- Info: `#1E88E5` (أزرق)

### الوضع الليلي
- Success: `#2E7D32` (أخضر داكن)
- Error: `#C62828` (أحمر داكن)
- Warning: `#EF6C00` (برتقالي داكن)
- Info: `#1565C0` (أزرق داكن)

---

## ⚡ الأداء

### مقارنة مع الأنظمة القديمة

| الميزة | النظام القديم | النظام الموحد |
|--------|---------------|---------------|
| عدد الملفات | 3 ملفات | ملف واحد |
| التموضع الذكي | ❌ | ✅ |
| Optimistic UI | ✅ | ✅ |
| إدارة الذاكرة | جيد | ممتاز |
| دعم الأحجام | محدود | شامل |
| سهولة الاستخدام | متوسط | عالي |

---

## 🧪 الاختبار

```dart
// اختبار الإشعار البسيط
testWidgets('should show simple notification', (tester) async {
  await tester.pumpWidget(MyApp());
  
  UnifiedNotificationService().show(
    context: tester.element(find.byType(Scaffold)),
    message: 'Test message',
    type: NotificationType.success,
  );
  
  await tester.pump();
  expect(find.text('Test message'), findsOneWidget);
});

// اختبار زر التراجع
testWidgets('should handle undo action', (tester) async {
  var executed = false;
  var undone = false;
  
  UnifiedNotificationService().showWithUndo(
    context: tester.element(find.byType(Scaffold)),
    message: 'Deleted',
    actionKey: 'test_delete',
    onExecute: () => executed = true,
    onUndo: () => undone = true,
  );
  
  await tester.tap(find.byIcon(Icons.undo));
  await tester.pump();
  
  expect(undone, true);
  expect(executed, false);
});
```

---

## 📝 ملاحظات مهمة

1. **استخدم مفاتيح فريدة** لكل نوع عملية لتجنب التعارضات
2. **استدعِ `cancelAll()`** في `dispose()` لتجنب تسرب الذاكرة
3. **تحقق من `mounted`** قبل `setState()` في الـ callbacks
4. **انسخ القوائم** قبل العمليات غير المتزامنة
5. **استخدم النوع المناسب** للإشعار (success, error, info, warning)

---

## 🔮 التحسينات المستقبلية

- [ ] دعم الإشعارات المتعددة (Queue)
- [ ] رسوم متحركة مخصصة
- [ ] دعم الاهتزاز (Haptic Feedback)
- [ ] أصوات الإشعارات
- [ ] تحسينات إمكانية الوصول
- [ ] دعم RTL محسّن
- [ ] سمات مخصصة (Custom Themes)

---

## 📄 الترخيص

Copyright © 2025 Apex Flow Group. All rights reserved.

---

**صُنع بـ ❤️ لتجربة مستخدم أفضل**
