# Requirements Document

## Introduction

This document specifies the requirements for refactoring the Sinan Note app's NotesProvider and note editor to improve maintainability, organization, and bidirectional text handling. The refactoring will split the 733-line NotesProvider into focused services following the Single Responsibility Principle, and reorganize the 1636-line note editor to better handle mixed Arabic/English content while maintaining zero breaking changes.

## Glossary

- **NotesProvider**: The main state management class that handles all note operations (currently 733 lines)
- **Note_Editor**: The main editor screen for creating and editing notes (currently 1636 lines)
- **Provider_Pattern**: Flutter's state management pattern using ChangeNotifier
- **RTL**: Right-to-Left text direction (for Arabic)
- **LTR**: Left-to-Right text direction (for English)
- **Bidirectional_Text**: Text content containing both RTL and LTR characters
- **Vault**: Secure storage for locked notes with encryption
- **Clean_Architecture**: Software design pattern separating concerns into layers
- **SRP**: Single Responsibility Principle - each class should have one reason to change
- **Note_Mode**: Type of note (Simple, Professional/Code, Checklist, Reminder)

## Requirements

### Requirement 1: Split NotesProvider into Focused Services

**User Story:** As a developer, I want the NotesProvider split into smaller, focused services, so that the codebase is more maintainable and follows Single Responsibility Principle.

#### Acceptance Criteria

1. THE System SHALL create a NoteStateService that manages the in-memory note list and filtering logic
2. THE System SHALL create a NoteCRUDService that handles create, read, update, and delete operations
3. THE System SHALL create a NoteSecurityService that manages vault sessions, encryption, and locked note operations
4. THE System SHALL create a NoteSideEffectService that handles reminders, notifications, and widget updates
5. THE System SHALL create a NoteBatchOperationsService that handles bulk operations (trash, restore, archive multiple notes)
6. THE System SHALL maintain the existing NotesProvider as a facade that delegates to the new services
7. WHEN any service is modified, THEN other services SHALL remain unaffected (loose coupling)
8. THE System SHALL preserve all existing public methods in NotesProvider for backward compatibility

### Requirement 2: Improve Bidirectional Text Handling in Editor

**User Story:** As a user, I want the note editor to handle mixed Arabic and English text properly, so that editing is smooth and text direction is correct regardless of language.

#### Acceptance Criteria

1. WHEN a user types in the editor, THE System SHALL detect text direction per paragraph (not per note)
2. WHEN a paragraph contains primarily RTL characters, THE System SHALL apply RTL text direction to that paragraph
3. WHEN a paragraph contains primarily LTR characters, THE System SHALL apply LTR text direction to that paragraph
4. WHEN a user switches between Arabic and English within a paragraph, THE System SHALL maintain proper cursor positioning
5. THE System SHALL use Flutter's Bidi class for accurate text direction detection
6. WHEN the editor displays mixed-language content, THE System SHALL render each paragraph with its appropriate text direction
7. THE System SHALL preserve existing text formatting and styling during direction changes

### Requirement 3: Organize Note Editor Components

**User Story:** As a developer, I want the note editor organized into logical components, so that the code is easier to understand and maintain.

#### Acceptance Criteria

1. THE System SHALL extract text direction logic into a TextDirectionController
2. THE System SHALL extract content rendering logic into separate widget builders
3. THE System SHALL maintain existing EditorStorageController, EditorFormattingController, and EditorSmartController
4. THE System SHALL organize editor state management into a dedicated EditorStateManager
5. THE System SHALL keep the main NoteEditorImmersive widget under 500 lines
6. WHEN any editor component is modified, THEN other components SHALL remain unaffected
7. THE System SHALL preserve all existing editor functionality and user interactions

### Requirement 4: Maintain Zero Breaking Changes

**User Story:** As a user, I want all existing functionality to work exactly as before, so that the refactoring doesn't disrupt my workflow.

#### Acceptance Criteria

1. THE System SHALL preserve all existing NotesProvider public methods with identical signatures
2. THE System SHALL maintain all existing note editor features (save, autosave, undo/redo, formatting)
3. THE System SHALL keep all existing security features (vault session, encryption, biometric auth)
4. THE System SHALL preserve all performance optimizations (debounced sorting, in-memory filtering)
5. THE System SHALL maintain all existing side effects (notifications, widget updates, version control)
6. WHEN a user performs any existing action, THE System SHALL produce the same result as before refactoring
7. THE System SHALL pass all existing tests without modification

### Requirement 5: Preserve Performance Optimizations

**User Story:** As a user, I want the app to remain fast and responsive, so that the refactoring doesn't degrade performance.

#### Acceptance Criteria

1. THE System SHALL maintain debounced sorting (50ms delay) for write-time optimization
2. THE System SHALL keep in-memory filtering for activeNotes, archivedNotes, and trashedNotes
3. THE System SHALL preserve optimistic UI updates for batch operations
4. THE System SHALL maintain the single source of truth pattern (_allNotes list)
5. THE System SHALL keep the functional immutable update pattern for batch operations
6. WHEN notes are modified, THE System SHALL update UI within 0ms (synchronous state update)
7. THE System SHALL maintain background database synchronization without blocking UI

### Requirement 6: Maintain Security Features

**User Story:** As a user, I want my locked notes to remain secure, so that my private information is protected.

#### Acceptance Criteria

1. THE System SHALL preserve vault session management with 5-minute timeout
2. THE System SHALL maintain encryption for locked note content (except checklists)
3. THE System SHALL keep biometric authentication for vault access
4. THE System SHALL preserve the separate _lockedNotes list for secure session management
5. THE System SHALL maintain the clearLockedSession method to wipe decrypted data from RAM
6. WHEN a vault session expires, THE System SHALL automatically lock the vault
7. THE System SHALL prevent double encryption when editing locked notes

### Requirement 7: Improve Code Documentation

**User Story:** As a developer, I want clear documentation for the refactored code, so that I can understand and maintain it easily.

#### Acceptance Criteria

1. THE System SHALL add comprehensive doc comments to all new service classes
2. THE System SHALL document the purpose and responsibility of each service
3. THE System SHALL add inline comments explaining complex logic (encryption, batch operations)
4. THE System SHALL create a README.md file explaining the new architecture
5. THE System SHALL document the relationship between NotesProvider and the new services
6. THE System SHALL add examples of how to use each service
7. THE System SHALL document all public methods with parameter descriptions and return values

### Requirement 8: Maintain Editor Mode Support

**User Story:** As a user, I want all note types (Simple, Professional, Checklist, Reminder) to work correctly, so that I can use all app features.

#### Acceptance Criteria

1. THE System SHALL preserve Simple note mode with plain text editing
2. THE System SHALL maintain Professional/Code mode with syntax highlighting
3. THE System SHALL keep Checklist mode with JSON-based task management
4. THE System SHALL preserve Reminder mode with date/time picker integration
5. WHEN a user switches between note modes, THE System SHALL maintain proper state
6. THE System SHALL preserve language detection for Professional mode
7. THE System SHALL maintain undo/redo functionality for all note modes

### Requirement 9: Preserve Autosave and Manual Save

**User Story:** As a user, I want my notes to save automatically and manually, so that I don't lose my work.

#### Acceptance Criteria

1. THE System SHALL maintain autosave with 500ms debounce timer
2. THE System SHALL preserve manual save functionality with user confirmation
3. THE System SHALL keep smart dirty checking to prevent unnecessary saves
4. THE System SHALL maintain the _isDirty flag for change tracking
5. WHEN a user exits the editor with unsaved changes, THE System SHALL show a save confirmation dialog
6. THE System SHALL preserve version control integration for manual saves
7. THE System SHALL maintain silent saves for autosave operations

### Requirement 10: Maintain Widget and Notification Integration

**User Story:** As a user, I want home screen widgets and notifications to work correctly, so that I can access my notes quickly.

#### Acceptance Criteria

1. THE System SHALL preserve widget updates when pinned notes are modified
2. THE System SHALL maintain notification scheduling for reminder notes
3. THE System SHALL keep notification cancellation when reminders are removed
4. THE System SHALL preserve recurrence rule handling for repeating reminders
5. WHEN a note is trashed or archived, THE System SHALL cancel its reminder notification
6. THE System SHALL maintain exact alarm permission checking for Android
7. THE System SHALL preserve widget reset when pinned notes are deleted
