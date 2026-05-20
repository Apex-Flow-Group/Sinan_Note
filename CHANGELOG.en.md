# Changelog — Sinan Note

All notable changes are documented here. Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
