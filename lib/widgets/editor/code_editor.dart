// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';

class CodeEditor extends StatefulWidget {
  final CodeController controller;
  final UndoHistoryController undoController;
  final String? detectedLanguage;
  final Color backgroundColor;
  final FocusNode? focusNode;

  const CodeEditor({
    super.key,
    required this.controller,
    required this.undoController,
    this.detectedLanguage,
    this.backgroundColor = Colors.white,
    this.focusNode,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.backgroundColor.computeLuminance() < 0.5;
    final theme = _buildTheme(isDark);
    final textColor = isDark ? Colors.white : Colors.black87;
    final gutterColor = isDark ? Colors.white38 : Colors.black38;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: CodeTheme(
        data: CodeThemeData(styles: theme),
        child: CodeField(
          controller: widget.controller,
          undoController: widget.undoController,
          focusNode: widget.focusNode,
          textStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.5,
            color: textColor,
          ),
          gutterStyle: GutterStyle(
            showLineNumbers: true,
            showFoldingHandles: false,
            showErrors: false,
            textStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: gutterColor,
            ),
            background: Colors.transparent,
            margin: 8,
            width: 60,
          ),
          background: Colors.transparent,
          expands: true,
          wrap: false,
        ),
      ),
    );
  }

  Map<String, TextStyle> _buildTheme(bool isDark) {
    final baseTheme = isDark
        ? Map<String, TextStyle>.from(monokaiSublimeTheme)
        : Map<String, TextStyle>.from(githubTheme);
    baseTheme['root'] = TextStyle(
      backgroundColor: Colors.transparent,
      color: isDark ? Colors.white : Colors.black87,
    );
    return baseTheme;
  }
}
