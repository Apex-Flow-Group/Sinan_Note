// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/quill_migration.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:apex_note/screens/shared/note_editor/widgets/checklist_editor_widget.dart';
import 'package:apex_note/screens/shared/note_editor/widgets/code_editor_widget.dart';
import 'package:apex_note/widgets/editor/checklist_undo_redo_controller.dart';
import 'package:apex_note/widgets/editor/quill_editor_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

class EditorContentBuilder {
  static Widget build({
    required BuildContext context,
    required EditorCoordinator coordinator,
    required double sidePadding,
    required Color finalTextColor,
    required Color finalHintColor,
    required NoteMode mode,
    required Note? note,
    required int? savedNoteId,
    required VoidCallback onReminderTap,
    required Future<void> Function({bool isManualSave}) saveCallback,
    required Function(ChecklistUndoRedoController) onUndoRedoControllerCreated,
    required VoidCallback onUndoRedoChanged,
    required Function(String) onChecklistTitleChanged,
    ValueChanged<double>? onScroll,
    bool readOnly = false,
    ValueNotifier<bool>? selectionBarActive,
  }) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const toolbarHeight = 60.0;
    const codeToolbarHeight = 110.0;
    final totalBottomSpace =
        (mode == NoteMode.code ? codeToolbarHeight : toolbarHeight) +
            bottomPadding +
            12;

    if (mode == NoteMode.code) {
      coordinator.codeController ??= CodeController(
        text: coordinator.contentController.text,
      );
      return CodeEditorWidget(
        codeController: coordinator.codeController!,
        undoController: coordinator.codeUndoController,
        focusNode: coordinator.codeFieldFocusNode,
        detectedLanguage: coordinator.detectedLanguage,
        backgroundColor: coordinator.getBackgroundColor(context),
        totalBottomSpace: totalBottomSpace,
      );
    } else if (mode == NoteMode.checklist) {
      return ChecklistEditorWidget(
        contentController: coordinator.contentController,
        backgroundColor: coordinator.getBackgroundColor(context),
        totalBottomSpace: totalBottomSpace,
        readOnly: readOnly,
        noteTitle: coordinator.stateManager.customTitle ?? note?.title,
        onUndoRedoControllerCreated: onUndoRedoControllerCreated,
        onUndoRedoChanged: onUndoRedoChanged,
        onChecklistTitleChanged: onChecklistTitleChanged,
        onContentChanged: () {
          coordinator.stateManager.markDirty();
        },
      );
    } else {
      coordinator.quillController ??= QuillMigration.controllerFromContent(
          coordinator.contentController.text);
      return QuillEditorWidget(
        key: ValueKey(coordinator.quillControllerVersion),
        quillController: coordinator.quillController!,
        focusNode: coordinator.textFieldFocusNode,
        textColor: finalTextColor,
        hintColor: finalHintColor,
        noteColor: coordinator.getBackgroundColor(context),
        fontSize: coordinator.fontSize,
        sidePadding: sidePadding,
        totalBottomSpace: totalBottomSpace,
        autoFocus: note == null && !readOnly,
        readOnly: readOnly,
        markdownPaste: mode == NoteMode.rich,
        onScroll: onScroll,
        selectionBarActive: selectionBarActive ?? ValueNotifier(false),
      );
    }
  }
}
