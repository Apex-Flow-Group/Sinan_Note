// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/widgets/editor/code_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

/// Professional code editor widget with syntax highlighting
class CodeEditorWidget extends StatelessWidget {
  final CodeController codeController;
  final UndoHistoryController undoController;
  final FocusNode focusNode;
  final String? detectedLanguage;
  final Color backgroundColor;
  final double totalBottomSpace;

  const CodeEditorWidget({
    super.key,
    required this.codeController,
    required this.undoController,
    required this.focusNode,
    required this.backgroundColor,
    required this.totalBottomSpace,
    this.detectedLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!focusNode.hasFocus) {
          focusNode.requestFocus();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(top: 80, bottom: totalBottomSpace),
        child: CodeEditor(
          controller: codeController,
          undoController: undoController,
          detectedLanguage: detectedLanguage,
          backgroundColor: backgroundColor,
          focusNode: focusNode,
        ),
      ),
    );
  }
}
