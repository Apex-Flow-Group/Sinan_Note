// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';

import 'package:apex_note/controllers/editor/editor_state_manager.dart';
import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/core/utils/apex_smart_controller.dart';
import 'package:apex_note/core/utils/quill_migration.dart';
import 'package:apex_note/core/utils/text_direction_utils.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/controllers/editor_formatting_controller.dart';
import 'package:apex_note/screens/shared/note_editor/controllers/editor_smart_controller.dart';
import 'package:apex_note/screens/shared/note_editor/controllers/editor_storage_controller.dart';
import 'package:apex_note/screens/shared/note_editor/utils/note_editor_utils.dart';
import 'package:apex_note/services/clipboard_guard.dart';
import 'package:apex_note/services/content_guard.dart';
import 'package:apex_note/services/language_detector.dart';
import 'package:apex_note/widgets/editor/checklist_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

/// Central coordinator for all editor operations
/// Manages state, controllers, and orchestrates all editor functionality
class EditorCoordinator {
  // Controllers
  late TextEditingController contentController;
  CodeController? codeController;
  QuillController? quillController;
  final UndoHistoryController undoController = UndoHistoryController();
  final UndoHistoryController codeUndoController = UndoHistoryController();
  ChecklistUndoRedoController? checklistUndoRedo;
  final FocusNode textFieldFocusNode = FocusNode();
  final FocusNode codeFieldFocusNode = FocusNode();

  // Feature Controllers
  final EditorStorageController storageController = EditorStorageController();
  final EditorFormattingController formattingController =
      EditorFormattingController();
  final EditorSmartController smartController = EditorSmartController();
  final EditorStateManager stateManager = EditorStateManager();

  // State Variables
  NotesProvider? notesProviderRef;
  String? notePassword;
  late bool initialLockState;
  double fontSize = 16.0; // يُحدَّث من context عند التهيئة
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
      stateManager.isAuthenticated =
          note!.isChecklist ? true : skipAuthentication;

      if (mode == NoteMode.code && note!.noteType.isNotEmpty) {
        String? restoredLanguage =
            LanguageDetector.getLanguageFromExtension(note!.noteType);
        restoredLanguage ??=
            NoteEditorUtils.mapNoteTypeToLanguage(note!.noteType);

        // For generic types, detect from content once
        if (restoredLanguage == null &&
            (note!.noteType == 'code' ||
                note!.noteType == 'pro' ||
                note!.noteType == 'professional')) {
          restoredLanguage = LanguageDetector.detectLanguage(note!.content);
        }

        if (restoredLanguage != null) {
          detectedLanguage = restoredLanguage;
          isLanguageManuallySelected = true;
        }
      }
    }

    String initialText = note?.content ?? '';
    contentController = ApexSmartController(text: initialText);

    if (mode == NoteMode.simple ||
        mode == NoteMode.reminder ||
        mode == NoteMode.rich) {
      quillController = QuillMigration.controllerFromContent(initialText);
    }

    if (mode == NoteMode.code) {
      codeController = CodeController(text: initialText);
    }

    _attachContentGuards();

    stateManager.loadFromNote(
      noteContent: initialText,
      noteTitle: note?.title != 'Untitled' ? note?.title : null,
      noteColorIndex: stateManager.colorIndex,
      noteReminderDateTime: note?.reminderDateTime,
      noteRecurrenceRule: note?.recurrenceRule,
      noteCategoryIds: note?.categoryIds ?? [],
      noteIsHiddenFromHome: note?.isHiddenFromHome ?? false,
    );

    if (note != null) {
      stateManager.hasContent = note!.content.trim().isNotEmpty;
      if (note!.isLocked && note!.id == null) {
        stateManager.markDirty();
        stateManager.isAuthenticated = true;
      }
    }

    // التحميل انتهى — نسمح بالـ autosave بعد frame واحد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stateManager.isLoading = false;
    });
  }

  /// Get background color based on current state
  Color getBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return NoteEditorUtils.getBackgroundColor(
        stateManager.colorIndex, brightness);
  }

  /// Get current title based on content and state
  String getCurrentTitle(String fallback) {
    final text = mode == NoteMode.code && codeController != null
        ? codeController!.text
        : (quillController != null
            ? QuillMigration.toPlainText(quillController!)
            : contentController.text);

    return NoteEditorUtils.generateTitle(
      customTitle: stateManager.customTitle,
      checklistTitle: stateManager.checklistTitle,
      content: text,
      isChecklist: mode == NoteMode.checklist || note?.noteType == 'checklist',
      fallback: fallback,
    );
  }

  /// يربط صمامات الأمان على جميع الـ controllers بعد التهيئة
  void _attachContentGuards() {
    contentController.addListener(() {
      ContentGuard.guardText(contentController);
    });
    quillController?.document.changes.listen((_) {
      ContentGuard.guardQuill(quillController!);
    });
    codeController?.addListener(() {
      ContentGuard.guardCode(codeController!);
    });
  }

  /// لصق آمن من الحافظة مع حد أقصى
  /// يُرجع [ClipboardResult] لإظهار تحذير عند الاقتطاع
  Future<ClipboardResult> safePaste() async {
    final result = await ClipboardGuard.getSafeText();
    if (result.text == null) return result;

    if (mode == NoteMode.code && codeController != null) {
      final ctrl = codeController!;
      final sel = ctrl.selection;
      final text = ctrl.text;
      final newText = sel.isValid
          ? text.replaceRange(sel.start, sel.end, result.text!)
          : text + result.text!;
      ctrl.text = newText;
    } else if (quillController != null) {
      final ctrl = quillController!;
      final sel = ctrl.selection;
      final offset = sel.isCollapsed ? sel.extentOffset : sel.start;
      final deleteLen = sel.isCollapsed ? 0 : sel.end - sel.start;
      // replaceText يحافظ على style الحالي (لون، حجم، إلخ)
      ctrl.replaceText(offset, deleteLen, result.text!, null);
      // إزالة أي color attribute من النص الملصوق لإرثه من customStyles
      ctrl.formatText(offset, result.text!.length, const ColorAttribute(null));
      // تطبيق اتجاه كل فقرة
      final lines = result.text!.split('\n');
      int pos = offset;
      for (final line in lines) {
        if (line.isNotEmpty) {
          final isRtl =
              TextDirectionUtils.getDirection(line) == TextDirection.rtl;
          ctrl.formatText(
            pos + line.length,
            1,
            isRtl ? const DirectionAttribute(null) : Attribute.rtl,
          );
        }
        pos += line.length + 1;
      }
    } else {
      final ctrl = contentController;
      final sel = ctrl.selection;
      final text = ctrl.text;
      final newText = sel.isValid
          ? text.replaceRange(sel.start, sel.end, result.text!)
          : text + result.text!;
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset:
              sel.isValid ? sel.start + result.text!.length : newText.length,
        ),
      );
    }
    stateManager.markDirty();
    return result;
  }

  /// تحديث حجم الخط من الثيم — يُستدعى من didChangeDependencies
  void updateFontSize(BuildContext context) {
    fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
  }

  /// Dispose all resources
  void dispose() {
    autosaveTimer?.cancel();
    languageDetectionTimer?.cancel();
    contentController.dispose();
    codeController?.dispose();
    quillController?.dispose();
    undoController.dispose();
    codeUndoController.dispose();
    textFieldFocusNode.dispose();
    codeFieldFocusNode.dispose();
  }
}
