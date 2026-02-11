// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../../controllers/editor/text_direction_controller.dart';
import '../../../controllers/editor/editor_state_manager.dart';

/// Simple text editor widget with bidirectional text support
class TextEditorWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 80,
          bottom: totalBottomSpace,
          left: sidePadding,
          right: sidePadding,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 180,
          ),
          child: _buildTextField(context, l10n),
        ),
      ),
    );
  }



  Widget _buildTextField(BuildContext context, AppLocalizations l10n) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: contentController,
      builder: (context, value, child) {
        // Use TextDirectionController for accurate direction detection
        final direction = textDirectionController.detectParagraphDirection(value.text);
        final isRtl = direction == TextDirection.rtl;
        
        return TextField(
          controller: contentController,
          undoController: undoController,
          focusNode: focusNode,
          scrollPadding: const EdgeInsets.only(bottom: 120.0),
          onTap: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final text = contentController.text;
              final selection = contentController.selection;
              if (selection.baseOffset > text.length) {
                contentController.selection = TextSelection.collapsed(
                  offset: text.length,
                );
              }
            });
          },
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          textDirection: direction,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.5,
            color: textColor,
          ),
          cursorColor: textColor.withValues(alpha: 0.8),
          cursorWidth: 2.5,
          cursorRadius: const Radius.circular(2),
          decoration: InputDecoration(
            hintText: l10n.startWriting,
            hintStyle: TextStyle(color: hintColor),
            border: InputBorder.none,
          ),
          maxLines: null,
          autofocus: autoFocus,
        );
      },
    );
  }


}
