# Sinan Note — Issues & Documentation Index

## Known Issues & Critical Bugs

> [`docs/known-issues/`](docs/known-issues/README.md)

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | [BiDi Cursor — Arabic Text with Numbers](docs/known-issues/BIDI_CURSOR_FIX.md) | High | ✅ Fixed |
| 2 | [Cursor Tear Handle — Drag Position Offset](docs/known-issues/TEAR_HANDLE_DRAG_FIX.md) | High | ✅ Fixed |
| 3 | [Selection Handle Direction — Mixed RTL/LTR](docs/known-issues/SELECTION_HANDLE_DIRECTION_FIX.md) | High | ✅ Fixed |
| 4 | [Hero Animation — Overlaps Search Bar & NavBar](docs/known-issues/HERO_OVERLAY_ISSUE.md) | Medium | 🔒 Key Debug Only |
| 5 | [Cursor Drift — Tear Handle on Mixed Text & Empty Lines](docs/known-issues/TEAR_HANDLE_MIXED_DRIFT.md) | High | ⏳ Open |
| 6 | Isar → SQLite Migration — note_versions missing `noteType` column | Critical | ✅ Fixed |
| 7 | Version History — not recording on mobile | Critical | ✅ Fixed |
| 8 | Batch operations — not triggering sync | Medium | ✅ Fixed |
| 9 | SnackBars — inconsistent (raw vs unified) | Low | ✅ Fixed |
| 10 | Trash view — checklist interactive in read-only | Medium | ✅ Fixed |
| 11 | Trash view — action buttons always visible (ugly) | Low | ✅ Fixed |
| 12 | Share sheet — save file notification not showing | Medium | ✅ Fixed |
| 13 | Checklist read-only — empty list shows blank | Medium | ✅ Fixed |
| 14 | Trash — empty note opens in edit mode on desktop | Medium | ✅ Fixed |
| 15 | Duplicate note — copy label hardcoded in English | Low | ✅ Fixed |

---

## Session: Google Drive Sync Engine Overhaul (Current)

### Zero Trust Sync via MD5 Checksum

**Problem:** The old sync relied on a 48-hour timestamp rule to decide trust. This failed silently during long offline periods or multi-device conflicts.

**Solution:** Replaced with `md5Checksum` from Google Drive API — mathematical proof of whether the remote file changed since last sync.

**Two sync paths:**
- **Fast Path** — MD5 matches local: apply all pending deletions (`deleted_ids`) immediately, upload changes directly.
- **Merge Path** — MD5 differs (another device synced): download Drive notes, resolve conflicts by comparing `deletedAt` vs `updatedAt` — newest event wins. (CRDT-level logic without schema changes.)

### Auto Housekeeping
After every successful upload: clear `deleted_note_ids` tombstones + update `last_known_drive_md5`. Prevents tombstone accumulation and keeps performance stable.

### Safe Backup Merge
On local backup restore: reset all trust paths (`last_upload_timestamp`, `last_known_drive_md5`, `deleted_note_ids`). Forces Merge Path on next sync — protects recent Drive changes from being overwritten by old backup.

### API Quota Protection
`Pull-to-Refresh` disabled by default. Relies on silent `smartSyncOnStartup` instead of user-triggered refreshes.

---

## Session: Desktop & Responsive UI (Current)

### Responsive Layout
- `ResponsiveLayoutWrapper` now uses `shouldUseDesktopLayout()` instead of `isDesktopPlatform` — tablets in landscape get Master-Details layout.
- `DetailsPanel` — trashed notes stay selected and open in read-only mode instead of clearing selection.
- `BackupWizardScreen` — responsive Master-Details layout for screens >= 800px.
- `SettingsScreenResponsive` — desktop settings now reuses existing section widgets (`GeneralSection`, `SwipeSection`, `SecuritySection`, `DataSection`, `AboutSection`) — no more duplicated code.

### AppDialog
New `AppDialog.show()` helper — opens any screen as a floating dialog with fade+scale animation on large screens (>= 800px), normal push on mobile. Applied to: `AboutScreen`, `SupportFormScreen`, `BackupWizardScreen`, `TourScreen`.

### Desktop Menu Bar
- Removed `Reminder` from File menu (wrong location).
- Added `Rich Text` note type.
- Merged Export + Import into single `Backup & Restore` button → opens `BackupWizardScreen`.
- `About` opens via `AppDialog.show()` internally — removed `onAbout` callback.

### Settings
- Hero Animation toggle hidden on desktop (`PlatformHelper.isDesktopPlatform`).
- `BetaSection` hidden on desktop.

### Read-Only View
- Added color picker button to bottom action bar.
- `onEnterEdit` blocked when `note.isTrashed == true`.

### Checklist Read-Only
- Empty checklist now shows progress bar + ghost item (checkbox + drag handle) instead of blank screen.

---

## Session: Isar → SQLite Migration Issues (May 13, 2026)

### #6 — `note_versions` table missing `noteType` column

**Root Cause:** `NativeDbMigrationService` (deleted during migration) created the `note_versions` table **without** the `noteType` column. The new `SqliteDatabaseService` tries to INSERT with `noteType` → fails silently → no history saved.

**Evidence:** Pulled the SQLite database from the phone via ADB:
```
SCHEMA: note_versions (id, noteId, title, content, timestamp, action)
                       ❌ no noteType column!
```

**Fix:** Bumped `_dbVersion` from 3 → 4, added `_migrateToV4()` that runs `ALTER TABLE note_versions ADD COLUMN noteType`.

---

### #7 — Version History not recording on mobile

**Root Cause (multi-layered):**
1. `startEditingSession` / `endEditingSession` were **never called** from app code (only tests)
2. `smartLogVersion` only fires on manual save (`isManualAction: true`)
3. On mobile, users exit by pressing Home or switching apps → `_handleBack` never called → no history
4. Significance thresholds too strict (100 chars, 10%, 10 words)

**Fix:**
- Added `startEditingSession` in `initState` when opening existing note
- Added `endEditingSession` in `_handleBack`, `dispose`, and `didChangeAppLifecycleState`
- Lowered thresholds: 20 chars, 5%, 3 words

---

### #8 — Batch operations not triggering sync

**Root Cause:** `NoteStateService.batchUpdateNotes()` only invalidated cache — did not call `_silentSync()`.

**Fix:** Added `_silentSync()` call at end of `batchUpdateNotes()`.

---

### #9 — Raw SnackBars not using UnifiedNotificationService

**Files fixed (9):** `categories_panel`, `home_drawer_widget`, `reminder_picker_sheet`, `widget_selection_screen`, `custom_share_sheet`, `code_preview_service`, `google_drive_handlers`, `google_drive_sync_page`, `sync_sign_in_widget`.

---

### #10 — Checklist interactive in trash read-only view

**Root Cause:** `ReadOnlyChecklistView` allowed checkbox toggle and reorder without checking `isTrashed`.

**Fix:** Added `isTrashed` parameter, disabled `onTap`, `onReorder`, and hid drag handles when true.

---

### #11 — Trash view action buttons always visible

**Old behavior:** Two buttons (Restore + Delete) always shown in bottom bar — looked cluttered.

**New behavior:** Floating bottom sheet with drag-to-reveal using `AnimationController` + `GestureDetector` (Apple Maps style). Buttons appear with fade on swipe up.

---

### #12 — Share sheet save file notification not showing

**Root Cause:** `Navigator.pop(context)` closed the sheet before `FilePicker.platform.saveFile` completed → context destroyed → notification never shown.

**Fix:** Moved `Navigator.pop` to after the save operation completes.

---

## Other Documentation

| File | Description |
|------|-------------|
| [`docs/technical/animation_and_editor_performance.md`](docs/technical/animation_and_editor_performance.md) | Editor & animation performance notes |
| [`docs/technical/refactoring_may_2026.md`](docs/technical/refactoring_may_2026.md) | Refactoring session — 5 files + tear handle |
| [`MIGRATION_ISAR_TO_SQLITE.md`](MIGRATION_ISAR_TO_SQLITE.md) | Full Isar → SQLite migration log |
| [`CHANGELOG.md`](CHANGELOG.md) | Version history |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Contribution guide |

---

*New issues → add to [`docs/known-issues/`](docs/known-issues/README.md)*
