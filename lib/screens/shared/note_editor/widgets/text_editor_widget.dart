// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/editor/editor_state_manager.dart';
import 'package:apex_note/controllers/editor/text_direction_controller.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Simple text editor widget with bidirectional text support
class TextEditorWidget extends StatefulWidget {
  final TextEditingController contentController;
  final UndoHistoryController undoController;
  final FocusNode focusNode;
  final TextDirectionController textDirectionController;
  final EditorStateManager stateManager;
  final Color backgroundColor;
  final Color textColor;
  final Color hintColor;
  final double fontSize;
  final double sidePadding;
  final double totalBottomSpace;
  final DateTime? reminderDateTime;
  final VoidCallback? onReminderTap;
  final VoidCallback? onReminderRemove;
  final VoidCallback? onReminderEdit;
  final bool autoFocus;

  const TextEditorWidget({
    super.key,
    required this.contentController,
    required this.undoController,
    required this.focusNode,
    required this.textDirectionController,
    required this.stateManager,
    required this.backgroundColor,
    required this.textColor,
    required this.hintColor,
    required this.fontSize,
    required this.sidePadding,
    required this.totalBottomSpace,
    this.reminderDateTime,
    this.onReminderTap,
    this.onReminderRemove,
    this.onReminderEdit,
    this.autoFocus = false,
  });

  @override
  State<TextEditorWidget> createState() => _TextEditorWidgetState();
}

class _TextEditorWidgetState extends State<TextEditorWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!widget.focusNode.hasFocus) {
          widget.focusNode.requestFocus();
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 80,
          bottom: widget.totalBottomSpace,
          left: widget.sidePadding,
          right: widget.sidePadding,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 180,
          ),
          child: TextField(
            controller: widget.contentController,
            undoController: widget.undoController,
            focusNode: widget.focusNode,
            scrollPadding: const EdgeInsets.only(bottom: 120.0),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: widget.fontSize,
              height: 1.5,
              color: widget.textColor,
            ),
            cursorColor: widget.textColor.withValues(alpha: 0.8),
            cursorWidth: 2.5,
            cursorRadius: const Radius.circular(2),
            decoration: InputDecoration(
              hintText: l10n.startWriting,
              hintStyle: TextStyle(color: widget.hintColor),
              border: InputBorder.none,
            ),
            maxLines: null,
            autofocus: widget.autoFocus,
          ),
        ),
      ),
    );
  }
}
