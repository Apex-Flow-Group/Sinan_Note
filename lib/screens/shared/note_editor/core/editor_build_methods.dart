// Copyright © 2025 Apex Flow Group. All rights reserved.
// Re-exports — use the specific builders directly for new code.

import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/controllers/editor_formatting_controller.dart';
import 'package:apex_note/screens/shared/note_editor/controllers/editor_smart_controller.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_content_builder.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_header_builder.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_toolbar_builder.dart';
import 'package:apex_note/widgets/editor/checklist_undo_redo_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

export 'editor_content_builder.dart';
export 'editor_header_builder.dart';
export 'editor_toolbar_builder.dart';

/// Facade — delegates to the three focused builders.
class EditorBuildMethods {
  static Widget buildContentArea({
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
  }) =>
      EditorContentBuilder.build(
        context: context,
        coordinator: coordinator,
        sidePadding: sidePadding,
        finalTextColor: finalTextColor,
        finalHintColor: finalHintColor,
        mode: mode,
        note: note,
        savedNoteId: savedNoteId,
        onReminderTap: onReminderTap,
        saveCallback: saveCallback,
        onUndoRedoControllerCreated: onUndoRedoControllerCreated,
        onUndoRedoChanged: onUndoRedoChanged,
        onChecklistTitleChanged: onChecklistTitleChanged,
        onScroll: onScroll,
        readOnly: readOnly,
        selectionBarActive: selectionBarActive,
      );

  static Widget buildHeader({
    required BuildContext context,
    required EditorCoordinator coordinator,
    required Color finalTextColor,
    required String currentTitle,
    required Note? note,
    required String? notePassword,
    required VoidCallback onReminderTap,
    required VoidCallback onHistoryTap,
    VoidCallback? onTitleTap,
    VoidCallback? onSaveTap,
    VoidCallback? onBackTap,
    required void Function(List<int>) onCategoryChanged,
    bool originallyLocked = false,
    ValueNotifier<double>? scrollProgress,
    bool isReadOnly = false,
    VoidCallback? onEditTap,
    ValueNotifier<bool>? selectionBarActive,
    QuillController? quillController,
    Future<void> Function()? onPaste,
  }) =>
      EditorHeaderBuilder.build(
        context: context,
        coordinator: coordinator,
        finalTextColor: finalTextColor,
        currentTitle: currentTitle,
        note: note,
        notePassword: notePassword,
        onReminderTap: onReminderTap,
        onHistoryTap: onHistoryTap,
        onTitleTap: onTitleTap,
        onSaveTap: onSaveTap,
        onBackTap: onBackTap,
        onCategoryChanged: onCategoryChanged,
        originallyLocked: originallyLocked,
        scrollProgress: scrollProgress,
        isReadOnly: isReadOnly,
        onEditTap: onEditTap,
        selectionBarActive: selectionBarActive,
        quillController: quillController,
        onPaste: onPaste,
      );

  static Widget buildToolbar({
    required BuildContext context,
    required EditorCoordinator coordinator,
    required Color finalTextColor,
    required NoteMode mode,
    required Note? note,
    required int? savedNoteId,
    required EditorSmartController smartController,
    required EditorFormattingController formattingController,
    required VoidCallback onReminderTap,
    required VoidCallback onColorPaletteTap,
    required VoidCallback onSmartSaveDialog,
    required Future<void> Function() saveNote,
    ValueNotifier<bool>? selectionBarActive,
    Function(String)? onInsertSymbol,
    VoidCallback? onRebuild,
    ValueNotifier<double>? scrollProgress,
  }) =>
      EditorToolbarBuilder.build(
        context: context,
        coordinator: coordinator,
        finalTextColor: finalTextColor,
        mode: mode,
        note: note,
        savedNoteId: savedNoteId,
        smartController: smartController,
        formattingController: formattingController,
        onReminderTap: onReminderTap,
        onColorPaletteTap: onColorPaletteTap,
        onSmartSaveDialog: onSmartSaveDialog,
        saveNote: saveNote,
        selectionBarActive: selectionBarActive,
        onInsertSymbol: onInsertSymbol,
        onRebuild: onRebuild,
        scrollProgress: scrollProgress,
      );
}
