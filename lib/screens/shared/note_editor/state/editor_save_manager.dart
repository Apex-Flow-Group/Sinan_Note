// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/controllers/editor_smart_controller.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/services/version_control_service.dart';
import 'package:flutter/material.dart';

class EditorSaveManager {
  /// Validate if note content is empty
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

  /// Prepare checklist content for saving
  static String prepareChecklistContent(String content, String defaultTask) {
    return content;
  }

  /// Determine note type based on mode and language
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

  /// Save note to database with smart validation
  static Future<int?> saveNote({
    required NotesProvider provider,
    required Note? existingNote,
    required int? savedNoteId,
    required String content,
    required String title,
    required int colorIndex,
    required bool initialLockState,
    required String noteType,
    required bool isChecklist,
    required DateTime? reminderDateTime,
    required String? recurrenceRule,
    required NoteMode mode,
    List<int> categoryIds = const [],
    bool isHiddenFromHome = false,
    bool silent = false,
    bool isAutoSave = false,
  }) async {
    final noteToSave = Note(
      id: savedNoteId ?? existingNote?.id,
      title: title,
      content: content,
      createdAt: existingNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: colorIndex,
      isLocked: initialLockState,
      noteType: noteType,
      reminderDateTime: reminderDateTime,
      recurrenceRule: recurrenceRule,
      isArchived: existingNote?.isArchived ?? false,
      isTrashed: existingNote?.isTrashed ?? false,
      isCompleted: existingNote?.isCompleted ?? false,
      isProfessional: existingNote?.isProfessional ?? (mode == NoteMode.code),
      isPinned: existingNote?.isPinned ?? false,
      isChecklist: isChecklist,
      categoryIds: categoryIds,
      isHiddenFromHome: isHiddenFromHome,
    );

    final newId = await provider.addOrUpdateNote(noteToSave, silent: silent);

    // Log version for history
    try {
      await VersionControlService().smartLogVersion(
        noteId: newId,
        title: title,
        content: content,
        isManualAction: !isAutoSave, // FIXED: respect auto-save flag
      );
    } catch (e) {
      // History logging failed, but note was saved
    }

    return newId;
  }

  /// Save as markdown format
  static Future<void> saveAsMarkdown({
    required BuildContext context,
    required NotesProvider provider,
    required Note? existingNote,
    required int? savedNoteId,
    required String content,
    required String title,
    required int colorIndex,
    required bool isLocked,
    required DateTime? reminderDateTime,
    required String? recurrenceRule,
    required NoteMode mode,
  }) async {
    final wrappedContent = '```\n$content\n```';

    final noteToSave = Note(
      id: savedNoteId ?? existingNote?.id,
      title: title,
      content: wrappedContent,
      createdAt: existingNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: colorIndex,
      isLocked: isLocked,
      noteType: 'markdown',
      reminderDateTime: reminderDateTime,
      recurrenceRule: recurrenceRule,
      isArchived: existingNote?.isArchived ?? false,
      isTrashed: existingNote?.isTrashed ?? false,
      isCompleted: existingNote?.isCompleted ?? false,
      isProfessional: existingNote?.isProfessional ?? false,
      isPinned: existingNote?.isPinned ?? false,
      isChecklist: existingNote?.isChecklist ?? false,
    );

    await provider.addOrUpdateNote(noteToSave);

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    UnifiedNotificationService().show(
      context: context,
      message: l10n.savedAsMarkdownSuccess,
      type: NotificationType.success,
    );
  }

  /// Save with specific extension/language
  static Future<void> saveWithExtension({
    required BuildContext context,
    required NotesProvider provider,
    required Note? existingNote,
    required int? savedNoteId,
    required String content,
    required String title,
    required int colorIndex,
    required bool isLocked,
    required DateTime? reminderDateTime,
    required String? recurrenceRule,
    required NoteMode mode,
    required String? detectedLanguage,
    required EditorSmartController smartController,
  }) async {
    String noteType = mode.name;

    if (detectedLanguage != null) {
      noteType = smartController.mapLanguageToNoteType(detectedLanguage);
    }

    final noteToSave = Note(
      id: savedNoteId ?? existingNote?.id,
      title: title,
      content: content,
      createdAt: existingNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      colorIndex: colorIndex,
      isLocked: isLocked,
      noteType: noteType,
      reminderDateTime: reminderDateTime,
      recurrenceRule: recurrenceRule,
      isArchived: existingNote?.isArchived ?? false,
      isTrashed: existingNote?.isTrashed ?? false,
      isCompleted: existingNote?.isCompleted ?? false,
      isProfessional: existingNote?.isProfessional ?? (mode == NoteMode.code),
      isPinned: existingNote?.isPinned ?? false,
      isChecklist: existingNote?.isChecklist ?? (mode == NoteMode.checklist),
    );

    await provider.addOrUpdateNote(noteToSave);

    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    UnifiedNotificationService().show(
      context: context,
      message: l10n.savedSuccessfully,
      type: NotificationType.success,
    );
  }
}
