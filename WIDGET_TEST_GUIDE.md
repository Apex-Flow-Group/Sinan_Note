# 🧪 Widget Testing Guide

## Quick Test Script

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug
flutter install

# Or use the test script
./test_notifications.sh  # Also works for widgets
```

## Test Scenarios

### ✅ Scenario 1: Note Widget (Regular Notes Only)

1. **Setup:**
   - Create 2 regular notes (not checklists)
   - Create 1 checklist note
   - Pin one regular note

2. **Add Widget:**
   - Long press home screen → Widgets
   - Find "Sinan Note Widget"
   - Add to home screen

3. **Expected Result:**
   - ✅ Shows the pinned regular note
   - ✅ Color matches note color
   - ✅ NO checklist appears
   - ✅ Clean design (no emoji)

4. **Test Update:**
   - Edit the pinned note
   - Widget should auto-update
   - Color should change if you change note color

5. **Test Delete:**
   - Delete the pinned note
   - Widget should show "Select Note"

---

### ✅ Scenario 2: Checklist Widget (Checklists Only)

1. **Setup:**
   - Create 2 checklist notes
   - Create 1 regular note
   - Pin one checklist

2. **Add Widget:**
   - Long press home screen → Widgets
   - Find "Sinan Checklist Widget"
   - Add to home screen

3. **Expected Result:**
   - ✅ Shows the pinned checklist
   - ✅ Items formatted with ☐/☑
   - ✅ Progress shows "X / Y"
   - ✅ NO regular note appears
   - ✅ Color matches checklist color

4. **Test Update:**
   - Check/uncheck items in the checklist
   - Widget should update progress
   - Color should change if you change checklist color

5. **Test Delete:**
   - Delete the pinned checklist
   - Widget should show "Select Checklist"

---

### ✅ Scenario 3: Strict Filtering

**Critical Test:** Ensure widgets NEVER mix types

1. **Setup:**
   - Create 1 regular note (title: "Regular Note")
   - Create 1 checklist (title: "Checklist Note")
   - Don't pin anything

2. **Test Note Widget:**
   - Add note widget
   - Should show "Regular Note"
   - Should NEVER show "Checklist Note"

3. **Test Checklist Widget:**
   - Add checklist widget
   - Should show "Checklist Note"
   - Should NEVER show "Regular Note"

4. **Result:**
   - ✅ Each widget type is strictly filtered
   - ✅ No mixing of note types

---

### ✅ Scenario 4: Color Adaptation

1. **Setup:**
   - Create a note with Blue color (index 8)
   - Create a checklist with Pink color (index 10)

2. **Add Widgets:**
   - Add both widgets to home screen

3. **Expected Result:**
   - ✅ Note widget has blue background
   - ✅ Checklist widget has pink background
   - ✅ Colors adapt to system theme (light/dark)

4. **Test Theme Change:**
   - Switch system theme (light ↔ dark)
   - Widget colors should adapt

---

### ✅ Scenario 5: Deep Linking

1. **Setup:**
   - Add both widgets with notes selected

2. **Test:**
   - Tap note widget → Opens that specific note
   - Tap checklist widget → Opens that specific checklist
   - Tap empty widget → Opens widget selection screen

3. **Expected Result:**
   - ✅ Direct navigation to correct note
   - ✅ No crashes
   - ✅ Correct note opens in editor

---

## Debug Checklist

### Visual Inspection
- [ ] No emoji in widget header
- [ ] Clean Material 3 design
- [ ] Proper padding and spacing
- [ ] Text is readable
- [ ] Colors look good in light/dark mode

### Functional Testing
- [ ] Note widget shows only regular notes
- [ ] Checklist widget shows only checklists
- [ ] Pinned notes appear first
- [ ] Recent notes appear if no pinned
- [ ] Progress indicator works (checklists)
- [ ] Deep linking works
- [ ] Auto-update on save works
- [ ] Auto-reset on delete works

### Edge Cases
- [ ] Empty note → Shows "Empty note"
- [ ] Empty checklist → Shows "Empty checklist"
- [ ] No notes → Shows "Select Note"
- [ ] No checklists → Shows "Select Checklist"
- [ ] Locked notes → Not shown in widgets
- [ ] Trashed notes → Not shown in widgets
- [ ] Archived notes → Not shown in widgets

---

## Debug Logs

Watch for these logs:
```bash
flutter logs | grep -i "widget"
```

Expected output:
```
✅ Note widget updated
✅ Checklist widget updated
```

If you see errors:
```
❌ Note widget update failed: [error]
❌ Checklist widget update failed: [error]
```

---

## Common Issues

### Widget Not Updating
**Solution:** 
1. Check if note is pinned to widget
2. Verify note is not locked/trashed/archived
3. Check logs for errors

### Wrong Note Type Showing
**Solution:**
1. This should NEVER happen with new code
2. If it does, file a bug report
3. Check `isChecklist` flag in database

### Colors Not Working
**Solution:**
1. Verify `colorIndex` is valid (0-11)
2. Check if system theme is set
3. Try rebuilding the app

### Deep Link Not Working
**Solution:**
1. Verify AndroidManifest.xml has correct intent filters
2. Check if MainActivity handles the intent
3. Test with `adb shell am start` command

---

## Performance Testing

### Widget Update Speed
- Save a note → Widget should update within 1 second
- Delete a note → Widget should reset within 1 second

### Memory Usage
- Widgets should not cause memory leaks
- Check with Android Profiler

### Battery Impact
- Widgets should not drain battery
- No background polling (only update on save/delete)

---

## Acceptance Criteria

### Must Pass All:
- ✅ Note widget NEVER shows checklists
- ✅ Checklist widget NEVER shows regular notes
- ✅ Colors match app color palette
- ✅ No emojis in widget UI
- ✅ Material 3 design
- ✅ Deep linking works
- ✅ Auto-update on save
- ✅ Auto-reset on delete
- ✅ Progress indicator works (checklists)
- ✅ Pinned notes prioritized

---

**Status:** Ready for QA ✅  
**Estimated Test Time:** 15-20 minutes  
**Priority:** HIGH - Core feature
