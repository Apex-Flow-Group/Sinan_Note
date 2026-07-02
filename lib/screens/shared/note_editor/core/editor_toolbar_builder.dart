// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/core/utils/checklist_formatter.dart';
import 'package:sinan_note/core/utils/quill_migration.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/shared/note_editor/controllers/editor_formatting_controller.dart';
import 'package:sinan_note/screens/shared/note_editor/controllers/editor_smart_controller.dart';
import 'package:sinan_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:sinan_note/screens/shared/note_editor/dialogs/editor_dialogs.dart';
import 'package:sinan_note/screens/shared/note_editor/handlers/editor_dialog_handlers.dart';
import 'package:sinan_note/services/code_export_service.dart';
import 'package:sinan_note/services/code_preview_service.dart';
import 'package:sinan_note/services/svg_service.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/common/custom_share_sheet.dart';
import 'package:sinan_note/widgets/editor/markdown_viewer.dart';
import 'package:sinan_note/widgets/editor/toolbars/editor_toolbar_factory.dart';

class EditorToolbarBuilder {
  static Widget build({
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
                  isBoldActive: coordinator.quillController
                          ?.getSelectionStyle()
                          .attributes['bold']
                          ?.value ==
                      true,
                  isItalicActive: coordinator.quillController
                          ?.getSelectionStyle()
                          .attributes['italic']
                          ?.value ==
                      true,
                  isH1Active: coordinator.quillController
                          ?.getSelectionStyle()
                          .attributes['header']
                          ?.value ==
                      1,
                  isH2Active: coordinator.quillController
                          ?.getSelectionStyle()
                          .attributes['header']
                          ?.value ==
                      2,
                  isH3Active: coordinator.quillController
                          ?.getSelectionStyle()
                          .attributes['header']
                          ?.value ==
                      3,
                  isListActive: coordinator.quillController
                          ?.getSelectionStyle()
                          .attributes['list']
                          ?.value ==
                      'bullet',
                  isOrderedListActive: coordinator.quillController
                          ?.getSelectionStyle()
                          .attributes['list']
                          ?.value ==
                      'ordered',
                  isBlockquoteActive: coordinator.quillController
                          ?.getSelectionStyle()
                          .attributes['blockquote']
                          ?.value ==
                      true,
                  isUnderlineActive: coordinator.quillController
                          ?.getSelectionStyle()
                          .attributes['underline']
                          ?.value ==
                      true,
                  isStrikethroughActive: coordinator.quillController
                          ?.getSelectionStyle()
                          .attributes['strike']
                          ?.value ==
                      true,
                  isChecklistActive: coordinator.quillController
                          ?.getSelectionStyle()
                          .attributes['list']
                          ?.value ==
                      'unchecked',
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
                    coordinator.detectedLanguage =
                        newLang == 'Auto' ? null : newLang;
                    coordinator.isLanguageManuallySelected = newLang != 'Auto';
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
                            if (lang == 'Markdown') {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => DraggableScrollableSheet(
                                  initialChildSize: 0.85,
                                  maxChildSize: 0.95,
                                  minChildSize: 0.4,
                                  builder: (_, sc) => Container(
                                    decoration: BoxDecoration(
                                      color: coordinator
                                          .getBackgroundColor(context),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 12),
                                        Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: finalTextColor.withValues(
                                                alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            controller: sc,
                                            padding: const EdgeInsets.all(16),
                                            child: MarkdownViewer(
                                              content: code,
                                              textColor: finalTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else if (lang == 'SVG') {
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
                  onUnderline: () {
                    HapticFeedback.lightImpact();
                    final qc = coordinator.quillController;
                    if (qc == null) return;
                    final isUnderline =
                        qc.getSelectionStyle().attributes['underline']?.value ==
                            true;
                    qc.formatSelection(isUnderline
                        ? Attribute.clone(Attribute.underline, null)
                        : Attribute.underline);
                  },
                  onStrikethrough: () {
                    HapticFeedback.lightImpact();
                    final qc = coordinator.quillController;
                    if (qc == null) return;
                    final isStrike =
                        qc.getSelectionStyle().attributes['strike']?.value ==
                            true;
                    qc.formatSelection(isStrike
                        ? Attribute.clone(Attribute.strikeThrough, null)
                        : Attribute.strikeThrough);
                  },
                  onOrderedList: () {
                    HapticFeedback.lightImpact();
                    final qc = coordinator.quillController;
                    if (qc == null) return;
                    final isOrdered =
                        qc.getSelectionStyle().attributes['list']?.value ==
                            'ordered';
                    qc.formatSelection(isOrdered
                        ? Attribute.clone(Attribute.ol, null)
                        : Attribute.ol);
                  },
                  onBlockquote: () {
                    HapticFeedback.lightImpact();
                    final qc = coordinator.quillController;
                    if (qc == null) return;
                    final isQuote = qc
                            .getSelectionStyle()
                            .attributes['blockquote']
                            ?.value ==
                        true;
                    qc.formatSelection(isQuote
                        ? Attribute.clone(Attribute.blockQuote, null)
                        : Attribute.blockQuote);
                  },
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
                  onH3: () {
                    HapticFeedback.lightImpact();
                    final qc = coordinator.quillController;
                    if (qc != null) {
                      final isH3 =
                          qc.getSelectionStyle().attributes['header']?.value ==
                              3;
                      qc.formatSelection(isH3
                          ? Attribute.clone(Attribute.h3, null)
                          : Attribute.h3);
                    } else {
                      formattingController.insertText(
                          coordinator.contentController, '### ');
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
                  onAddItem: mode == NoteMode.checklist
                      ? () {
                          HapticFeedback.lightImpact();
                          coordinator.checklistAddItem?.call();
                        }
                      : null,
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
