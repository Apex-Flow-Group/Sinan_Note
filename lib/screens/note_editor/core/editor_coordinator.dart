// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:provider/provider.dart';

import '../../../models/note.dart';
import '../../../models/note_mode.dart';
import '../../../services/notes_provider.dart';
import '../../../services/language_detector.dart';
import '../../../utils/apex_smart_controller.dart';
import '../../../controllers/editor/editor_state_manager.dart';
import '../../../controllers/editor/text_direction_controller.dart';
import '../../../widgets/editor/checklist_editor.dart';
import '../controllers/editor_storage_controller.dart';
import '../controllers/editor_formatting_controller.dart';
import '../controllers/editor_smart_controller.dart';
import '../utils/note_editor_utils.dart';

/// Central coordinator for all editor operations
/// Manages state, controllers, and orchestrates all editor functionality
class EditorCoordinator {
  // Controllers
  late TextEditingController contentController;
  late CodeController codeController;
  final UndoHistoryController undoController = UndoHistoryController();
  final UndoHistoryController codeUndoController = UndoHistoryController();
  ChecklistUndoRedoController? checklistUndoRedo;
  final FocusNode textFieldFocusNode = FocusNode();
  final FocusNode codeFieldFocusNode = FocusNode();

  // Feature Controllers
  final EditorStorageController storageController = EditorStorageController();
  final EditorFormattingController formattingController = EditorFormattingController();
  final EditorSmartController smartController = EditorSmartController();
  final TextDirectionController textDirectionController = TextDirectionController();
  final EditorStateManager stateManager = EditorStateManager();

  // State Variables
  NotesProvider? notesProviderRef;
  String? notePassword;
  late bool initialLockState;
  double fontSize = 18.0;
  Color textColor = Colors.black87;
  Timer? autosaveTimer;
  String? detectedLanguage;
  bool isLanguageManuallySelected = false;
  Timer? languageDetectionTimer;
  int? savedNoteId;

  final Note? note;
  final NoteMode mode;
  final bool skipAuthentication;
  final bool originallyLocked;

  EditorCoordinator({
    required this.note,
    required this.mode,
    required this.skipAuthentication,
    required this.originallyLocked,
  });

  /// Initialize all controllers and state
  void initialize(BuildContext context) {
    notesProviderRef = Provider.of<NotesProvider>(context, listen: false);
    stateManager.isAuthenticated = true;

    if (note?.id != null) {
      savedNoteId = note!.id;
    }

    initialLockState = originallyLocked || (note?.isLocked ?? false);

    if (note != null) {
      stateManager.colorIndex = note!.colorIndex;
      stateManager.isAuthenticated = note!.isChecklist ? true : skipAuthentication;
      
      if (mode == NoteMode.code && note!.noteType.isNotEmpty) {
        String? restoredLanguage = LanguageDetector.getLanguageFromExtension(note!.noteType);
        restoredLanguage ??= NoteEditorUtils.mapNoteTypeToLanguage(note!.noteType);
        
        if (restoredLanguage != null) {
          detectedLanguage = restoredLanguage;
          isLanguageManuallySelected = true;
        }
      }
    }

    String initialText = note?.content ?? '';
    contentController = ApexSmartController(text: initialText);
    
    if (mode == NoteMode.code) {
      codeController = CodeController(text: initialText);
    }
    
    stateManager.loadFromNote(
      noteContent: initialText,
      noteTitle: note?.title != 'Untitled' ? note?.title : null,
      noteColorIndex: stateManager.colorIndex,
      noteReminderDateTime: note?.reminderDateTime,
      noteRecurrenceRule: note?.recurrenceRule,
    );

    if (note != null) {
      stateManager.hasContent = note!.content.trim().isNotEmpty;
      if (note!.isLocked && note!.id == null) {
        stateManager.markDirty();
        stateManager.isAuthenticated = true;
      }
    }
  }

  /// Get background color based on current state
  Color getBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return NoteEditorUtils.getBackgroundColor(stateManager.colorIndex, brightness);
  }

  /// Get current title based on content and state
  String getCurrentTitle(String fallback) {
    final text = mode == NoteMode.code
        ? codeController.text
        : contentController.text;
    
    return NoteEditorUtils.generateTitle(
      customTitle: stateManager.customTitle,
      checklistTitle: stateManager.checklistTitle,
      content: text,
      isChecklist: mode == NoteMode.checklist || note?.noteType == 'checklist',
      fallback: fallback,
    );
  }

  /// Dispose all resources
  void dispose() {
    autosaveTimer?.cancel();
    languageDetectionTimer?.cancel();
    contentController.dispose();
    if (mode == NoteMode.code) {
      codeController.dispose();
    }
    undoController.dispose();
    codeUndoController.dispose();
    textFieldFocusNode.dispose();
    codeFieldFocusNode.dispose();
  }
}
