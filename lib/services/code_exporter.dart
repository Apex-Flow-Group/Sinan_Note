// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum CodeLanguage {
  python,
  javascript,
  java,
  dart,
  html,
  css,
  sql,
  cpp,
  c,
  csharp,
  swift,
  kotlin,
  go,
  rust,
  php,
  ruby,
  bash,
  json,
  markdown,
  xml,
  plainText
}

class CodeExporter {
  static final Map<CodeLanguage, Set<String>> _keywords = {
    CodeLanguage.python: {
      'def ',
      'import ',
      'print(',
      'class ',
      'self.',
      'elif ',
      'try:',
      'except:',
      '# '
    },
    CodeLanguage.javascript: {
      'function ',
      'console.log',
      'const ',
      'let ',
      '=>',
      'document.',
      'window.',
      '// '
    },
    CodeLanguage.java: {
      'public class',
      'System.out',
      'public static void',
      'String ',
      'extends ',
      'implements '
    },
    CodeLanguage.dart: {
      'void main',
      'Widget',
      'build(',
      'StatelessWidget',
      'StatefulWidget',
      'package:',
      'setState',
      'final ',
      'const ',
      '=>',
      'runApp',
      'import \'package:'
    },
    CodeLanguage.css: {
      'background:',
      'color:',
      'font-size:',
      '.class',
      '#id',
      '@media',
      'margin:',
      'padding:'
    },
    CodeLanguage.sql: {
      'SELECT ',
      'FROM ',
      'WHERE ',
      'INSERT INTO',
      'CREATE TABLE',
      'UPDATE ',
      'DELETE ',
      'JOIN '
    },
    CodeLanguage.html: {
      '<html>',
      '<body>',
      '<div>',
      '<script>',
      '<style>',
      'href=',
      'class='
    },
    // System Languages
    CodeLanguage.cpp: {
      '#include <iostream>',
      'using namespace std',
      'cout <<',
      'int main(',
      'std::vector',
      'class ',
      '::'
    },
    CodeLanguage.c: {
      '#include <stdio.h>',
      'printf(',
      'scanf(',
      'malloc(',
      'struct ',
      'int main(',
      'void '
    },
    CodeLanguage.csharp: {
      'using System;',
      'namespace ',
      'public class',
      'Console.WriteLine',
      'private void',
      'static void'
    },
    CodeLanguage.swift: {
      'import UIKit',
      'import SwiftUI',
      'func ',
      'var body: some View',
      '@State',
      'guard let'
    },
    CodeLanguage.kotlin: {
      'fun main(',
      'val ',
      'var ',
      'data class',
      'suspend fun',
      'companion object'
    },
    CodeLanguage.go: {
      'package main',
      'func main(',
      'fmt.Println',
      'go func',
      'defer ',
      'import ('
    },
    CodeLanguage.rust: {
      'fn main()',
      'let mut',
      'println!',
      'pub mod',
      'impl ',
      'cargo'
    },
    // Backend & Scripting
    CodeLanguage.php: {
      r'<?php',
      'echo ',
      r'$this->',
      'function ',
      r'$_GET',
      'namespace '
    },
    CodeLanguage.ruby: {
      'def ',
      'end',
      'require ',
      'puts ',
      'class ',
      'attr_accessor'
    },
    CodeLanguage.bash: {
      '#!/bin/bash',
      'echo ',
      'sudo ',
      'apt-get',
      'grep ',
      'chmod ',
      'export '
    },
    // Data & Config
    CodeLanguage.json: {'{', '}', '":', '[', ']', 'true', 'false', 'null'},
    CodeLanguage.markdown: {'##', '**', '[', '](', '![', '- ', '> '},
    CodeLanguage.xml: {'<?xml', '<root>', '</', 'xmlns=', '<config>'},
  };

  static final Map<CodeLanguage, String> _extensions = {
    CodeLanguage.python: '.py',
    CodeLanguage.javascript: '.js',
    CodeLanguage.java: '.java',
    CodeLanguage.dart: '.dart',
    CodeLanguage.css: '.css',
    CodeLanguage.sql: '.sql',
    CodeLanguage.html: '.html',
    CodeLanguage.cpp: '.cpp',
    CodeLanguage.c: '.c',
    CodeLanguage.csharp: '.cs',
    CodeLanguage.swift: '.swift',
    CodeLanguage.kotlin: '.kt',
    CodeLanguage.go: '.go',
    CodeLanguage.rust: '.rs',
    CodeLanguage.php: '.php',
    CodeLanguage.ruby: '.rb',
    CodeLanguage.bash: '.sh',
    CodeLanguage.json: '.json',
    CodeLanguage.markdown: '.md',
    CodeLanguage.xml: '.xml',
    CodeLanguage.plainText: '.txt',
  };

  static String _sanitizeCode(String rawContent) {
    return rawContent
        .replaceAll('"', '"')
        .replaceAll('"', '"')
        .replaceAll(''', "'")
        .replaceAll(''', "'")
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('\u00A0', ' ');
  }

  static CodeLanguage detectLanguage(String content) {
    return _detectLanguage(content);
  }

  static String getFileExtension(String content) {
    CodeLanguage lang = _detectLanguage(content);
    return _extensions[lang]!;
  }

  static String getLanguageName(CodeLanguage lang) {
    const names = {
      CodeLanguage.python: 'Python',
      CodeLanguage.javascript: 'JavaScript',
      CodeLanguage.java: 'Java',
      CodeLanguage.dart: 'Dart',
      CodeLanguage.css: 'CSS',
      CodeLanguage.sql: 'SQL',
      CodeLanguage.html: 'HTML',
      CodeLanguage.cpp: 'C++',
      CodeLanguage.c: 'C',
      CodeLanguage.csharp: 'C#',
      CodeLanguage.swift: 'Swift',
      CodeLanguage.kotlin: 'Kotlin',
      CodeLanguage.go: 'Go',
      CodeLanguage.rust: 'Rust',
      CodeLanguage.php: 'PHP',
      CodeLanguage.ruby: 'Ruby',
      CodeLanguage.bash: 'Bash',
      CodeLanguage.json: 'JSON',
      CodeLanguage.markdown: 'Markdown',
      CodeLanguage.xml: 'XML',
      CodeLanguage.plainText: 'نص عادي',
    };
    return names[lang]!;
  }

  static CodeLanguage _detectLanguage(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return CodeLanguage.markdown;

    final lines = trimmed.split('\n');

    // Step 1: Check Shebang
    if (lines.isNotEmpty && lines.first.trim().startsWith('#!')) {
      final shebang = lines.first.toLowerCase();
      if (shebang.contains('bash') || shebang.contains('sh')) {
        return CodeLanguage.bash;
      }
      if (shebang.contains('python')) return CodeLanguage.python;
      if (shebang.contains('ruby')) return CodeLanguage.ruby;
      if (shebang.contains('node')) return CodeLanguage.javascript;
      if (shebang.contains('php')) return CodeLanguage.php;
    }

    // Step 2: Markdown Pre-Check (BEFORE code detection)
    int markdownMatches = 0;

    // Headers: # Title
    if (RegExp(r'^#{1,6}\s', multiLine: true).hasMatch(content)) {
      markdownMatches++;
    }

    // Bold/Italic: **text** or __text__
    if (RegExp(r'\*\*.*\*\*').hasMatch(content) ||
        RegExp(r'__.*__').hasMatch(content)) {
      markdownMatches++;
    }

    // Links: [text](url)
    if (RegExp(r'\[.*\]\(.*\)').hasMatch(content)) {
      markdownMatches++;
    }

    // Lists: - item
    if (RegExp(r'^\s*-\s', multiLine: true).hasMatch(content)) {
      markdownMatches++;
    }

    // If 2+ Markdown patterns found, it's Markdown
    if (markdownMatches >= 2) return CodeLanguage.markdown;

    // Step 3: Skip comments and collect first 3 non-comment lines
    List<String> realLines = [];
    for (var line in lines) {
      final l = line.trim();
      if (l.isEmpty) continue;
      if (l.startsWith('//') ||
          l.startsWith('#') ||
          l.startsWith('*') ||
          l.startsWith('/*') ||
          l.startsWith('--')) {
        continue;
      }
      realLines.add(l);
      if (realLines.length >= 3) break;
    }

    if (realLines.isEmpty) return CodeLanguage.markdown;

    // Step 4: Analyze the window (first 3 lines)
    final window = realLines.join(' ');
    final hasStrongCodeIndicators = window.endsWith(';') ||
        window.endsWith('{') ||
        window.endsWith('}') ||
        window.contains('import ') ||
        window.contains('class ') ||
        window.contains('def ') ||
        window.contains('void ') ||
        window.contains('func ') ||
        window.contains('return') ||
        window.contains(RegExp(r'\w+\s*=\s*\w+')) ||
        window.contains(RegExp(r'\w+\s*\(.*\)'));

    if (!hasStrongCodeIndicators) return CodeLanguage.markdown;

    // Step 5: JSON/XML/HTML specific checks
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      if (!trimmed.contains('class ') && !trimmed.contains('void ')) {
        return CodeLanguage.json;
      }
    }

    if (trimmed.startsWith('<') && trimmed.endsWith('>')) {
      if (trimmed.contains('<?xml')) return CodeLanguage.xml;
      return CodeLanguage.html;
    }

    // Step 6: Scoring system for specific language
    Map<CodeLanguage, int> scores = {};

    for (var language in _keywords.keys) {
      if (language == CodeLanguage.json ||
          language == CodeLanguage.xml ||
          language == CodeLanguage.markdown ||
          language == CodeLanguage.plainText) {
        continue;
      }

      scores[language] = 0;
      for (var keyword in _keywords[language]!) {
        if (content.contains(keyword)) {
          scores[language] = scores[language]! + 1;
        }
      }
    }

    if (content.contains(RegExp(r'<[a-zA-Z]+>'))) {
      scores[CodeLanguage.html] = (scores[CodeLanguage.html] ?? 0) + 3;
    }

    var sortedLanguages = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedLanguages.isEmpty || sortedLanguages.first.value < 2) {
      return CodeLanguage.markdown;
    }

    return sortedLanguages.first.key;
  }

  static Future<void> exportNote(String title, String content) async {
    if (content.trim().isEmpty) return;

    String cleanContent = _sanitizeCode(content);

    CodeLanguage lang = _detectLanguage(cleanContent);
    String ext = _extensions[lang]!;

    String safeTitle = title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .trim()
        .replaceAll(' ', '_');

    if (safeTitle.isEmpty) safeTitle = "untitled_code";

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/$safeTitle$ext';
    final file = File(path);

    await file.writeAsString(cleanContent, encoding: utf8);

    await Share.shareXFiles(
      [XFile(path)],
      text: "Code snippet ($ext) exported from Sinan Note",
      subject: "$safeTitle$ext",
    );
  }
}
