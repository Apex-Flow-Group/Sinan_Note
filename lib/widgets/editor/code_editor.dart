// Copyright © 2025 Apex Flow Group. All rights reserved.


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
import 'package:sinan_note/core/constants/app_text_styles.dart';

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

  static Mode? _resolveLanguage(String? lang) {
    if (lang == null) return null;
    switch (lang.toLowerCase()) {
      case 'python':
        return python;
      case 'javascript':
        return javascript;
      case 'typescript':
        return typescript;
      case 'java':
        return java;
      case 'dart':
        return dart;
      case 'html':
        return xml;
      case 'xml':
        return xml;
      case 'svg':
        return xml;
      case 'css':
        return css;
      case 'sql':
        return sql;
      case 'cpp':
      case 'c++':
      case 'c':
        return cpp;
      case 'go':
        return go;
      case 'rust':
        return rust;
      case 'kotlin':
        return kotlin;
      case 'swift':
        return swift;
      case 'php':
        return php;
      case 'ruby':
        return ruby;
      case 'bash':
      case 'shell':
        return bash;
      case 'json':
        return json;
      case 'yaml':
        return yaml;
      case 'lua':
        return lua;
      case 'dockerfile':
        return dockerfile;
      default:
        return null;
    }
  }

  /// قياس العرض الفعلي للنص باستخدام TextPainter — دقيق 100%
  static double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  double _calculateGutterWidth(String text) {
    final lineCount = text.split('\n').length;
    // نضيف هامش للتوقع — نحسب للرقم التالي في المرتبة (مثلاً 100 بدل 99)
    final digits = lineCount.toString().length;
    final nextOrderOfMagnitude = '9' * (digits + 1);
    const fontSize = AppFontSize.noteBody;
    const style = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: 1.5,
    );
    final textWidth = _measureTextWidth(nextOrderOfMagnitude, style);
    const packageDeduction = 32.0;
    const safetyBuffer = 12.0;
    return textWidth + packageDeduction + safetyBuffer;
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
    widget.controller.language = _resolveLanguage(lang);
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
}

