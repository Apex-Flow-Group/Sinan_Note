# Design Document

## Overview

This design document outlines the refactoring of the Sinan Note app's NotesProvider and note editor to improve maintainability, code organization, and bidirectional text handling. The refactoring follows Clean Architecture principles and the Single Responsibility Principle (SRP) while maintaining 100% backward compatibility.

### Key Design Goals

1. **Service Decomposition**: Split the 733-line NotesProvider into 5 focused services
2. **Bidirectional Text Support**: Implement per-paragraph text direction detection for mixed Arabic/English content
3. **Component Organization**: Reorganize the 1636-line note editor into logical, maintainable components
4. **Zero Breaking Changes**: Maintain all existing functionality and public APIs
5. **Performance Preservation**: Keep all existing optimizations (debounced sorting, in-memory filtering, optimistic UI)

## Architecture

### Current Architecture Issues

**NotesProvider (733 lines)**:
- Violates SRP by handling state management, CRUD operations, security, side effects, and batch operations
- Difficult to test individual concerns in isolation
- High coupling between unrelated features
- Hard to maintain and extend

**Note Editor (1636 lines)**:
- Monolithic widget with mixed concerns
- Text direction handling is note-level, not paragraph-level
- Complex state management scattered throughout
- Difficult to understand and modify

### Proposed Architecture

#### Service Layer Decomposition

```
NotesProvider (Facade Pattern)
├── NoteStateService (State Management)
│   ├── _allNotes: List<Note>
│   ├── _lockedNotes: List<Note>
│   ├── activeNotes getter
│   ├── archivedNotes getter
│   ├── trashedNotes getter
│   └── searchNotes(query)
│
├── NoteCRUDService (CRUD Operations)
│   ├── addNote(note)
│   ├── updateNote(note)
│   ├── deleteNote(id)
│   ├── getNoteById(id)
│   └── refreshAllNotes()
│
├── NoteSecurityService (Security & Encryption)
│   ├── Vault session management
│   ├── Encryption/decryption
│   ├── toggleLockStatus(id, status)
│   ├── fetchAndDecryptLockedNotes()
│   └── clearLockedSession()
│
├── NoteSideEffectService (Side Effects)
│   ├── Reminder scheduling/cancellation
│   ├── Widget updates
│   └── Notification management
│
└── NoteBatchOperationsService (Batch Operations)
    ├── trashNotes(ids)
    ├── restoreNotes(ids)
    ├── archiveNotes(ids)
    └── unarchiveNotes(ids)
```

#### Editor Component Organization

```
NoteEditorImmersive (Main Widget - <500 lines)
├── EditorStateManager (State Management)
│   ├── Content state
│   ├── UI state
│   ├── Dirty tracking
│   └── Mode management
│
├── TextDirectionController (Bidirectional Text)
│   ├── detectParagraphDirection(text)
│   ├── getParagraphDirections(content)
│   └── updateCursorPosition(selection)
│
├── EditorStorageController (Persistence)
│   ├── saveNoteToDatabase()
│   ├── loadStickySettings()
│   └── authenticateAndDecrypt()
│
├── EditorFormattingController (Text Formatting)
│   ├── wrapText(controller, wrapper)
│   ├── insertText(controller, text)
│   └── insertSymbol(controller, symbol)
│
└── EditorSmartController (Smart Features)
    ├── detectLanguage(text)
    ├── analyzeMathAndDates()
    └── showSmartCalculationResult()
```

## Components and Interfaces

### 1. NoteStateService

**Responsibility**: Manage in-memory note state and provide filtered views

```dart
class NoteStateService {
  List<Note> _allNotes = [];
  List<Note> _lockedNotes = [];
  bool _isInitialDataLoaded = false;
  
  // Getters with in-memory filtering
  List<Note> get activeNotes => _allNotes
      .where((n) => !n.isLocked && !n.isTrashed && !n.isArchived)
      .toList();
  
  List<Note> get archivedNotes => _allNotes
      .where((n) => n.isArchived && !n.isTrashed && !n.isLocked)
      .toList();
  
  List<Note> get trashedNotes => _allNotes
      .where((n) => n.isTrashed && !n.isLocked)
      .toList();
  
  List<Note> get lockedNotes => _lockedNotes;
  
  // State management
  void updateAllNotes(List<Note> notes) {
    _allNotes = notes;
    _isInitialDataLoaded = true;
  }
  
  void updateNote(Note note) {
    final index = _allNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _allNotes[index] = note;
      _allNotes = List.from(_allNotes); // New reference for Selector
    }
  }
  
  void removeNote(int id) {
    _allNotes.removeWhere((n) => n.id == id);
    _lockedNotes.removeWhere((n) => n.id == id);
  }
  
  // Search
  List<Note> searchNotes(String query) {
    final lowerQuery = query.toLowerCase();
    return _allNotes
        .where((n) =>
            !n.isLocked &&
            (n.title.toLowerCase().contains(lowerQuery) ||
                n.content.toLowerCase().contains(lowerQuery)))
        .toList();
  }
  
  // Sorting with debounce
  Timer? _sortDebounce;
  void sortNotes({bool immediate = false}) {
    if (immediate) {
      _performSort();
      return;
    }
    _sortDebounce?.cancel();
    _sortDebounce = Timer(const Duration(milliseconds: 50), _performSort);
  }
  
  void _performSort() {
    _allNotes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }
}
```

### 2. NoteCRUDService

**Responsibility**: Handle all CRUD operations with database synchronization

```dart
class NoteCRUDService {
  final DatabaseService _dbService;
  final NoteStateService _stateService;
  
  NoteCRUDService(this._dbService, this._stateService);
  
  Future<int> addNote(Note note) async {
    // 1. Add to memory immediately
    if (note.isLocked) {
      _stateService._lockedNotes.insert(0, note);
    } else {
      _stateService._allNotes.insert(0, note);
      _stateService.sortNotes(immediate: true);
    }
    
    // 2. DB insert in background
    final id = await _dbService.insertNote(note);
    
    // 3. Update ID only (no reload)
    _stateService.updateNote(note.copyWith(id: id));
    
    return id;
  }
  
  Future<int> updateNote(Note note, {bool silent = false}) async {
    final result = await _dbService.updateNote(note);
    
    // Update in-memory state
    final index = _stateService._allNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      final freshNote = await _dbService.getNoteById(note.id!);
      if (freshNote != null) {
        _stateService._allNotes[index] = freshNote;
      }
      _stateService.sortNotes(immediate: true);
      _stateService._allNotes = List.from(_stateService._allNotes);
    }
    
    return result;
  }
  
  Future<int> deleteNote(int id) async {
    final result = await _dbService.deleteNote(id);
    _stateService.removeNote(id);
    return result;
  }
  
  Future<Note?> getNoteById(int id) async {
    return await _dbService.getNoteById(id);
  }
  
  Future<void> refreshAllNotes() async {
    final notes = await _dbService.getAllNotes();
    _stateService.updateAllNotes(notes);
    _stateService.sortNotes(immediate: true);
  }
}
```

### 3. NoteSecurityService

**Responsibility**: Manage vault sessions, encryption, and locked note operations

```dart
class NoteSecurityService {
  bool _isVaultUnlocked = false;
  DateTime? _vaultUnlockedAt;
  static const _sessionDuration = Duration(minutes: 5);
  
  bool get isVaultUnlocked {
    if (!_isVaultUnlocked || _vaultUnlockedAt == null) return false;
    final elapsed = DateTime.now().difference(_vaultUnlockedAt!);
    if (elapsed > _sessionDuration) {
      _isVaultUnlocked = false;
      _vaultUnlockedAt = null;
      return false;
    }
    return true;
  }
  
  void unlockVault() {
    _isVaultUnlocked = true;
    _vaultUnlockedAt = DateTime.now();
  }
  
  void lockVault() {
    _isVaultUnlocked = false;
    _vaultUnlockedAt = null;
  }
  
  Future<List<Note>> fetchAndDecryptLockedNotes(DatabaseService dbService) async {
    final encryptedNotes = await dbService.getLockedNotes();
    final decryptedNotes = <Note>[];
    
    for (final note in encryptedNotes) {
      try {
        final decryptedTitle = note.isChecklist 
            ? note.title 
            : await EncryptionService.decrypt(note.title);
        final decryptedContent = note.isChecklist 
            ? note.content 
            : await EncryptionService.decrypt(note.content);
        
        decryptedNotes.add(note.copyWith(
          title: decryptedTitle,
          content: decryptedContent,
        ));
      } catch (e) {
        decryptedNotes.add(note);
      }
    }
    
    return decryptedNotes;
  }
  
  Future<void> toggleLockStatus(
    int id, 
    bool lockStatus,
    DatabaseService dbService,
  ) async {
    final note = await dbService.getNoteById(id);
    if (note == null) return;
    
    String finalTitle = note.title;
    String finalContent = note.content;
    
    if (lockStatus && !note.isChecklist) {
      // Encrypt
      if (note.title.isNotEmpty) {
        finalTitle = await EncryptionService.encrypt(note.title);
      }
      if (note.content.isNotEmpty) {
        finalContent = await EncryptionService.encrypt(note.content);
      }
    } else if (!lockStatus && !note.isChecklist) {
      // Decrypt
      finalTitle = await EncryptionService.decrypt(note.title);
      finalContent = await EncryptionService.decrypt(note.content);
    }
    
    final updatedNote = note.copyWith(
      title: finalTitle,
      content: finalContent,
      isLocked: lockStatus,
      updatedAt: DateTime.now(),
    );
    
    await dbService.updateNote(updatedNote);
  }
  
  void clearLockedSession(NoteStateService stateService) {
    stateService._lockedNotes = [];
  }
}
```

### 4. NoteSideEffectService

**Responsibility**: Handle side effects (reminders, notifications, widgets)

```dart
class NoteSideEffectService {
  Future<bool> handleReminderSideEffect(Note note) async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    
    try {
      final notificationService = NotificationService();
      
      // Cancel old reminder
      await notificationService.cancelNotification(note.id!);
      
      // Schedule new reminder if exists and is future
      if (note.reminderDateTime != null &&
          note.reminderDateTime!.isAfter(DateTime.now()) &&
          !note.isTrashed &&
          !note.isArchived) {
        
        final hasPermission = await notificationService.checkExactAlarmPermission();
        if (!hasPermission) return false;
        
        String notificationBody = note.isChecklist
            ? ChecklistFormatter.formatForSharing(note.title, note.content)
            : note.content;
        
        if (notificationBody.length > 100) {
          notificationBody = '${notificationBody.substring(0, 100)}...';
        }
        
        await notificationService.scheduleNotification(
          id: note.id!,
          title: note.title.isEmpty ? 'تذكير' : note.title,
          body: notificationBody,
          scheduledTime: note.reminderDateTime!,
          recurrenceRule: note.recurrenceRule,
          payload: note.id.toString(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> cancelReminderSideEffect(int noteId) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await NotificationService().cancelNotification(noteId);
    } catch (e) {
      debugPrint('⚠️ Cancel reminder error: $e');
    }
  }
  
  Future<void> updateWidgetSideEffect() async {
    if (!Platform.isAndroid) return;
    // Widget update logic (currently skipped during batch operations)
  }
}
```

### 5. NoteBatchOperationsService

**Responsibility**: Handle bulk operations with optimistic UI updates

```dart
class NoteBatchOperationsService {
  final DatabaseService _dbService;
  final NoteStateService _stateService;
  final NoteSideEffectService _sideEffectService;
  
  NoteBatchOperationsService(
    this._dbService,
    this._stateService,
    this._sideEffectService,
  );
  
  Future<void> trashNotes(List<int> ids) async {
    // 1. Functional immutable update
    _stateService._allNotes = _stateService._allNotes.map((n) => 
        ids.contains(n.id) 
            ? n.copyWith(isTrashed: true, isPinned: false, updatedAt: DateTime.now())
            : n
    ).toList();
    
    // 2. Silent background DB sync
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.trashNote(id);
        await _sideEffectService.cancelReminderSideEffect(id);
      }
      await _sideEffectService.updateWidgetSideEffect();
    });
  }
  
  Future<void> restoreNotes(List<int> ids) async {
    _stateService._allNotes = _stateService._allNotes.map((n) => 
        ids.contains(n.id) 
            ? n.copyWith(isArchived: false, isTrashed: false, updatedAt: DateTime.now())
            : n
    ).toList();
    
    _stateService.sortNotes();
    
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.restoreNote(id);
      }
      await _sideEffectService.updateWidgetSideEffect();
    });
  }
  
  Future<void> archiveNotes(List<int> ids) async {
    _stateService._allNotes = _stateService._allNotes.map((n) => 
        ids.contains(n.id) 
            ? n.copyWith(isArchived: true, isPinned: false, updatedAt: DateTime.now())
            : n
    ).toList();
    
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.archiveNote(id);
        await _sideEffectService.cancelReminderSideEffect(id);
      }
      await _sideEffectService.updateWidgetSideEffect();
    });
  }
  
  Future<void> unarchiveNotes(List<int> ids) async {
    _stateService._allNotes = _stateService._allNotes.map((n) => 
        ids.contains(n.id) 
            ? n.copyWith(isArchived: false, updatedAt: DateTime.now())
            : n
    ).toList();
    
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.unarchiveNote(id);
      }
    });
  }
}
```

### 6. NotesProvider (Facade)

**Responsibility**: Maintain backward compatibility by delegating to services

```dart
class NotesProvider extends ChangeNotifier {
  late final NoteStateService _stateService;
  late final NoteCRUDService _crudService;
  late final NoteSecurityService _securityService;
  late final NoteSideEffectService _sideEffectService;
  late final NoteBatchOperationsService _batchService;
  
  NotesProvider() {
    final dbService = DatabaseService();
    _stateService = NoteStateService();
    _crudService = NoteCRUDService(dbService, _stateService);
    _securityService = NoteSecurityService();
    _sideEffectService = NoteSideEffectService();
    _batchService = NoteBatchOperationsService(
      dbService,
      _stateService,
      _sideEffectService,
    );
  }
  
  // Delegate all methods to appropriate services
  List<Note> get activeNotes => _stateService.activeNotes;
  List<Note> get notes => activeNotes;
  List<Note> get archivedNotes => _stateService.archivedNotes;
  List<Note> get trashedNotes => _stateService.trashedNotes;
  List<Note> get lockedNotes => _stateService.lockedNotes;
  
  bool get isVaultUnlocked => _securityService.isVaultUnlocked;
  void unlockVault() => _securityService.unlockVault();
  void lockVault() {
    _securityService.lockVault();
    _securityService.clearLockedSession(_stateService);
    notifyListeners();
  }
  
  Future<int> addNote(Note note) async {
    final id = await _crudService.addNote(note);
    await _sideEffectService.handleReminderSideEffect(note.copyWith(id: id));
    notifyListeners();
    return id;
  }
  
  Future<int> updateNote(Note note, {bool silent = false}) async {
    final result = await _crudService.updateNote(note, silent: silent);
    await _sideEffectService.handleReminderSideEffect(note);
    await WidgetService.checkAndUpdateIfPinned(note);
    if (!silent) notifyListeners();
    return result;
  }
  
  // ... delegate all other methods similarly
}
```

### 7. TextDirectionController

**Responsibility**: Handle per-paragraph bidirectional text detection

```dart
class TextDirectionController {
  /// Detect text direction for a single paragraph
  TextDirection detectParagraphDirection(String text) {
    if (text.trim().isEmpty) return TextDirection.ltr;
    
    // Use Flutter's Bidi class for accurate detection
    final isRtl = Bidi.detectRtlDirectionality(text);
    return isRtl ? TextDirection.rtl : TextDirection.ltr;
  }
  
  /// Get text directions for all paragraphs in content
  List<ParagraphDirection> getParagraphDirections(String content) {
    final paragraphs = content.split('\n');
    final directions = <ParagraphDirection>[];
    
    int offset = 0;
    for (final paragraph in paragraphs) {
      final direction = detectParagraphDirection(paragraph);
      directions.add(ParagraphDirection(
        text: paragraph,
        direction: direction,
        startOffset: offset,
        endOffset: offset + paragraph.length,
      ));
      offset += paragraph.length + 1; // +1 for newline
    }
    
    return directions;
  }
  
  /// Update cursor position when switching between RTL/LTR
  TextSelection updateCursorPosition(
    TextSelection selection,
    String text,
    TextDirection oldDirection,
    TextDirection newDirection,
  ) {
    // Preserve cursor position during direction changes
    return selection;
  }
}

class ParagraphDirection {
  final String text;
  final TextDirection direction;
  final int startOffset;
  final int endOffset;
  
  ParagraphDirection({
    required this.text,
    required this.direction,
    required this.startOffset,
    required this.endOffset,
  });
}
```

### 8. EditorStateManager

**Responsibility**: Centralize editor state management

```dart
class EditorStateManager {
  // Content state
  String content = '';
  String? customTitle;
  String? checklistTitle;
  int colorIndex = 0;
  
  // UI state
  bool isAuthenticated = false;
  bool isSaving = false;
  bool isDirty = false;
  bool hasContent = false;
  
  // Undo/Redo state
  bool canUndo = false;
  bool canRedo = false;
  
  // Reminder state
  DateTime? reminderDateTime;
  String? recurrenceRule;
  
  // Original state snapshot for dirty checking
  String originalContent = '';
  String originalTitle = '';
  int originalColorIndex = 0;
  DateTime? originalReminderDateTime;
  String? originalRecurrenceRule;
  
  // Check if content has changed
  bool hasChanges() {
    return content != originalContent ||
           customTitle != originalTitle ||
           colorIndex != originalColorIndex ||
           reminderDateTime != originalReminderDateTime ||
           recurrenceRule != originalRecurrenceRule;
  }
  
  // Update original snapshot after save
  void updateSnapshot() {
    originalContent = content;
    originalTitle = customTitle ?? '';
    originalColorIndex = colorIndex;
    originalReminderDateTime = reminderDateTime;
    originalRecurrenceRule = recurrenceRule;
  }
}
```

## Data Models

### Existing Models (No Changes)

All existing models remain unchanged:
- `Note`: Core note model with all fields
- `NoteMode`: Enum for note types (Simple, Code, Checklist, Reminder)
- `NoteVersion`: Version control model

### New Models

#### ParagraphDirection

```dart
class ParagraphDirection {
  final String text;
  final TextDirection direction;
  final int startOffset;
  final int endOffset;
  
  ParagraphDirection({
    required this.text,
    required this.direction,
    required this.startOffset,
    required this.endOffset,
  });
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Per-Paragraph Text Direction Detection

*For any* multi-paragraph text content containing mixed RTL and LTR characters, the TextDirectionController should correctly detect and assign the appropriate text direction (RTL or LTR) to each paragraph based on its predominant character set.

**Validates: Requirements 2.1, 2.2, 2.3**

### Property 2: Text Direction Preserves Formatting

*For any* formatted text content (bold, italic, headers, lists), changing the text direction should preserve all existing formatting and styling without modification.

**Validates: Requirements 2.7**

### Property 3: Mixed-Language Paragraph Rendering

*For any* content containing paragraphs in different languages (Arabic, English, mixed), each paragraph should render with its correctly detected text direction independent of other paragraphs.

**Validates: Requirements 2.6**

### Property 4: Cursor Position Stability

*For any* text selection or cursor position in mixed-language content, switching text direction should maintain the cursor's logical position within the text.

**Validates: Requirements 2.4**

### Property 5: Backward Compatibility (Metamorphic Property)

*For any* existing user action (add note, update note, delete note, archive, trash, restore, search), the refactored system should produce identical results to the original system.

**Validates: Requirements 4.6**

### Property 6: Encryption Correctness

*For any* locked note (except checklists), the content should be encrypted exactly once when saved, and decryption followed by encryption should produce the original encrypted content (round-trip property).

**Validates: Requirements 6.2, 6.7**

### Property 7: Mode State Preservation

*For any* note mode switch (Simple ↔ Code ↔ Checklist ↔ Reminder), all note content, formatting, and metadata should be preserved without loss.

**Validates: Requirements 8.5**

### Property 8: Undo/Redo Consistency

*For any* sequence of edit operations in any note mode, applying undo followed by redo should restore the exact state before the undo operation.

**Validates: Requirements 8.7**

### Property 9: Smart Dirty Checking

*For any* note content, if the content has not changed from its original state, the system should not trigger a save operation.

**Validates: Requirements 9.3**

### Property 10: Widget Update on Pinned Note Modification

*For any* pinned note modification (content, title, color, reminder), the home screen widget should receive an update notification.

**Validates: Requirements 10.1**

### Property 11: Notification Scheduling for Reminders

*For any* note with a future reminder date/time, the system should schedule a notification with the correct time and recurrence rule.

**Validates: Requirements 10.2, 10.4**

### Property 12: Notification Cancellation

*For any* note with an active reminder that is removed, trashed, or archived, the system should cancel the scheduled notification.

**Validates: Requirements 10.3, 10.5**

### Property 13: Widget Reset on Pinned Note Deletion

*For any* pinned note that is deleted or trashed, the home screen widget should be reset if it was displaying that note.

**Validates: Requirements 10.7**

## Error Handling

### Service Layer Error Handling

**NoteStateService**:
- No direct error handling needed (in-memory operations)
- Sorting errors are silently ignored (defensive programming)

**NoteCRUDService**:
- Database errors are propagated to the caller
- Failed operations do not modify in-memory state
- Partial updates are rolled back

**NoteSecurityService**:
- Decryption failures return the original encrypted note
- Vault session expiration is handled gracefully
- Encryption errors are logged but not thrown

**NoteSideEffectService**:
- Notification scheduling failures return false (not thrown)
- Widget update failures are logged but don't block operations
- Permission errors are handled with user-friendly messages

**NoteBatchOperationsService**:
- Individual operation failures don't stop the batch
- Failed operations are logged for debugging
- UI updates happen optimistically regardless of DB success

### Editor Error Handling

**TextDirectionController**:
- Empty text defaults to LTR
- Invalid text is treated as LTR
- Direction detection never throws

**EditorStateManager**:
- State transitions are atomic
- Invalid state changes are ignored
- Dirty flag is always consistent

**EditorStorageController**:
- Save failures show user-friendly error messages
- Autosave failures are silent (retry on next change)
- Decryption failures prompt for re-authentication

## Testing Strategy

### Dual Testing Approach

This refactoring requires both **unit tests** and **property-based tests** for comprehensive coverage:

**Unit Tests** focus on:
- Specific examples of text direction detection (Arabic paragraph, English paragraph, mixed paragraph)
- Edge cases (empty content, single character, special characters)
- API compatibility (method signatures, return types)
- Integration points (service delegation, notification scheduling)
- Timing behavior (debounce delays, session timeouts)

**Property-Based Tests** focus on:
- Universal properties across all inputs (text direction detection for any content)
- Metamorphic properties (refactored system = original system for any action)
- Round-trip properties (encryption/decryption, undo/redo)
- Invariants (formatting preservation, cursor stability)

### Property-Based Testing Configuration

**Library**: Use `faker` package for Dart to generate random test data
**Iterations**: Minimum 100 iterations per property test
**Tag Format**: `// Feature: notes-provider-refactoring-and-editor-enhancement, Property {number}: {property_text}`

### Test Organization

```
test/
├── unit/
│   ├── services/
│   │   ├── note_state_service_test.dart
│   │   ├── note_crud_service_test.dart
│   │   ├── note_security_service_test.dart
│   │   ├── note_side_effect_service_test.dart
│   │   └── note_batch_operations_service_test.dart
│   ├── controllers/
│   │   ├── text_direction_controller_test.dart
│   │   └── editor_state_manager_test.dart
│   └── integration/
│       ├── notes_provider_facade_test.dart
│       └── editor_integration_test.dart
│
└── property/
    ├── text_direction_properties_test.dart
    ├── encryption_properties_test.dart
    ├── backward_compatibility_properties_test.dart
    ├── mode_switching_properties_test.dart
    └── notification_properties_test.dart
```

### Example Property Test

```dart
// Feature: notes-provider-refactoring-and-editor-enhancement, Property 1: Per-Paragraph Text Direction Detection
test('Property 1: Text direction detection for mixed content', () {
  final controller = TextDirectionController();
  final faker = Faker();
  
  for (int i = 0; i < 100; i++) {
    // Generate random mixed content
    final arabicParagraph = faker.lorem.words(10).join(' ') + ' مرحبا بك';
    final englishParagraph = faker.lorem.sentence();
    final mixedContent = '$arabicParagraph\n$englishParagraph';
    
    // Test property
    final directions = controller.getParagraphDirections(mixedContent);
    
    expect(directions.length, equals(2));
    expect(directions[0].direction, equals(TextDirection.rtl));
    expect(directions[1].direction, equals(TextDirection.ltr));
  }
});
```

### Example Unit Test

```dart
test('NotesProvider maintains backward compatibility', () {
  final provider = NotesProvider();
  
  // Verify all public methods exist with correct signatures
  expect(provider.activeNotes, isA<List<Note>>());
  expect(provider.addNote, isA<Future<int> Function(Note)>());
  expect(provider.updateNote, isA<Future<int> Function(Note, {bool silent})>());
  expect(provider.deleteNote, isA<Future<int> Function(int)>());
  expect(provider.trashNotes, isA<Future<void> Function(List<int>)>());
  expect(provider.isVaultUnlocked, isA<bool>());
  expect(provider.unlockVault, isA<void Function()>());
});
```

### Integration Testing

**Critical Integration Points**:
1. NotesProvider → Services delegation
2. Services → DatabaseService interaction
3. Editor → NotesProvider state updates
4. TextDirectionController → Editor rendering
5. Side effects → External systems (notifications, widgets)

**Integration Test Strategy**:
- Test complete user flows (create note → edit → save → delete)
- Verify service coordination (CRUD + side effects)
- Test vault session management across services
- Verify batch operations with side effects

### Performance Testing

**Benchmarks to Maintain**:
- Note list sorting: < 50ms for 1000 notes
- In-memory filtering: < 10ms for 1000 notes
- Text direction detection: < 5ms for 1000 characters
- Autosave debounce: exactly 500ms delay
- Vault session check: < 1ms

**Performance Test Strategy**:
- Measure before and after refactoring
- Ensure no regression in any benchmark
- Test with large datasets (10,000+ notes)
- Profile memory usage (should not increase)

### Regression Testing

**Existing Test Suite**:
- Run all existing tests without modification
- All tests must pass (100% pass rate)
- No test modifications allowed (validates backward compatibility)

**Regression Test Strategy**:
1. Run existing test suite before refactoring (baseline)
2. Perform refactoring
3. Run existing test suite after refactoring
4. Compare results (must be identical)
5. Any failures indicate breaking changes

## Migration Strategy

### Phase 1: Service Extraction (No Breaking Changes)

1. Create new service classes alongside existing NotesProvider
2. Implement all service methods
3. Add comprehensive unit tests for each service
4. Services are not yet used (parallel implementation)

### Phase 2: Facade Implementation (Backward Compatible)

1. Modify NotesProvider to instantiate services
2. Delegate methods to services while keeping original signatures
3. Run existing tests to verify no breaking changes
4. Add integration tests for service coordination

### Phase 3: Editor Refactoring (Incremental)

1. Extract TextDirectionController
2. Extract EditorStateManager
3. Refactor content rendering into separate widgets
4. Test each extraction independently
5. Maintain all existing functionality

### Phase 4: Validation and Cleanup

1. Run full test suite (unit + property + integration)
2. Performance benchmarking
3. Code review and documentation
4. Remove any dead code or temporary scaffolding

### Rollback Strategy

If any phase introduces breaking changes:
1. Revert to previous commit
2. Identify root cause
3. Fix issue in isolation
4. Re-run tests before proceeding

## Documentation

### Service Documentation

Each service class will include:
- Class-level doc comment explaining responsibility
- Method-level doc comments with parameters and return values
- Usage examples in doc comments
- Links to related services

### Architecture Documentation

Create `ARCHITECTURE.md` in the project root:
- Overview of service layer architecture
- Diagram showing service relationships
- Explanation of facade pattern usage
- Guidelines for adding new features

### Migration Guide

Create `MIGRATION_GUIDE.md` for developers:
- Explanation of changes
- Before/after code examples
- How to use new services directly (if needed)
- Troubleshooting common issues

### Code Comments

Add inline comments for:
- Complex encryption logic
- Batch operation optimizations
- Text direction detection algorithm
- Vault session management
- Performance-critical sections

## Performance Considerations

### Memory Optimization

**Current State**:
- Single `_allNotes` list (single source of truth)
- Separate `_lockedNotes` list for security
- Filtered views computed on-demand (no caching)

**After Refactoring**:
- Same memory footprint (no additional caching)
- Services share references to state (no duplication)
- Functional updates create new list references (required for Selector)

### CPU Optimization

**Debounced Sorting**:
- Maintained at 50ms delay
- Prevents multiple sorts during rapid changes
- Immediate sort for critical operations (pin, restore)

**In-Memory Filtering**:
- No database queries for filtered views
- O(n) filtering complexity (acceptable for < 10,000 notes)
- Lazy evaluation (computed on getter access)

**Optimistic UI Updates**:
- Synchronous state updates (0ms UI response)
- Asynchronous database sync (non-blocking)
- Functional immutable updates (efficient for batch operations)

### Database Optimization

**Write-Time Optimization**:
- Batch operations use single transaction (future enhancement)
- Silent saves don't trigger UI updates
- Background sync doesn't block user interactions

**Read-Time Optimization**:
- Single database query on app start
- All subsequent operations use in-memory state
- Refresh only when explicitly requested

## Security Considerations

### Vault Session Management

**Session Timeout**:
- 5-minute inactivity timeout
- Automatic lock on timeout
- Session check on every vault access

**Memory Security**:
- Decrypted notes stored in separate list
- `clearLockedSession()` wipes decrypted data
- No decrypted content in logs or crash reports

### Encryption

**Content Encryption**:
- AES-256 encryption for locked notes
- Checklists stored as plain JSON (by design)
- No double encryption (checked before save)

**Key Management**:
- Encryption keys managed by EncryptionService
- Keys never stored in plain text
- Biometric authentication for key access

### Data Integrity

**Atomic Operations**:
- Database transactions for critical operations
- Rollback on failure
- Consistent state between memory and database

**Validation**:
- Input validation before encryption
- Decryption failure handling
- Corrupted data recovery (return original)

## Accessibility Considerations

### Text Direction

**RTL Support**:
- Proper text alignment for Arabic content
- Correct cursor positioning in RTL text
- Bidirectional text rendering

**LTR Support**:
- Standard left-to-right rendering
- Mixed content handling
- Seamless language switching

### Keyboard Navigation

**Maintained Features**:
- Tab navigation between fields
- Keyboard shortcuts (undo/redo)
- Focus management

### Screen Readers

**Maintained Features**:
- Semantic labels for all UI elements
- Proper focus order
- Announcement of state changes

## Internationalization

### Language Support

**Current Languages**:
- Arabic (RTL)
- English (LTR)

**Text Direction Detection**:
- Automatic per-paragraph detection
- Manual override if needed
- Proper rendering for mixed content

### Localization

**Maintained Features**:
- All UI strings localized
- Date/time formatting per locale
- Number formatting per locale

## Future Enhancements

### Service Layer

**Potential Additions**:
- NoteSyncService for cloud synchronization
- NoteCollaborationService for real-time editing
- NoteAnalyticsService for usage tracking
- NoteExportService for bulk export

### Editor

**Potential Improvements**:
- Real-time collaboration
- Advanced formatting (tables, images)
- Voice input with automatic transcription
- AI-powered suggestions

### Text Direction

**Potential Enhancements**:
- Per-word direction detection
- Automatic language switching
- Custom direction rules
- Direction hints for ambiguous text

## Conclusion

This refactoring improves code maintainability and organization while maintaining 100% backward compatibility. The service layer decomposition follows Clean Architecture principles and the Single Responsibility Principle, making the codebase easier to understand, test, and extend. The enhanced bidirectional text handling provides a better user experience for mixed Arabic/English content. All existing functionality, performance optimizations, and security features are preserved.
