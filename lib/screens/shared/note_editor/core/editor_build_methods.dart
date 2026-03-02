// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui';

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/quill_migration.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/shared/note_editor/controllers/editor_formatting_controller.dart';
import 'package:apex_note/screens/shared/note_editor/controllers/editor_smart_controller.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:apex_note/screens/shared/note_editor/dialogs/editor_dialogs.dart';
import 'package:apex_note/screens/shared/note_editor/widgets/checklist_editor_widget.dart';
import 'package:apex_note/screens/shared/note_editor/widgets/code_editor_widget.dart';
import 'package:apex_note/services/svg_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/editor/apex_editor_header.dart';
import 'package:apex_note/widgets/editor/checklist_editor.dart';
import 'package:apex_note/widgets/editor/quill_editor_widget.dart';
import 'package:apex_note/widgets/editor/toolbars/editor_toolbar_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:provider/provider.dart';

/// All build methods extracted from main editor
class EditorBuildMethods {
  /// Build content area based on mode
  static Widget buildContentArea({
    required BuildContext context,
    required EditorCoordinator coordinator,
    required double sidePadding,
    required Color finalTextColor,
    required Color finalHintColor,
    required NoteMode mode,
    required Note? note,
    required int? savedNoteId,
    required VoidCallback onReminderTap,
    required Future<void> Function({bool isManualSave}) saveCallback,
    required Function(ChecklistUndoRedoController) onUndoRedoControllerCreated,
    required VoidCallback onUndoRedoChanged,
    required Function(String) onChecklistTitleChanged,
  }) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const toolbarHeight = 60.0;
    final totalBottomSpace = toolbarHeight + bottomPadding + 16;

    if (mode == NoteMode.code) {
      // Ensure codeController is initialized
      coordinator.codeController ??= CodeController(
        text: coordinator.contentController.text,
      );
      return CodeEditorWidget(
        codeController: coordinator.codeController!,
        undoController: coordinator.codeUndoController,
        focusNode: coordinator.codeFieldFocusNode,
        detectedLanguage: coordinator.detectedLanguage,
        backgroundColor: coordinator.getBackgroundColor(context),
        totalBottomSpace: totalBottomSpace,
      );
    } else if (mode == NoteMode.checklist) {
      return ChecklistEditorWidget(
        contentController: coordinator.contentController,
        backgroundColor: coordinator.getBackgroundColor(context),
        totalBottomSpace: totalBottomSpace,
        onUndoRedoControllerCreated: onUndoRedoControllerCreated,
        onUndoRedoChanged: onUndoRedoChanged,
        onChecklistTitleChanged: onChecklistTitleChanged,
        onContentChanged: () {
          coordinator.stateManager.markDirty();
        },
      );
    } else {
      // Ensure quillController is initialized
      coordinator.quillController ??= QuillMigration.controllerFromContent(
          coordinator.contentController.text);
      return QuillEditorWidget(
        quillController: coordinator.quillController!,
        focusNode: coordinator.textFieldFocusNode,
        textColor: finalTextColor,
        hintColor: finalHintColor,
        fontSize: coordinator.fontSize,
        sidePadding: sidePadding,
        totalBottomSpace: totalBottomSpace,
        autoFocus: note == null,
      );
    }
  }

  /// Build header widget
  static Widget buildHeader({
    required BuildContext context,
    required EditorCoordinator coordinator,
    required Color finalTextColor,
    required String currentTitle,
    required Note? note,
    required String? notePassword,
    required VoidCallback onReminderTap,
    required VoidCallback onHistoryTap,
    required VoidCallback onTitleTap,
    required VoidCallback onSaveTap,
    VoidCallback? onBackTap,
  }) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ApexEditorHeader(
                backgroundColor: coordinator
                    .getBackgroundColor(context)
                    .withValues(alpha: 0.7),
                textColor: finalTextColor,
                title: currentTitle,
                isLocked: note?.isLocked == true || notePassword != null,
                hasHistory: note?.id != null,
                hasReminder: coordinator.stateManager.reminderDateTime != null,
                onReminderTap: () {
                  HapticFeedback.mediumImpact();
                  onReminderTap();
                },
                onHistoryTap: onHistoryTap,
                onTitleTap: () {
                  HapticFeedback.lightImpact();
                  onTitleTap();
                },
                onSaveTap: () async {
                  HapticFeedback.mediumImpact();
                  onSaveTap();
                },
                onBackTap: onBackTap,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build toolbar widget
  static Widget buildToolbar({
    required BuildContext context,
    required EditorCoordinator coordinator,
    required Color finalTextColor,
    required NoteMode mode,
    required Note? note,
    required int? savedNoteId,
    required EditorSmartController smartController,
    required EditorFormattingController formattingController,
    required VoidCallback onReminderTap,
    required VoidCallback onColorPaletteTap,
    required VoidCallback onSmartSaveDialog,
    required Future<void> Function() saveNote,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: coordinator.getBackgroundColor(context),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: coordinator.getBackgroundColor(context),
            ),
            child: EditorToolbarFactory.build(
              mode: mode,
              backgroundColor: coordinator.getBackgroundColor(context),
              textColor: finalTextColor,
              undoController: coordinator.undoController,
              detectedLanguage: coordinator.detectedLanguage,
              hasReminder: coordinator.stateManager.reminderDateTime != null,
              hasContent: coordinator.stateManager.hasContent,
              onUndo: coordinator.stateManager.canUndo
                  ? () {
                      HapticFeedback.lightImpact();
                      if (mode == NoteMode.checklist) {
                        coordinator.checklistUndoRedo?.undo();
                      } else if (mode == NoteMode.code) {
                        coordinator.codeUndoController.undo();
                      } else {
                        coordinator.undoController.undo();
                      }
                    }
                  : null,
              onRedo: coordinator.stateManager.canRedo
                  ? () {
                      HapticFeedback.lightImpact();
                      if (mode == NoteMode.checklist) {
                        coordinator.checklistUndoRedo?.redo();
                      } else if (mode == NoteMode.code) {
                        coordinator.codeUndoController.redo();
                      } else {
                        coordinator.undoController.redo();
                      }
                    }
                  : null,
              onLanguageChanged: (newLang) async {
                String? normalizedLang;
                if (newLang == 'Auto') {
                  normalizedLang = null;
                } else {
                  normalizedLang = newLang; // includes "custom:ext" as-is
                }
                coordinator.detectedLanguage = normalizedLang;
                coordinator.isLanguageManuallySelected = normalizedLang != null;
                coordinator.stateManager.markDirty();
              },
              onRunCode: coordinator.detectedLanguage == 'SVG'
                  ? () async {
                      HapticFeedback.mediumImpact();
                      try {
                        await SvgService.previewSvgCode(
                            coordinator.codeController!.text);
                      } catch (e) {
                        if (context.mounted) {
                          UnifiedNotificationService().show(
                            context: context,
                            message: 'Could not open browser: $e',
                            type: NotificationType.error,
                          );
                        }
                      }
                    }
                  : null,
              onExportCode: coordinator.detectedLanguage == 'SVG'
                  ? () async {
                      HapticFeedback.mediumImpact();
                      final title = coordinator.getCurrentTitle(
                          AppLocalizations.of(context)?.newNoteTitle ?? 'svg');
                      await SvgService.exportSvgFile(
                          coordinator.codeController!.text, title);
                    }
                  : null,
              onCalculate: () {
                HapticFeedback.mediumImpact();
                smartController.showSmartCalculationResult(
                  context,
                  coordinator.contentController,
                  l10n,
                );
              },
              onBackgroundColorTap: () {
                HapticFeedback.mediumImpact();
                onColorPaletteTap();
              },
              onReminderTap: coordinator.stateManager.hasContent
                  ? () {
                      HapticFeedback.mediumImpact();
                      onReminderTap();
                    }
                  : null,
              onShareTap: () {
                HapticFeedback.mediumImpact();
                String text;
                if (mode == NoteMode.code) {
                  text = coordinator.codeController!.text;
                } else if (mode == NoteMode.checklist) {
                  text = ChecklistFormatter.formatForSharing(
                      coordinator.getCurrentTitle(l10n.newNoteTitle),
                      coordinator.contentController.text);
                } else {
                  final content = coordinator.quillController != null
                      ? QuillMigration.toPlainText(coordinator.quillController!)
                      : coordinator.contentController.text;
                  text = '${coordinator.getCurrentTitle(l10n.newNoteTitle)}\n\n$content';
                }
                CustomShareSheet.show(context, text,
                    subject: coordinator.getCurrentTitle(l10n.newNoteTitle));
              },
              onArchiveTap: () async {
                HapticFeedback.mediumImpact();
                if (note?.id != null) {
                  final provider =
                      Provider.of<NotesProvider>(context, listen: false);
                  await provider.archiveNote(note!.id!);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  UnifiedNotificationService().show(
                    context: context,
                    message: l10n.movedToArchive,
                    type: NotificationType.success,
                  );
                } else {
                  UnifiedNotificationService().show(
                    context: context,
                    message: l10n.saveNoteFirst,
                    type: NotificationType.warning,
                  );
                }
              },
              onDeleteTap: () => NoteEditorDialogs.showDeleteDialog(
                context: context,
                backgroundColor: coordinator.getBackgroundColor(context),
                textColor: finalTextColor,
                noteId: savedNoteId ?? note?.id,
              ),
              onBold: () {
                HapticFeedback.lightImpact();
                formattingController.showFormattingHint(
                  context,
                  coordinator.getBackgroundColor(context),
                  coordinator.textColor,
                  () => formattingController.wrapText(
                      coordinator.contentController, '**'),
                );
              },
              onItalic: () {
                HapticFeedback.lightImpact();
                formattingController.wrapText(
                    coordinator.contentController, '*');
              },
              onH1: () {
                HapticFeedback.lightImpact();
                formattingController.insertText(
                    coordinator.contentController, '# ');
              },
              onH2: () {
                HapticFeedback.lightImpact();
                formattingController.insertText(
                    coordinator.contentController, '## ');
              },
              onList: () {
                HapticFeedback.lightImpact();
                formattingController.insertText(
                    coordinator.contentController, '• ');
              },
              onChecklist: () {
                HapticFeedback.lightImpact();
                formattingController.insertText(
                    coordinator.contentController, '☐ ');
              },
              onColorTap: () {
                HapticFeedback.mediumImpact();
                onColorPaletteTap();
              },
            ),
          ),
        ),
      ),
    );
  }
}
