# Changelog — Sinan Note

All notable changes are documented here. Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [3.2.4+3409] — 2026-07 | Unified SafeArea for Bottom Sheets (Tablet Fix)

### 🔧 Bug Fixes

**Bottom sheets not respecting safe area on tablets (navigation bar overlap)**
- On tablets running in desktop layout mode, the system navigation bar overlaps the bottom of bottom sheets — buttons and content were partially hidden behind the gesture/navigation bar.
- Root cause: ~12 bottom sheets across the app called `showModalBottomSheet` directly without wrapping content in `SafeArea`, and several others used manual `MediaQuery.of(context).padding.bottom` which is fragile and inconsistent.

### 🏗️ Architecture — Centralized SafeArea in `AppBottomSheet`

**`AppBottomSheet.show()` now wraps content in `SafeArea(top: false)` automatically**
- Every bottom sheet opened via `AppBottomSheet.show()` now gets bottom safe area protection without any additional code at the call site.
- Added optional `backgroundColor` and `constraints` parameters to support more use cases without falling back to raw `showModalBottomSheet`.

**Migrated all unprotected bottom sheets to use SafeArea**
- `master_panel.dart` — migrated to `AppBottomSheet.show()`
- `custom_share_sheet.dart` — added `SafeArea(top: false)`, removed manual `padding.bottom`
- `note_history_sheet.dart` — added `SafeArea(top: false)` wrapper
- `code_preview_sheet.dart` — added `SafeArea(top: false)` wrapper
- `svg_preview_sheet.dart` — added `SafeArea(top: false)` wrapper
- `db_inspector_service.dart` — added `SafeArea(top: false)` wrapper
- `google_drive_widgets.dart` (upload + download) — added `SafeArea(top: false)`, removed manual `padding.bottom`
- `locked_notes_screen.dart` — added `SafeArea(top: false)` wrapper
- `version_history_screen.dart` — added `SafeArea(top: false)`, removed manual `padding.bottom`
- `general_section.dart` (font family sheet) — added `SafeArea(top: false)` wrapper
- `editor_toolbar_builder.dart` (markdown preview) — added `SafeArea(top: false)` wrapper

---

## [3.2.4+3408] — 2026-07 | Unified Toolbar & Smart Sharing & Separate View Modes

### ✨ New Features

**Unified Toolbar — Menu bar + Search in one bar (Desktop)**
- The menu bar (File | Edit | View | Help) and search field are now merged into a single rounded container in the AppBar across all desktop screens (Home, Archive, Trash, Professional, Reminders, Vault, Note History).
- When search is active: menu bar animates out, search expands to fill the space.
- When search is inactive: menu bar + divider + search hint shown together.
- Mobile layout is unaffected — no menu bar appears on phones.

**Search/Exit button in actions area (Desktop)**
- A dedicated search/exit icon button in the AppBar actions replaces the old inline clear button inside the search field.
- Shows 🔍 when idle (tap to focus search), shows ✕ when searching (tap to clear & exit).

**Separate view mode persistence for Mobile vs Desktop**
- View mode (compact/expanded/grid) is now saved independently for each layout:
  - Mobile: `viewType_home_mobile` (supports all 3 modes)
  - Desktop: `viewType_home_desktop` (compact/expanded only)
- Changing view mode in one layout no longer affects the other.

**Smart sharing via Apex — preview without auto-save**
- Notes shared via Apex Transfer (or any external app) now open in the editor as a preview — not saved to the database automatically.
- The note is displayed in its correct type (checklist, code, rich, simple) with full content.
- On exit, user is asked: "Would you like to save this note?" with Save/Discard options.
- Manual save (Ctrl+S or save button) during editing also works normally.
- Applies to all incoming content: `.sinan` files, shared text, and files from external apps.

### 🔧 Bug Fixes

**Apex Share — file arrives with random name instead of note title**
- The Intent used `ACTION_VIEW` + FileProvider URI, which loses the display name on transfer. Changed to `ACTION_SEND` + `EXTRA_STREAM` — Apex now reads the correct file name via `ContentResolver.DISPLAY_NAME`.

**Editor header taking double height in Details Panel**
- `SafeArea` inside `ApexEditorHeader` added unnecessary top padding when the editor was embedded in the Details Panel (desktop master-details). Now `SafeArea` is only applied when the editor runs as a standalone page.

**Reminder TabBar too large on Desktop**
- Replaced the full-width 720px TabBar with a compact 400px rounded pill-style tab selector that matches the unified toolbar aesthetic.

### 🏗️ Architecture

- `SearchableHeader` gained a `menuBar` parameter — when provided, renders the unified toolbar style automatically.
- `_UnifiedToolbar` widget in `home_screen_responsive.dart` handles the animated show/hide of the menu bar with `AnimatedSize`.
- `DesktopMenuBar` is now shared across all desktop screens (same File/Edit/View/Help menu everywhere).
- `AppNavigator.toEditorViaKey` gained `isSharedPreview` parameter.
- `NoteEditorImmersive` gained `isSharedPreview` flag that triggers the save prompt on back.

---

## [3.2.4+3405] — 2026-07 | AGP 9 Upgrade & Codebase Restructuring

> ⚓ **STABLE BASELINE** — Safe rollback point.
> Architecture is clean, all features complete, tests passing.
> Any major refactor or new feature starts from here.
> Next version (3.3.0+) → if it fails, revert to tag: `v3.2.4-stable`

### 🚀 Build & Performance

**Android Gradle Plugin upgraded to 9.0.1**
- Upgraded AGP from 8.9.1 → 9.0.1, enabling latest R8 optimizations.
- Added `android.builtInKotlin=false` and `android.newDsl=false` flags for Flutter plugin compatibility.
- Increased `MaxMetaspaceSize` from 512m → 1g to prevent R8 OOM during release builds.
- Forced `espresso-core` and `espresso-idling-resource` to 3.6.1 to resolve namespace conflict with AGP 9.

**Optimized Resource Shrinking enabled**
- Added `android.r8.optimizedResourceShrinking=true` — R8 now removes unused resources more aggressively, resulting in smaller APK size.

### 🔧 Bug Fixes

**R8 crash with AGP 9 — WorkManager/Room classes stripped**
- `shrinkResources true` with AGP 9.0.1 caused R8 to strip `androidx.work.impl.WorkDatabase` (Room-generated class used by WorkManager via `InitializationProvider`). App crashed on startup with `Failed to create an instance of WorkDatabase`.
- Fixed by adding `-keep class androidx.work.** { *; }` and `-keep class androidx.room.** { *; }` to ProGuard rules.

### 🏗️ Architecture — Codebase Restructuring

**Dead code removal**
- Deleted unused duplicate `lib/services/keyboard/app_shortcuts.dart` (not imported anywhere).
- Removed empty `lib/providers/` and `lib/controllers/editor/` directories.

**Controllers consolidated**
- Moved `selected_note_provider.dart` and `master_width_provider.dart` from `providers/` → `controllers/`.
- Moved `version_history_controller.dart` from `screens/other/version_history/` → `controllers/version_history/`.
- Moved `EditorStateManager` from `controllers/editor/` → `screens/shared/note_editor/state/` (where it's actually consumed).

**Services reorganized by responsibility**
- Created `services/code/` — moved `language_detector.dart`, `smart_analyzer.dart`, `code_executor.dart`, `code_export_service.dart` into it.
- Moved `clipboard_guard.dart` and `content_guard.dart` → `services/security/`.
- Moved `version_control_service.dart` and `version_history_service.dart` → `services/note_services/`.
- Moved `svg_service.dart` → `widgets/common/svg_preview_sheet.dart` (it was a full widget masquerading as a service).
- Moved `unified_notification_service.dart` → `widgets/common/` (uses BuildContext — not a pure service).
- Moved `paste_handler.dart` → `core/utils/` (pure Isolate utility, not a widget).

**Widgets organized**
- Created `widgets/layout/` — moved 8 layout files from `widgets/` root: `master_details_layout`, `master_panel`, `details_panel`, `empty_details_view`, `note_list_tile`, `responsive_layout_wrapper`, `vault_desktop_wrapper`, `vault_details_panel`.

**Business logic extracted from main.dart**
- Created `services/intent_handler_service.dart` — extracted `cleanSharedText`, `extractTitle`, `detectNoteMode`, `getModeString`, `parseSinanFile`, `hasValidContent` from main.dart.
- `main.dart` reduced from 516 → 462 lines.

### ✨ New

**Cloud Code Executor (Judge0 CE API) — built, not connected**
- Added `services/code/cloud_code_executor.dart` — complete implementation with submission, polling, result parsing, and 21 supported languages.
- Includes `CodeExecutionResult` model with formatted output and error categorization.
- Ready to activate: requires `http` package + API key.

---

## [3.2.5+3403] — 2026-07 | Pull-to-Refresh Fixes & Tear Handle & Cross-Platform Links

### 🔧 Bug Fixes

**Pull-to-refresh mode not updating after settings change**
- `_pullToRefreshMode` was cached in `HomeScreen` state and only updated in `didChangeDependencies` with `listen: false` — changes made in Settings were never reflected until a full restart.
- Fixed by removing the cached field entirely. `_onScrollChanged` now reads `pullToRefreshMode` directly from `SettingsProvider` on every scroll event.

**Refresh bar appearing before internet check**
- `_isRefreshingNotifier.value = true` was set inside `_onScrollChanged` (during pull gesture), before any internet check — the bar appeared even with no connection.
- Fixed by moving `_isRefreshingNotifier.value = true` into `_onRefresh`, after the internet check passes. The bar now never starts if there is no internet.

**No feedback when pulling to refresh without internet**
- When `mode == 'full'` and no internet is available, the refresh silently did nothing.
- Fixed: `_onRefresh` now checks `SyncTransport.hasInternet()` first. If no internet → immediate pull state reset + `UnifiedNotificationService` error snackbar with a Retry button.
- Added 30-second timeout on `CloudSyncGateway.smartSync()`. On `TimeoutException` → same error snackbar with Retry.

**About screen links not working on Linux/Windows**
- Links used a custom `MethodChannel('com.apexflow.app.sinan/launcher')` which only works on Android.
- Replaced with `url_launcher` (`launchUrl` + `LaunchMode.externalApplication`) — works on Android, Linux, and Windows without any platform-specific code.

**Double tap selects word but tear handle steals the second tap**
- `showOnTap` was called on every `_onTapDown` via `addPostFrameCallback`. On double tap, the second tap arrived while the tear was still visible, and `_TearWidget._onPointerDown` intercepted it instead of passing it to Quill for word selection.
- Fixed in `TearController.showOnTap`: tracks `_lastShowRequest` timestamp. If two calls arrive within `kDoubleTapTimeout` (300ms), the second is treated as a double tap and `_show()` is skipped — Quill receives the tap normally and selects the word.

---

## [3.2.4+3402] — 2026-07 | Desktop Screens Unification & Drawer Navigation Fixes

### 🏗️ Architecture — Desktop Screens Rewrite

**All responsive desktop screens fully rewritten**
- `ArchiveScreenResponsive`, `TrashScreenResponsive`, `ReminderDashboardResponsive`, `CodeTabResponsive`, `LockedNotesScreenResponsive`, `HomeScreenResponsive`, `SettingsScreenResponsive`, and `GoogleDriveScreenResponsive` all rewritten following a unified pattern: `Scaffold → Drawer + Column[SearchableHeader → MasterDetailsLayout(masterPanel, DetailsPanel)]`.
- Reminders desktop: `SearchableHeader` + `TabBar` (Upcoming/Scheduled/Expired) above `MasterDetailsLayout` with `TabBarView` as masterPanel.
- Professional desktop: `SearchableHeader` above `MasterDetailsLayout` with filtered code notes list.
- All screens include selection mode, sort (date/title), search, and proper `PopScope` handling.
- Mobile layout unchanged — original mobile screens still used as-is.

**Removed `sharedDetailsPanel` parameter**
- `CodeTabResponsive` and `ReminderDashboardResponsive` no longer accept `sharedDetailsPanel` — they manage their own `DetailsPanel()` internally (matching Archive/Trash pattern).
- Updated `MainLayoutScreen._cachedScreens` accordingly.

**Deleted `SideNavRail`**
- Removed the dead code (`&& false` condition) and deleted `lib/widgets/navigation/side_nav_rail.dart` entirely.

### 🔧 Bug Fixes

**Drawer "Home" tap did not switch tab on desktop**
- Pressing "Home" in the drawer only called `popUntil('/main')` but never set `currentTabIndexNotifier.value = 0`. Added `widget.onTabSelected?.call(0)`.

**Reminders/Professional tabs missing from drawer in Settings, Google Drive, Version History, and Locked Notes**
- These screens constructed `HomeDrawerWidget` without `onTabSelected`, so the tabs were hidden. Added `onTabSelected` with the standard `popUntil + currentTabIndexNotifier` pattern to all of them.

**Drawer highlighting — Reminders/Professional never highlighted**
- `isActive` was hardcoded to `false`. Changed to `currentTabIndexNotifier.value == index && route == '/main'`.

**Drawer highlighting — Home highlighted together with Reminders/Professional**
- Home's `isActive` didn't check the tab index. Added `(widget.onTabSelected == null || currentTabIndexNotifier.value == 0)` condition.

**Drawer highlighting — Category highlighted together with Reminders/Professional**
- `_buildCategoriesItem.isOnHome` didn't check tab index. Added `currentTabIndexNotifier.value == 0`.
- `CategoriesPanelWrapper` tile `isSelected` now checks `isOnHomeTab` — categories only highlight when tab 0 is active.

**Google Drive screen not showing desktop layout on foldable**
- Was using `constraints.maxWidth >= 900` hardcoded breakpoint. Replaced with `PlatformHelper.shouldUseDesktopLayout(context)`.

**Vault intro screen — redundant SafeArea causing top gap**
- `AppBar` already handles top SafeArea, but body also had `SafeArea(child: ...)`. Changed to `SafeArea(top: false)`.

**Vault intro screen — padding too large on big screens**
- Reduced top padding and SizedBox spacing when screen height < 700px.

### ✨ Improvements

**Vault intro — exit button replaces back arrow**
- Replaced `IconButton(arrow_back)` with a styled `TextButton.icon(close_rounded + l10n.close)` in AppBar actions — cleaner and more discoverable.

**Settings & Google Drive — SafeArea for desktop layout**
- Added `SafeArea(top: false)` to both `SettingsScreenResponsive` and `GoogleDriveScreen` desktop body to prevent content clipping on foldables.

**Swipe Gestures section — disabled on desktop instead of hidden**
- Mobile-only controls (search bar animation, bottom nav animation) now appear on desktop but with 50% opacity and `IgnorePointer` — visually disabled rather than removed.
- Added hint text: "These settings apply to the mobile version only" / "هذه الإعدادات تنطبق على نسخة الجوال فقط".

### 🌐 Localization

- Added `swipeGesturesMobileHint` key (EN/AR).

---

## [3.2.4+3401] — 2026-07 | BiDi Numerals & Editor Fixes & Responsive Unification

### 🔧 Bug Fixes

**Delete shortcut triggered 3 times when pressing Delete key inside editor**
- The `Delete` key (no modifier) was registered as a shortcut to trash the note, conflicting with normal text deletion. Changed to `Ctrl+Delete`. Also added a static deduplication guard in `ShortcutScope` to prevent multiple `HardwareKeyboard` handlers from firing the same action within the same frame.

**Text direction incorrectly set to LTR for digit-only lines on Enter**
- When a line contained only Western digits (e.g. `500`) and user pressed Enter, `Bidi.detectRtlDirectionality` returned `false` (= LTR) because digits are neutral. The new line was incorrectly set to LTR. Now the direction detection treats Western digits (0-9) as LTR and Arabic-Indic digits (٠-٩) as RTL — based on the first strong character or digit encountered.

**Arabic-Indic numerals incorrectly treated as strong RTL characters in `hasExplicitDir`**
- The regex `[a-zA-Z\u0600-\u06FF]` included Arabic-Indic digits (U+0660–U+0669) in the Arabic range, causing direction formatting to trigger for digit-only lines. Updated to include digits explicitly: `[a-zA-Z0-9\u0600-\u06FF\u0750-\u077F]`.

**Reminder picker bottom sheet overflow by 69px**
- The `Column` inside `ReminderPickerSheet` had a `SingleChildScrollView` without flex constraint. Wrapped it with `Flexible` so it scrolls within available space.

**Text color picker missing SafeArea**
- The inline color picker bottom sheet used fixed `bottom: 32` padding. Replaced with proper `SafeArea(top: false)` wrapper.

**More menu bottom sheet double SafeArea padding**
- `AppBottomSheet` had both `useSafeArea: true` on `showModalBottomSheet` AND a `SafeArea` widget inside `build()`, plus manual `padding.bottom` in `_showMoreSheet`. Removed the redundant inner `SafeArea` and manual padding — `useSafeArea: true` handles it.

### ✨ New Features

**H3 heading button in rich editor toolbar**
- Added a third heading size (H3) button in the bottom formatting bar, between H2 and the list buttons. Uses `Icons.text_fields_rounded` icon. Toggles `Attribute.h3` on the current line.

### 🏗️ Architecture

- `TextDirectionUtils.getDirection()`: Rewritten to scan for the first strong character or digit — Western digits → LTR, Arabic-Indic digits → RTL, alphabetic characters → delegate to `Bidi.detectRtlDirectionality`. Empty text defaults to RTL.
- `ShortcutScope._handleKey()`: Added static timestamp-based deduplication (50ms window) to prevent multiple handlers from executing the same shortcut.
- `PlatformHelper`: Rewritten with 5-layer detection: Platform → WindowedMode (View.display API) → DisplayFeatures (hinge/fold) → AspectRatio → Size. Supports foldable phones (Honor V5/V6, Samsung Fold), split screen, floating windows.
- Unified all scattered `width >= 600` checks across 8 files to use `PlatformHelper.isWideDisplay()` / `getDisplayMode()` — foldables no longer trigger desktop layout.

---

## [3.2.4+3399] — 2026-06 | Architecture Safety & Sync Fixes

### 🔧 Bug Fixes

**Notes not appearing after Google sync on startup**
- After `smartSync()` completed in the background, the UI was not refreshing because `SplashScreen` had already navigated away (`mounted = false`). Fixed by capturing Provider references before launching sync, so `refreshAllNotes(force: true)` executes regardless of screen lifecycle.

**Reminder tab — overlay and scroll broken on pull**
- Pulling down on an empty reminder tab caused the battery optimization banner to disappear below the tabs, and switching to a tab with notes made the first note stick at the bottom. Fixed by using `ListView` (with `AlwaysScrollableScrollPhysics`) for empty state instead of `Center`, and adding `hasScrollBody: true` to `SliverFillRemaining`.

**Duplicate sync on app startup**
- Both `SplashScreen` and `MainLayoutScreen` were calling `smartSync()` independently, causing concurrent sync operations. Removed `_autoSyncOnStartup()` from `MainLayoutScreen` — `SplashScreen` handles it.

**Crash after dispose — silent sync callback**
- `NoteStateService._silentSync()` could invoke `onSyncCompleted` callback after the Provider was disposed (e.g., if the user killed the app within 5 seconds of editing). Added `_isDisposed` guard that stops all Timer callbacks after `dispose()`.

### 🏗️ Architecture (Family Rules Compliance)

- `MainLayoutScreen`: `onCategoriesRefreshNeeded` callback registered immediately in `initState` instead of delayed `addPostFrameCallback` — prevents missing early sync events.
- `note_readonly_view.dart`: Replaced direct `SqliteDatabaseService().getNoteById()` with `provider.stateService.getNoteById()` — UI no longer bypasses Provider layer.
- `splash_screen.dart`: Categories also refreshed after sync (was only refreshing notes before).

---

## [3.2.3] — 2026-06 | Refactoring & Architecture + Intent Fixes + Hero Removal + Editor Fixes + Save Guard Fix

### ✨ New Features

**Book Mode — formatted text toggle**
- Added a toggle button in `BookModeView` AppBar to switch between formatted (Quill) and plain text rendering.
- State is persisted in `SharedPreferences` under `book_mode_show_formatted` — remembered across sessions.
- Button is only shown when `deltaJson` is available (rich notes) and `isMarkdown` is false.

### ⚡ Performance

**Long note pre-build in isolate**
- Notes longer than 1000 characters in read-only mode are pre-built in a Dart isolate via `compute(buildDeltaJsonForIsolate)` before the route is pushed. The resulting Delta JSON is passed directly to `EditorCoordinator` as `prebuiltDeltaJson`, eliminating a second synchronous parse on the main thread and preventing UI freeze.
- A small `CircularProgressIndicator` (14×14px) appears in the top-right corner of the card while the isolate is running.

**Read-only view — formatted content without jank**
- `ReadOnlyContent` now renders rich text using `QuillEditor` in read-only mode instead of plain `SelectableText`, switching after `isQuillFullyLoaded` is set in `EditorCoordinator`.

### 🔧 Bug Fixes

**Missing snackbar notifications in desktop right-click context menu**
- Actions triggered from the right-click bottom sheet on notes (pin/unpin, archive, delete) completed silently without any visual feedback. Fixed by adding `UnifiedNotificationService().showWithUndo()` with circular progress timer and undo support — matching the same pattern already used in swipe actions and multi-select toolbar.
- Pin/Unpin shows success snackbar with undo to revert.
- Archive shows "moved to archive" with undo to unarchive.
- Delete shows "moved to trash" with undo to restore.
- Also fixed missing `onNoteChanged()` calls after archive and delete in the context menu — the note list was not refreshing immediately after these actions.

**Desktop right-click in Trash shows wrong actions**
- Right-clicking a note in the trash screen on desktop showed the same actions as the home screen (pin, archive, delete). Now the context menu detects `source` and shows the correct trash actions: Restore (with undo snackbar) and Permanent Delete (with confirmation sheet).

**Desktop right-click in Archive shows wrong actions**
- Right-clicking a note in the archive screen on desktop showed "Pin" and "Archive" which don't belong there. Now the context menu detects `source='archive'` and shows: Open, Color, Unarchive (with undo snackbar), Share, and Delete — without the pin option.

**`commitAll()` crashes with setState during dispose**
- `UnifiedNotificationService().commitAll()` called from `_TrashScreenState.dispose()` triggered `executedEarly.value = true` synchronously, which notified `ValueListenableBuilder` while the widget tree was locked. Fixed by deferring the value assignment to `addPostFrameCallback`.

**External intent data lost after biometric/PIN authentication**
- Shared files, shared text, and widget taps from the Android home screen all lost their data after fingerprint/PIN auth completed. Root cause: intent was read immediately on cold start and executed with a fixed 400–500ms delay — which expired before the biometric dialog finished, so the editor was pushed onto `SplashScreen` and wiped by `pushReplacement`.
- New mechanism: intent data is saved in `pendingIntentNotifier` instead of executed immediately. `MainLayoutScreen.initState()` sets `isMainLayoutActive = true` in `addPostFrameCallback` (guaranteed to run only after auth succeeds, because `SplashScreen` never navigates here until auth passes). `_ApexNoteAppState._onPendingIntent()` checks `isMainLayoutActive` before executing — works regardless of biometric duration.
- Warm intents (`onNewIntent` while app is backgrounded) also check `isMainLayoutActive`: execute directly if `MainLayoutScreen` is ready, store otherwise.
- Empty intents (null action, 0 note_id, empty shared_text) are filtered and never stored.

**Shared text from browser shows "insert:" and raw URL**
- Two separate issues: (1) Chrome/Android appends the full page URL after the selected text in `EXTRA_TEXT`, producing `"selected text\n\nhttps://very/long/url"`. (2) `buildDeltaInIsolate` result was serialized with `.toString()` instead of `jsonEncode()`, producing Dart's `{insert: text}` syntax which is not valid JSON — the editor failed to parse it and displayed the raw string including the word "insert".
- Fix 1: `_cleanSharedText()` extracts the URL with a regex, strips it from the text body, and collapses excess blank lines. If only a URL remains, it's treated as a Shared Link note.
- Fix 2: `content = jsonEncode(delta.toJson())` replaces `content = delta.toJson().toString()`.
- Title is now auto-extracted from the first line of the cleaned text (truncated at 60 chars).

**Tap on empty line places cursor on next line instead**
- In RTL mode, tapping an empty line (`\n` only) placed the cursor at `offset+1` (beginning of the next line) instead of `offset` (the empty line itself). Root cause: Flutter's `RenderParagraph.getPositionForOffset` returns `offset=1` for a single-`\n` paragraph when tapped from the left side in RTL — interpreting it as "after the character".
- Fix: `RenderEditableTextLine.getPositionForOffset` now returns `TextPosition(offset: 0)` immediately when `container.length == 1` (empty line), bypassing `RenderParagraph` entirely.

**Enter on empty line stays on same line instead of inserting new line**
- Pressing Enter on an empty line did not move the cursor to a new line. Root cause: `handleEnterKey()` called `formatSelection` (direction formatting) before Quill executed the Enter, causing `document.compose()` to interfere and prevent the line insertion.
- Fix: `handleEnterKey()` skips `applyEnterDirection` when the current line is empty — Quill executes Enter normally, then `onDocumentChange` applies direction after the fact.
- `onDocumentChange` also skips `applyEnterDirection` when the previous line is empty, preventing cursor jump to end of line on the second press.

**Cursor tear handle (دمعة المؤشر) behavior fixes**
- Tear handle was not moving with the cursor after pressing Enter — it stayed on the previous line. Fixed by skipping `tearHandle.onTextChanged()` (which hides the tear) when the document change is an Enter-only insert, then immediately calling `showOnTap` in the next frame to reposition it.
- Tear handle was hidden and not redrawn on the new line after Enter on a line with content. Fixed by calling `showOnTap` after `scrollToCursor` in all Enter paths (empty line, non-empty line, list).
- Tear handle was not hidden during manual scroll. Fixed by calling `tearHandle.forceHide()` in `onScrollChanged`.
- Tear handle phantom cursor (the blue line drawn alongside the tear during drag) removed — no longer rendered during drag.
- Tear handle was drifting away from the cursor after a tap on a new character — fixed by binding `_TearWidgetState` to a `quillController` listener that repositions the tear in the next frame on every selection change.
- Cursor was jumping on BiDi boundaries during tear drag — root cause was `TextSelection.collapsed(offset: pos.offset)` discarding the `TextAffinity` returned by `getPositionForOffset`. Fixed by passing `affinity: pos.affinity` so both the real cursor and the virtual cursor use the same affinity.

**Desktop / Tablet layout clipped by status bar**
- On tablets and large-screen devices, the `MasterDetailsLayout` extended behind the system status bar. Fixed by wrapping `MasterDetailsLayout` with `SafeArea(bottom: false)`, resolving the issue for all desktop screens (Reminders, Professional, Home, Archive, Trash, Locked Notes) in a single change.

**"Hide Professional from Home" setting not synced with Google Drive**
- The `hide_pro_from_home` toggle in the Professional catalog drawer tile was stored only in `SharedPreferences` and never included in the Drive backup. Fixed by adding a `settings` object to the backup payload in `SyncEngine.upload()`, restoring it in both `download()` and `silentMerge()`, and having `CategoriesProvider` listen to `CloudSyncGateway.isSyncing` to reload the setting from `SharedPreferences` immediately after any sync completes.

**Fixed code notes being saved and moved to top when opened without editing**
- Opening a code note in the viewer (read-only) or editor without making any changes would trigger an unwanted save, updating `updatedAt` and moving the note to the top of the list. Root cause: `CodeController` fires change events during initialization (syntax highlighting), and `_onContentChanged` had no `isLoading` or `_isReadOnly` guard — unlike `_onQuillContentChanged` which already had the `isLoading` guard.
- Fix: Added `isLoading` and `_isReadOnly` guards to `_onContentChanged`. Also prevented attaching `codeController` listener in read-only mode via `_attachListeners()`.

**Fixed false "Note Saved" notification when opening notes in editor without changes**
- Regular notes (simple, rich, checklist) showed "Saved" notification on back press even when no actual save occurred. Root cause: the notification logic checked `hasContent && wasSaved` instead of the actual return value of `_saveNoteToDatabase()`.
- Fix: Notification now only appears when `_saveNoteToDatabase()` returns `true` (an actual database write happened).

**Fixed code controller listener not attached after transitioning from viewer to editor**
- When switching from read-only to edit mode via `onEnterEdit`, the `codeController` listener was not attached because `_isReadOnly` was still `true` at `_attachListeners()` time. Fix: listener is now explicitly attached after `_isReadOnly` is set to `false`.

### 🏗️ Refactoring

**Widget deep link — cold start fix**
- `_openNoteById()` now waits for `settings.isInitialized` + 500ms before navigating, matching the pattern already used in `_openEditorWithSharedText`. Fixes the race condition where the widget tap arrived before `SplashScreen` finished and the pushed route was overwritten by `pushReplacement`.

**`ApexErrorManager` — severity system + sync & vault coverage**
- Rebuilt `ApexErrorManager` with an `ApexErrorSeverity` enum (`expected` / `unexpected`). Expected errors (e.g. `VaultLockedException`) are now logged silently without showing a snackbar to the user.
- Added `monitorVault`, `monitorSync` wrappers alongside the existing `monitorDB`. `VaultEncrypt` and `VaultDecrypt` in `VaultService` now use `expectedError: true` — no more false "unexpected error" snackbar when the vault is locked.
- `SyncEngine.upload()`, `download()`, and `silentMerge()` are now wrapped with `monitorSync`, replacing manual `try/catch` blocks with consistent logging and user feedback.
- `monitorCritical` retained for backward compatibility with an `expectedError` parameter.


- Extracted `Pull to Refresh` and `Double Tap to Edit` controls from `GeneralSection` into a dedicated `MotionNavigationSection` widget (`motion_navigation_section.dart`).
- `settings_screen.dart` updated to include the new section between General and Beta.

**File splitting — Single Responsibility**
- `note_editor.dart` (1235 → ~1095 lines): menu action methods extracted into `EditorMenuHandlersMixin` (`editor_menu_handlers.dart`). Mixed into `_NoteEditorImmersiveState` via `with`.

**Unified content change handler**
- Extracted `_handleContentChange()` — a single method containing all shared logic for content changes (guards, `markDirty`, `hasContent` update, autosave timer). `_onQuillContentChanged` and `_onContentChanged` are now thin wrappers (5 lines each) that only specify the text source and timer duration.
- Both handlers now share the same guards (`isLoading`, `_isReadOnly`) and the same autosave behavior — eliminating the inconsistency that caused the original bug.
- `pin_lock_screen.dart` (829 → ~730 lines): `_numpadKey` and `_numRow` extracted into `PinNumpadKey` / `PinNumpadRow` stateless widgets (`pin_numpad_key.dart`).
- `backup_wizard_screen.dart` (717 → ~483 lines): `_FlowCard`, `_SectionHeader`, `_OptionTile`, `_ActionBtn`, `_SideItem` extracted to `backup_wizard_widgets.dart` with public names.
- `unified_notification_service.dart`: `_buildContent`, `_buildActionButton`, `_buildProgressWithUndo`, `_getBackgroundColor`, `_getIcon` extracted to `NotificationSnackBar` class (`notification_snack_bar.dart`). Service is now pure orchestration with no Flutter widget construction.
- `note_card_actions.dart`: `_PermanentDeleteSheet` extracted to `permanent_delete_sheet.dart` (`widgets/common/`).
- `categories_panel.dart`: `_ProCategoryTile` (stateful, independent expansion state) extracted to `pro_category_tile.dart` (`widgets/home/`).

### 🧪 Tests
- 19 new tests in `intent_preservation_test.dart` covering: cold-start intent storage, guard against execution before `MainLayoutScreen` is ready, correct execution after ready, empty intent filtering, warm intent routing, and double-execution prevention.
- 23 new tests in `editor_save_guard_test.dart` covering: code note opened without edits → no save, `isLoading` guard prevents false dirty during init, Quill/checklist notes without edits → no notification, full `saveToDatabase` guard simulation, `_handleBack` notification logic, edge cases (color-only change, undo to original, multiple loads).

**Read-Only View — Formatted Content overhaul**

**Formatted text in read-only view**
- `ReadOnlyContent` now renders rich text using `QuillEditor` in read-only mode instead of plain `SelectableText`. The switch happens after `isQuillFullyLoaded` is set to `true` in `EditorCoordinator`.
- In read-only mode (`readOnly: true`), `EditorCoordinator.initialize()` builds the full `QuillController` immediately (synchronously for short notes, from pre-built Delta JSON for long notes) instead of the 20-line preview used in edit mode.
- `Directionality(rtl)` wraps `QuillEditor` in read-only view so `fixDeltaDirections` block directions are respected correctly.

**Book Mode — formatting toggle**
- Added a toggle button in `BookModeView` AppBar to switch between formatted (Quill) and plain text rendering.
- State is persisted in `SharedPreferences` under `book_mode_show_formatted` — remembered across sessions.
- Button is only shown when `deltaJson` is available (rich notes) and `isMarkdown` is false.
- `_openBookMode()` in `note_readonly_view.dart` now always reads from `contentController` (full content) instead of `quillController` (preview only), ensuring Book Mode receives the complete Delta JSON.

**Cursor tear handle after entering edit mode**
- `QuillEditorWidget.didUpdateWidget`: when `quillController` changes (e.g. after `_initQuillForEdit()`), `_ctrl` is now fully rebuilt instead of reusing the old instance. This re-binds `tearHandle` and all listeners to the new controller, restoring the cursor tear handle (دمعة المؤشر) after transitioning from read-only to edit mode.

### 🗑️ Removed

**Hero animation — fully removed**
- Removed the experimental Hero card-to-fullscreen transition that was causing instability on various devices.
- Deleted `EditorPageRoute` (the custom transparent `PageRouteBuilder` used only for Hero flight) — navigation now always uses `MaterialPageRoute`.
- Deleted `HeroAnimationInfoSheet` (the settings bottom sheet explaining the beta feature).
- Removed `heroTag` parameter from `NoteCardWidget`, `PremiumCardEffect`, `NoteEditorImmersive`, and `NoteReadOnlyView`.
- Removed `heroAnimationEnabled` field, getter, setter, and `SharedPreferences` load from `SettingsProvider`.
- Removed Hero toggle from `MotionNavigationSection` (settings) and emptied `BetaSection` (debug-only).
- Removed `heroAnimation` localization key from ARB files and generated l10n classes (`app_localizations.dart`, `_ar.dart`, `_en.dart`).
- Removed `dart:ui show lerpDouble` import from `note_readonly_view.dart` and `provider`/`settings_provider` imports from `premium_card_effect.dart` — no longer needed.
- The long-note pre-build via `compute(buildDeltaJsonForIsolate)` is **retained** — it still prevents UI freeze when opening heavy notes, now applied unconditionally regardless of Hero state.

---

## [3.2.2] — 2026-06 | Paste Performance + Apex Sharing

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
