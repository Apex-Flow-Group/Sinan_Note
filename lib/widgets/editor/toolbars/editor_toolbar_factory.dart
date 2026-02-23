// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/widgets/editor/code_editor_toolbar.dart';
import 'package:apex_note/widgets/editor/smart_editor_toolbar.dart';
import 'package:apex_note/widgets/editor/toolbars/checklist_bottom_bar.dart';
import 'package:apex_note/widgets/editor/toolbars/editor_options_menu.dart';
import 'package:flutter/material.dart';

class EditorToolbarFactory {
  static Widget build({
    required NoteMode mode,
    required Color backgroundColor,
    required Color textColor,
    required UndoHistoryController undoController,
    String? detectedLanguage,
    bool hasReminder = false,
    bool hasContent = false,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    VoidCallback? onCalculate,
    VoidCallback? onBackgroundColorTap,
    VoidCallback? onReminderTap,
    VoidCallback? onShareTap,
    VoidCallback? onArchiveTap,
    VoidCallback? onDeleteTap,
    VoidCallback? onBold,
    VoidCallback? onItalic,
    VoidCallback? onH1,
    VoidCallback? onH2,
    VoidCallback? onList,
    VoidCallback? onChecklist,
    VoidCallback? onColorTap,
    Function(String)? onInsertSymbol,
    VoidCallback? onRunCode,
    VoidCallback? onExportCode,
    Function(String)? onLanguageChanged,
  }) {
    switch (mode) {
      case NoteMode.code:
        return CodeEditorToolbar(
          backgroundColor: Colors.transparent,
          textColor: textColor,
          onInsertSymbol: onInsertSymbol ?? (_) {},
          onUndo: onUndo,
          onRedo: onRedo,
          onRunCode: onRunCode,
          onExportCode: onExportCode,
          onBackgroundColorTap: onBackgroundColorTap ?? () {},
          detectedLanguage: detectedLanguage,
          onLanguageChanged: onLanguageChanged,
        );

      case NoteMode.checklist:
        return ChecklistBottomBar(
          backgroundColor: backgroundColor,
          textColor: textColor,
          hasContent: hasContent,
          onUndo: onUndo,
          onRedo: onRedo,
          onBackgroundColorTap: onBackgroundColorTap ?? () {},
          onReminderTap: onReminderTap,
          onShareTap: onShareTap ?? () {},
          onArchiveTap: onArchiveTap ?? () {},
          onDeleteTap: onDeleteTap ?? () {},
        );

      case NoteMode.simple:
        return _SimpleToolbar(
          backgroundColor: backgroundColor,
          textColor: textColor,
          hasReminder: hasReminder,
          hasContent: hasContent,
          onUndo: onUndo,
          onRedo: onRedo,
          onCalculate: onCalculate ?? () {},
          onBackgroundColorTap: onBackgroundColorTap ?? () {},
          onReminderTap: onReminderTap ?? () {},
          onShareTap: onShareTap ?? () {},
          onArchiveTap: onArchiveTap ?? () {},
          onDeleteTap: onDeleteTap ?? () {},
        );

      case NoteMode.rich:
      case NoteMode.reminder:
        return SmartEditorToolbar(
          backgroundColor: Colors.transparent,
          textColor: textColor,
          hasReminder: hasReminder,
          hasContent: hasContent,
          onUndo: onUndo,
          onRedo: onRedo,
          onCalculate: onCalculate ?? () {},
          onBackgroundColorTap: onBackgroundColorTap ?? () {},
          onReminderTap: onReminderTap ?? () {},
          onShareTap: onShareTap ?? () {},
          onArchiveTap: onArchiveTap ?? () {},
          onDeleteTap: onDeleteTap ?? () {},
          onBold: onBold ?? () {},
          onItalic: onItalic ?? () {},
          onH1: onH1 ?? () {},
          onH2: onH2 ?? () {},
          onList: onList ?? () {},
          onChecklist: onChecklist ?? () {},
          onColorTap: onColorTap ?? () {},
        );
    }
  }
}

// Simple toolbar without formatting buttons
class _SimpleToolbar extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final bool hasReminder;
  final bool hasContent;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onCalculate;
  final VoidCallback onBackgroundColorTap;
  final VoidCallback onReminderTap;
  final VoidCallback onShareTap;
  final VoidCallback onArchiveTap;
  final VoidCallback onDeleteTap;

  const _SimpleToolbar({
    required this.backgroundColor,
    required this.textColor,
    required this.hasReminder,
    required this.hasContent,
    required this.onUndo,
    required this.onRedo,
    required this.onCalculate,
    required this.onBackgroundColorTap,
    required this.onReminderTap,
    required this.onShareTap,
    required this.onArchiveTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
            top:
                BorderSide(color: textColor.withValues(alpha: 0.08), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildIconBtn(Icons.calculate_outlined, onCalculate),
                _buildIconBtn(Icons.palette_outlined, onBackgroundColorTap),
                _buildIconBtn(Icons.undo_rounded, onUndo),
                _buildIconBtn(Icons.redo_rounded, onRedo),
              ],
            ),
            Builder(
              builder: (ctx) => Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final RenderBox button =
                        ctx.findRenderObject() as RenderBox;
                    final RenderBox overlay = Overlay.of(context)
                        .context
                        .findRenderObject() as RenderBox;
                    final RelativeRect position = RelativeRect.fromRect(
                      Rect.fromPoints(
                        button.localToGlobal(Offset.zero, ancestor: overlay),
                        button.localToGlobal(
                            button.size.bottomRight(Offset.zero),
                            ancestor: overlay),
                      ),
                      Offset.zero & overlay.size,
                    );
                    EditorOptionsMenu.show(
                      context: context,
                      position: position,
                      hasContent: hasContent,
                      showReminder: true,
                    ).then((value) {
                      if (value == 'reminder') {
                        onReminderTap();
                      } else if (value == 'share') {
                        onShareTap();
                      } else if (value == 'archive') {
                        onArchiveTap();
                      } else if (value == 'delete') {
                        onDeleteTap();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: textColor.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Icon(Icons.more_vert_rounded,
                        color: textColor, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback? onTap) {
    final effectiveColor = onTap == null ? Colors.grey : textColor;
    return IconButton(
      icon: Icon(icon, color: effectiveColor, size: 22),
      onPressed: onTap,
      splashRadius: 24,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
