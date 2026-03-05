// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/services/note_services/note_side_effect_service.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';
import 'package:apex_note/services/storage/isar_database_service.dart';

class NoteBatchOperationsService {
  final IsarDatabaseService _dbService;
  final NoteStateService _stateService;
  final NoteSideEffectService _sideEffectService;
  
  NoteBatchOperationsService(this._dbService, this._stateService, this._sideEffectService);
  
  Future<void> batchTrashNotes(List<int> ids) async {
    AppLogger.debug('🗑️ trashNotes: ${ids.length} IDs');
    _stateService.batchUpdateNotes(ids, (note) => note.copyWith(
      isTrashed: true,
      isPinned: false,
      updatedAt: DateTime.now(),
    ));
    for (var id in ids) {
      await _dbService.trashNote(id);
      await _sideEffectService.cancelReminderSideEffect(id);
    }
    await _sideEffectService.updateWidgetSideEffect();
  }
  
  Future<void> batchRestoreNotes(List<int> ids) async {
    _stateService.batchUpdateNotes(ids, (note) => note.copyWith(
      isArchived: false,
      isTrashed: false,
      updatedAt: DateTime.now(),
    ));
    _stateService.sortNotes();
    for (var id in ids) {
      await _dbService.restoreNote(id);
    }
    await _sideEffectService.updateWidgetSideEffect();
  }
  
  Future<void> batchArchiveNotes(List<int> ids) async {
    _stateService.batchUpdateNotes(ids, (note) => note.copyWith(
      isArchived: true,
      isPinned: false,
      updatedAt: DateTime.now(),
    ));
    for (var id in ids) {
      await _dbService.archiveNote(id);
      await _sideEffectService.cancelReminderSideEffect(id);
    }
    await _sideEffectService.updateWidgetSideEffect();
  }
  
  Future<void> batchUnarchiveNotes(List<int> ids) async {
    _stateService.batchUpdateNotes(ids, (note) => note.copyWith(
      isArchived: false,
      updatedAt: DateTime.now(),
    ));
    for (var id in ids) {
      await _dbService.unarchiveNote(id);
    }
    await _sideEffectService.updateWidgetSideEffect();
  }
}
