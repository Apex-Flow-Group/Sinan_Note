# Changelog — Sinan Note

All notable changes are documented here. Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [3.2.3] — 2026-06 | Paste Performance + Apex Sharing

### ✨ New Features
- **Share notes via Apex Transfer** — new button in the share sheet sends the note to nearby devices over the local network without internet

### ⚡ Performance
- **Fixed app freeze on large text paste** — intercepted paste event and built Delta in a separate Isolate via a virtual Document, then handed it to Quill in a single compose call. Eliminates ANR dialogs on all devices
- **Fixed app freeze on share from external apps** — shared text builds Delta in Isolate before opening the editor, using the same mechanism as paste
- **Removed QuillEditor from View Mode** — replaced with SelectableText + ListView.builder per paragraph. Fixes scroll lag and cursor tap on long notes
- **Fixed duplicate note confirmation message** — replaced misleading “note copied” message with “note duplicated”
- **Renamed Reading Mode to Book Mode** — renamed reading_mode_view.dart to book_mode_view.dart and updated all references

---

## [3.2.2] — 2026-06 | Editor & UX Fixes

### ✨ New Features
- **Catalog button in multi-select bar** — assign notes to catalogs directly from the selection toolbar (home, code tab, reminders tab)
- **Smart multi-select catalog logic** — single note opens its actual catalog state; multiple notes open empty picker and merge (add-only) without overwriting existing catalogs
- **Reading Mode** — button in readonly toolbar opens a comfortable reading view for long notes (600+ chars, supports Markdown)

### 🔧 Bug Fixes
- **Fixed share truncating note content** — all share paths now pass full content without the 300-char limit
- **Fixed catalog button in readonly view not reflecting saved state** — `_currentNote` now updates on refresh so the icon shows the correct state
- **Fixed checklist dispose crash** — removed `controller.clear()` calls in dispose that triggered removed listeners causing `NoSuchMethodError`
- **Fixed paste button icon not changing** — `SmartEditorToolbar` (rich/reminder modes) now toggles between paste and close icons when selection bar opens
- **Fixed text direction resetting to LTR after save** — `fixDeltaDirections` no longer recalculates paragraph directions; only cleans legacy `align:right` attributes
- **Fixed paste direction stopping mid-text** — `isPasting` flag cleared in `addPostFrameCallback` so `onChanged` cannot interfere during formatting
- **Fixed checklist item direction** — removed fixed `textDirection` from `TextField` so Flutter auto-detects direction per line
- **Fixed raw JSON showing in empty checklist cards** — `toDisplayText` now returns empty string instead of raw JSON when checklist has no items
- **Fixed home widget opening selection screen instead of note** — `NoteWidgetProvider` and `ChecklistWidgetProvider` now open the note directly when `noteId > 0`; root cause was keys being read without the correct prefix
- **Fixed tear handle position after pressing Enter** — delayed `_showAtCaret` with `addPostFrameCallback` until layout completes for the new line
- **Fixed reading mode showing plain unformatted text** — passing full Delta JSON to preserve formatting (bold, lists, headers)
- **Fixed text direction detection with numbered text** — replaced manual regex with `Bidi.detectRtlDirectionality` that correctly ignores numbers and symbols
- **Fixed list direction flipping mid-list** — lists retain the direction of the first item throughout all items
- **Fixed list number position in flutter_quill** — leading now uses block direction instead of parent direction
- **Fixed list number format** — LTR: `1.` on left, RTL: `.1` on right
- **Fixed raw content in readonly view** — `_openReadingMode` uses `quillController` directly instead of raw `contentController.text`
- **Fixed stored Delta block directions** — `fixDeltaDirections` corrects each block's direction based on its content on load

### ⚡ Performance
- **Debounced `onChanged` (50ms)** — direction logic batched after typing pauses instead of running on every keystroke
- **Fast hash comparison before full string diff** — `hashCode` short-circuits expensive comparison on large documents
- **`getPrevNonEmptyLineDirection` rewritten** — replaced `substring + split('\n')` with backward `lastIndexOf` scan; critical for long texts and novels
- **Cursor tear handle rewritten with `ValueNotifier`** — replaced `setState` with `ValueNotifier` + 16ms throttle to reduce rebuilds during drag
- **Removed editor performance debug prints** — stripped `debugPrint` and `Stopwatch` from `QuillEditorController` and `CursorTearHandle`

### 📖 Reading Mode
- **Character-based page splitting with word awareness** — 900 chars per page, breaks at nearest space
- **Improved swipe sensitivity** — `ClampingScrollPhysics` releases vertical scroll immediately
- **Stronger swipe required for page navigation** — raised `minFlingVelocity` to prevent accidental page turns

### 🔔 Reminder Badge
- **Reminder badge in readonly view** — shows at bottom of note when a reminder is set (past or future)
- **Three-section design** — reminder info | edit button | delete button
- **Smart relative time** — "In X min / Tomorrow / X days ago..."
- **Content protected** — automatic padding prevents text hiding under the badge

---

## [3.2.1] — 2026-05 | Open Source + Targeted Fixes

> A new chapter begins — the code is now open to the world on GitHub.

### 🌍 Open Source
- **Sinan Note is now open source** — code available on [GitHub](https://github.com/Apex-Flow-Group/Sinan_Note) to explore, learn, and contribute

### 🔧 Bug Fixes
- **Fixed hide option when catalog is cleared** — deselecting the last catalog resets the hide toggle to false automatically
- **Fixed hidden notes with empty catalog** — automatic DB migration (v5) repairs affected notes on first launch
- **Fixed cursor position after paste** — cursor now moves to end of pasted text instead of keeping old selection
- **Fixed immediate sync on auto-sync enable** — app triggers sync right after the option is turned on

---

## [3.2.0] — 2026-05 | Full Refactoring + Security Improvements

> 50+ changes, 8 refactoring rounds, 469/469 tests passing.

### ✨ New Features
- **Add item button in bottom toolbar** — quick checklist item addition without scrolling to end
- **Swipe to dismiss notifications** — all snackbars support swipe-down to dismiss
- **Immediate execution on undo snackbar swipe** — action executes instantly instead of waiting for timer
- **Improved Checklist** — swipe left to delete with Undo, single + button at bottom, gestures replace buttons
- **Vault Import Sheet** — standalone file with improved UI, filter by type and search
- **Cloud Sync Gateway** — independent sync layer (SyncEngine + SyncTransport)
- **createDefaultNote / createDefaultLockedNote / createSharedNote** — directly in Provider

### 🔒 Security Improvements
- **PBKDF2** raised from 10,000 to **100,000 iterations** with automatic migration
- **`setPasswordAfterRecovery()`** separated from `changePassword()`
- **`isEncrypted()`** checks IV length = 24 chars base64 (replaces simple length check)
- **`validateVaultPassword()`** unifies 3 validation functions into one

### 🔧 Bug Fixes
- **Fixed lost edits on lock** — editor saves content immediately on background instead of waiting for autosave timer
- **Fixed editor destroyed on lock trigger** — lock screen pushes on top of the stack instead of replacing everything with SplashScreen
- **Fixed biometric prompt shown 3 times** — unified auth flow via `forceUnlock()` directly after `PinLockScreen` success
- **Fixed biometric toggle in settings** — only shown when a fingerprint is actually enrolled on the device (hardware alone is not enough)
- **Fixed duplicate app in Recent Apps** — removed `taskAffinity=""` from AndroidManifest
- **Fixed checklist scroll with keyboard** — new item and add button now appear above the bottom bar
- **Smart scroll on item addition** — multiple attempts (200/500/800ms) to wait for keyboard animation
- First note in vault now appears immediately (added `_onProviderChanged` listener)
- Vault opens automatically after initial setup
- Desktop no longer shows encrypted notes (reads `lockedNotes` instead of `activeNotes`)
- Sync time translation works in both Arabic and English
- Hardcoded `'No notes'` text → `l10n.noNotes`
- **Fixed window growing on each launch on Windows** — DPI scaling was doubling size on every open/close
- **Fixed toggle button border radius in Arabic** — rounded corners now follow text direction (RTL/LTR)

### ⚡ Performance
- Removed colored shadow (`blurRadius: 18`) from every card — noticeable scroll improvement
- `listen: false` in `PremiumCardEffect`
- `convertNoteType` removed double rebuild
- Cache for `reminderNotes` with invalidation

### 🏗️ Refactoring
- `note_readonly_view.dart` from 944 lines → ~320 lines (extracted `TrashFloatingSheet` + `ReadOnlyContent`)
- `VaultNavigator` — single vault navigation center
- `SqliteDatabaseService.getDbPath()` static — unified DB path across 3 files
- `settings_provider.dart` — `_savePref()` helper removes 15+ repeated calls
- Removed 10 dead code instances (ValueNotifiers, empty listeners, unused functions)
- **Version history limit** — raised from 5 to 20 versions per note
- **`SecurityController.forceUnlock()`** — direct unlock without re-triggering authentication

### 🧪 Tests
- 127 new tests covering: `EditorSaveManager`, `VersionControlService` (edge cases), `EditorStateManager` (autosave sequence)

---

## [3.0.5] — 2026-05 | Performance & Interaction Improvements

### ✨ New Features
- **Interactive Checkbox in Rich Note** — tap toggles state directly in edit mode
- **Note-colored Checkbox** — unified appearance in editor and viewer
- **Dynamic line height** — adapts automatically to font size and type
- **Filter & search in Import Sheet** — vault supports filter by type and search on import
- **Filter bar in Vault** — filter by note types with FilterChips
- **FAB to add note in Vault** — clean bottom sheet instead of AddMenuWidget
- **Active effect on format buttons** — circular background in note color when Bold/Italic/H1/H2 is active

### 🔧 Bug Fixes
- Fixed black checkbox in Rich Note (was using theme colors)
- Fixed full-row tap capture on checklist line (now only checkbox area)
- Fixed `ClampingScrollPhysics` + `keyboardDismissBehavior` in Checklist

---

## [3.0.4] — 2026-05 | Final Update Before Launch

### ✨ New Features
- **Custom swipe options** — custom button opens bottom sheet with configurable options (5 choices)
- **Reminder and catalog from swipe** — add reminder or category directly from card swipe
- **Duplicate from swipe** — copy note with one tap
- **Filter without category** — show uncategorized notes from filter list
- **Key Debug** — experimental settings section visible only in debug mode

### 🔧 Bug Fixes
- Fixed category not applying when swiping from custom button
- Fixed `BuildContext across async gaps` in editor_save_operations

---

## [3.0.3] — 2026-04 | Code Editor + Database

### ✨ New Features
- **Code preview** — run button in editor shows SVG as real image, formatted JSON, all languages as preview
- **Code download** — download button saves file directly to Downloads with correct extension
- **DB Inspector** — database inspection tool from within the app (debug mode)
- **Font picker** — new sheet with live font preview before applying
- **Text direction display** — home screen cards auto-detect text direction (RTL/LTR)

### 🗄️ Database
- **Full SQLite sync** — automatic sync on every launch: notes, categories, note_versions, deleted_notes
- **React Native ready** — schema compatible with the correct migration path

### 🔧 Bug Fixes
- Fixed Floating SnackBar appearing off-screen when bottom navigation bar is present
- Fixed overflow in home screen cards
- Fixed SVG/YAML/TypeScript files opening as Rich Text instead of code editor

---

## [3.0.2] — 2026-03 | Core Features

### ✨ Major Features
- Full Google Drive sync with smart merge and conflict resolution
- Vault protected with AES-256 + biometrics + Rate Limiter
- Code editor with 25+ languages and syntax highlighting
- Reminder system with Exact Alarms
- Catalogs with smart Drawer
- Home Widget for home screen
- Note version history
- Master-Details layout for large screens
- Material You + dynamic colors

---

## [2.x] — 2025 | Core Architecture

- Built Clean Architecture with Provider
- Migrated from single 3000+ line file to 50+ files
- Unified Toast system, smart search, Pagination
- Full RTL/LTR support

---

## [1.0.0] — 2024 | Initial Release

- Create and edit notes
- Archive and trash
- Basic search
- Dark mode

---

*Copyright © 2025–2026 Apex Flow Group. All rights reserved.*
