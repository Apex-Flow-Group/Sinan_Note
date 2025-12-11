# 🧪 Clipboard Copy Test Guide

## Quick Test (2 minutes)

### Test 1: Regular Note Copy ✅
1. Create a regular note:
   ```
   Title: Meeting Notes
   Content: Discuss project timeline
   Review budget
   ```
2. Open the note
3. Click Copy button (📋 icon)
4. Paste in any app
5. **Expected:** Plain text with title and content

---

### Test 2: Checklist Copy ✅
1. Create a checklist:
   ```
   Title: Shopping List
   Items:
   ☐ Buy milk
   ☑ Call mom
   ☐ Finish project
   ```
2. Open the checklist
3. Click Copy button (📋 icon)
4. Paste in any app (WhatsApp, Notes, Email)
5. **Expected:**
   ```
   Shopping List

   [ ] Buy milk
   [x] Call mom
   [ ] Finish project
   ```

---

### Test 3: History Copy (Checklist) ✅
1. Open an existing checklist
2. Make some edits and save
3. Click History button
4. Select an old version
5. Click Copy button on the version
6. Paste in any app
7. **Expected:** Formatted checklist (not JSON)

---

### Test 4: History Copy (Regular) ✅
1. Open a regular note
2. Make some edits and save
3. Click History button
4. Select an old version
5. Click Copy button on the version
6. Paste in any app
7. **Expected:** Plain text content

---

## Visual Comparison

### ❌ Before Fix
```
{"items":[{"text":"Buy milk","isDone":false},{"text":"Call mom","isDone":true}]}
```

### ✅ After Fix
```
Shopping List

[ ] Buy milk
[x] Call mom
```

---

## Test in Different Apps

### WhatsApp
- Paste checklist → Should show clean list ✅
- Formatting preserved ✅

### Email
- Paste checklist → Should show clean list ✅
- Can be sent professionally ✅

### Notes App
- Paste checklist → Should show clean list ✅
- Can be edited easily ✅

### Google Docs
- Paste checklist → Should show clean list ✅
- Formatting maintained ✅

---

## Edge Cases

### Empty Checklist
1. Create checklist with no items
2. Copy → Should copy title only ✅

### Checklist with No Title
1. Create checklist without title
2. Copy → Should copy items only ✅

### Very Long Checklist
1. Create checklist with 20+ items
2. Copy → Should copy all items formatted ✅

### Mixed Characters (Arabic + English)
1. Create checklist with mixed text
2. Copy → Should preserve all characters ✅

---

## Acceptance Criteria

- [ ] Regular notes copy as plain text
- [ ] Checklists copy as formatted lists
- [ ] History versions format correctly
- [ ] No JSON visible to user
- [ ] Works in all apps (WhatsApp, Email, etc.)
- [ ] Preserves all characters
- [ ] Handles empty/long lists

---

## Quick Verification

**Pass:** User can paste checklist into WhatsApp and it looks professional  
**Fail:** User sees JSON code when pasting

---

**Status:** Ready for testing ✅  
**Time:** 2 minutes per test  
**Priority:** HIGH - User-facing feature
