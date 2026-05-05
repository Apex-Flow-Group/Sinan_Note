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


---

### 7. وميض المؤشر أثناء السحب

**المشكلة:** المؤشر يومض بسرعة جنونية بعد الانتهاء من السحب، ولا يتوقف.

**السبب:** أثناء السحب، كل `updateSelection` يُشغّل `_onChangeTextEditingValue` في Quill الذي يستدعي `stopCursorTimer` + `startCursorTimer` — فتتراكم timers متعددة وتسبب وميض سريع غير طبيعي.

**الحل:** إضافة `suspended` flag في `CursorCont` يمنع أي timer من العمل أثناء السحب:

```dart
// في packages/flutter_quill/.../cursor.dart
bool _suspended = false;
set suspended(bool value) {
  _suspended = value;
  if (value) {
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _targetCursorVisibility = true;
    _blinkOpacityController.value = 1.0;
    color.value = _style.color;
    blink.value = true;
  } else {
    startCursorTimer(); // إعادة الوميض الطبيعي
  }
}

void startCursorTimer() {
  if (_isDisposed || _suspended) return; // ← الحماية
  // ...
}
```

```dart
// في cursor_tear_handle.dart
onDragStart: () {
  state.cursorCont.suspended = true;  // تثبيت المؤشر
},
onDragEnd: () {
  state.cursorCont.suspended = false; // إعادة الوميض
},
```

**النتيجة:** المؤشر ثابت ومرئي أثناء السحب، يعود للوميض الطبيعي بعد رفع الإصبع.

**الملفات المتأثرة:**
- `packages/flutter_quill/lib/src/editor/widgets/cursor.dart` ← إضافة `suspended`
- `packages/flutter_quill/lib/src/editor/raw_editor/raw_editor.dart` ← إضافة `cursorCont` getter في `EditorState`
- `packages/flutter_quill/lib/src/editor/raw_editor/raw_editor_state.dart` ← override الـ getter
- `lib/widgets/editor/tear/cursor_tear_handle.dart` ← استخدام `suspended`

---

### 8. إزاحة الدمعة عن الإصبع أثناء السحب

**المشكلة:** عند بدء السحب، الكرسر والدمعة يظهران فوق الإصبع بمقدار 6-10 بكسل.

**السبب:** الإصبع يكون على مركز الدمعة (أسفل الكرسر)، لكن `_updateDrag` يحسب السطر من موضع الإصبع مباشرة بدون تعويض — فيضع الكرسر على سطر أعلى من المتوقع.

**الحل:** إضافة إزاحة `+8` بكسل للأسفل في حساب `viewportDy`:

```dart
final scrollOffset = re.offset?.pixels ?? 0.0;
// إزاحة لتعويض أن الإصبع على الدمعة (أسفل الكرسر)
final viewportDy = local.dy - scrollOffset + 8;
final lineIndex = (viewportDy / lineH).floor();
```

**النتيجة:** الكرسر يتبع الإصبع بدقة أكبر أثناء السحب.

**الملفات المتأثرة:**
- `lib/widgets/editor/tear/tear_handle_widget.dart` ← إزاحة في `_updateDrag`
