# BiDi Cursor Fix — Arabic Text with Numbers

## The Problem

In Arabic (RTL) text containing numbers, tapping after a number placed the cursor at the **wrong logical position**.

**Example:**
```
تطوير 2025 تطبيق
```

User taps visually **after** `2025` (to the right of the number in RTL flow).  
Flutter's `TextPainter.getPositionForOffset` maps that visual tap to the **logical start** of the digit run (index before `2`), not the end (index after `5`).

Result: typing `أ` after `2025` would insert **before** `2` instead of after `5`.

---

## Root Cause

Unicode BiDi Algorithm creates a **directional run** for digits inside Arabic text:

```
Logical storage:  ت ط و ي ر [sp] 2 0 2 5 [sp] ت ط ب ي ق
                  0 1 2 3 4   5  6 7 8 9  10  11 ...

Visual display (RTL paragraph):
  قيبطت  5202  ريوطت
         ↑
  Tap here visually = offset 6 (start of digit run)
  But user expects  = offset 10 (end of digit run)
```

The digit block `2025` is a **weak LTR run** inside an RTL paragraph. Flutter places the cursor at `offset 6` (logical start = visual right edge in RTL), but the user expects `offset 10` (logical end = visual left edge in RTL).

---

## The Solution

### Architecture: Selection Interceptor Middleware

File: `lib/core/utils/bidi_cursor_middleware.dart`

```dart
class BiDiCursorCorrectionMiddleware {
  final QuillController controller;
  bool _isCorrectingSelection = false;
  int _previousOffset = -1;

  static final _digitRun = RegExp(r'^[\d٠-٩]+([.,،][\d٠-٩]+)*');
  static final _arabicOrSpace = RegExp(r'[\u0600-\u06FF\u0750-\u077F\s]');
  static final _digitChar = RegExp(r'[\d٠-٩]');

  void _onSelectionChanged() {
    if (_isCorrectingSelection) return;

    final selection = controller.selection;
    if (!selection.isCollapsed) return;  // ignore drag/selection

    final offset = selection.baseOffset;
    final plainText = controller.document.toPlainText();

    if (offset <= 0 || offset >= plainText.length) return;

    // Arrow key navigation (delta == 1) → skip correction
    final delta = (offset - _previousOffset).abs();
    _previousOffset = offset;
    if (delta == 1) return;

    final charAtCursor = plainText[offset];    // char AT cursor position
    final charBefore   = plainText[offset - 1]; // char BEFORE cursor

    // Condition: cursor is at START of digit run, preceded by Arabic/space
    if (!_digitChar.hasMatch(charAtCursor)) return;
    if (!_arabicOrSpace.hasMatch(charBefore)) return;

    // Calculate full digit run length
    final match = _digitRun.firstMatch(plainText.substring(offset));
    final runLength = match?.group(0)?.length ?? 0;
    if (runLength == 0) return;

    // Jump cursor to END of digit run using microtask (safe, no build conflict)
    _isCorrectingSelection = true;
    Future.microtask(() {
      controller.updateSelection(
        TextSelection.collapsed(offset: offset + runLength),
        ChangeSource.local,
      );
      _isCorrectingSelection = false;
    });
  }
}
```

---

## How It Works — Step by Step

### Scenario: `تطوير 2025 تطبيق`

| Step | What happens |
|------|-------------|
| User taps visually after `2025` | Flutter sets cursor to `offset 6` (start of digit run) |
| `_onSelectionChanged` fires | `selection.isCollapsed == true` ✓ |
| `delta` check | Tap jumps many positions, not `1` → not arrow key ✓ |
| `charAtCursor = '2'` | Matches `_digitChar` ✓ |
| `charBefore = ' '` | Matches `_arabicOrSpace` ✓ |
| Regex on `"2025 تطبيق"` | Matches `"2025"`, length = `4` |
| `Future.microtask` | Moves cursor to `offset 6 + 4 = 10` |
| User types `أ` | Inserts at `offset 10` → `تطوير 2025أ تطبيق` ✓ |

---

## Key Design Decisions

### 1. `Future.microtask()` not `setState()`
Avoids build-phase conflicts and IME (keyboard) composing region loops.

### 2. Arrow key guard (`delta == 1`)
Allows user to navigate **inside** a number with arrow keys without being thrown to the end.

```
تطوير 2|025  ← arrow right → تطوير 20|25  (no correction, delta == 1)
تطوير |2025  ← tap          → تطوير 2025| (correction fires, delta > 1)
```

### 3. Mutex flag (`_isCorrectingSelection`)
Prevents infinite loop: correction triggers `_onSelectionChanged` again → flag blocks re-entry.

### 4. Only collapsed selections
Does not interfere with text selection/highlighting (drag handles).

### 5. Supports Eastern Arabic-Indic digits
Regex `[\d٠-٩]` covers both `0-9` and `٠-٩`.

---

## Integration

```dart
// In EditorCoordinator._attachQuillGuard():
_bidiMiddleware = BiDiCursorCorrectionMiddleware(controller: quillController!);

// In EditorCoordinator.dispose():
_bidiMiddleware?.dispose();
```

---

## Before / After

```
Text: "السعر 1500 ريال"

BEFORE fix:
  Tap after 1500 → cursor at offset 7 (before '1')
  Type 'أ'       → "السعر أ1500 ريال"  ✗

AFTER fix:
  Tap after 1500 → cursor corrected to offset 11 (after '0')
  Type 'أ'       → "السعر 1500أ ريال"  ✓
```
