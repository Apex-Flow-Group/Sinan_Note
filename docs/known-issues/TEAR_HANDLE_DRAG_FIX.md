# Cursor Tear Handle — Complete Fix Documentation

## ما تم في هذه الجلسة

### 1. تقسيم الملف لهيكل منطقي

الملف الأصلي `cursor_tear_handle.dart` كان يحتوي على كل شيء. تم تقسيمه إلى:

| الملف | المحتوى |
|-------|---------|
| `tear/cursor_tear_handle.dart` | المنطق والتحكم فقط |
| `tear/tear_handle_widget.dart` | الواجهة + السحب |
| `tear/tear_magnifier.dart` | المكبر |
| `tear/tear_painters.dart` | الرسامين (TearPainter + MagBgPainter) |
| `tear/tear.dart` | barrel export |

الملف القديم أصبح re-export للتوافق مع الكود الموجود.

---

### 2. مشكلة القفز عند الضغط على الدمعة

**المشكلة:** عند الضغط على الدمعة كان الكرسر يقفز سطراً للأسفل فوراً.

**السبب:** أول `onPointerMove` يمرر موضع الإصبع (على الدمعة = أسفل الكرسر) مباشرة لـ `getPositionForOffset` فيحسب السطر التالي.

**الحل:** منطق البلوكات — تقسيم المحرر لسطور بارتفاع `lineHeight` ثابت، وحساب رقم السطر من موضع الإصبع في الـ viewport:

```dart
final viewportDy = local.dy - scrollOffset;
final lineIndex = (viewportDy / lineH).floor();
final targetLocal = Offset(local.dx, lineIndex * lineH + lineH / 2);
```

---

### 3. مشكلة الانزياح مع السكرول

**المشكلة:** كلما نزل المستخدم في النص، كلما انزاح الكرسر أكثر عن موضع الإصبع.

**السبب:** `re.globalToLocal(fingerPos)` يعطي إحداثيات شاملة السكرول، لكن `getPositionForOffset` يتوقع إحداثيات الـ viewport فقط.

**الحل:** طرح `scrollOffset` قبل الحساب، وتمرير viewport coordinates مباشرة:

```dart
final scrollOffset = re.offset?.pixels ?? 0.0;
final viewportDy = local.dy - scrollOffset;
final lineIndex = (viewportDy / lineH).floor();
final targetLocal = Offset(local.dx, lineIndex * lineH + lineH / 2);
final pos = re.getPositionForOffset(targetLocal); // viewport coords فقط
```

---

### 4. مشكلة تجميد اللمس

**المشكلة:** بعد الضغط على الدمعة، كان اللمس يتجمد ولا يصل للمحرر.

**السبب:** `HitTestBehavior.opaque` يمنع كل الأحداث من الوصول للمحرر دائماً.

**الحل:** `opaque` أثناء السحب فقط، `translucent` في باقي الأوقات:

```dart
behavior: _dragging ? HitTestBehavior.opaque : HitTestBehavior.translucent,
```

---

### 5. مشكلة setState بعد dispose

**المشكلة:** `setState() called after dispose()` عند رفع الإصبع.

**السبب:** `PointerUpEvent` يصل للـ widget بعد إزالته من الشجرة.

**الحل:**
```dart
void _endDrag() {
  if (!mounted) return;
  setState(() => _dragging = false);
  widget.onDragEnd();
}
```

---

### 6. إضافات بصرية

- `magnificationScale: 1.0` — إرجاع حجم المكبر للافتراضي
- حد `1.2px` على المكبر لإعطاء إحساس العمق وفصله عن الخلفية

---

## الملفات المتأثرة

- `lib/widgets/editor/tear/` (مجلد جديد كامل)
- `lib/widgets/editor/cursor_tear_handle.dart` (re-export)
- `lib/widgets/editor/quill_editor_widget.dart` (تحديث الاستيراد)
- `lib/widgets/editor/quill_editor_state_mixin.dart` (StableScrollController → public)

## ملاحظة مهمة

`re.offset` في Quill هو `ViewportOffset?` — يمثل موضع السكرول. `getPositionForOffset` يتوقع دائماً إحداثيات الـ viewport وليس المستند الكامل.
