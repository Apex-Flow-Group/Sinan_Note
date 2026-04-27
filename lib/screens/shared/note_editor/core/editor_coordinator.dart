// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:async';
import 'dart:convert';

import 'package:apex_note/controllers/editor/editor_state_manager.dart';
import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/core/constants/app_text_styles.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:provider/provider.dart';

/// دالة تعمل في isolate منفصل — تبني Delta JSON من النص
/// لا تعتمد على أي Flutter widgets أو BuildContext
String _buildDeltaJsonInIsolate(String content) {
  if (content.isEmpty) {
    final delta = Delta()..insert('\n');
    return jsonEncode(delta.toJson());
  }

  // Delta JSON موجود مسبقاً — أصلح الاتجاهات فقط
  if (content.trimLeft().startsWith('[')) {
    try {
      final rawDelta = Delta.fromJson(jsonDecode(content) as List);
      final fixed = _fixDeltaDirectionsIsolate(rawDelta);
      return jsonEncode(fixed.toJson());
    } catch (_) {
      // fall through
    }
  }

  // نص عادي → Delta
  final delta = _buildDeltaWithDirectionsIsolate(content);
  return jsonEncode(delta.toJson());
}

/// نسخة من _fixDeltaDirections تعمل في isolate (بدون Flutter imports)
Delta _fixDeltaDirectionsIsolate(Delta original) {
  final ops = original.toList();
  final fixed = Delta();
  String paragraphText = '';
  String lastNonEmptyDir = '';

  for (final op in ops) {
    if (!op.isInsert) {
      if (op.isDelete) fixed.delete(op.length!);
      if (op.isRetain) fixed.retain(op.length!, op.attributes);
      continue;
    }
    final data = op.data;
    if (data is! String) {
      fixed.insert(data, op.attributes);
      continue;
    }
    Map<String, dynamic>? cleanAttrs;
    if (op.attributes != null) {
      cleanAttrs = Map<String, dynamic>.from(op.attributes!);
      if (cleanAttrs['align'] == 'right') cleanAttrs.remove('align');
      if (cleanAttrs.isEmpty) cleanAttrs = null;
    }
    final segments = data.split('\n');
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.isNotEmpty) {
        paragraphText += seg;
        fixed.insert(seg, cleanAttrs);
      }
      if (i < segments.length - 1) {
        final dirText =
            paragraphText.isNotEmpty ? paragraphText : lastNonEmptyDir;
        final isRtl =
            TextDirectionUtils.getDirection(dirText) == TextDirection.rtl;
        final attrs = Map<String, dynamic>.from(op.attributes ?? {});
        if (isRtl) {
          attrs.remove('direction');
          attrs.remove('align');
        } else {
          attrs['direction'] = 'rtl';
          attrs.remove('align');
        }
        fixed.insert('\n', attrs.isEmpty ? null : attrs);
        if (paragraphText.isNotEmpty) lastNonEmptyDir = paragraphText;
        paragraphText = '';
      }
    }
  }
  return fixed;
}

/// نسخة من _buildDeltaWithDirections تعمل في isolate
Delta _buildDeltaWithDirectionsIsolate(String content) {
  final delta = Delta();
  final paragraphs = content.split('\n');
  for (int i = 0; i < paragraphs.length; i++) {
    final paragraph = paragraphs[i];
    final isRtl =
        TextDirectionUtils.getDirection(paragraph) == TextDirection.rtl;
    if (paragraph.isNotEmpty) delta.insert(paragraph);
    delta.insert('\n', isRtl ? null : {'direction': 'rtl'});
  }
  return delta;
}

/// Central coordinator for all editor operations
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

  EditorCoordinator({
    required this.note,
    required this.mode,
    required this.skipAuthentication,
    required this.originallyLocked,
  });

  /// Initialize all controllers and state
  void initialize(BuildContext context) {
    debugPrint('⏱️ [Coordinator] initialize() start: ${DateTime.now().millisecondsSinceEpoch}ms');
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

    // بناء QuillController بأول 20 سطر فقط — سريع جداً للانيميشن
    // initializeQuillAsync() سيستبدله بالمحتوى الكامل من isolate
    if (mode == NoteMode.simple ||
        mode == NoteMode.reminder ||
        mode == NoteMode.rich) {
      final t0 = DateTime.now().millisecondsSinceEpoch;
      final preview = QuillMigration.previewContent(initialText, maxLines: 20);
      quillController = QuillMigration.controllerFromContent(preview);
      debugPrint('⏱️ [Coordinator] QuillController built (preview 20 lines, ${preview.length} chars): ${DateTime.now().millisecondsSinceEpoch - t0}ms');
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

    debugPrint('⏱️ [Coordinator] initializeQuillAsync start (${initialText.length} chars): ${DateTime.now().millisecondsSinceEpoch}ms');
    final t0 = DateTime.now().millisecondsSinceEpoch;

    final deltaJson = await compute(_buildDeltaJsonInIsolate, initialText);

    debugPrint('⏱️ [Coordinator] isolate done: ${DateTime.now().millisecondsSinceEpoch - t0}ms');

    final delta = Delta.fromJson(jsonDecode(deltaJson) as List);
    final doc = Document.fromDelta(delta);
    quillController?.dispose();
    quillController = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _attachQuillGuard();
    debugPrint('⏱️ [Coordinator] initializeQuillAsync total: ${DateTime.now().millisecondsSinceEpoch - t0}ms');
  }

  void _attachQuillGuard() {
    quillController?.document.changes.listen((_) {
      ContentGuard.guardQuill(quillController!);
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
    contentController.dispose();
    codeController?.dispose();
    quillController?.dispose();
    undoController.dispose();
    codeUndoController.dispose();
    textFieldFocusNode.dispose();
    codeFieldFocusNode.dispose();
  }
}
