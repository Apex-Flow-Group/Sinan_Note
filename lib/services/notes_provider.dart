// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/note.dart';
import 'database_service.dart';
import 'encryption_service.dart';

// Import new service layer
import 'note_services/note_state_service.dart';
import 'note_services/note_crud_service.dart';
import 'note_services/note_security_service.dart';
import 'note_services/note_side_effect_service.dart';
import 'note_services/note_batch_operations_service.dart';

/// NotesProvider - Facade for note management services
/// 
/// This class maintains backward compatibility by delegating to specialized services.
/// It follows the Facade pattern to provide a unified interface while internally
/// using the Single Responsibility Principle for better maintainability.
/// 
/// **Architecture:**
/// - NoteStateService: State management and filtering
/// - NoteCRUDService: Create, Read, Update, Delete operations
/// - NoteSecurityService: Vault session and encryption
/// - NoteSideEffectService: Reminders, notifications, widgets
/// - NoteBatchOperationsService: Bulk operations
/// 
/// **Backward Compatibility:**
/// All existing public methods are preserved with identical signatures.
/// No breaking changes for existing code using NotesProvider.
class NotesProvider extends ChangeNotifier {
  // Service instances
  late final NoteStateService _stateService;
  late final NoteCRUDService _crudService;
  late final NoteSecurityService _securityService;
  late final NoteSideEffectService _sideEffectService;
  late final NoteBatchOperationsService _batchService;
  
  // Loading lock to prevent redundant calls
  bool _isLoading = false;
  
  /// Constructor: Initialize all services
  NotesProvider({DatabaseService? dbService}) {
    final db = dbService ?? DatabaseService();
    _stateService = NoteStateService();
    _crudService = NoteCRUDService(db, _stateService);
    _securityService = NoteSecurityService();
    _sideEffectService = NoteSideEffectService();
    _batchService = NoteBatchOperationsService(
      db,
      _stateService,
      _sideEffectService,
    );
  }
  
  // ==================== STATE GETTERS ====================
  // Delegate to NoteStateService
  
  bool get isInitialDataLoaded => _stateService.isInitialDataLoaded;
  
  List<Note> get activeNotes => _stateService.activeNotes;
  
  List<Note> get notes => activeNotes; // Backward compatibility
  
  List<Note> get archivedNotes => _stateService.archivedNotes;
  
  List<Note> get trashedNotes => _stateService.trashedNotes;
  
  List<Note> get reminderNotes => _stateService.reminderNotes;
  
  List<Note> get lockedNotes => _stateService.lockedNotes;
  
  // ==================== SECURITY GETTERS ====================
  // Delegate to NoteSecurityService
  
  bool get isVaultUnlocked => _securityService.isVaultUnlocked;
  
  void unlockVault() {
    _securityService.unlockVault();
  }
  
  void lockVault() {
    _securityService.lockVault();
    _securityService.clearLockedSession(_stateService);
    notifyListeners();
  }
  
  // ==================== DATA LOADING ====================
  
  /// Refresh all notes from database
  Future<void> refreshAllNotes() async {
    if (_isLoading) return;
    
    _isLoading = true;
    
    try {
      await _crudService.refreshAllNotes();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load notes (backward compatibility)
  Future<void> loadNotes() async {
    if (_isLoading || _stateService.isInitialDataLoaded) return;
    await refreshAllNotes();
  }
  
  /// Get notes (backward compatibility)
  Future<List<Note>> getNotes() async {
    await refreshAllNotes();
    return activeNotes;
  }
  
  /// Fetch notes (backward compatibility)
  Future<void> fetchNotes() async => await refreshAllNotes();
  Future<void> fetchTrashedNotes() async => await refreshAllNotes();
  Future<void> fetchArchivedNotes() async => await refreshAllNotes();
  Future<void> fetchTrashNotes() async => await refreshAllNotes();
  
  // ==================== SEARCH ====================
  
  /// Search notes by query
  List<Note> searchNotes(String query) {
    return _stateService.searchNotes(query);
  }
  
  // ==================== CRUD OPERATIONS ====================
  // Delegate to NoteCRUDService + NoteSideEffectService
  
  /// Add a new note
  Future<int> addNote(Note note) async {
    // Handle encryption for locked notes (except checklists)
    Note noteToInsert = note;
    if (note.isLocked && note.content.isNotEmpty && !note.isChecklist) {
      final encryptedTitle = note.title.isNotEmpty 
          ? await EncryptionService.encrypt(note.title) 
          : '';
      final encryptedContent = await EncryptionService.encrypt(note.content);
      
      noteToInsert = note.copyWith(
        title: encryptedTitle,
        content: encryptedContent,
      );
    }
    
    // Add note via CRUD service
    final id = await _crudService.addNote(noteToInsert);
    
    // Handle side effects
    await _sideEffectService.handleReminderSideEffect(note.copyWith(id: id));
    
    notifyListeners();
    return id;
  }
  
  /// Insert note (backward compatibility)
  Future<int> insertNote(Note note) async {
    return addNote(note);
  }
  
  /// Update an existing note
  Future<int> updateNote(Note note, {bool silent = false}) async {
    // Handle encryption for locked notes (except checklists)
    Note noteToUpdate = note;
    if (note.isLocked && note.content.isNotEmpty && !note.isChecklist) {
      if (!EncryptionService.isEncrypted(note.content)) {
        final encryptedTitle = note.title.isNotEmpty 
            ? await EncryptionService.encrypt(note.title) 
            : '';
        final encryptedContent = await EncryptionService.encrypt(note.content);
        
        noteToUpdate = note.copyWith(
          title: encryptedTitle,
          content: encryptedContent,
        );
      }
    }
    
    // Update note via CRUD service
    final result = await _crudService.updateNote(noteToUpdate, silent: silent);
    
    // Handle side effects
    await _sideEffectService.handleReminderSideEffect(note);
    await _sideEffectService.checkAndUpdateIfPinned(note);
    
    if (!silent) {
      notifyListeners();
    }
    
    return result;
  }
  
  /// Delete a note permanently
  Future<int> deleteNote(int id) async {
    // Cancel reminder before delete
    await _sideEffectService.cancelReminderSideEffect(id);
    
    // Delete note via CRUD service
    final result = await _crudService.deleteNote(id);
    
    // Reset widget if pinned note was deleted
    await _sideEffectService.checkAndResetIfPinned(id);
    
    notifyListeners();
    return result;
  }
  
  /// Archive a note
  Future<int> archiveNote(int id) async {
    await _sideEffectService.cancelReminderSideEffect(id);
    final result = await _crudService.archiveNote(id);
    notifyListeners();
    return result;
  }
  
  /// Unarchive a note
  Future<int> unarchiveNote(int id) async {
    final result = await _crudService.unarchiveNote(id);
    notifyListeners();
    return result;
  }
  
  /// Trash a note (soft delete)
  Future<int> trashNote(int id) async {
    await _sideEffectService.cancelReminderSideEffect(id);
    final result = await _crudService.trashNote(id);
    notifyListeners();
    return result;
  }
  
  /// Restore a note from trash
  Future<int> restoreNote(int id) async {
    final result = await _crudService.restoreNote(id);
    notifyListeners();
    return result;
  }
  
  /// Add or update note (unified method)
  Future<int> addOrUpdateNote(Note note, {bool silent = false}) async {
    if (note.id != null) {
      await updateNote(note, silent: silent);
      return note.id!;
    } else {
      return await addNote(note);
    }
  }
  
  // ==================== BATCH OPERATIONS ====================
  // Delegate to NoteBatchOperationsService
  
  /// Trash multiple notes
  Future<void> trashNotes(List<int> ids) async {
    await _batchService.trashNotes(ids);
    notifyListeners();
  }
  
  /// Restore multiple notes
  Future<void> restoreNotes(List<int> ids) async {
    await _batchService.restoreNotes(ids);
    notifyListeners();
  }
  
  /// Archive multiple notes
  Future<void> archiveNotes(List<int> ids) async {
    await _batchService.archiveNotes(ids);
    notifyListeners();
  }
  
  /// Unarchive multiple notes
  Future<void> unarchiveNotes(List<int> ids) async {
    await _batchService.unarchiveNotes(ids);
    notifyListeners();
  }
  
  // ==================== SECURITY OPERATIONS ====================
  // Delegate to NoteSecurityService
  
  /// Fetch locked notes (backward compatibility)
  Future<void> fetchLockedNotes() async {
    final notes = await _securityService.fetchAndDecryptLockedNotes(DatabaseService());
    _stateService.updateLockedNotes(notes);
    notifyListeners();
  }
  
  /// Fetch and decrypt locked notes for vault display
  Future<List<Note>> fetchAndDecryptLockedNotes() async {
    return await _securityService.fetchAndDecryptLockedNotes(DatabaseService());
  }
  
  /// Toggle lock status for a note
  Future<void> toggleLockStatus(int id, bool lockStatus) async {
    await _securityService.toggleLockStatus(id, lockStatus, DatabaseService());
    
    // Update in-memory lists
    final note = await _crudService.getNoteById(id);
    if (note != null) {
      if (lockStatus) {
        _stateService.removeNote(id);
        _stateService.updateLockedNotes([...lockedNotes, note]);
      } else {
        _stateService.updateLockedNotes(lockedNotes.where((n) => n.id != id).toList());
        _stateService.addNote(note);
      }
    }
    
    notifyListeners();
  }
  
  /// Clear locked session (wipe decrypted data from RAM)
  void clearLockedSession({bool notify = true}) {
    _securityService.clearLockedSession(_stateService);
    if (notify) {
      notifyListeners();
    }
  }
  
  // ==================== DISPOSE ====================
  
  @override
  void dispose() {
    _stateService.dispose();
    super.dispose();
  }
}
