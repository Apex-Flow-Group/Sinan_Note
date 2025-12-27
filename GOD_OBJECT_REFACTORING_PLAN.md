# 🦖 God Object Refactoring Plan
## Target: `note_editor.dart` (1,718 lines)

---

## 🎯 Goal
Reduce `note_editor.dart` from **1,718 lines** to **~600 lines** by extracting logic into specialized controllers and widgets.

---

## 📊 Current State Analysis

### File Breakdown:
- **State Variables**: ~50 lines
- **initState/dispose**: ~150 lines
- **Save Logic**: ~200 lines
- **UI Builders**: ~400 lines
- **Dialog/Sheet Methods**: ~300 lines
- **Event Handlers**: ~200 lines
- **Utility Methods**: ~400 lines

---

## 🛠️ Phase 1: Extract Save Logic (Priority: HIGH)

### Target: `EditorStorageController`
**Lines to move: ~250**

```dart
// Move these methods:
- _saveNoteToDatabase()
- _saveNote()
- _saveAsMarkdown()
- _saveWithExtension()
- Validation logic for empty notes
- Checklist validation
```

**Benefits:**
- ✅ Testable save logic
- ✅ Reusable across app
- ✅ Cleaner separation

**Risk:** LOW (already has controller structure)

---

## 🎨 Phase 2: Extract Dialog/Sheet Widgets (Priority: MEDIUM)

### Create New Files:
1. `lib/widgets/editor/dialogs/color_picker_dialog.dart` (~80 lines)
2. `lib/widgets/editor/dialogs/reminder_dialog.dart` (~100 lines)
3. `lib/widgets/editor/dialogs/rename_dialog.dart` (already exists ✅)
4. `lib/widgets/editor/sheets/smart_save_sheet.dart` (~120 lines)

**Lines to remove: ~300**

**Benefits:**
- ✅ Reusable dialogs
- ✅ Easier to maintain
- ✅ Better testing

**Risk:** LOW (pure UI extraction)

---

## 🧠 Phase 3: Extract State Management (Priority: HIGH)

### Target: `EditorState` (expand existing)

```dart
class EditorState {
  // Consolidate scattered state:
  final String? customTitle;
  final int colorIndex;
  final bool isDirty;
  final bool isSaving;
  final bool hasContent;
  final DateTime? reminderDateTime;
  final String? recurrenceRule;
  // ... etc
  
  // Add methods:
  EditorState copyWith({...});
  bool get hasUnsavedChanges;
  bool get canSave;
}
```

**Lines to remove: ~100**

**Benefits:**
- ✅ Immutable state
- ✅ Easier debugging
- ✅ Better state tracking

**Risk:** MEDIUM (requires careful migration)

---

## ⚡ Phase 4: Extract Smart Features (Priority: LOW)

### Target: `EditorSmartController` (expand existing)

```dart
// Move these methods:
- _handleSmartCalculation()
- _runCode()
- _exportCode()
- _analyzeMathAndDates()
- Language detection logic
```

**Lines to remove: ~200**

**Benefits:**
- ✅ Isolated smart features
- ✅ Easier to disable/enable
- ✅ Better performance

**Risk:** LOW (already has controller)

---

## 🎯 Phase 5: Extract UI Builders (Priority: MEDIUM)

### Create: `lib/screens/note_editor/widgets/`

1. `editor_content_area.dart` (~150 lines)
2. `editor_header_bar.dart` (~100 lines)
3. `editor_toolbar.dart` (already exists ✅)

**Lines to remove: ~250**

**Benefits:**
- ✅ Modular UI
- ✅ Easier to redesign
- ✅ Better hot reload

**Risk:** MEDIUM (tight coupling with state)

---

## 📈 Expected Results

| Phase | Lines Removed | Risk | Time Estimate |
|-------|---------------|------|---------------|
| Phase 1 | ~250 | LOW | 2 hours |
| Phase 2 | ~300 | LOW | 3 hours |
| Phase 3 | ~100 | MEDIUM | 4 hours |
| Phase 4 | ~200 | LOW | 2 hours |
| Phase 5 | ~250 | MEDIUM | 3 hours |
| **Total** | **~1,100** | - | **14 hours** |

**Final Size:** ~600 lines (acceptable for main screen)

---

## ⚠️ Critical Rules

1. **One Phase at a Time** - Never mix phases
2. **Git Commit After Each Phase** - Always have rollback point
3. **Test After Each Move** - Manual testing required
4. **Keep Original Logic** - Don't "improve" while refactoring
5. **Document Breaking Changes** - Update CHANGELOG.md

---

## 🧪 Testing Checklist (After Each Phase)

- [ ] Create new note (simple)
- [ ] Create new note (code)
- [ ] Create new note (checklist)
- [ ] Edit existing note
- [ ] Save note
- [ ] Delete note
- [ ] Lock/unlock note
- [ ] Add reminder
- [ ] Change color
- [ ] Undo/redo
- [ ] Share note
- [ ] Archive note

---

## 🚀 Execution Strategy

### Week 1: Preparation
- [ ] Review all dependencies
- [ ] Create backup branch
- [ ] Write integration tests (if possible)

### Week 2: Phase 1 + 2
- [ ] Extract save logic
- [ ] Extract dialogs
- [ ] Test thoroughly

### Week 3: Phase 3 + 4
- [ ] Migrate to EditorState
- [ ] Extract smart features
- [ ] Test thoroughly

### Week 4: Phase 5 + Polish
- [ ] Extract UI builders
- [ ] Final testing
- [ ] Update documentation

---

## 📝 Notes

- **Current Status:** Planning phase
- **Started:** Not yet
- **Blocked By:** Need dedicated time slot
- **Priority:** Medium (not urgent, but important)

---

**Created:** 2025  
**Author:** Amazon Q Developer  
**Status:** 📋 PLANNED (Not Started)
