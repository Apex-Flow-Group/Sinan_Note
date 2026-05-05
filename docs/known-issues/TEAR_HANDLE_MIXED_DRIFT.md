# Cursor Drift — Tear Handle on Mixed Text & Empty Lines

**Status:** ⏳ Open  
**Severity:** High

---

## Summary

When dragging the tear handle (custom single-cursor handle) on mixed content — Arabic/English text combined with numbers, or lines containing empty lines — the cursor jumps to incorrect positions instead of following the drag accurately.

## Symptoms

- Cursor drifts to wrong line/position during tear handle drag
- Most noticeable with:
  - Mixed RTL/LTR text (Arabic + English)
  - Text containing numbers inline with Arabic
  - Paragraphs separated by empty lines
- Behavior is random/inconsistent across drag sessions

## Root Cause

Not yet fully investigated.  
Suspected causes:
- `getPositionForOffset` line index calculation breaks on BiDi-reordered runs — the visual Y position maps to the wrong logical line when empty lines or direction switches are present
- Empty lines have zero height in some configurations, causing line index arithmetic to skip or double-count lines during drag

## Relation to Previous Issues

This is distinct from [Issue #2 — Cursor Tear Handle Drag Position Offset](TEAR_HANDLE_DRAG_FIX.md) (which fixed scroll offset drift). The current issue is specific to **content type** (mixed text + empty lines), not scroll position.

## Affected Files

- `lib/widgets/editor/tear/` — tear handle drag logic
- Possibly `lib/core/utils/bidi_cursor_middleware.dart` — BiDi correction may interfere with drag

---

*Reported: 2025 | Fix: Pending*
