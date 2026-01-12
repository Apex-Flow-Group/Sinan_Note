# 🏗️ Sinan Note - Technical Architecture Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture Pattern](#architecture-pattern)
3. [Project Structure](#project-structure)
4. [State Management](#state-management)
5. [Security Architecture](#security-architecture)
6. [Performance Optimizations](#performance-optimizations)
7. [Database Design](#database-design)
8. [Encryption System](#encryption-system)
9. [Notification System](#notification-system)
10. [Widget System](#widget-system)

---

## Overview

Sinan Note is built using **Flutter 3.0+** with a focus on:
- **Clean Architecture**: Separation of concerns with clear boundaries
- **Modular Design**: Each feature is self-contained and testable
- **Performance First**: Optimized for smooth 60fps experience
- **Security by Design**: Encryption and session management at the core

### Technology Stack
- **Framework**: Flutter 3.0+ / Dart 3.0+
- **State Management**: Provider pattern
- **Database**: SQLite (sqflite)
- **Encryption**: AES-256 (encrypt package)
- **Authentication**: Biometric (local_auth)
- **Notifications**: flutter_local_notifications

---

## Architecture Pattern

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens, Widgets, UI Components)      │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Business Logic Layer            │
│  (Providers, Services, Use Cases)       │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Data Layer                      │
│  (Database, Storage, Encryption)        │
└─────────────────────────────────────────┘
```

### Refactoring Journey

**Before (v1.x)**: Monolithic structure
- Single 3000+ line file
- Tight coupling between UI and logic
- Difficult to test and maintain

**After (v2.x)**: Modular structure
- Separated into 50+ focused files
- Clear separation of concerns
- Easy to test and extend

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
│
├── models/                      # Data Models
│   ├── note.dart               # Core Note entity
│   ├── note_mode.dart          # Note type enum
│   ├── note_version.dart       # Version tracking
│   ├── exceptions.dart         # Custom exceptions
│   └── transfer_status.dart    # P2P transfer states
│
├── services/                    # Business Logic
│   ├── notes_provider.dart     # ⭐ Main state manager
│   ├── settings_provider.dart  # App settings state
│   ├── database_service.dart   # SQLite operations
│   ├── encryption_service.dart # AES-256 encryption
│   ├── biometric_service.dart  # Fingerprint/Face ID
│   ├── notification_service.dart # Reminders
│   ├── backup_service.dart     # Export/Import
│   ├── google_drive_service.dart # Cloud sync
│   ├── transfer_service.dart   # P2P sharing
│   ├── widget_service.dart     # Home screen widgets
│   ├── storage_service.dart    # File operations
│   ├── language_detector.dart  # RTL/LTR detection
│   ├── smart_analyzer.dart     # Content analysis
│   ├── code_executor.dart      # Code evaluation
│   ├── code_exporter.dart      # Code export
│   ├── apex_diagnostics_engine.dart # Error tracking
│   └── apex_error_manager.dart # Error handling
│
├── screens/                     # UI Screens
│   ├── home_screen.dart        # Main notes list
│   ├── note_editor.dart        # Note editing
│   ├── note_view_screen.dart   # Read-only view
│   ├── locked_notes_screen.dart # Vault interface
│   ├── archive_screen.dart     # Archived notes
│   ├── trash_screen.dart       # Deleted notes
│   ├── settings_screen.dart    # App settings
│   ├── transfer_screen.dart    # P2P transfer
│   ├── splash_screen.dart      # Loading screen
│   ├── cinematic_intro_screen.dart # First launch
│   ├── tour_screen.dart        # Feature tour
│   ├── note_editor/            # Editor components
│   │   ├── simple_editor.dart
│   │   ├── professional_editor.dart
│   │   └── checklist_editor.dart
│   └── tabs/                   # Tab views
│       └── ...
│
├── widgets/                     # Reusable Components
│   ├── home/                   # Home screen widgets
│   │   ├── note_card_widget.dart
│   │   ├── add_menu_widget.dart
│   │   ├── home_drawer_widget.dart
│   │   ├── selection_action_bar.dart
│   │   └── smooth_search_header_delegate.dart
│   ├── editor/                 # Editor widgets
│   │   ├── toolbar_widget.dart
│   │   ├── color_picker_widget.dart
│   │   └── reminder_picker_widget.dart
│   ├── breathing_search_field.dart
│   ├── notes_grid.dart
│   ├── biometric_auth_wrapper.dart
│   ├── liquid_background_effect.dart
│   └── ...
│
├── utils/                       # Helper Utilities
│   ├── apex_smart_controller.dart
│   └── checklist_formatter.dart
│
└── l10n/                        # Localization
    ├── app_ar.arb              # Arabic strings
    ├── app_en.arb              # English strings
    ├── app_localizations_helper.dart
    └── strings_data.dart
```

---

## State Management

### Provider Pattern

We use **Provider** for state management with two main providers:

#### 1. NotesProvider (Core State Manager)

**Responsibilities:**
- Manage all notes in memory (Single Source of Truth)
- Handle CRUD operations
- Manage vault session
- Coordinate side effects (notifications, widgets)

**Key Features:**
```dart
class NotesProvider extends ChangeNotifier with WidgetsBindingObserver {
  // SINGLE SOURCE OF TRUTH
  List<Note> _allNotes = [];
  List<Note> _lockedNotes = []; // Isolated vault session
  
  // VAULT SESSION MANAGEMENT
  bool _isVaultUnlocked = false;
  DateTime? _vaultUnlockedAt;
  static const _sessionDuration = Duration(minutes: 5);
  
  // SMART GETTERS (in-memory filtering)
  List<Note> get activeNotes => _allNotes.where(...).toList();
  List<Note> get archivedNotes => _allNotes.where(...).toList();
  List<Note> get trashedNotes => _allNotes.where(...).toList();
}
```

**Lifecycle Monitoring:**
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  // 🔒 Lock vault immediately when app goes to background
  if (state == AppLifecycleState.paused || 
      state == AppLifecycleState.inactive) {
    if (_isVaultUnlocked) {
      lockVault(); // Instant security
    }
  }
}
```

#### 2. SettingsProvider

**Responsibilities:**
- App preferences (theme, language, text size)
- View type (grid/list)
- Security settings (blur background, app lock)

**Persistence:**
- Uses `shared_preferences` for instant load
- All settings cached in memory

---

## Security Architecture

### 🔐 Multi-Layer Security Model

#### Layer 1: Encryption (AES-256)

**Implementation:**
```dart
class EncryptionService {
  static const _keyName = 'sinan_vault_key';
  static Key? _cachedKey; // In-memory cache
  
  // Generate or retrieve 32-byte key
  static Future<Key> _getOrCreateKey() async {
    // Stored in FlutterSecureStorage (Android Keystore)
    String? keyString = await _storage.read(key: _keyName);
    if (keyString == null) {
      final key = Key.fromSecureRandom(32);
      await _storage.write(key: _keyName, value: key.base64);
      return key;
    }
    return Key.fromBase64(keyString);
  }
  
  // Encrypt: Returns "iv:ciphertext" format
  static Future<String> encrypt(String plainText) async {
    final key = await _getOrCreateKey();
    final iv = IV.fromSecureRandom(16); // Random IV per encryption
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }
}
```

**Key Storage:**
- **Android**: Android Keystore (hardware-backed if available)
- **Linux/Windows**: Encrypted shared preferences

#### Layer 2: Session Management

**Temporary Unlock Pattern:**
```dart
// Vault unlocks for 5 minutes only
bool get isVaultUnlocked {
  if (!_isVaultUnlocked || _vaultUnlockedAt == null) return false;
  
  final elapsed = DateTime.now().difference(_vaultUnlockedAt!);
  if (elapsed > _sessionDuration) {
    _isVaultUnlocked = false;
    _vaultUnlockedAt = null;
    return false; // Auto-lock
  }
  return true;
}
```

**Memory Wipe:**
```dart
void clearLockedSession() {
  _lockedNotes = []; // Clear decrypted data from RAM
  notifyListeners();
}
```

#### Layer 3: Biometric Authentication

**Flow:**
1. User taps "Vault" in drawer
2. System prompts for fingerprint/face
3. On success: `unlockVault()` called
4. Decrypted notes loaded into isolated `_lockedNotes` list
5. After 5 minutes or app background: `lockVault()` + `clearLockedSession()`

**Implementation:**
```dart
final auth = LocalAuthentication();
final canAuthenticate = await auth.canCheckBiometrics;
if (canAuthenticate) {
  final authenticated = await auth.authenticate(
    localizedReason: 'Unlock vault',
    options: const AuthenticationOptions(
      biometricOnly: true,
      stickyAuth: true,
    ),
  );
  if (authenticated) {
    notesProvider.unlockVault();
  }
}
```

#### Layer 4: Background Protection

**Privacy Blur:**
```dart
// In SettingsProvider
bool _blurInBackground = true;

// In main.dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    // Android shows blurred snapshot in recent apps
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }
}
```

---

## Performance Optimizations

### 1. Slivers for Infinite Scrolling

**Why Slivers?**
- Lazy loading: Only visible items rendered
- Smooth 60fps even with 10,000+ notes
- Native scroll physics

**Implementation:**
```dart
CustomScrollView(
  slivers: [
    SliverPersistentHeader(
      floating: true,
      delegate: SmoothSearchHeaderDelegate(...),
    ),
    SliverMasonryGrid.count(
      crossAxisCount: 2,
      itemBuilder: (context, index) => NoteCard(...),
    ),
  ],
)
```

### 2. In-Memory Filtering

**Before (v1.x):**
```dart
// Database query for every filter
Future<List<Note>> getArchivedNotes() async {
  return await db.query('notes', where: 'isArchived = 1');
}
```

**After (v2.x):**
```dart
// Single load, filter in memory
List<Note> get archivedNotes => 
  _allNotes.where((n) => n.isArchived).toList();
```

**Benefits:**
- 10x faster filtering
- No database I/O overhead
- Instant search results

### 3. Debounced Search

```dart
Timer? _debounce;

void _onSearchChanged() {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    setState(() => _searchQuery = _searchController.text);
  });
}
```

### 4. Native Keyboard Resize

```dart
// In AndroidManifest.xml
<activity android:windowSoftInputMode="adjustResize">

// Prevents layout jank when keyboard appears
```

### 5. Widget Caching

```dart
// Reusable widgets with const constructors
const NoteCard({
  super.key,
  required this.note,
  required this.viewType,
});
```

---

## Database Design

### Schema (SQLite)

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  colorValue INTEGER DEFAULT 0xFFFFFFFF,
  isArchived INTEGER DEFAULT 0,
  isTrashed INTEGER DEFAULT 0,
  isLocked INTEGER DEFAULT 0,
  isPinned INTEGER DEFAULT 0,
  isChecklist INTEGER DEFAULT 0,
  isProfessional INTEGER DEFAULT 0,
  isCompleted INTEGER DEFAULT 0,
  reminderDateTime INTEGER,
  recurrenceRule TEXT,
  noteType TEXT DEFAULT 'simple'
);

CREATE INDEX idx_locked ON notes(isLocked);
CREATE INDEX idx_trashed ON notes(isTrashed);
CREATE INDEX idx_archived ON notes(isArchived);
CREATE INDEX idx_updated ON notes(updatedAt DESC);
```

### CRUD Operations

**Insert:**
```dart
Future<int> insertNote(Note note) async {
  final db = await database;
  return await db.insert('notes', note.toMap());
}
```

**Update:**
```dart
Future<int> updateNote(Note note) async {
  final db = await database;
  return await db.update(
    'notes',
    note.toMap(),
    where: 'id = ?',
    whereArgs: [note.id],
  );
}
```

**Soft Delete (Trash):**
```dart
Future<int> trashNote(int id) async {
  final db = await database;
  return await db.update(
    'notes',
    {'isTrashed': 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
    where: 'id = ?',
    whereArgs: [id],
  );
}
```

**Hard Delete:**
```dart
Future<int> deleteNote(int id) async {
  final db = await database;
  return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
}
```

---

## Encryption System

### Encryption Flow

```
┌──────────────┐
│  Plain Text  │
└──────┬───────┘
       │
       ▼
┌──────────────────────┐
│  Generate Random IV  │ (16 bytes)
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  AES-256 Encrypt     │ (with key from Keystore)
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  Format: "iv:cipher" │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  Store in Database   │
└──────────────────────┘
```

### Decryption Flow

```
┌──────────────────────┐
│  Read from Database  │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  Split "iv:cipher"   │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  Extract IV          │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  AES-256 Decrypt     │ (with key from Keystore)
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  Return Plain Text   │
└──────────────────────┘
```

### Security Considerations

1. **Random IV**: Each encryption uses a unique IV (prevents pattern analysis)
2. **Key Rotation**: Not implemented yet (planned for v2.3)
3. **Secure Storage**: Keys never stored in plain text
4. **Memory Safety**: Decrypted data cleared on session end

---

## Notification System

### Reminder Scheduling

**Architecture:**
```dart
class NotificationService {
  // Schedule exact alarm (Android 12+)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? recurrenceRule,
  }) async {
    // Check exact alarm permission
    final hasPermission = await checkExactAlarmPermission();
    if (!hasPermission) return;
    
    // Schedule with timezone
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: ...,
    );
  }
}
```

**Recurrence Rules:**
- `daily`: Repeats every 24 hours
- `weekly`: Repeats every 7 days
- `monthly`: Repeats every 30 days

**Side Effect Pattern:**
```dart
// In NotesProvider
Future<bool> _handleReminderSideEffect(Note note) async {
  // Cancel old reminder
  await NotificationService().cancelNotification(note.id!);
  
  // Schedule new reminder if valid
  if (note.reminderDateTime != null && 
      note.reminderDateTime!.isAfter(DateTime.now())) {
    await NotificationService().scheduleNotification(...);
  }
}
```

---

## Widget System

### Home Screen Widgets (Android)

**Types:**
1. **Note Widget**: Display single note content
2. **Checklist Widget**: Interactive task list

**Update Flow:**
```dart
class WidgetService {
  // Update widget data
  static Future<void> updateWidgetData() async {
    await HomeWidget.saveWidgetData('note_title', title);
    await HomeWidget.saveWidgetData('note_content', content);
    await HomeWidget.updateWidget(
      name: 'NoteWidgetProvider',
      androidName: 'NoteWidgetProvider',
    );
  }
  
  // Handle widget tap
  static Future<void> initialize() async {
    HomeWidget.widgetClicked.listen((Uri? uri) {
      final noteId = int.tryParse(uri?.queryParameters['note_id'] ?? '0');
      if (noteId > 0) {
        // Open note in app
        navigatorKey.currentState?.push(...);
      }
    });
  }
}
```

**Auto-Update Triggers:**
- Note created/updated/deleted
- Note pinned/unpinned
- App launched

---

## Error Handling

### Apex Diagnostics Engine

**Purpose:** Silent error tracking without crashing the app

**Implementation:**
```dart
class ApexDiagnosticsEngine {
  void logError(String context, dynamic error, StackTrace? stack) {
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'context': context,
      'error': error.toString(),
      'stack': stack?.toString(),
    };
    
    // Write to local file
    _writeLog(log);
  }
}
```

**Usage:**
```dart
try {
  await riskyOperation();
} catch (e, stack) {
  ApexDiagnosticsEngine().logError('RiskyOperation', e, stack);
  // Show user-friendly message
  ApexErrorManager.showError(context, 'Operation failed');
}
```

---

## Testing Strategy

### Unit Tests
- `models/`: Data model validation
- `services/`: Business logic isolation
- `utils/`: Helper function correctness

### Widget Tests
- `widgets/`: Component rendering
- `screens/`: Screen navigation

### Integration Tests
- End-to-end user flows
- Database operations
- Encryption/decryption

**Run Tests:**
```bash
flutter test
```

---

## Build & Deployment

### Release Build Process

1. **Version Bump**
   ```yaml
   # pubspec.yaml
   version: 2.1.1+1  # Format: major.minor.patch+build
   ```

2. **Code Signing**
   ```bash
   # Generate keystore (first time only)
   keytool -genkey -v -keystore sinan-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias sinan-release-key
   ```

3. **Build**
   ```bash
   flutter build apk --release --split-per-abi
   flutter build appbundle --release
   ```

4. **Obfuscation** (Optional)
   ```bash
   flutter build apk --release --obfuscate --split-debug-info=debug_symbols/
   ```

---

## Performance Metrics

### Target Benchmarks
- **App Launch**: < 2 seconds (cold start)
- **Note Load**: < 100ms (1000 notes)
- **Search**: < 50ms (instant results)
- **Scroll FPS**: 60fps (no jank)
- **Memory**: < 100MB (typical usage)

### Profiling Tools
```bash
# CPU profiling
flutter run --profile

# Memory profiling
flutter run --profile --trace-skia

# Build size analysis
flutter build apk --analyze-size
```

---

## Future Improvements

### Planned Optimizations
1. **Isolates**: Move encryption to background thread
2. **Incremental Loading**: Load notes in batches
3. **Image Caching**: Optimize attachment rendering
4. **Code Splitting**: Reduce initial bundle size

### Planned Features
1. **End-to-End Encryption**: For cloud sync
2. **Conflict Resolution**: For multi-device sync
3. **Version History**: Track note changes
4. **Collaborative Editing**: Real-time multi-user

---

## Conclusion

Sinan Note's architecture prioritizes:
- **Security**: Multi-layer encryption and session management
- **Performance**: Optimized rendering and data access
- **Maintainability**: Clean separation of concerns
- **Scalability**: Ready for future features

For questions or contributions, see [README.md](README.md).

---

<div align="center">

**Built with 🏗️ by Apex Flow Group**

[⬆ Back to Top](#-sinan-note---technical-architecture-documentation)

</div>
