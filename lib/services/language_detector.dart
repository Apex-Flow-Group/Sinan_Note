// Copyright © 2025 Apex Flow Group. All rights reserved.

/// Language detection service with performance optimizations
///
/// ⚡ PERFORMANCE NOTE:
/// For large code files (>2000 chars), this function samples the first 2000 characters.
/// For real-time detection in UI, use with compute() to avoid blocking:
///
/// ```dart
/// final detected = await compute(LanguageDetector.detectLanguage, code);
/// ```
class LanguageDetector {
  static const Map<String, String> _extensions = {
    'Dart': '.dart',
    'Python': '.py',
    'JavaScript': '.js',
    'TypeScript': '.ts',
    'Java': '.java',
    'C++': '.cpp',
    'C': '.c',
    'C#': '.cs',
    'PHP': '.php',
    'Ruby': '.rb',
    'Go': '.go',
    'Rust': '.rs',
    'Kotlin': '.kt',
    'Swift': '.swift',
    'HTML': '.html',
    'CSS': '.css',
    'SQL': '.sql',
    'JSON': '.json',
    'YAML': '.yaml',
    'TOML': '.toml',
    'XML': '.xml',
    'Bash': '.sh',
    'Lua': '.lua',
    'R': '.r',
    'Dockerfile': '.dockerfile',
    'SVG': '.svg',
  };

  static String getFileExtension(String language) {
    return _extensions[language] ?? '.txt';
  }

  /// Alias for [getFileExtension] — kept for API compatibility.
  static String getExtensionForLanguage(String language) =>
      getFileExtension(language);

  static String? getLanguageFromExtension(String extension) {
    final normalizedExt = extension.startsWith('.') ? extension : '.$extension';
    for (var entry in _extensions.entries) {
      if (entry.value == normalizedExt) {
        return entry.key;
      }
    }
    return null;
  }

  static String? detectLanguage(String code) {
    if (code.trim().isEmpty) return null;

    // Performance: Limit sample size to first 2000 chars for large files
    final sample = code.length > 2000 ? code.substring(0, 2000) : code;

    // Strong signatures - if found, language is certain
    if (sample.contains('<?php')) return 'PHP';
    if (sample.contains('<?xml')) return 'XML';
    if (RegExp(r'<!DOCTYPE\s+html>', caseSensitive: false).hasMatch(sample)) {
      return 'HTML';
    }
    if (sample.startsWith('#!/bin/bash') || sample.startsWith('#!/bin/sh')) {
      return 'Bash';
    }
    if (sample.contains('<svg') ||
        sample.contains('xmlns="http://www.w3.org/2000/svg"')) {
      return 'SVG';
    }
    if (sample.startsWith('FROM ') || sample.contains('\nFROM ')) {
      return 'Dockerfile';
    }
    if (RegExp(r'^\[\w+\]', multiLine: true).hasMatch(sample) &&
        sample.contains(' = ')) {
      return 'TOML';
    }

    final patterns = <String, List<MapEntry<RegExp, int>>>{
      'Dart': [
        MapEntry(RegExp(r'import\s+.package:flutter'), 15),
        MapEntry(RegExp(r'import\s+.package:'), 12),
        MapEntry(
            RegExp(r'class\s+\w+\s+extends\s+(StatelessWidget|StatefulWidget)'),
            15),
        MapEntry(RegExp(r'Widget\s+build\s*\('), 12),
        MapEntry(RegExp(r'setState\s*\(\s*\(\s*\)\s*\{'), 10),
        MapEntry(RegExp(r'void\s+main\s*\(\s*\)\s*\{'), 8),
        MapEntry(RegExp(r'runApp\s*\('), 10),
      ],
      'Python': [
        MapEntry(RegExp(r'def\s+\w+\s*\([^)]*\)\s*:'), 8),
        MapEntry(RegExp(r'if\s+__name__\s*==\s*["\x27]__main__["\x27]'), 15),
        MapEntry(RegExp(r'from\s+\w+\s+import'), 7),
        MapEntry(RegExp(r'\belif\s+'), 8),
        MapEntry(RegExp(r':\s*$', multiLine: true), 2),
        MapEntry(RegExp(r'self\.\w+'), 6),
      ],
      'JavaScript': [
        MapEntry(RegExp(r'console\.(log|error|warn|info)'), 10),
        MapEntry(RegExp(r'\b(const|let)\s+\w+\s*='), 5),
        MapEntry(RegExp(r'function\s+\w+\s*\('), 4),
        MapEntry(RegExp(r'document\.(getElementById|querySelector)'), 10),
        MapEntry(RegExp(r'(export\s+default|module\.exports)'), 8),
        MapEntry(RegExp(r'=>\s*\{'), 3),
      ],
      'TypeScript': [
        MapEntry(RegExp(r'interface\s+\w+\s*\{'), 12),
        MapEntry(RegExp(r':\s*(string|number|boolean)\s*[;=)]'), 8),
        MapEntry(RegExp(r'type\s+\w+\s*='), 10),
        MapEntry(RegExp(r'<\w+>'), 3),
      ],
      'Java': [
        MapEntry(RegExp(r'public\s+static\s+void\s+main\s*\('), 15),
        MapEntry(RegExp(r'System\.out\.println'), 15),
        MapEntry(RegExp(r'package\s+[\w.]+\s*;'), 8),
        MapEntry(RegExp(r'public\s+class\s+\w+'), 6),
        MapEntry(RegExp(r'import\s+java\.'), 8),
      ],
      'C#': [
        MapEntry(RegExp(r'using\s+System'), 15),
        MapEntry(RegExp(r'Console\.(WriteLine|Write)'), 15),
        MapEntry(RegExp(r'namespace\s+\w+'), 10),
        MapEntry(RegExp(r'static\s+void\s+Main'), 12),
      ],
      'C++': [
        MapEntry(RegExp(r'#include\s*<iostream>'), 15),
        MapEntry(RegExp(r'std::(cout|cin|endl|string|vector)'), 12),
        MapEntry(RegExp(r'using\s+namespace\s+std'), 10),
        MapEntry(RegExp(r'cout\s*<<'), 10),
      ],
      'C': [
        MapEntry(RegExp(r'#include\s*<stdio\.h>'), 15),
        MapEntry(RegExp(r'printf\s*\('), 8),
        MapEntry(RegExp(r'scanf\s*\('), 8),
        MapEntry(RegExp(r'int\s+main\s*\('), 6),
        MapEntry(RegExp(r'malloc\s*\('), 8),
      ],
      'Go': [
        MapEntry(RegExp(r'package\s+main'), 15),
        MapEntry(RegExp(r'fmt\.(Print|Println|Printf)'), 12),
        MapEntry(RegExp(r'func\s+main\s*\(\s*\)\s*\{'), 12),
        MapEntry(RegExp(r':='), 5),
        MapEntry(RegExp(r'import\s+\('), 6),
      ],
      'Rust': [
        MapEntry(RegExp(r'fn\s+main\s*\(\s*\)'), 12),
        MapEntry(RegExp(r'let\s+mut\s+'), 10),
        MapEntry(RegExp(r'println!\s*\('), 12),
        MapEntry(RegExp(r'impl\s+\w+\s+for'), 10),
        MapEntry(RegExp(r'use\s+std::'), 8),
      ],
      'Kotlin': [
        MapEntry(RegExp(r'fun\s+main\s*\('), 12),
        MapEntry(RegExp(r'\b(val|var)\s+\w+\s*:\s*\w+'), 6),
        MapEntry(RegExp(r'data\s+class'), 10),
        MapEntry(RegExp(r'companion\s+object'), 12),
      ],
      'Swift': [
        MapEntry(RegExp(r'import\s+(UIKit|SwiftUI)'), 15),
        MapEntry(RegExp(r'struct\s+\w+\s*:\s*View'), 12),
        MapEntry(RegExp(r'@State\s+var'), 10),
        MapEntry(RegExp(r'var\s+body:\s*some\s+View'), 12),
      ],
      'PHP': [
        MapEntry(RegExp(r'\$\w+\s*='), 8),
        MapEntry(RegExp(r'echo\s+'), 6),
        MapEntry(RegExp(r'->\w+'), 6),
        MapEntry(RegExp(r'function\s+\w+\s*\('), 4),
      ],
      'Ruby': [
        MapEntry(RegExp(r'\bdef\s+\w+'), 6),
        MapEntry(RegExp(r'\bend\b'), 4),
        MapEntry(RegExp(r'puts\s+'), 8),
        MapEntry(RegExp(r'attr_accessor'), 12),
        MapEntry(RegExp(r'require\s+'), 6),
      ],
      'SQL': [
        MapEntry(RegExp(r'\bSELECT\s+.+\s+FROM\b', caseSensitive: false), 12),
        MapEntry(RegExp(r'\bINSERT\s+INTO\b', caseSensitive: false), 12),
        MapEntry(RegExp(r'\bCREATE\s+TABLE\b', caseSensitive: false), 12),
        MapEntry(RegExp(r'\bWHERE\s+', caseSensitive: false), 4),
      ],
      'CSS': [
        MapEntry(RegExp(r'\.[a-zA-Z][\w-]*\s*\{'), 8),
        MapEntry(RegExp(r'#[a-zA-Z][\w-]*\s*\{'), 8),
        MapEntry(RegExp(r'@media\s+'), 10),
        MapEntry(RegExp(r'(color|background|margin|padding):\s*[^;]+;'), 5),
      ],
      'JSON': [
        MapEntry(RegExp(r'^\s*\{\s*"\w+"\s*:'), 10),
        MapEntry(RegExp(r'"\w+"\s*:\s*(true|false|null|\d+|")'), 6),
      ],
      'YAML': [
        MapEntry(RegExp(r'^\w[\w-]*:\s*\S', multiLine: true), 5),
        MapEntry(RegExp(r'^\s+-\s+\w', multiLine: true), 4),
        MapEntry(RegExp(r'^---\s*$', multiLine: true), 10),
      ],
      'Lua': [
        MapEntry(RegExp(r'\bfunction\s+\w+\s*\('), 8),
        MapEntry(RegExp(r'\blocal\s+\w+'), 6),
        MapEntry(RegExp(r'\bend\b'), 4),
        MapEntry(RegExp(r'print\s*\('), 5),
      ],
      'R': [
        MapEntry(RegExp(r'<-\s*'), 8),
        MapEntry(RegExp(r'\bc\s*\('), 6),
        MapEntry(RegExp(r'library\s*\('), 10),
        MapEntry(RegExp(r'data\.frame\s*\('), 12),
      ],
    };

    Map<String, int> scores = {};
    int maxScore = 0;

    for (var entry in patterns.entries) {
      int score = 0;
      for (var patternEntry in entry.value) {
        if (patternEntry.key.hasMatch(sample)) {
          score += patternEntry.value;
          // Early exit: if score is very high, it's certain
          if (score >= 20) {
            return entry.key;
          }
        }
      }
      if (score > 0) {
        scores[entry.key] = score;
        if (score > maxScore) maxScore = score;
      }
    }

    if (scores.isEmpty || maxScore < 8) return null;

    // If top score is significantly higher, return it
    var sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedScores.length > 1) {
      // Require clear winner (at least 50% more than second)
      if (sortedScores[0].value < sortedScores[1].value * 1.5) {
        return null;
      }
    }

    return sortedScores.first.key;
  }
}
