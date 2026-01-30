// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import '../../models/note.dart';

/// Service responsible for managing in-memory note state and providing filtered views.
/// 
/// This service follows the Single Responsibility Principle by focusing solely on
/// state management, filtering, and sorting operations. It does not handle database
/// operations, encryption, or side effects.
/// 
/// **Responsibilities:**
/// - Maintain the single source of truth for all notes (_allNotes)
/// - Maintain separate session for locked notes (_lockedNotes)
/// - Provide filtered views (active, archived, trashed notes)
/// - Handle in-memory search operations
/// - Manage debounced sorting for performance optimization
class NoteStateService {
  // SINGLE SOURCE OF TRUTH: Central list for all notes
  List<Note> _allNotes = [];
  
  // SECURITY: Separate session for locked notes (vault)
  List<Note> _lockedNotes = [];
  
  // Track if initial data has been loaded
  bool _isInitialDataLoaded = false;
  
  // Debounce timer for sorting optimization
  Timer? _sortDebounce;
  
  /// Check if initial data has been loaded from database
  bool get isInitialDataLoaded => _isInitialDataLoaded;
  
  /// Get all active notes (not locked, not trashed, not archived)
  /// 
  /// This getter performs in-memory filtering for optimal performance.
  /// No database queries are executed.
  List<Note> get activeNotes {
    return _allNotes
        .where((n) => !n.isLocked && !n.isTrashed && !n.isArchived)
        .toList();
  }
  
  /// Get all archived notes (archived, not trashed, not locked)
  List<Note> get archivedNotes {
    return _allNotes
        .where((n) => n.isArchived && !n.isTrashed && !n.isLocked)
        .toList();
  }
  
  /// Get all trashed notes (trashed, not locked)
  List<Note> get trashedNotes {
    return _allNotes.where((n) => n.isTrashed && !n.isLocked).toList();
  }
  
  /// Get all notes with active reminders (future reminders, not locked, not trashed)
  List<Note> get reminderNotes {
    return _allNotes
        .where((n) =>
            n.reminderDateTime != null &&
            !n.isLocked &&
            !n.isTrashed &&
            n.reminderDateTime!.isAfter(DateTime.now()))
        .toList();
  }
  
  /// Get locked notes from secure session
  /// 
  /// SECURITY: This list is separate from _allNotes and only populated
  /// when the vault is unlocked. It's cleared when the vault is locked.
  List<Note> get lockedNotes => _lockedNotes;
  
  /// Update the entire notes list (typically after database load)
  /// 
  /// This method replaces the entire _allNotes list and marks data as loaded.
  /// It also triggers an immediate sort.
  void updateAllNotes(List<Note> notes) {
    _allNotes = notes;
    _isInitialDataLoaded = true;
    sortNotes(immediate: true);
  }
  
  /// Update a single note in the list
  /// 
  /// This method finds the note by ID and replaces it with the updated version.
  /// It creates a new list reference to trigger Selector updates in the UI.
  void updateNote(Note note) {
    final index = _allNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _allNotes[index] = note;
      _allNotes = List.from(_allNotes); // New reference for Selector
    } else {
      // Note not found, add it
      _allNotes.add(note);
      _allNotes = List.from(_allNotes);
    }
  }
  
  /// Add a note to the list
  /// 
  /// Adds the note at the beginning of the list and triggers sorting.
  void addNote(Note note) {
    if (note.isLocked) {
      _lockedNotes.insert(0, note);
    } else {
      _allNotes.insert(0, note);
      sortNotes(immediate: true);
      _allNotes = List.from(_allNotes);
    }
  }
  
  /// Remove a note from the list by ID
  /// 
  /// Removes the note from both _allNotes and _lockedNotes.
  void removeNote(int id) {
    _allNotes.removeWhere((n) => n.id == id);
    _lockedNotes.removeWhere((n) => n.id == id);
  }
  
  /// Update locked notes list (for vault session)
  void updateLockedNotes(List<Note> notes) {
    _lockedNotes = notes;
  }
  
  /// Clear locked notes from memory (for vault lock)
  /// 
  /// SECURITY: This method wipes decrypted locked notes from RAM
  /// when the vault is locked or the session expires.
  void clearLockedNotes() {
    _lockedNotes = [];
  }
  
  /// Search notes by query string
  /// 
  /// Performs case-insensitive search on title and content.
  /// Only searches unlocked notes.
  /// 
  /// **Performance:** O(n) in-memory search, no database queries.
  List<Note> searchNotes(String query) {
    if (query.trim().isEmpty) {
      return activeNotes;
    }
    
    final lowerQuery = query.toLowerCase();
    return _allNotes
        .where((n) =>
            !n.isLocked &&
            !n.isTrashed &&
            (n.title.toLowerCase().contains(lowerQuery) ||
                n.content.toLowerCase().contains(lowerQuery)))
        .toList();
  }
  
  /// Sort notes with optional debouncing
  /// 
  /// **Sorting Rules:**
  /// 1. Pinned notes first
  /// 2. Then by updatedAt (newest first)
  /// 
  /// **Performance Optimization:**
  /// - By default, sorting is debounced by 50ms to prevent multiple sorts
  ///   during rapid changes (e.g., batch operations)
  /// - Use `immediate: true` for critical operations that need instant sorting
  void sortNotes({bool immediate = false}) {
    if (immediate) {
      _performSort();
      return;
    }
    
    // Debounce: Only sort once after multiple rapid changes
    _sortDebounce?.cancel();
    _sortDebounce = Timer(const Duration(milliseconds: 50), _performSort);
  }
  
  /// Perform the actual sorting operation
  void _performSort() {
    _allNotes.sort((a, b) {
      // 1. Pinned notes first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // 2. Newest first (by updatedAt)
      return b.updatedAt.compareTo(a.updatedAt);
    });
  }
  
  /// Batch update notes using functional immutable pattern
  /// 
  /// This method applies a transformation function to all notes matching
  /// the given IDs, creating a new list with updated notes.
  /// 
  /// **Example:**
  /// ```dart
  /// batchUpdateNotes([1, 2, 3], (note) => note.copyWith(isTrashed: true));
  /// ```
  void batchUpdateNotes(List<int> ids, Note Function(Note) transform) {
    _allNotes = _allNotes.map((n) => 
        ids.contains(n.id) ? transform(n) : n
    ).toList();
  }
  
  /// Dispose resources
  void dispose() {
    _sortDebounce?.cancel();
  }
}
