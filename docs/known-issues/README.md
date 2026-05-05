# Known Issues & Critical Bugs

> All documented issues with root cause analysis, fix details, and affected files.

---

## Index

| # | Issue | Severity | Status | File |
|---|-------|----------|--------|------|
| 1 | [BiDi Cursor — Arabic Text with Numbers](#1-bidi-cursor--arabic-text-with-numbers) | High | ✅ Fixed | `bidi_cursor_middleware.dart` |
| 2 | [Cursor Tear Handle — Drag Position Offset](TEAR_HANDLE_DRAG_FIX.md) | High | ✅ Fixed | `tear/` |
| 3 | [Selection Handle Direction — Mixed RTL/LTR Text](SELECTION_HANDLE_DIRECTION_FIX.md) | High | ✅ Fixed | `flutter_quill` patch |
| 4 | [Hero Animation — Overlaps Search Bar & NavBar](HERO_OVERLAY_ISSUE.md) | Medium | 🔒 Key Debug Only | `hero_animation` |
| 5 | [Cursor Drift — Tear Handle on Mixed Text & Empty Lines](TEAR_HANDLE_MIXED_DRIFT.md) | High | ⏳ Open | `tear/` |

---

## 1. BiDi Cursor — Arabic Text with Numbers

**Full documentation:** [`docs/known-issues/BIDI_CURSOR_FIX.md`](BIDI_CURSOR_FIX.md)

**Summary:**  
Tapping after a number inside Arabic text placed the cursor at the wrong position (start of digit run instead of end), causing newly typed characters to appear on the wrong side of the number.

**Example:**
```
"السعر 1500 ريال"
Tap after 1500 → cursor lands before '1' instead of after '0'
Type 'أ'        → "السعر أ1500 ريال"  ✗  (should be "السعر 1500أ ريال")
```

**Root Cause:**  
Unicode BiDi Algorithm treats digit sequences as weak-LTR runs inside RTL paragraphs. Flutter's `TextPainter.getPositionForOffset` maps the visual tap position to the logical start of the digit run.

**Fix:**  
`BiDiCursorCorrectionMiddleware` — a `QuillController` listener that detects when the cursor lands at the start of a digit run preceded by Arabic text, then uses `Future.microtask()` to jump the cursor to the end of the run.

**Affected files:**
- `lib/core/utils/bidi_cursor_middleware.dart` ← fix implementation
- `lib/screens/shared/note_editor/core/editor_coordinator.dart` ← middleware wired here

---

*Add new issues below following the same format.*

---

## 2. Cursor Tear Handle — Drag Position Offset

**Full documentation:** [`docs/known-issues/TEAR_HANDLE_DRAG_FIX.md`](TEAR_HANDLE_DRAG_FIX.md)

**Summary:**  
The cursor tear handle (custom single-cursor handle) was jumping to the wrong line on drag start, drifting with scroll, and freezing touch input.

**Root Cause:**  
`getPositionForOffset` expects viewport coordinates but was receiving document coordinates (including scroll offset). Also `HitTestBehavior.opaque` was blocking touch events permanently.

**Fix:**  
Subtract scroll offset before computing line index. Use `opaque` only during active drag. Guard `setState` with `mounted` check.

**Affected files:**
- `lib/widgets/editor/tear/` ← full new module

---

## 3. Selection Handle Direction — Mixed RTL/LTR Text

**Full documentation:** [`docs/known-issues/SELECTION_HANDLE_DIRECTION_FIX.md`](SELECTION_HANDLE_DIRECTION_FIX.md)

**Summary:**  
When selecting mixed Arabic/English text, both selection handles (teardrops) appeared clustered together in the middle instead of at the correct start/end of the selection. Handle direction (teardrop tail) was always RTL regardless of the actual text direction at the selection point.

**Root Cause:**  
Two separate bugs in `flutter_quill 11.5.0`:
1. `_getEndpointForSelection` in `text_line.dart` relied on `boxes.first/last` ordering which breaks with BiDi-reordered text runs.
2. `_chooseType` in `text_selection.dart` used `renderObject.textDirection` (always RTL globally) instead of the actual script direction at each handle position.

**Fix:**  
Patched `flutter_quill` pub cache directly:
- `text_line.dart`: use `getOffsetForCaret(selection.base/extent)` for precise handle X position
- `text_selection.dart`: add `_getDirectionAtPosition()` + cache result in `initState` as `_cachedDirection`, use it in `_chooseType`

**Affected files (pub cache):**
- `flutter_quill-11.5.0/lib/src/editor/widgets/text/text_line.dart`
- `flutter_quill-11.5.0/lib/src/editor/widgets/text/text_selection.dart`

---

*Add new issues below following the same format.*
