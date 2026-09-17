// Copyright © 2025 Apex Flow Group. All rights reserved.

/// Manager for centralized editor state management
///
/// This class consolidates all editor state into a single, manageable object,
/// making it easier to track changes, implement dirty checking, and maintain
/// consistent state across the editor.
///
/// **Responsibilities:**
/// - Manage content state (content, title, color)
/// - Manage UI state (authentication, saving, dirty flag)
/// - Manage undo/redo state
/// - Manage reminder state
/// - Track original state for dirty checking
/// - Provide hasChanges() method for smart dirty checking
///
/// **Benefits:**
/// - Single source of truth for editor state
/// - Easy to implement dirty checking
/// - Clear state management
/// - Prevents scattered state variables
class EditorStateManager {
  // ==================== CONTENT STATE ====================

  /// Current note content
  String content = '';

  /// Custom title (if user sets a specific title)
  String? customTitle;

  /// Checklist title (for checklist notes)
  String? checklistTitle;

  /// Color index for note background
  int colorIndex = 0;

  // ==================== UI STATE ====================

  /// Whether user is authenticated (for locked notes)
  bool isAuthenticated = false;

  /// Whether note is currently being saved
  bool isSaving = false;

  /// Whether note is loading (prevents autosave during initial load)
  bool isLoading = true;

  /// Whether note has unsaved changes
  bool isDirty = false;

  /// Whether note has any content
  bool hasContent = false;

  // ==================== UNDO/REDO STATE ====================

  /// Whether undo operation is available
  bool canUndo = false;

  /// Whether redo operation is available
  bool canRedo = false;

  // ==================== REMINDER STATE ====================

  /// Scheduled reminder date/time
  DateTime? reminderDateTime;

  /// Recurrence rule for repeating reminders (daily, weekly, monthly)
  String? recurrenceRule;

  /// التصنيفات المرتبطة بالملاحظة
  List<int> categoryIds = [];
  bool isHiddenFromHome = false;

  // ==================== ORIGINAL STATE SNAPSHOT ====================
  // Used for dirty checking to detect changes

  /// Original content when note was loaded
  String originalContent = '';

  /// Original title when note was loaded
  String originalTitle = '';

  /// Original color index when note was loaded
  int originalColorIndex = 0;

  /// Original reminder date/time when note was loaded
  DateTime? originalReminderDateTime;

  /// Original recurrence rule when note was loaded
  String? originalRecurrenceRule;

  // ==================== METHODS ====================

  /// Check if note has unsaved changes
  ///
  /// Compares current state with original snapshot to detect changes.
  /// This enables smart dirty checking to prevent unnecessary saves.
  ///
  /// **Comparison:**
  /// - isDirty flag (set when content changes)
  /// - Title vs originalTitle
  /// - Color vs originalColorIndex
  /// - Reminder vs originalReminderDateTime
  /// - Recurrence vs originalRecurrenceRule
  ///
  /// **Returns:** true if any field has changed
  bool hasChanges() {
    return isDirty ||
        (customTitle ?? checklistTitle ?? '') != originalTitle ||
        colorIndex != originalColorIndex ||
        reminderDateTime != originalReminderDateTime ||
        recurrenceRule != originalRecurrenceRule;
  }

  /// Update original snapshot after save
  ///
  /// Call this method after successfully saving the note to update
  /// the baseline for dirty checking.
  ///
  /// **Use Cases:**
  /// - After manual save
  /// - After autosave
  /// - After loading note from database
  void updateSnapshot() {
    originalContent = content;
    originalTitle = customTitle ?? checklistTitle ?? '';
    originalColorIndex = colorIndex;
    originalReminderDateTime = reminderDateTime;
    originalRecurrenceRule = recurrenceRule;
    isDirty = false;
  }

  /// Clear all state
  ///
  /// Resets all fields to their default values.
  ///
  /// **Use Cases:**
  /// - Creating a new note
  /// - Closing editor
  void clear() {
    content = '';
    customTitle = null;
    checklistTitle = null;
    colorIndex = 0;
    isAuthenticated = false;
    isSaving = false;
    isDirty = false;
    hasContent = false;
    canUndo = false;
    canRedo = false;
    reminderDateTime = null;
    recurrenceRule = null;
    originalContent = '';
    originalTitle = '';
    originalColorIndex = 0;
    originalReminderDateTime = null;
    originalRecurrenceRule = null;
  }

  /// Load state from a note
  ///
  /// Initializes the editor state from an existing note.
  ///
  /// **Parameters:**
  /// - `noteContent`: Note content
  /// - `noteTitle`: Note title (for regular notes) or checklist title
  /// - `noteColorIndex`: Note color index
  /// - `noteReminderDateTime`: Note reminder date/time
  /// - `noteRecurrenceRule`: Note recurrence rule
  /// - `isChecklist`: Whether this is a checklist note
  void loadFromNote({
    required String noteContent,
    String? noteTitle,
    int? noteColorIndex,
    DateTime? noteReminderDateTime,
    String? noteRecurrenceRule,
    List<int> noteCategoryIds = const [],
    bool noteIsHiddenFromHome = false,
    bool isChecklist = false,
  }) {
    content = noteContent;
    categoryIds = List.from(noteCategoryIds);
    isHiddenFromHome = noteIsHiddenFromHome;

    // For checklist notes, store title in checklistTitle
    if (isChecklist) {
      checklistTitle = noteTitle;
      customTitle = null;
    } else {
      customTitle = noteTitle;
      checklistTitle = null;
    }

    colorIndex = noteColorIndex ?? 0;
    reminderDateTime = noteReminderDateTime;
    recurrenceRule = noteRecurrenceRule;

    // Update snapshot to match loaded state
    updateSnapshot();

    // Update flags
    hasContent = content.isNotEmpty;
    isDirty = false;
  }

  /// Mark state as dirty
  ///
  /// Call this when content changes to indicate unsaved changes.
  void markDirty() {
    isDirty = true;
  }

  /// Mark state as clean
  ///
  /// Call this after saving to indicate no unsaved changes.
  void markClean() {
    isDirty = false;
  }

  /// Update content and mark as dirty
  ///
  /// Convenience method to update content and set dirty flag.
  ///
  /// **Parameters:**
  /// - `newContent`: New content value
  void updateContent(String newContent) {
    content = newContent;
    hasContent = newContent.isNotEmpty;
    if (newContent != originalContent) {
      markDirty();
    }
  }

  /// Update title and mark as dirty
  ///
  /// Convenience method to update title and set dirty flag.
  ///
  /// **Parameters:**
  /// - `newTitle`: New title value
  void updateTitle(String? newTitle) {
    customTitle = newTitle;
    if (newTitle != originalTitle) {
      markDirty();
    }
  }

  @override
  String toString() {
    return 'EditorStateManager('
        'content: ${content.length} chars, '
        'title: $customTitle, '
        'color: $colorIndex, '
        'isDirty: $isDirty, '
        'hasChanges: ${hasChanges()}'
        ')';
  }
}
