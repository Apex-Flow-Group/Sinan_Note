// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

import '../../../models/note.dart';
import '../../../models/note_mode.dart';
import '../../../services/notes_provider.dart';
import '../../../services/notification_service.dart';
import '../../../utils/checklist_formatter.dart';
import '../../../widgets/apex_snackbar.dart';
import '../../../widgets/custom_share_sheet.dart';
import '../../../widgets/editor/apex_editor_header.dart';
import '../../../widgets/editor/toolbars/editor_toolbar_factory.dart';
import '../../../widgets/editor/checklist_editor.dart';
import '../controllers/editor_smart_controller.dart';
import '../controllers/editor_formatting_controller.dart';
import '../dialogs/editor_dialogs.dart';
import '../widgets/text_editor_widget.dart';
import '../widgets/code_editor_widget.dart';
import '../widgets/checklist_editor_widget.dart';
import './editor_coordinator.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const toolbarHeight = 60.0;
    final totalBottomSpace = toolbarHeight + bottomPadding + 16;

    if (mode == NoteMode.code) {
      return CodeEditorWidget(
        codeController: coordinator.codeController,
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
      return TextEditorWidget(
        contentController: coordinator.contentController,
        undoController: coordinator.undoController,
        focusNode: coordinator.textFieldFocusNode,
        textDirectionController: coordinator.textDirectionController,
        stateManager: coordinator.stateManager,
        backgroundColor: coordinator.getBackgroundColor(context),
        textColor: finalTextColor,
        hintColor: finalHintColor,
        fontSize: coordinator.fontSize,
        sidePadding: sidePadding,
        totalBottomSpace: totalBottomSpace,
        reminderDateTime: coordinator.stateManager.reminderDateTime,
        onReminderTap: onReminderTap,
        onReminderRemove: () async {
          debugPrint('🔴 CLOSE BUTTON PRESSED!');
          HapticFeedback.lightImpact();
          coordinator.stateManager.reminderDateTime = null;
          coordinator.stateManager.recurrenceRule = null;
          coordinator.stateManager.markDirty();
          
          if (savedNoteId != null || note?.id != null) {
            await NotificationService().cancelNotification(savedNoteId ?? note!.id!);
          }
          await saveCallback(isManualSave: true);
          if (context.mounted) {
            ApexSnackBar.show(
              context,
              l10n.reminderRemoved,
              type: SnackBarType.info,
            );
          }
        },
        onReminderEdit: onReminderTap,
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
                backgroundColor: coordinator.getBackgroundColor(context).withValues(alpha: 0.7),
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
                final normalizedLang = newLang == 'Auto' ? null : newLang;
                coordinator.detectedLanguage = normalizedLang;
                coordinator.isLanguageManuallySelected = normalizedLang != null;
                coordinator.stateManager.markDirty();
              },
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
                  text = coordinator.codeController.text;
                } else if (mode == NoteMode.checklist) {
                  text = ChecklistFormatter.formatForSharing(
                      coordinator.getCurrentTitle(l10n.newNoteTitle), 
                      coordinator.contentController.text);
                } else {
                  text = '${coordinator.getCurrentTitle(l10n.newNoteTitle)}\n\n${coordinator.contentController.text}';
                }
                CustomShareSheet.show(context, text, subject: coordinator.getCurrentTitle(l10n.newNoteTitle));
              },
              onArchiveTap: () async {
                HapticFeedback.mediumImpact();
                if (note?.id != null) {
                  final provider = Provider.of<NotesProvider>(context, listen: false);
                  await provider.archiveNote(note!.id!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ApexSnackBar.show(context, l10n.movedToArchive,
                        type: SnackBarType.success);
                  }
                } else {
                  ApexSnackBar.show(context, l10n.saveNoteFirst,
                      type: SnackBarType.warning);
                }
              },
              onDeleteTap: () => EditorDialogs.showDeleteDialog(
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
                  () => formattingController.wrapText(coordinator.contentController, '**'),
                );
              },
              onItalic: () {
                HapticFeedback.lightImpact();
                formattingController.wrapText(coordinator.contentController, '*');
              },
              onH1: () {
                HapticFeedback.lightImpact();
                formattingController.insertText(coordinator.contentController, '# ');
              },
              onH2: () {
                HapticFeedback.lightImpact();
                formattingController.insertText(coordinator.contentController, '## ');
              },
              onList: () {
                HapticFeedback.lightImpact();
                formattingController.insertText(coordinator.contentController, '• ');
              },
              onChecklist: () {
                HapticFeedback.lightImpact();
                formattingController.insertText(coordinator.contentController, '☐ ');
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
