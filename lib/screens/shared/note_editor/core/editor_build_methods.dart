// Copyright © 2025 Apex Flow Group. All rights reserved.

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
import 'package:apex_note/screens/shared/note_editor/handlers/editor_dialog_handlers.dart';
import 'package:apex_note/screens/shared/note_editor/widgets/checklist_editor_widget.dart';
import 'package:apex_note/screens/shared/note_editor/widgets/code_editor_widget.dart';
import 'package:apex_note/services/code_export_service.dart';
import 'package:apex_note/services/code_preview_service.dart';
import 'package:apex_note/services/svg_service.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/common/custom_share_sheet.dart';
import 'package:apex_note/widgets/editor/apex_editor_header.dart';
import 'package:apex_note/widgets/editor/category_picker_sheet.dart';
import 'package:apex_note/widgets/editor/checklist_editor.dart';
import 'package:apex_note/widgets/editor/editor_selection_panel.dart';
import 'package:apex_note/widgets/editor/quill_editor_widget.dart';
import 'package:apex_note/widgets/editor/toolbars/editor_toolbar_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_quill/flutter_quill.dart';
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
    ValueChanged<double>? onScroll,
    bool readOnly = false,
    ValueNotifier<bool>? selectionBarActive,
  }) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const toolbarHeight = 60.0;
    const codeToolbarHeight = 110.0;
    final totalBottomSpace =
        (mode == NoteMode.code ? codeToolbarHeight : toolbarHeight) +
            bottomPadding +
            16;

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
        readOnly: readOnly,
        noteTitle: coordinator.stateManager.customTitle ?? note?.title,
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
        noteColor: coordinator.getBackgroundColor(context),
        fontSize: coordinator.fontSize,
        sidePadding: sidePadding,
        totalBottomSpace: totalBottomSpace,
        autoFocus: note == null && !readOnly,
        readOnly: readOnly,
        onScroll: onScroll,
        selectionBarActive: selectionBarActive ?? ValueNotifier(false),
      );
    }
  }

  /// Build header widget — حاوية واحدة تعرض الهيدر أو شريط التحديد
  static Widget buildHeader({
    required BuildContext context,
    required EditorCoordinator coordinator,
    required Color finalTextColor,
    required String currentTitle,
    required Note? note,
    required String? notePassword,
    required VoidCallback onReminderTap,
    required VoidCallback onHistoryTap,
    VoidCallback? onTitleTap,
    VoidCallback? onSaveTap,
    VoidCallback? onBackTap,
    required void Function(List<int>) onCategoryChanged,
    bool originallyLocked = false,
    ValueNotifier<double>? scrollProgress,
    bool isReadOnly = false,
    VoidCallback? onEditTap,
    ValueNotifier<bool>? selectionBarActive,
    QuillController? quillController,
    Future<void> Function()? onPaste,
  }) {
    final base = coordinator.getBackgroundColor(context);
    final isDark = base.computeLuminance() < 0.5;
    final scrolled = Color.alphaBlend(
      isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
      base,
    );

    Widget buildHeaderWidget(Color bg) => SafeArea(
          bottom: false,
          child: ApexEditorHeader(
            backgroundColor: bg,
            textColor: finalTextColor,
            title: currentTitle,
            isLocked: note?.isLocked == true || notePassword != null,
            hasHistory: note?.id != null,
            hasReminder: coordinator.stateManager.reminderDateTime != null,
            onReminderTap: isReadOnly
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    onReminderTap();
                  },
            onHistoryTap: onHistoryTap,
            onTitleTap: isReadOnly
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onTitleTap?.call();
                  },
            onSaveTap: isReadOnly
                ? null
                : () async {
                    HapticFeedback.mediumImpact();
                    onSaveTap?.call();
                  },
            onEditTap: isReadOnly
                ? () {
                    HapticFeedback.mediumImpact();
                    onEditTap?.call();
                  }
                : null,
            onBackTap: onBackTap,
            onCategoryTap: (isReadOnly || originallyLocked)
                ? null
                : () async {
                    final current = coordinator.stateManager.categoryIds;
                    final result = await CategoryPickerSheet.show(
                      context,
                      current,
                      isHiddenFromHome:
                          coordinator.stateManager.isHiddenFromHome,
                    );
                    if (result != null) {
                      onCategoryChanged(result['categoryIds'] as List<int>);
                      coordinator.stateManager.isHiddenFromHome =
                          result['isHiddenFromHome'] as bool;
                    }
                  },
          ),
        );

    Widget buildSelectionBar(Color bg) => (selectionBarActive != null &&
            quillController != null &&
            onPaste != null)
        ? SafeArea(
            bottom: false,
            child: EditorSelectionPanel(
              ctrl: quillController,
              backgroundColor: bg,
              textColor: finalTextColor,
              onPaste: onPaste,
              onDismiss: () => selectionBarActive.value = false,
            ),
          )
        : buildHeaderWidget(bg);

    Widget buildContainer(Color bg) => Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: selectionBarActive != null
              ? ValueListenableBuilder<bool>(
                  valueListenable: selectionBarActive,
                  builder: (_, isBarActive, __) => Stack(
                    children: [
                      // Header always present as base layer
                      AnimatedOpacity(
                        opacity: isBarActive ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: buildHeaderWidget(bg),
                      ),
                      // Selection bar overlays on top
                      if (isBarActive) buildSelectionBar(bg),
                    ],
                  ),
                )
              : buildHeaderWidget(bg),
        );

    if (scrollProgress == null) return buildContainer(base);
    return ValueListenableBuilder<double>(
      valueListenable: scrollProgress,
      builder: (_, progress, __) =>
          buildContainer(Color.lerp(base, scrolled, progress)!),
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
    ValueNotifier<bool>? selectionBarActive,
    Function(String)? onInsertSymbol,
    VoidCallback? onRebuild,
    ValueNotifier<double>? scrollProgress,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final base = coordinator.getBackgroundColor(context);
    final isDark = base.computeLuminance() < 0.5;
    final scrolled = Color.alphaBlend(
      isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
      base,
    );

    Widget buildWidget(Color bg) => AnimatedPositioned(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 16),
                child: child,
              ),
            ),
            child: Container(
              color: bg,
              child: SafeArea(
                top: false,
                child: EditorToolbarFactory.build(
                  mode: mode,
                  backgroundColor: bg,
                  textColor: finalTextColor,
                  undoController: coordinator.undoController,
                  detectedLanguage: coordinator.detectedLanguage,
                  selectionBarActive: selectionBarActive,
                  hasReminder:
                      coordinator.stateManager.reminderDateTime != null,
                  hasContent: coordinator.stateManager.hasContent,
                  showChecklist: note?.isLocked != true,
                  onUndo: coordinator.stateManager.canUndo
                      ? () {
                          HapticFeedback.lightImpact();
                          if (mode == NoteMode.checklist) {
                            coordinator.checklistUndoRedo?.undo();
                          } else if (mode == NoteMode.code) {
                            coordinator.codeUndoController.undo();
                          } else {
                            coordinator.quillController?.undo();
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
                            coordinator.quillController?.redo();
                          }
                        }
                      : null,
                  onLanguageChanged: (newLang) async {
                    String? normalizedLang;
                    if (newLang == 'Auto') {
                      normalizedLang = null;
                    } else {
                      normalizedLang = newLang;
                    }
                    coordinator.detectedLanguage = normalizedLang;
                    coordinator.isLanguageManuallySelected =
                        normalizedLang != null;
                    coordinator.stateManager.markDirty();
                    onRebuild?.call();
                  },
                  onInsertSymbol: onInsertSymbol,
                  onRunCode: coordinator.detectedLanguage != null
                      ? () async {
                          HapticFeedback.mediumImpact();
                          try {
                            final lang = coordinator.detectedLanguage!;
                            final code = coordinator.codeController!.text;
                            if (lang == 'SVG') {
                              await SvgService.previewSvgCode(context, code);
                            } else {
                              await CodePreviewService.preview(
                                  context, lang, code);
                            }
                          } catch (_) {}
                        }
                      : null,
                  onExportCode: () async {
                    HapticFeedback.mediumImpact();
                    final l10nSnap = AppLocalizations.of(context);
                    final title = coordinator
                        .getCurrentTitle(l10nSnap?.newNoteTitle ?? 'code');
                    final code = coordinator.codeController!.text;
                    final lang = coordinator.detectedLanguage;
                    try {
                      final path = await CodeExportService.saveToDownloads(
                        code: code,
                        language: lang,
                        fileName: title,
                      );
                      if (context.mounted) {
                        final fileName = path.split('/').last;
                        UnifiedNotificationService().show(
                          context: context,
                          message:
                              '${l10nSnap?.savedToDownloads ?? 'Saved'}: $fileName',
                          type: NotificationType.success,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        UnifiedNotificationService().show(
                          context: context,
                          message: 'Export failed: $e',
                          type: NotificationType.error,
                        );
                      }
                    }
                  },
                  onCalculate: () {
                    HapticFeedback.mediumImpact();
                    final dynamic calcController =
                        coordinator.quillController ??
                            coordinator.contentController;
                    smartController.showSmartCalculationResult(
                      context,
                      calcController,
                      l10n,
                    );
                  },
                  onPaste: selectionBarActive != null
                      ? () {
                          HapticFeedback.lightImpact();
                          selectionBarActive.value = !selectionBarActive.value;
                        }
                      : () async {
                          HapticFeedback.lightImpact();
                          final result = await coordinator.safePaste();
                          if (!context.mounted) return;
                          if (result.isEmpty) {
                            UnifiedNotificationService().show(
                              context: context,
                              message: l10n.clipboardEmpty,
                              type: NotificationType.info,
                              duration: const Duration(seconds: 2),
                            );
                          } else if (result.isTruncated) {
                            UnifiedNotificationService().show(
                              context: context,
                              message: l10n.clipboardTruncated,
                              type: NotificationType.warning,
                              duration: const Duration(seconds: 3),
                            );
                          }
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
                          ? QuillMigration.toPlainText(
                              coordinator.quillController!)
                          : coordinator.contentController.text;
                      text =
                          '${coordinator.getCurrentTitle(l10n.newNoteTitle)}\n\n$content';
                    }
                    CustomShareSheet.show(context, text,
                        subject:
                            coordinator.getCurrentTitle(l10n.newNoteTitle));
                  },
                  onArchiveTap: () async {
                    HapticFeedback.mediumImpact();
                    if (note?.id != null) {
                      // انتظر إغلاق الـ bottom sheet بالكامل
                      await Future.delayed(const Duration(milliseconds: 150));
                      if (!context.mounted) return;
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
                    final qc = coordinator.quillController;
                    if (qc != null) {
                      final isBold =
                          qc.getSelectionStyle().attributes['bold']?.value ==
                              true;
                      qc.formatSelection(isBold
                          ? Attribute.clone(Attribute.bold, null)
                          : Attribute.bold);
                    } else {
                      formattingController.wrapText(
                          coordinator.contentController, '**');
                    }
                  },
                  onItalic: () {
                    HapticFeedback.lightImpact();
                    final qc = coordinator.quillController;
                    if (qc != null) {
                      final isItalic =
                          qc.getSelectionStyle().attributes['italic']?.value ==
                              true;
                      qc.formatSelection(isItalic
                          ? Attribute.clone(Attribute.italic, null)
                          : Attribute.italic);
                    } else {
                      formattingController.wrapText(
                          coordinator.contentController, '*');
                    }
                  },
                  onH1: () {
                    HapticFeedback.lightImpact();
                    final qc = coordinator.quillController;
                    if (qc != null) {
                      final isH1 =
                          qc.getSelectionStyle().attributes['header']?.value ==
                              1;
                      qc.formatSelection(isH1
                          ? Attribute.clone(Attribute.h1, null)
                          : Attribute.h1);
                    } else {
                      formattingController.insertText(
                          coordinator.contentController, '# ');
                    }
                  },
                  onH2: () {
                    HapticFeedback.lightImpact();
                    final qc = coordinator.quillController;
                    if (qc != null) {
                      final isH2 =
                          qc.getSelectionStyle().attributes['header']?.value ==
                              2;
                      qc.formatSelection(isH2
                          ? Attribute.clone(Attribute.h2, null)
                          : Attribute.h2);
                    } else {
                      formattingController.insertText(
                          coordinator.contentController, '## ');
                    }
                  },
                  onList: () {
                    HapticFeedback.lightImpact();
                    final qc = coordinator.quillController;
                    if (qc != null) {
                      final isList =
                          qc.getSelectionStyle().attributes['list']?.value ==
                              'bullet';
                      qc.formatSelection(isList
                          ? Attribute.clone(Attribute.ul, null)
                          : Attribute.ul);
                    } else {
                      formattingController.insertText(
                          coordinator.contentController, '• ');
                    }
                  },
                  onChecklist: () {
                    HapticFeedback.lightImpact();
                    final qc = coordinator.quillController;
                    if (qc != null) {
                      final isCheck =
                          qc.getSelectionStyle().attributes['list']?.value ==
                              'unchecked';
                      qc.formatSelection(isCheck
                          ? Attribute.clone(Attribute.ul, null)
                          : const ListAttribute('unchecked'));
                    } else {
                      formattingController.insertText(
                          coordinator.contentController, '☐ ');
                    }
                  },
                  onColorTap: () {
                    HapticFeedback.mediumImpact();
                    final qc = coordinator.quillController;
                    if (qc != null) {
                      EditorDialogHandlers.showInlineColorPicker(
                        context: context,
                        backgroundColor:
                            coordinator.getBackgroundColor(context),
                        quillController: qc,
                      );
                    } else {
                      onColorPaletteTap();
                    }
                  },
                ),
              ),
            ),
          ),
        );

    if (scrollProgress == null) return buildWidget(base);
    return ValueListenableBuilder<double>(
      valueListenable: scrollProgress,
      builder: (_, progress, __) =>
          buildWidget(Color.lerp(base, scrolled, progress)!),
    );
  }
}
