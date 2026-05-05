// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/screens/shared/note_editor/core/editor_coordinator.dart';
import 'package:flutter/material.dart';

class ReadOnlyChecklistView extends StatefulWidget {
  final EditorCoordinator coordinator;
  final Color textColor;
  final Color noteColor;
  final ScrollController scrollController;
  final Future<void> Function({bool isManualSave}) onSave;

  const ReadOnlyChecklistView({
    super.key,
    required this.coordinator,
    required this.textColor,
    required this.noteColor,
    required this.scrollController,
    required this.onSave,
  });

  @override
  State<ReadOnlyChecklistView> createState() => _ReadOnlyChecklistViewState();
}

class _ReadOnlyChecklistViewState extends State<ReadOnlyChecklistView> {
  void _save(List<ChecklistItem> updated) {
    final currentContent = widget.coordinator.contentController.text;
    String existingTitle = '';
    try {
      final decoded = jsonDecode(currentContent);
      if (decoded is Map && decoded.containsKey('title')) {
        existingTitle = (decoded['title'] as String?) ?? '';
      }
    } catch (_) {}

    if (existingTitle.isEmpty) {
      existingTitle = widget.coordinator.stateManager.customTitle ??
          widget.coordinator.stateManager.checklistTitle ??
          '';
    }

    final newJson = jsonEncode({
      'title': existingTitle,
      'items': updated.map((item) => item.toJson()).toList(),
    });

    widget.coordinator.contentController.text = newJson;
    widget.coordinator.stateManager.markDirty();
    widget.onSave(isManualSave: true);
  }

  @override
  Widget build(BuildContext context) {
    final items =
        ChecklistFormatter.parseJson(widget.coordinator.contentController.text);
    if (items.isEmpty) {
      return Text(widget.coordinator.contentController.text,
          style: TextStyle(fontSize: 16, color: widget.textColor));
    }

    final done = items.where((e) => e.isDone).length;
    final progress = done / items.length;

    return ScrollbarTheme(
      data: const ScrollbarThemeData(thickness: WidgetStatePropertyAll(0)),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(progress * 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor.withValues(alpha: 0.7))),
                Text('$done / ${items.length}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.textColor.withValues(alpha: 0.7))),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: widget.textColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? Colors.green : Colors.blue),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: Colors.transparent,
                  shadowColor: Colors.black26,
                  elevation: 10,
                  borderRadius: BorderRadius.circular(8),
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                });
                _save(items);
              },
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return ListTile(
                  key: ValueKey(item.id),
                  contentPadding: EdgeInsets.zero,
                  leading: ReorderableDragStartListener(
                    index: index,
                    child: Icon(Icons.drag_handle,
                        color: widget.textColor.withValues(alpha: 0.3)),
                  ),
                  title: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => items[index].isDone = !item.isDone);
                          _save(items);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: item.isDone
                                ? Colors.green
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: item.isDone
                                  ? Colors.green
                                  : widget.textColor.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: item.isDone
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.text.isEmpty ? '...' : item.text,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: item.isDone
                                ? widget.textColor.withValues(alpha: 0.5)
                                : widget.textColor,
                            decoration: item.isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
