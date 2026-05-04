# Selection Handles — RTL/LTR Mixed Text Fix

## المشكلة

عند تحديد نص مختلط (عربي + إنجليزي) في المحرر، مشكلتان:

1. **موقع الدمعتين**: تظهران متلاصقتين في المنتصف بدلاً من طرفي التحديد
2. **اتجاه الدمعة**: ثابت دائماً (RTL) بغض النظر عن اتجاه النص الفعلي عند نقطة التحديد

**مثال:**
```
النص: "لطالما غُرفت فلاتر (Flutter) بكونها الإطار"
التحديد: كلمة "Flutter"
✗ الدمعتان متلاصقتان في المنتصف، كلاهما RTL
✓ دمعة يمين عند F ودمعة يسار عند r، كلاهما LTR
```

---

## السبب الجذري

### مشكلة الموقع (`text_line.dart`)

```dart
// الكود الأصلي المعطوب:
final targetBox = first ? boxes.first : boxes.last;
return TextSelectionPoint(
  Offset(first ? targetBox.start : targetBox.end, targetBox.bottom),
  targetBox.direction,
);
```

`boxes.first` و `boxes.last` في نص BiDi مختلط قد يشيران لنفس الصندوق أو صناديق بترتيب بصري خاطئ. `targetBox.start` و `targetBox.end` يتأثران بإعادة ترتيب الـ BiDi.

### مشكلة الاتجاه (`text_selection.dart`)

```dart
// الكود الأصلي:
type = _chooseType(
  widget.renderObject.textDirection,  // ← RTL دائماً
  TextSelectionHandleType.left,
  TextSelectionHandleType.right,
);
```

`renderObject.textDirection` هو الاتجاه العام للمحرر (RTL دائماً في تطبيقنا)، لا يراعي اتجاه النص الفعلي عند نقطة التحديد.

---

## الحل

### الجزء 1 — موقع الدمعتين (`text_line.dart`)

استبدال `boxes.first/last` + `start/end` بـ `getOffsetForCaret` الذي يعطي الموقع الدقيق للحرف:

```dart
TextSelectionPoint _getEndpointForSelection(
    TextSelection textSelection, bool first) {
  if (textSelection.isCollapsed) {
    return TextSelectionPoint(
        Offset(0, preferredLineHeight(textSelection.extent)) +
            getOffsetForCaret(textSelection.extent),
        null);
  }
  final boxes = _getBoxes(textSelection);
  assert(boxes.isNotEmpty);
  if (first) {
    final caretOffset = getOffsetForCaret(textSelection.base);
    return TextSelectionPoint(
      Offset(caretOffset.dx, boxes.first.bottom),
      boxes.first.direction,
    );
  } else {
    final caretOffset = getOffsetForCaret(textSelection.extent);
    return TextSelectionPoint(
      Offset(caretOffset.dx, boxes.last.bottom),
      boxes.last.direction,
    );
  }
}
```

**لماذا يعمل:** `getOffsetForCaret(position)` يحسب الموقع البصري الدقيق للحرف بغض النظر عن ترتيب الـ BiDi. الـ Y يأتي من `boxes.bottom` والـ X من الـ caret.

### الجزء 2 — اتجاه الدمعة (`text_selection.dart`)

ثلاثة تعديلات:

**أ) إضافة `resolvedDirection` كـ parameter في `_TextSelectionHandleOverlay`:**

```dart
class _TextSelectionHandleOverlay extends StatefulWidget {
  // ... الحقول الموجودة ...
  final TextDirection resolvedDirection;  // ← جديد
}
```

**ب) حساب الاتجاه مرة واحدة في `_buildHandle` من أول حرف في النص المحدد:**

```dart
Widget _buildHandle(BuildContext context, _TextSelectionHandlePosition position) {
  // ...
  return _TextSelectionHandleOverlay(
    // ... الحقول الموجودة ...
    resolvedDirection: _resolveSelectionDirection(),  // ← جديد
  );
}

TextDirection _resolveSelectionDirection() {
  try {
    final docText = renderObject.document.toPlainText();
    final start = _selection.start.clamp(0, docText.length);
    final end = _selection.end.clamp(0, docText.length);
    final selected = docText.substring(start, end);
    for (final ch in selected.split('')) {
      final cp = ch.codeUnitAt(0);
      if ((cp >= 0x0600 && cp <= 0x06FF) ||   // Arabic
          (cp >= 0x0750 && cp <= 0x077F) ||   // Arabic Supplement
          (cp >= 0xFB50 && cp <= 0xFDFF) ||   // Arabic Presentation A
          (cp >= 0xFE70 && cp <= 0xFEFF) ||   // Arabic Presentation B
          (cp >= 0x0590 && cp <= 0x05FF)) {   // Hebrew
        return TextDirection.rtl;
      }
      if ((cp >= 0x0041 && cp <= 0x005A) ||   // A-Z
          (cp >= 0x0061 && cp <= 0x007A)) {   // a-z
        return TextDirection.ltr;
      }
    }
  } catch (_) {}
  return renderObject.textDirection;
}
```

**ج) استخدام `widget.resolvedDirection` في `_chooseType` بدلاً من `widget.renderObject.textDirection`:**

```dart
type = _chooseType(
  widget.resolvedDirection,  // ← بدلاً من widget.renderObject.textDirection
  TextSelectionHandleType.left,
  TextSelectionHandleType.right,
);
```

---

## المحاولات الفاشلة (للتوثيق)

| المحاولة | لماذا فشلت |
|----------|-----------|
| `RtlAwareMaterialSelectionControls` مخصص | `buildHandle` يستقبل `type` جاهزاً — لا يمكن تغيير منطق الاختيار من الخارج |
| `textSelectionThemeData.selectionHandleColor` | flutter_quill 11.5.0 كان يحتوي على كود debug يُغلّف المقبض بـ `Colors.red` ثابت |
| `boxes.first.right` / `boxes.last.left` | يعمل لعدة أسطر لكن يفشل لسطر واحد (نفس الصندوق) |
| `boxes.reduce(a.right > b.right)` | نفس المشكلة — كل الصناديق في سطر واحد متجاورة |
| `getLocalRectForCaret` لحساب الاتجاه | نتائج غير ثابتة — كل ضغطة تعطي احتمال مختلف |
| تعديل pub cache مباشرة | يُفقد عند `pub upgrade` أو جهاز آخر |

---

## الملفات المعدّلة

> التعديلات في النسخة المحلية `packages/flutter_quill/` (path dependency)

| الملف | التعديل |
|-------|---------|
| `lib/src/editor/widgets/text/text_line.dart` | `_getEndpointForSelection` — `getOffsetForCaret` بدلاً من `boxes.start/end` |
| `lib/src/editor/widgets/text/text_selection.dart` | `resolvedDirection` + `_resolveSelectionDirection()` + تعديل `_chooseType` |

---

## ملاحظة: النسخة المحلية

المكتبة منسوخة في `packages/flutter_quill/` ومُعرّفة كـ path dependency:

```yaml
# pubspec.yaml
flutter_quill:
  path: packages/flutter_quill
```

عند تحديث flutter_quill مستقبلاً:
1. انسخ النسخة الجديدة إلى `packages/flutter_quill/`
2. أعد تطبيق التعديلين أعلاه (text_line.dart + text_selection.dart)
3. شغّل `flutter pub get`

---

## النتيجة

- ✅ كل دمعة تظهر عند الطرف الصحيح للتحديد
- ✅ اتجاه الدمعة يتبع أول حرف في النص المحدد (عربي → RTL، إنجليزي → LTR)
- ✅ الاتجاه يُحسب مرة واحدة فقط عند ظهور التحديد
- ✅ يعمل مع double-tap (كلمة واحدة) والسحب (عدة أسطر)
- ✅ النسخة المحلية تضمن عدم فقدان التعديلات
