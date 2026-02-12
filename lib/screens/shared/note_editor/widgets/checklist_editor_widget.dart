// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../widgets/editor/checklist_editor.dart';

/// Checklist editor widget with JSON-based task management
class ChecklistEditorWidget extends StatelessWidget {
  final TextEditingController contentController;
  final Color backgroundColor;
  final double totalBottomSpace;
  final Function(ChecklistUndoRedoController) onUndoRedoControllerCreated;
  final VoidCallback onUndoRedoChanged;
  final Function(String) onChecklistTitleChanged;
  final VoidCallback onContentChanged;

  const ChecklistEditorWidget({
    super.key,
    required this.contentController,
    required this.backgroundColor,
    required this.totalBottomSpace,
    required this.onUndoRedoControllerCreated,
    required this.onUndoRedoChanged,
    required this.onChecklistTitleChanged,
    required this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 80, bottom: totalBottomSpace),
      child: ChecklistEditor(
        initialContent: contentController.text,
        backgroundColor: backgroundColor,
        onUndoRedoControllerCreated: onUndoRedoControllerCreated,
        onUndoRedoChanged: onUndoRedoChanged,
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
