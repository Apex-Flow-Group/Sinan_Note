// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../../models/note_mode.dart';
import '../smart_editor_toolbar.dart';
import '../code_editor_toolbar.dart';
import 'checklist_bottom_bar.dart';

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
    VoidCallback? onAlignLeft,
    VoidCallback? onAlignCenter,
    VoidCallback? onAlignRight,
    VoidCallback? onDirectionToggle,
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
          onInsertSymbol: onInsertSymbol!,
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
          onAlignLeft: onAlignLeft ?? () {},
          onAlignCenter: onAlignCenter ?? () {},
          onAlignRight: onAlignRight ?? () {},
          onDirectionToggle: onDirectionToggle ?? () {},
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
          onAlignLeft: onAlignLeft ?? () {},
          onAlignCenter: onAlignCenter ?? () {},
          onAlignRight: onAlignRight ?? () {},
          onDirectionToggle: onDirectionToggle ?? () {},
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
  final VoidCallback onAlignLeft;
  final VoidCallback onAlignCenter;
  final VoidCallback onAlignRight;
  final VoidCallback onDirectionToggle;

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
    required this.onAlignLeft,
    required this.onAlignCenter,
    required this.onAlignRight,
    required this.onDirectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                    showMenu(
                      context: context,
                      position: position,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2D2D2D)
                          : Colors.white,
                      elevation: 8,
                      items: [
                        PopupMenuItem(
                          value: 'reminder',
                          child: Row(
                            children: [
                              Icon(
                                hasReminder
                                    ? Icons.alarm_on_rounded
                                    : Icons.alarm_add_rounded,
                                size: 20,
                                color: hasReminder ? Colors.orange : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                hasReminder ? 'Edit Reminder' : 'Add Reminder',
                                style: TextStyle(
                                  color: hasReminder ? Colors.orange : null,
                                  fontWeight: hasReminder
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share',
                          enabled: hasContent,
                          child: Row(
                            children: [
                              Icon(Icons.share_outlined,
                                  size: 20,
                                  color: hasContent ? null : Colors.grey),
                              const SizedBox(width: 12),
                              Text(l10n.actionShare,
                                  style: TextStyle(
                                      color: hasContent ? null : Colors.grey)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'archive',
                          enabled: hasContent,
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined,
                                  size: 20,
                                  color: hasContent ? null : Colors.grey),
                              const SizedBox(width: 12),
                              Text(l10n.actionArchive,
                                  style: TextStyle(
                                      color: hasContent ? null : Colors.grey)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          enabled: hasContent,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: hasContent ? Colors.red : Colors.grey,
                                  size: 20),
                              const SizedBox(width: 12),
                              Text(l10n.actionDelete,
                                  style: TextStyle(
                                      color: hasContent
                                          ? Colors.red
                                          : Colors.grey)),
                            ],
                          ),
                        ),
                      ],
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
