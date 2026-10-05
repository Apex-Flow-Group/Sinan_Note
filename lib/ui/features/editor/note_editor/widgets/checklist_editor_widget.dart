// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/ui/features/editor/widgets/checklist_editor.dart';
import 'package:sinan_note/ui/features/editor/widgets/checklist_undo_redo_controller.dart';

/// Checklist editor widget with JSON-based task management
class ChecklistEditorWidget extends StatelessWidget {
  final TextEditingController contentController;
  final Color backgroundColor;
  final double totalBottomSpace;
  final Function(ChecklistUndoRedoController) onUndoRedoControllerCreated;
  final VoidCallback onUndoRedoChanged;
  final Function(String) onChecklistTitleChanged;
  final ValueChanged<String> onContentChanged;

  /// المحتوى كما حمّله المحرر: يصبح مرجع "هل تغيّر شيء؟".
  final ValueChanged<String> onContentLoaded;
  final Function(VoidCallback addItem)? onAddItemCreated;
  final bool readOnly;
  final String? noteTitle; // ← العنوان الأصلي للنوتة

  const ChecklistEditorWidget({
    super.key,
    required this.contentController,
    required this.backgroundColor,
    required this.totalBottomSpace,
    required this.onUndoRedoControllerCreated,
    required this.onUndoRedoChanged,
    required this.onChecklistTitleChanged,
    required this.onContentChanged,
    required this.onContentLoaded,
    this.onAddItemCreated,
    this.readOnly = false,
    this.noteTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: readOnly
          ? EdgeInsets.zero
          : EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 52.0,
              bottom: totalBottomSpace,
            ),
      child: ChecklistEditor(
        initialContent: contentController.text,
        initialTitle: noteTitle,
        backgroundColor: backgroundColor,
        readOnly: readOnly,
        onUndoRedoControllerCreated: onUndoRedoControllerCreated,
        onUndoRedoChanged: onUndoRedoChanged,
        onAddItemCreated: onAddItemCreated,
        onTitleChanged: onChecklistTitleChanged,
        onChanged: (jsonContent) {
          contentController.text = jsonContent;
          onContentChanged(jsonContent);
        },
        onLoaded: (jsonContent) {
          contentController.text = jsonContent;
          onContentLoaded(jsonContent);
        },
      ),
    );
  }
}
