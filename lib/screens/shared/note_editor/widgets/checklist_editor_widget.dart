// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sinan_note/widgets/editor/checklist_editor.dart';
import 'package:sinan_note/widgets/editor/checklist_undo_redo_controller.dart';

/// Checklist editor widget with JSON-based task management
class ChecklistEditorWidget extends StatelessWidget {
  final TextEditingController contentController;
  final Color backgroundColor;
  final double totalBottomSpace;
  final Function(ChecklistUndoRedoController) onUndoRedoControllerCreated;
  final VoidCallback onUndoRedoChanged;
  final Function(String) onChecklistTitleChanged;
  final VoidCallback onContentChanged;
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
        onChanged: (jsonContent) {
          contentController.text = jsonContent;
          onContentChanged();

          try {
            final decoded = jsonDecode(jsonContent);
            if (decoded is Map && decoded['title'] != null) {
              onChecklistTitleChanged(decoded['title']);
            }
          } catch (e) {
            // Invalid JSON, ignore
          }
        },
      ),
    );
  }
}
