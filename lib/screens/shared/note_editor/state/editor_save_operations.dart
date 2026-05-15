// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/quill_migration.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:apex_note/screens/shared/note_editor/state/editor_save_manager.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:flutter/material.dart';

/// High-level save orchestration for the note editor.
///
/// Handles content validation, mode-specific preparation, and delegates
/// actual persistence to [EditorSaveManager].
class EditorSaveOperations {
  /// Save note to database with full validation and mode-specific logic.
  ///
  /// Returns `true` if the note was actually saved.
  static Future<bool> saveToDatabase({
    required EditorCoordinator coordinator,
    required NoteMode mode,
    required Note? existingNote,
    required AppLocalizations? l10n,
    required bool Function() isMounted,
    required VoidCallback onSavedNewId,
    bool forceUpdate = false,
    bool isManualSave = false,
  }) async {
    if (coordinator.stateManager.isSaving) return false;

    final isNewLockedNote =
        (coordinator.initialLockState || existingNote?.isLocked == true) &&
            existingNote?.id == null &&
            coordinator.savedNoteId == null;

    if (!forceUpdate &&
        !isNewLockedNote &&
        (coordinator.savedNoteId != null || existingNote != null)) {
      if (!coordinator.stateManager.hasChanges()) {
        return false;
      }
    }

    coordinator.stateManager.isSaving = true;

    try {
      String contentToSave = _getContent(coordinator, mode);

      // Code note empty validation
      if (mode == NoteMode.code) {
        if (contentToSave.trim().isEmpty && !isNewLockedNote) {
          coordinator.stateManager.isSaving = false;
          return false;
        }
      }

      // Checklist validation
      if (mode == NoteMode.checklist || existingNote?.noteType == 'checklist') {
        contentToSave = EditorSaveManager.prepareChecklistContent(
          contentToSave,
          l10n?.checklistItemHint ?? 'Task...',
        );
        if (EditorSaveManager.isContentEmpty(
            contentToSave, NoteMode.checklist)) {
          coordinator.stateManager.isSaving = false;
          return false;
        }
      }

      // Empty content → trash (فقط إذا كانت ملاحظة جديدة أو المحتوى كان فارغاً أصلاً)
      if (contentToSave.trim().isEmpty && !isNewLockedNote) {
        final noteId = coordinator.savedNoteId ?? existingNote?.id;
        // إذا كانت الملاحظة موجودة مسبقاً وتغير اللون فقط — لا نرميها
        final isColorOnlyChange = noteId != null &&
            coordinator.stateManager.colorIndex !=
                coordinator.stateManager.originalColorIndex;
        if (isColorOnlyChange) {
          // حفظ اللون فقط بدون رمي في السلة
          await coordinator.notesProviderRef!.updateNote(
            existingNote!.copyWith(
              colorIndex: coordinator.stateManager.colorIndex,
              updatedAt: DateTime.now(),
            ),
            silent: false,
          );
          coordinator.stateManager.markClean();
          coordinator.stateManager.isSaving = false;
          return true;
        }
        if (noteId != null) {
          await coordinator.notesProviderRef!.trashNote(noteId);
        }
        coordinator.stateManager.isSaving = false;
        return false;
      }

      final noteType = EditorSaveManager.determineNoteType(
        mode: mode,
        detectedLanguage: coordinator.detectedLanguage,
        isLanguageManuallySelected: coordinator.isLanguageManuallySelected,
        existingNoteType: existingNote?.noteType,
        smartController: coordinator.smartController,
      );

      final newId = await EditorSaveManager.saveNote(
        provider: coordinator.notesProviderRef!,
        existingNote: existingNote,
        savedNoteId: coordinator.savedNoteId,
        content: contentToSave,
        title: coordinator.getCurrentTitle(l10n?.newNoteTitle ?? 'New Note'),
        colorIndex: coordinator.stateManager.colorIndex,
        initialLockState: coordinator.initialLockState,
        noteType: noteType,
        isChecklist: mode == NoteMode.checklist,
        reminderDateTime: coordinator.stateManager.reminderDateTime,
        recurrenceRule: coordinator.stateManager.recurrenceRule,
        categoryIds: coordinator.stateManager.categoryIds,
        isHiddenFromHome: coordinator.stateManager.isHiddenFromHome,
        mode: mode,
        silent: !isManualSave,
        isAutoSave: !isManualSave,
      );

      if (coordinator.savedNoteId == null) {
        coordinator.savedNoteId = newId;
        onSavedNewId();
      }

      if (isManualSave) {
        coordinator.stateManager.updateSnapshot();
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      coordinator.stateManager.isSaving = false;
    }
  }

  /// Manual save with user feedback notification.
  static Future<void> saveManually({
    required BuildContext context,
    required EditorCoordinator coordinator,
    required NoteMode mode,
    required Note? existingNote,
    required AppLocalizations? l10n,
    required bool Function() isMounted,
    required VoidCallback onSavedNewId,
  }) async {
    coordinator.autosaveTimer?.cancel();

    final content = _getPlainContent(coordinator, mode);
    final title = coordinator.stateManager.customTitle ?? '';

    if (content.trim().isEmpty && title.trim().isEmpty) return;

    final notificationService = UnifiedNotificationService();
    final savedMessage = l10n?.noteSaved ?? '';
    final ctx = context;

    final saved = await saveToDatabase(
      coordinator: coordinator,
      mode: mode,
      existingNote: existingNote,
      l10n: l10n,
      isMounted: isMounted,
      onSavedNewId: onSavedNewId,
      forceUpdate: true,
      isManualSave: true,
    );

    if (saved && isMounted()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isMounted()) return;
        notificationService.show(
          context: ctx,
          message: savedMessage,
          type: NotificationType.success,
          duration: const Duration(seconds: 1),
        );
      });
    }
  }

  /// Export as markdown format.
  static Future<void> saveAsMarkdown({
    required BuildContext context,
    required EditorCoordinator coordinator,
    required NoteMode mode,
    required Note? existingNote,
    required AppLocalizations? l10n,
  }) async {
    final content = mode == NoteMode.code
        ? coordinator.codeController!.text
        : coordinator.contentController.text;

    await EditorSaveManager.saveAsMarkdown(
      context: context,
      provider: coordinator.notesProviderRef!,
      existingNote: existingNote,
      savedNoteId: coordinator.savedNoteId,
      content: content,
      title: coordinator.getCurrentTitle(l10n?.newNoteTitle ?? 'New Note'),
      colorIndex: coordinator.stateManager.colorIndex,
      isLocked: coordinator.initialLockState,
      reminderDateTime: coordinator.stateManager.reminderDateTime,
      recurrenceRule: coordinator.stateManager.recurrenceRule,
      mode: mode,
    );

    coordinator.stateManager.markClean();
  }

  /// Export with specific file extension.
  static Future<void> saveWithExtension({
    required BuildContext context,
    required EditorCoordinator coordinator,
    required NoteMode mode,
    required Note? existingNote,
    required AppLocalizations? l10n,
    required String extension,
  }) async {
    final content = mode == NoteMode.code
        ? coordinator.codeController!.text
        : coordinator.contentController.text;

    await EditorSaveManager.saveWithExtension(
      context: context,
      provider: coordinator.notesProviderRef!,
      existingNote: existingNote,
      savedNoteId: coordinator.savedNoteId,
      content: content,
      title: coordinator.getCurrentTitle(l10n?.newNoteTitle ?? 'New Note'),
      colorIndex: coordinator.stateManager.colorIndex,
      isLocked: coordinator.initialLockState,
      reminderDateTime: coordinator.stateManager.reminderDateTime,
      recurrenceRule: coordinator.stateManager.recurrenceRule,
      mode: mode,
      detectedLanguage: coordinator.detectedLanguage,
      smartController: coordinator.smartController,
    );

    coordinator.stateManager.markClean();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Get content in storage format (Delta JSON for Quill, plain for others).
  static String _getContent(EditorCoordinator coordinator, NoteMode mode) {
    if (mode == NoteMode.code) return coordinator.codeController!.text;
    if (mode == NoteMode.checklist) return coordinator.contentController.text;
    return QuillMigration.toDeltaJson(coordinator.quillController!);
  }

  /// Get content as plain text (for empty checks).
  static String _getPlainContent(EditorCoordinator coordinator, NoteMode mode) {
    if (mode == NoteMode.code) return coordinator.codeController!.text;
    if (mode == NoteMode.checklist) return coordinator.contentController.text;
    return QuillMigration.toPlainText(coordinator.quillController!);
  }
}
