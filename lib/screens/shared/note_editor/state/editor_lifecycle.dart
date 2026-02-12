// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import '../../../../models/note.dart';
import '../../../../models/note_mode.dart';
import '../../../../services/language_detector.dart';
import '../utils/note_editor_utils.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

class EditorStateLifecycleManager {
  /// Initialize controllers and state
  static Future<Map<String, dynamic>> initialize({
    required Note? note,
    required NoteMode mode,
    required bool skipAuthentication,
    required bool originallyLocked,
    required Function loadStickySettings,
    required Function loadDecryptedContent,
    required Function promptForPassword,
  }) async {
    final initialLockState = originallyLocked || (note?.isLocked ?? false);
    String? detectedLanguage;
    bool isLanguageManuallySelected = false;

    // Restore saved language for code notes
    if (mode == NoteMode.code && note != null && note.noteType.isNotEmpty) {
      String? restoredLanguage = LanguageDetector.getLanguageFromExtension(note.noteType);
      restoredLanguage ??= NoteEditorUtils.mapNoteTypeToLanguage(note.noteType);
      
      if (restoredLanguage != null) {
        detectedLanguage = restoredLanguage;
        isLanguageManuallySelected = true;
      }
    }

    return {
      'initialLockState': initialLockState,
      'detectedLanguage': detectedLanguage,
      'isLanguageManuallySelected': isLanguageManuallySelected,
    };
  }

  /// Handle app lifecycle state changes
  static Future<void> handleLifecycleChange({
    required AppLifecycleState state,
    required Note? note,
    required NoteMode mode,
    required TextEditingController contentController,
    required CodeController? codeController,
    required bool isDirty,
    required bool mounted,
    required BuildContext? context,
    required Function saveNoteToDatabase,
  }) async {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final currentText = mode == NoteMode.code
          ? codeController?.text ?? ''
          : contentController.text;
      if (currentText.isNotEmpty && isDirty && mounted) {
        await saveNoteToDatabase(isManualSave: true);
      }
    } else if (state == AppLifecycleState.resumed) {
      // Security check when app resumes
      if (note?.isLocked == true && mounted && context != null) {
        // Handle vault unlock check if needed
      }
    }
  }

  /// Clean up resources
  static void dispose({
    required TextEditingController contentController,
    required UndoHistoryController undoController,
    required CodeController? codeController,
    required UndoHistoryController? codeUndoController,
    required FocusNode textFieldFocusNode,
    required FocusNode codeFieldFocusNode,
    required NoteMode mode,
  }) {
    contentController.clear();
    contentController.dispose();
    undoController.dispose();
    
    if (mode == NoteMode.code && codeController != null) {
      codeController.clear();
      codeController.dispose();
      codeUndoController?.dispose();
    }
    
    textFieldFocusNode.dispose();
    codeFieldFocusNode.dispose();
  }
}
