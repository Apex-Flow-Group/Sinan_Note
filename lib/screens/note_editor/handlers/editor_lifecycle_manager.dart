// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

import '../../../models/note.dart';
import '../../../models/note_mode.dart';
import '../../../controllers/editor/editor_state_manager.dart';
import '../controllers/editor_smart_controller.dart';
import '../../../widgets/editor/checklist_editor.dart';

/// Manages editor lifecycle events and content changes
class EditorLifecycleManager {
  /// Handle content change with autosave
  static void onContentChanged({
    required BuildContext context,
    required EditorStateManager stateManager,
    required NoteMode mode,
    required TextEditingController contentController,
    required CodeController codeController,
    required EditorSmartController smartController,
    required Timer? autosaveTimer,
    required Timer? languageDetectionTimer,
    required String? detectedLanguage,
    required bool isLanguageManuallySelected,
    required Note? note,
    required Function(Timer?) setAutosaveTimer,
    required Function(Timer?) setLanguageDetectionTimer,
    required Function(String?) setDetectedLanguage,
    required Future<void> Function() saveCallback,
    required VoidCallback cleanupMemory,
    required VoidCallback analyzeMathAndDates,
  }) {
    stateManager.markDirty();

    final currentText = mode == NoteMode.code
        ? codeController.text
        : contentController.text;
    final newHasContent = currentText.trim().isNotEmpty;
    
    if (stateManager.hasContent != newHasContent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        stateManager.hasContent = newHasContent;
      });
    }

    // Autosave timer
    autosaveTimer?.cancel();
    final newAutosaveTimer = Timer(const Duration(milliseconds: 500), () async {
      if (contentController.text.isNotEmpty) {
        await saveCallback();
        cleanupMemory();
      }
    });
    setAutosaveTimer(newAutosaveTimer);

    // Language detection for code mode
    if (mode == NoteMode.code && !isLanguageManuallySelected) {
      languageDetectionTimer?.cancel();
      final newDetectionTimer = Timer(const Duration(milliseconds: 500), () {
        final text = codeController.text;
        final detectedLang = smartController.detectLanguage(text);

        if (detectedLang != null && detectedLang != detectedLanguage) {
          setDetectedLanguage(detectedLang);
          
          // Show notification only for new notes
          if (context.mounted && note?.id == null) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n.detected}: $detectedLang'),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                width: 200,
              ),
            );
          }
        }
      });
      setLanguageDetectionTimer(newDetectionTimer);
    }

    // Math and date analysis for simple mode
    if (mode == NoteMode.simple) {
      analyzeMathAndDates();
    }
  }

  /// Update undo/redo state for text/code editors
  static void updateUndoRedoState({
    required EditorStateManager stateManager,
    required NoteMode mode,
    required UndoHistoryController undoController,
    required UndoHistoryController codeUndoController,
  }) {
    if (mode == NoteMode.checklist) {
      return; // Handled by updateChecklistUndoRedo
    }
    
    final controller = mode == NoteMode.code ? codeUndoController : undoController;
    stateManager.canUndo = controller.value.canUndo;
    stateManager.canRedo = controller.value.canRedo;
  }

  /// Update undo/redo state for checklist editor
  static void updateChecklistUndoRedo({
    required EditorStateManager stateManager,
    required ChecklistUndoRedoController? checklistUndoRedo,
  }) {
    if (checklistUndoRedo != null) {
      stateManager.canUndo = checklistUndoRedo.canUndo;
      stateManager.canRedo = checklistUndoRedo.canRedo;
    }
  }

  /// Analyze math expressions and dates in content
  static void analyzeMathAndDates({
    required BuildContext context,
    required TextEditingController contentController,
    required EditorSmartController smartController,
  }) {
    final result = smartController.analyzeMathAndDates(contentController);
    if (result == null || !context.mounted) return;

    if (result['type'] == 'math') {
      final resultStr = result['result'].toString();
      final newText = contentController.text.replaceFirst(
        result['line'],
        '${result['line'].trim()} $resultStr',
      );
      contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: contentController.selection.baseOffset + resultStr.length + 1,
        ),
      );
    } else if (result['type'] == 'date') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Cleanup memory (placeholder for future optimizations)
  static void cleanupMemory() {
    // Memory cleanup handled by Flutter internally
    // This method exists for future manual cleanup if needed
  }
}
