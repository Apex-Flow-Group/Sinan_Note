// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Standalone widget for rendering a single checklist item
/// Can be reused in different contexts (editor, preview, widget, etc.)
class ChecklistItemWidget extends StatefulWidget {
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
  State<ChecklistItemWidget> createState() => _ChecklistItemWidgetState();
}

class _ChecklistItemWidgetState extends State<ChecklistItemWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDone = widget.item.isDone;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: widget.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? Colors.transparent : widget.textColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showControls)
            IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: widget.textColor.withValues(alpha: 0.6), size: 20),
              onPressed: widget.onAddBelow,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          if (widget.showControls)
            ReorderableDragStartListener(
              index: widget.index,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 4, right: 8, top: 12, bottom: 12),
                child: Icon(Icons.drag_indicator,
                    color: widget.textColor.withValues(alpha: 0.4), size: 20),
              ),
            ),
          GestureDetector(
            onTap: widget.onToggleDone,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDone ? Colors.green : widget.textColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              textAlignVertical: TextAlignVertical.center,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => widget.onSubmitted?.call(),
              onChanged: widget.onTextChanged,
              style: TextStyle(
                fontSize: 16,
                decoration: isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: isDone
                    ? widget.textColor.withValues(alpha: 0.5)
                    : widget.textColor,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: l10n.checklistItemHint,
                hintStyle: TextStyle(color: widget.textColor.withValues(alpha: 0.4)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (widget.showControls && widget.canDelete)
            IconButton(
              icon: Icon(Icons.close,
                  size: 18, color: widget.textColor.withValues(alpha: 0.4)),
              onPressed: widget.onDelete,
            ),
        ],
      ),
    );
  }
}
