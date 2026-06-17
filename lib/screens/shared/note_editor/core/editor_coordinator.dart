// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/editor/editor_state_manager.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/core/constants/app_text_styles.dart';
import 'package:sinan_note/core/utils/apex_smart_controller.dart';
import 'package:sinan_note/core/utils/bidi_cursor_middleware.dart';
import 'package:sinan_note/core/utils/quill_migration.dart';
import 'package:sinan_note/core/utils/text_direction_utils.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/shared/note_editor/controllers/editor_formatting_controller.dart';
import 'package:sinan_note/screens/shared/note_editor/controllers/editor_smart_controller.dart';
import 'package:sinan_note/screens/shared/note_editor/controllers/editor_storage_controller.dart';
import 'package:sinan_note/screens/shared/note_editor/utils/note_editor_utils.dart';
import 'package:sinan_note/services/clipboard_guard.dart';
import 'package:sinan_note/services/content_guard.dart';
import 'package:sinan_note/services/language_detector.dart';
import 'package:sinan_note/widgets/editor/checklist_undo_redo_controller.dart';

/// Central coordinator for all editor operations
class EditorCoordinator {
  // Controllers
  late TextEditingController contentController;
  CodeController? codeController;
  QuillController? quillController;
  int quillControllerVersion = 0;
  BiDiCursorCorrectionMiddleware? _bidiMiddleware;

  /// وصول خارجي للـ middleware لإيقافها أثناء السحب
  BiDiCursorCorrectionMiddleware? get bidiMiddleware => _bidiMiddleware;
  final UndoHistoryController undoController = UndoHistoryController();
  final UndoHistoryController codeUndoController = UndoHistoryController();
  ChecklistUndoRedoController? checklistUndoRedo;
  VoidCallback? checklistAddItem;
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
  double fontSize = 16.0;
  Color textColor = Colors.black87;
  Timer? autosaveTimer;
  String? detectedLanguage;
  bool isLanguageManuallySelected = false;
  Timer? languageDetectionTimer;
  int? savedNoteId;
  final scrollProgress = ValueNotifier<double>(0.0);

  final Note? note;
  final NoteMode mode;
  final bool skipAuthentication;
  final bool originallyLocked;
  final bool readOnly;
  final String? prebuiltDeltaJson;

  /// يصبح true بعد اكتمال initializeQuillAsync — يُستخدم في العارض لتبديل plain→Quill
  bool isQuillFullyLoaded = false;

  EditorCoordinator({
    required this.note,
    required this.mode,
    required this.skipAuthentication,
    required this.originallyLocked,
    this.readOnly = false,
    this.prebuiltDeltaJson,
  });

  /// Initialize all controllers and state
  void initialize(BuildContext context) {
    notesProviderRef = Provider.of<NotesProvider>(context, listen: false);
    stateManager.isAuthenticated = true;

    if (note?.id != null) savedNoteId = note!.id;

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

    final String initialText = note?.content ?? '';
    contentController = ApexSmartController(text: initialText);

    if (mode == NoteMode.simple ||
        mode == NoteMode.reminder ||
        mode == NoteMode.rich) {
      if (readOnly) {
        if (prebuiltDeltaJson != null) {
          // نوت طويل: استخدم الـ JSON المحضّر من isolate مباشرة
          final delta = Delta.fromJson(jsonDecode(prebuiltDeltaJson!) as List);
          quillController = QuillController(
            document: Document.fromDelta(delta),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } else {
          // نوت قصير: ابنِ مباشرة — سريع بدون isolate
          quillController = QuillMigration.controllerFromContent(initialText);
        }
        isQuillFullyLoaded = true;
      } else {
        final preview =
            QuillMigration.previewContent(initialText, maxLines: 20);
        quillController = QuillMigration.controllerFromContent(preview);
      }
    }

    if (mode == NoteMode.code) {
      codeController = CodeController(text: initialText);
    }

    _attachContentGuards();

    stateManager.loadFromNote(
      noteContent: initialText,
      noteTitle:
          (note?.title != null && note!.title.isNotEmpty) ? note!.title : null,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stateManager.isLoading = false;
    });
  }

  /// بناء QuillController في isolate للنوتات الطويلة (> 5000 حرف)
  /// يُستدعى من note_editor.dart بعد initialize() ويُعيد بناء quillController
  /// بدون تجميد الـ UI
  Future<void> initializeQuillAsync() async {
    if (mode != NoteMode.simple &&
        mode != NoteMode.reminder &&
        mode != NoteMode.rich) {
      return;
    }

    final String initialText = note?.content ?? '';
    // نوتة فارغة — لا شيء لبناؤه
    if (initialText.isEmpty) return;

    final deltaJson = await compute(buildDeltaJsonForIsolate, initialText);

    final delta = Delta.fromJson(jsonDecode(deltaJson) as List);
    final doc = Document.fromDelta(delta);
    quillController?.dispose();
    quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    isQuillFullyLoaded = true;
    _attachQuillGuard();
  }

  void _attachQuillGuard() {
    quillController?.document.changes.listen((_) {
      ContentGuard.guardQuill(quillController!);
    });
    if (quillController != null) {
      _bidiMiddleware?.dispose();
      _bidiMiddleware = BiDiCursorCorrectionMiddleware(
        controller: quillController!,
      );
    }
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

    // للـ checklist: إذا لم يكن customTitle موجوداً، اقرأ العنوان من JSON مباشرة
    String? resolvedChecklistTitle = stateManager.checklistTitle;
    if (resolvedChecklistTitle == null &&
        (mode == NoteMode.checklist || note?.noteType == 'checklist')) {
      try {
        final decoded = jsonDecode(contentController.text);
        if (decoded is Map && decoded.containsKey('title')) {
          final t = (decoded['title'] as String?)?.trim();
          if (t != null && t.isNotEmpty) resolvedChecklistTitle = t;
        }
      } catch (_) {}
    }

    return NoteEditorUtils.generateTitle(
      customTitle: stateManager.customTitle,
      checklistTitle: resolvedChecklistTitle,
      content: text,
      isChecklist: mode == NoteMode.checklist || note?.noteType == 'checklist',
      fallback: fallback,
    );
  }

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
      ctrl.replaceText(offset, deleteLen, result.text!, null);
      ctrl.formatText(offset, result.text!.length, const ColorAttribute(null));
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

  void updateFontSize(BuildContext context) {
    fontSize = AppFontSize.noteBody;
  }

  void dispose() {
    autosaveTimer?.cancel();
    languageDetectionTimer?.cancel();
    scrollProgress.dispose();
    _bidiMiddleware?.dispose();
    contentController.dispose();
    codeController?.dispose();
    quillController?.dispose();
    undoController.dispose();
    codeUndoController.dispose();
    textFieldFocusNode.dispose();
    codeFieldFocusNode.dispose();
  }
}
