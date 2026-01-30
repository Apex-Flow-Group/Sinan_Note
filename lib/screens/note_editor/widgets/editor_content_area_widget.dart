// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

import '../../../models/note_mode.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/apex_snackbar.dart';
import '../../../controllers/editor/text_direction_controller.dart';
import '../../../controllers/editor/editor_state_manager.dart';
import '../widgets/text_editor_widget.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/checklist_editor_widget.dart';
import '../../../widgets/editor/checklist_editor.dart';

/// Extracted content area widget for note editor
class EditorContentAreaWidget extends StatelessWidget {
  final NoteMode mode;
  final TextEditingController contentController;
  final CodeController codeController;
  final UndoHistoryController undoController;
  final UndoHistoryController codeUndoController;
  final FocusNode textFieldFocusNode;
  final FocusNode codeFieldFocusNode;
  final TextDirectionController textDirectionController;
  final EditorStateManager stateManager;
  final Color backgroundColor;
  final Color textColor;
  final Color hintColor;
  final double fontSize;
  final double sidePadding;
  final String? detectedLanguage;
  final int? savedNoteId;
  final int? noteId;
  final bool autoFocus;
  final VoidCallback onReminderTap;
  final Future<void> Function({bool isManualSave}) saveCallback;
  final Function(ChecklistUndoRedoController) onUndoRedoControllerCreated;
  final VoidCallback onUndoRedoChanged;
  final Function(String) onChecklistTitleChanged;
  final VoidCallback onContentChanged;

  const EditorContentAreaWidget({
    super.key,
    required this.mode,
    required this.contentController,
    required this.codeController,
    required this.undoController,
    required this.codeUndoController,
    required this.textFieldFocusNode,
    required this.codeFieldFocusNode,
    required this.textDirectionController,
    required this.stateManager,
    required this.backgroundColor,
    required this.textColor,
    required this.hintColor,
    required this.fontSize,
    required this.sidePadding,
    required this.detectedLanguage,
    required this.savedNoteId,
    required this.noteId,
    required this.autoFocus,
    required this.onReminderTap,
    required this.saveCallback,
    required this.onUndoRedoControllerCreated,
    required this.onUndoRedoChanged,
    required this.onChecklistTitleChanged,
    required this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const toolbarHeight = 60.0;
    final totalBottomSpace = toolbarHeight + bottomPadding + 16;
    final l10n = AppLocalizations.of(context)!;

    if (mode == NoteMode.code) {
      return CodeEditorWidget(
        codeController: codeController,
        undoController: codeUndoController,
        focusNode: codeFieldFocusNode,
        detectedLanguage: detectedLanguage,
        backgroundColor: backgroundColor,
        totalBottomSpace: totalBottomSpace,
      );
    } else if (mode == NoteMode.checklist) {
      return ChecklistEditorWidget(
        contentController: contentController,
        backgroundColor: backgroundColor,
        totalBottomSpace: totalBottomSpace,
        onUndoRedoControllerCreated: onUndoRedoControllerCreated,
        onUndoRedoChanged: onUndoRedoChanged,
        onChecklistTitleChanged: onChecklistTitleChanged,
        onContentChanged: onContentChanged,
      );
    } else {
      return TextEditorWidget(
        contentController: contentController,
        undoController: undoController,
        focusNode: textFieldFocusNode,
        textDirectionController: textDirectionController,
        stateManager: stateManager,
        backgroundColor: backgroundColor,
        textColor: textColor,
        hintColor: hintColor,
        fontSize: fontSize,
        sidePadding: sidePadding,
        totalBottomSpace: totalBottomSpace,
        reminderDateTime: stateManager.reminderDateTime,
        onReminderTap: onReminderTap,
        onReminderRemove: () async {
          debugPrint('🔴 CLOSE BUTTON PRESSED!');
          HapticFeedback.lightImpact();
          stateManager.reminderDateTime = null;
          stateManager.recurrenceRule = null;
          stateManager.markDirty();
          
          debugPrint('🔴 Reminder removed: _reminderDateTime=${stateManager.reminderDateTime}');
          if (savedNoteId != null || noteId != null) {
            await NotificationService().cancelNotification(savedNoteId ?? noteId!);
          }
          await saveCallback(isManualSave: true);
          if (context.mounted) {
            ApexSnackBar.show(
              context,
              l10n.reminderRemoved,
              type: SnackBarType.info,
            );
          }
        },
        onReminderEdit: () {
          debugPrint('✏️ EDIT BUTTON PRESSED!');
          onReminderTap();
        },
        autoFocus: autoFocus,
      );
    }
  }
}
