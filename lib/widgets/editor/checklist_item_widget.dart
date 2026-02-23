// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

/// Standalone widget for rendering a single checklist item
/// Can be reused in different contexts (editor, preview, widget, etc.)
class ChecklistItemWidget extends StatelessWidget {
  final ChecklistItem item;
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color textColor;
  final Color backgroundColor;
  final bool showControls;
  final bool canDelete;
  final VoidCallback? onToggleDone;
  final VoidCallback? onDelete;
  final VoidCallback? onAddBelow;
  final ValueChanged<String>? onTextChanged;
  final VoidCallback? onSubmitted;

  const ChecklistItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.textColor,
    required this.backgroundColor,
    this.showControls = true,
    this.canDelete = true,
    this.onToggleDone,
    this.onDelete,
    this.onAddBelow,
    this.onTextChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDone = item.isDone;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? Colors.transparent : textColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showControls)
            IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: textColor.withValues(alpha: 0.6), size: 20),
              onPressed: onAddBelow,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          if (showControls)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 4, right: 8, top: 12, bottom: 12),
                child: Icon(Icons.drag_indicator,
                    color: textColor.withValues(alpha: 0.4), size: 20),
              ),
            ),
          GestureDetector(
            onTap: onToggleDone,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDone ? Colors.green : textColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final isRtl = value.text.isNotEmpty &&
                    Bidi.detectRtlDirectionality(value.text);
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  textAlignVertical: TextAlignVertical.center,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onSubmitted: (_) => onSubmitted?.call(),
                  onChanged: onTextChanged,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: isDone
                        ? textColor.withValues(alpha: 0.5)
                        : textColor,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l10n.checklistItemHint,
                    hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                );
              },
            ),
          ),
          if (showControls && canDelete)
            IconButton(
              icon: Icon(Icons.close,
                  size: 18, color: textColor.withValues(alpha: 0.4)),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
