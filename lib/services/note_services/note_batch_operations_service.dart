// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import '../database_service.dart';
import 'note_state_service.dart';
import 'note_side_effect_service.dart';

/// Service responsible for batch operations on multiple notes.
/// 
/// This service handles bulk operations (trash, restore, archive, unarchive)
/// with optimistic UI updates for better user experience.
/// 
/// **Responsibilities:**
/// - Trash multiple notes at once
/// - Restore multiple notes from trash
/// - Archive multiple notes
/// - Unarchive multiple notes
/// 
/// **Performance Strategy:**
/// - **Optimistic UI:** Update state immediately using functional immutable pattern
/// - **Background Sync:** Database operations run asynchronously without blocking UI
/// - **Side Effects:** Coordinate with NoteSideEffectService for reminders and widgets
/// 
/// **Functional Immutable Pattern:**
/// Instead of mutating the list in place, we create a new list with updated notes.
/// This ensures proper change detection in Flutter's Selector widgets.
class NoteBatchOperationsService {
  final DatabaseService _dbService;
  final NoteStateService _stateService;
  final NoteSideEffectService _sideEffectService;
  
  NoteBatchOperationsService(
    this._dbService,
    this._stateService,
    this._sideEffectService,
  );
  
  /// Trash multiple notes
  /// 
  /// **Flow:**
  /// 1. Update state immediately (optimistic UI) using functional immutable pattern
  /// 2. Sync database in background (asynchronous, non-blocking)
  /// 3. Cancel reminders for trashed notes
  /// 4. Update widgets if needed
  /// 
  /// **Functional Immutable Update:**
  /// ```dart
  /// _allNotes = _allNotes.map((n) => 
  ///     ids.contains(n.id) ? n.copyWith(isTrashed: true) : n
  /// ).toList();
  /// ```
  /// 
  /// **Parameters:**
  /// - `ids`: List of note IDs to trash
  Future<void> trashNotes(List<int> ids) async {
    debugPrint('🗑️ trashNotes called with ${ids.length} IDs: $ids');
    
    // 1. Functional immutable update (Golden Solution)
    _stateService.batchUpdateNotes(ids, (note) => note.copyWith(
      isTrashed: true,
      isPinned: false,
      updatedAt: DateTime.now(),
    ));
    
    debugPrint('✅ Memory updated: ${ids.length} notes trashed');
    
    // 2. Silent background DB sync (NO await, NO reload)
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.trashNote(id);
        await _sideEffectService.cancelReminderSideEffect(id);
      }
      await _sideEffectService.updateWidgetSideEffect();
    });
  }
  
  /// Restore multiple notes from trash
  /// 
  /// **Flow:**
  /// 1. Update state immediately (optimistic UI)
  /// 2. Trigger sort (restored notes should appear in correct position)
  /// 3. Sync database in background
  /// 4. Update widgets if needed
  /// 
  /// **Parameters:**
  /// - `ids`: List of note IDs to restore
  Future<void> restoreNotes(List<int> ids) async {
    // 1. Functional immutable update
    _stateService.batchUpdateNotes(ids, (note) => note.copyWith(
      isArchived: false,
      isTrashed: false,
      updatedAt: DateTime.now(),
    ));
    
    // 2. Re-sort after restore
    _stateService.sortNotes();
    
    // 3. Silent background DB sync
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.restoreNote(id);
      }
      await _sideEffectService.updateWidgetSideEffect();
    });
  }
  
  /// Archive multiple notes
  /// 
  /// **Flow:**
  /// 1. Update state immediately (optimistic UI)
  /// 2. Sync database in background
  /// 3. Cancel reminders for archived notes
  /// 4. Update widgets if needed
  /// 
  /// **Parameters:**
  /// - `ids`: List of note IDs to archive
  Future<void> archiveNotes(List<int> ids) async {
    // 1. Functional immutable update
    _stateService.batchUpdateNotes(ids, (note) => note.copyWith(
      isArchived: true,
      isPinned: false,
      updatedAt: DateTime.now(),
    ));
    
    // 2. Silent background DB sync
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.archiveNote(id);
        await _sideEffectService.cancelReminderSideEffect(id);
      }
      await _sideEffectService.updateWidgetSideEffect();
    });
  }
  
  /// Unarchive multiple notes
  /// 
  /// **Flow:**
  /// 1. Update state immediately (optimistic UI)
  /// 2. Sync database in background
  /// 
  /// **Parameters:**
  /// - `ids`: List of note IDs to unarchive
  Future<void> unarchiveNotes(List<int> ids) async {
    // 1. Functional immutable update
    _stateService.batchUpdateNotes(ids, (note) => note.copyWith(
      isArchived: false,
      updatedAt: DateTime.now(),
    ));
    
    // 2. Silent background DB sync
    Future.microtask(() async {
      for (var id in ids) {
        await _dbService.unarchiveNote(id);
      }
    });
  }
}
