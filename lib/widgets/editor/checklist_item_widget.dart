// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/text_direction_utils.dart';
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
  final bool readOnly;
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
    this.readOnly = false,
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
  late TextDirection _textDirection;

  @override
  void initState() {
    super.initState();
    _textDirection = TextDirectionUtils.getDirection(widget.controller.text);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final newDir = TextDirectionUtils.getDirection(widget.controller.text);
    if (newDir != _textDirection) {
      setState(() => _textDirection = newDir);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDone = widget.item.isDone;

    return Container(
      margin: widget.readOnly
          ? const EdgeInsets.symmetric(vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: widget.readOnly
          ? null
          : BoxDecoration(
              color: widget.backgroundColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDone
                    ? Colors.transparent
                    : widget.textColor.withValues(alpha: 0.2),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.showControls && !widget.readOnly)
            IconButton(
              icon: Icon(Icons.add_circle_outline,
                  color: widget.textColor.withValues(alpha: 0.6), size: 20),
              onPressed: widget.onAddBelow,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          if (widget.showControls && !widget.readOnly)
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
              textDirection: _textDirection,
              textAlign: _textDirection == TextDirection.rtl
                  ? TextAlign.right
                  : TextAlign.left,
              textAlignVertical: TextAlignVertical.center,
              maxLines: null,
              readOnly: widget.readOnly,
              textInputAction: TextInputAction.newline,
              onSubmitted: widget.readOnly ? null : (_) => widget.onSubmitted?.call(),
              onChanged: widget.readOnly ? null : widget.onTextChanged,
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
                hintText: widget.readOnly ? null : l10n.checklistItemHint,
                hintStyle: TextStyle(color: widget.textColor.withValues(alpha: 0.4)),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: widget.readOnly ? 4 : 12,
                ),
              ),
            ),
          ),
          if (widget.showControls && widget.canDelete && !widget.readOnly)
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
