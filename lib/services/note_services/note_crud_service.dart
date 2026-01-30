// Copyright © 2025 Apex Flow Group. All rights reserved.

import '../../models/note.dart';
import '../database_service.dart';
import 'note_state_service.dart';

/// Service responsible for CRUD (Create, Read, Update, Delete) operations on notes.
/// 
/// This service coordinates between the database layer and the state management layer,
/// implementing optimistic UI updates for better user experience.
/// 
/// **Responsibilities:**
/// - Add new notes to database and state
/// - Update existing notes with fresh data fetch
/// - Delete notes from database and state
/// - Retrieve notes by ID
/// - Refresh all notes from database
/// 
/// **Performance Strategy:**
/// - Optimistic UI: Update state immediately, sync database in background
/// - Fresh data fetch: Always fetch latest data after updates to prevent stale state
/// - No redundant reloads: Update specific notes instead of reloading entire list
class NoteCRUDService {
  final DatabaseService _dbService;
  final NoteStateService _stateService;
  
  NoteCRUDService(this._dbService, this._stateService);
  
  /// Add a new note
  /// 
  /// **Flow:**
  /// 1. Add to memory immediately (optimistic UI)
  /// 2. Insert into database in background
  /// 3. Update note ID in memory (no full reload)
  /// 
  /// **Returns:** The database-assigned note ID
  Future<int> addNote(Note note) async {
    // 1. Add to memory immediately for instant UI update
    _stateService.addNote(note);
    
    // 2. DB insert in background
    final id = await _dbService.insertNote(note);
    
    // 3. Update ID only (no reload needed)
    final updatedNote = note.copyWith(id: id);
    _stateService.updateNote(updatedNote);
    
    return id;
  }
  
  /// Update an existing note
  /// 
  /// **Flow:**
  /// 1. Update database
  /// 2. Fetch fresh data from database (prevents stale state)
  /// 3. Update memory with fresh data
  /// 4. Trigger sort (important for pin changes)
  /// 
  /// **Parameters:**
  /// - `note`: The note to update
  /// - `silent`: If true, skip notifyListeners (for autosave)
  /// 
  /// **Returns:** Number of rows affected (should be 1)
  Future<int> updateNote(Note note, {bool silent = false}) async {
    // 1. Update database
    final result = await _dbService.updateNote(note);
    
    // 2. Fetch fresh data to prevent stale state
    final freshNote = await _dbService.getNoteById(note.id!);
    
    // 3. Update in-memory state
    if (freshNote != null) {
      _stateService.updateNote(freshNote);
    } else {
      // Fallback: use provided note if fetch fails
      _stateService.updateNote(note);
    }
    
    // 4. Sort immediately (critical for pin changes)
    _stateService.sortNotes(immediate: true);
    
    return result;
  }
  
  /// Delete a note permanently
  /// 
  /// **Flow:**
  /// 1. Delete from database
  /// 2. Remove from memory
  /// 
  /// **Note:** This is a hard delete. For soft delete, use trashNote instead.
  /// 
  /// **Returns:** Number of rows affected (should be 1)
  Future<int> deleteNote(int id) async {
    final result = await _dbService.deleteNote(id);
    _stateService.removeNote(id);
    return result;
  }
  
  /// Get a note by ID
  /// 
  /// **Note:** This method queries the database directly, not the in-memory cache.
  /// Use this when you need the absolute latest data from the database.
  /// 
  /// **Returns:** The note if found, null otherwise
  Future<Note?> getNoteById(int id) async {
    return await _dbService.getNoteById(id);
  }
  
  /// Refresh all notes from database
  /// 
  /// **Flow:**
  /// 1. Load all notes from database
  /// 2. Update state with loaded notes
  /// 3. Trigger immediate sort
  /// 
  /// **Use Cases:**
  /// - Initial app load
  /// - After major data changes (import, sync)
  /// - When state might be out of sync with database
  Future<void> refreshAllNotes() async {
    final notes = await _dbService.getAllNotes();
    _stateService.updateAllNotes(notes);
  }
  
  /// Archive a note
  /// 
  /// **Flow:**
  /// 1. Update database (set isArchived = true)
  /// 2. Update note in memory
  /// 
  /// **Returns:** Number of rows affected (should be 1)
  Future<int> archiveNote(int id) async {
    final result = await _dbService.archiveNote(id);
    
    // Update in memory
    final note = await _dbService.getNoteById(id);
    if (note != null) {
      _stateService.updateNote(note);
    }
    
    return result;
  }
  
  /// Unarchive a note
  /// 
  /// **Flow:**
  /// 1. Update database (set isArchived = false)
  /// 2. Update note in memory
  /// 
  /// **Returns:** Number of rows affected (should be 1)
  Future<int> unarchiveNote(int id) async {
    final result = await _dbService.unarchiveNote(id);
    
    // Update in memory
    final note = await _dbService.getNoteById(id);
    if (note != null) {
      _stateService.updateNote(note);
    }
    
    return result;
  }
  
  /// Trash a note (soft delete)
  /// 
  /// **Flow:**
  /// 1. Check if note is locked (locked notes are hard deleted)
  /// 2. Update database (set isTrashed = true) or delete if locked
  /// 3. Update note in memory or remove if locked
  /// 
  /// **Returns:** Number of rows affected (should be 1)
  Future<int> trashNote(int id) async {
    final note = await _dbService.getNoteById(id);
    if (note == null) return 0;
    
    final result = note.isLocked
        ? await _dbService.deleteNote(id)
        : await _dbService.trashNote(id);
    
    if (note.isLocked) {
      _stateService.removeNote(id);
    } else {
      // Update in memory
      final updatedNote = await _dbService.getNoteById(id);
      if (updatedNote != null) {
        _stateService.updateNote(updatedNote);
      }
    }
    
    return result;
  }
  
  /// Restore a note from trash
  /// 
  /// **Flow:**
  /// 1. Update database (set isTrashed = false, isArchived = false)
  /// 2. Update note in memory
  /// 3. Trigger sort
  /// 
  /// **Returns:** Number of rows affected (should be 1)
  Future<int> restoreNote(int id) async {
    final result = await _dbService.restoreNote(id);
    
    // Update in memory
    final note = await _dbService.getNoteById(id);
    if (note != null) {
      _stateService.updateNote(note);
      _stateService.sortNotes(immediate: true);
    }
    
    return result;
  }
}
