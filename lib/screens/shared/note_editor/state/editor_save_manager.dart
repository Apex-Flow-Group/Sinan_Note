// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:sinan_note/domain/models/note_mode.dart';
import 'package:sinan_note/screens/shared/note_editor/controllers/editor_smart_controller.dart';

/// قواعد المحرر الصغيرة: متى يكون المحتوى فارغاً، وما نوع الملاحظة.
/// الحفظ نفسه في EditorViewModel.
abstract final class EditorSaveManager {
  static bool isContentEmpty(String content, NoteMode mode) {
    if (mode == NoteMode.checklist) {
      try {
        final decoded = jsonDecode(content);
        if (decoded is Map) {
          final title = (decoded['title'] ?? '').toString().trim();
          final items = decoded['items'] as List? ?? [];
          return title.isEmpty &&
              !items.any(
                  (item) => (item['text'] ?? '').toString().trim().isNotEmpty);
        }
      } catch (e) {
        return true;
      }
    }
    return content.trim().isEmpty;
  }

  static String determineNoteType({
    required NoteMode mode,
    required String? detectedLanguage,
    required bool isLanguageManuallySelected,
    required String? existingNoteType,
    required EditorSmartController smartController,
  }) {
    // Priority 1: Checklist
    if (mode == NoteMode.checklist) {
      return 'checklist';
    }

    // Priority 2: Manual selection OR auto-detected language
    if (detectedLanguage != null) {
      return smartController.mapLanguageToNoteType(detectedLanguage);
    }

    // Priority 3: Preserve existing specific type (not generic)
    const genericTypes = {'code', 'pro', 'professional'};
    if (existingNoteType != null &&
        existingNoteType.isNotEmpty &&
        mode == NoteMode.code &&
        !genericTypes.contains(existingNoteType)) {
      return existingNoteType;
    }

    // Priority 4: Default to mode name
    return mode.name;
  }
}
