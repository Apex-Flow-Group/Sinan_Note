// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/services/note_services/note_side_effect_service.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';

class NoteBatchOperationsService {
  final SqliteDatabaseService _dbService;
  final NoteStateService _stateService;
  final NoteSideEffectService _sideEffectService;

  NoteBatchOperationsService(
      this._dbService, this._stateService, this._sideEffectService);

  Future<void> batchTrashNotes(List<int> ids) async {
    for (var id in ids) {
      final note = _stateService.getNoteById(id);
      if (note == null) continue;

      if (note.isLocked) {
        // الملاحظات المقفلة تُحذف نهائياً بدل النقل للمهملات
        _stateService.removeNote(id);
        await _dbService.deleteNote(id);
      } else {
        _stateService.batchUpdateNotes(
            [id],
            (n) => n.copyWith(
                  isTrashed: true,
                  isPinned: false,
                  updatedAt: DateTime.now(),
                ));
        await _dbService.trashNote(id);
        await _sideEffectService.cancelReminderSideEffect(id);
      }
    }
    await _sideEffectService.updateWidgetSideEffect();
  }

  Future<void> batchRestoreNotes(List<int> ids) async {
    _stateService.batchUpdateNotes(
        ids,
        (note) => note.copyWith(
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
    _stateService.batchUpdateNotes(
        ids,
        (note) => note.copyWith(
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
    _stateService.batchUpdateNotes(
        ids,
        (note) => note.copyWith(
              isArchived: false,
              updatedAt: DateTime.now(),
            ));
    for (var id in ids) {
      await _dbService.unarchiveNote(id);
    }
    await _sideEffectService.updateWidgetSideEffect();
  }
}
