// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/highlight_core.dart' show Mode;
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/dockerfile.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/lua.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/ruby.dart';
import 'package:highlight/languages/rust.dart';
import 'package:highlight/languages/sql.dart';
import 'package:highlight/languages/swift.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/yaml.dart';

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
  late double _gutterWidth;

  // تحويل اسم اللغة إلى Mode مناسب لـ highlight
  static Mode? _resolveLanguage(String? lang) {
    if (lang == null) return null;
    switch (lang.toLowerCase()) {
      case 'python':       return python;
      case 'javascript':   return javascript;
      case 'typescript':   return typescript;
      case 'java':         return java;
      case 'dart':         return dart;
      case 'html':         return xml;   // HTML → xml mode
      case 'xml':          return xml;
      case 'svg':          return xml;   // SVG → xml mode (same syntax)
      case 'css':          return css;
      case 'sql':          return sql;
      case 'cpp':
      case 'c++':
      case 'c':            return cpp;
      case 'go':           return go;
      case 'rust':         return rust;
      case 'kotlin':       return kotlin;
      case 'swift':        return swift;
      case 'php':          return php;
      case 'ruby':         return ruby;
      case 'bash':
      case 'shell':        return bash;
      case 'json':         return json;
      case 'yaml':         return yaml;
      case 'lua':          return lua;
      case 'dockerfile':   return dockerfile;
      default:             return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _gutterWidth = _calculateGutterWidth(widget.controller.text);
    widget.controller.addListener(_onTextChanged);
    _applyLanguage(widget.detectedLanguage);
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detectedLanguage != widget.detectedLanguage) {
      _applyLanguage(widget.detectedLanguage);
    }
  }

  void _applyLanguage(String? lang) {
    final mode = _resolveLanguage(lang);
    // flutter_code_editor 0.3.x: language property على الـ controller
    widget.controller.language = mode;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final newWidth = _calculateGutterWidth(widget.controller.text);
    if (newWidth != _gutterWidth) {
      setState(() => _gutterWidth = newWidth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.backgroundColor.computeLuminance() < 0.5;
    final theme = _buildTheme(isDark);
    final textColor = isDark ? Colors.white : Colors.black87;
    final gutterColor = isDark ? Colors.white38 : Colors.black38;
    const systemFontSize = AppFontSize.noteBody;

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
            fontSize: systemFontSize,
            height: 1.5,
            color: textColor,
          ),
          gutterStyle: GutterStyle(
            showLineNumbers: true,
            showFoldingHandles: false,
            showErrors: false,
            textStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: systemFontSize,
              height: 1.5,
              color: gutterColor,
            ),
            background: Colors.transparent,
            margin: 8,
            width: _gutterWidth,
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

  /// حساب عرض منطقة الأرقام حسب عدد الأسطر
  double _calculateGutterWidth(String text) {
    final lineCount = text.split('\n').length;
    if (lineCount < 10) return 50;        // 1-9: 50px
    if (lineCount < 100) return 60;       // 10-99: 60px
    if (lineCount < 1000) return 70;      // 100-999: 70px
    return 80;                             // 1000+: 80px
  }
}
