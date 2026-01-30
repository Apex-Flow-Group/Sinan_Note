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
            maxWidth: 800,
            minHeight: MediaQuery.of(context).size.height - 180,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (reminderDateTime != null) _buildReminderBanner(context, l10n),
              _buildTextField(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderBanner(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.alarm, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onReminderTap,
                child: Text(
                  _getTimeRemaining(reminderDateTime!),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Colors.orange,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onReminderRemove,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: Colors.orange,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onReminderEdit,
            ),
          ],
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

  String _getTimeRemaining(DateTime reminderTime) {
    final now = DateTime.now();
    final difference = reminderTime.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    }
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}
