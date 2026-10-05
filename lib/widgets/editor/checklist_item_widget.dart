// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/domain/text/checklist.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/direction/text_direction.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';

/// Standalone widget for rendering a single checklist item.
///
/// Gestures:
/// - Tap checkbox → toggle done
/// - Long press → activate drag-to-reorder (handled by parent ReorderableList)
/// - Swipe right → delete (handled by parent Dismissible)
class ChecklistItemWidget extends StatefulWidget {
  final ChecklistItem item;
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color textColor;
  final Color backgroundColor;
  final bool showControls;
  final bool readOnly;
  final VoidCallback? onToggleDone;
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
    this.readOnly = false,
    this.onToggleDone,
    this.onTextChanged,
    this.onSubmitted,
  });

  @override
  State<ChecklistItemWidget> createState() => _ChecklistItemWidgetState();
}

class _ChecklistItemWidgetState extends State<ChecklistItemWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  TextDirection _textDirection = TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    _textDirection = directionOf(widget.controller.text);
    widget.controller.addListener(_updateDirection);
  }

  @override
  void didUpdateWidget(covariant ChecklistItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateDirection);
      widget.controller.addListener(_updateDirection);
      _textDirection = directionOf(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateDirection);
    super.dispose();
  }

  void _updateDirection() {
    final newDir = directionOf(widget.controller.text);
    if (newDir != _textDirection) {
      setState(() => _textDirection = newDir);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final isDone = widget.item.isDone;

    final content = Container(
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
          // Checkbox
          GestureDetector(
            onTap: widget.onToggleDone,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone ? context.colors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDone
                        ? context.colors.success
                        : widget.textColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: isDone
                    ? Icon(Icons.check, size: 16, color: context.scheme.surface)
                    : null,
              ),
            ),
          ),
          // Text field
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
              onSubmitted:
                  widget.readOnly ? null : (_) => widget.onSubmitted?.call(),
              onChanged: widget.readOnly ? null : widget.onTextChanged,
              style: TextStyle(
                fontSize: context.text.bodyLarge?.fontSize,
                decoration:
                    isDone ? TextDecoration.lineThrough : TextDecoration.none,
                color: isDone
                    ? widget.textColor.withValues(alpha: 0.5)
                    : widget.textColor,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.readOnly ? null : l10n.checklistItemHint,
                hintStyle:
                    TextStyle(color: widget.textColor.withValues(alpha: 0.4)),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: widget.readOnly ? 4 : 12,
                ),
              ),
            ),
          ),
          // Long-press drag handle hint (visible only in edit mode)
          if (widget.showControls && !widget.readOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.drag_indicator,
                size: 18,
                color: widget.textColor.withValues(alpha: 0.25),
              ),
            ),
        ],
      ),
    );

    // Wrap with ReorderableDragStartListener using long press
    if (widget.showControls && !widget.readOnly) {
      return ReorderableDelayedDragStartListener(
        index: widget.index,
        child: content,
      );
    }

    return content;
  }
}
