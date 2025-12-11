// Copyright © 2025 Apex Flow Group. All rights reserved.

class LanguageDetector {
  static const Map<String, String> _extensions = {
    'Dart': '.dart',
    'Python': '.py',
    'JavaScript': '.js',
    'Java': '.java',
    'C++': '.cpp',
    'C': '.c',
    'HTML': '.html',
    'CSS': '.css',
    'SQL': '.sql',
    'JSON': '.json',
    'Bash': '.sh',
  };

  static String getFileExtension(String language) {
    return _extensions[language] ?? '.txt';
  }

  static String getExtensionForLanguage(String language) {
    return _extensions[language] ?? '.txt';
  }

  static String? detectLanguage(String code) {
    if (code.trim().isEmpty) return null;

    final patterns = <String, List<RegExp>>{
      'Dart': [
        RegExp(r'\bvoid\s+main\s*\('),
        RegExp(r'\bclass\s+\w+\s+extends\s+StatelessWidget'),
        RegExp(r'\bclass\s+\w+\s+extends\s+StatefulWidget'),
        RegExp(r'\bimport\s+package:'),
        RegExp(r"\bimport\s+'package:"),
        RegExp(r'=>'),
        RegExp(r'\brunApp\s*\('),
        RegExp(r'\bconst\s+'),
        RegExp(r'\bfinal\s+'),
        RegExp(r'\bWidget\b'),
        RegExp(r'\bsetState\s*\('),
      ],
      'Python': [
        RegExp(r'\bdef\s+\w+\s*\('),
        RegExp(r'\bimport\s+\w+'),
        RegExp(r'\bfrom\s+\w+\s+import'),
        RegExp(r'\bprint\s*\('),
        RegExp(r':\s*$', multiLine: true),
      ],
      'JavaScript': [
        RegExp(r'\bfunction\s+\w+\s*\('),
        RegExp(r'\bconst\s+\w+\s*='),
        RegExp(r'\blet\s+\w+\s*='),
        RegExp(r'\bconsole\.log\s*\('),
        RegExp(r'=>'),
      ],
      'Java': [
        RegExp(r'\bpublic\s+class\s+\w+'),
        RegExp(r'\bpublic\s+static\s+void\s+main'),
        RegExp(r'\bSystem\.out\.println'),
        RegExp(r'\bimport\s+java\.'),
      ],
      'C++': [
        RegExp(r'#include\s*<'),
        RegExp(r'\bstd::'),
        RegExp(r'\bint\s+main\s*\('),
        RegExp(r'\bcout\s*<<'),
      ],
      'C': [
        RegExp(r'#include\s*<stdio\.h>'),
        RegExp(r'\bprintf\s*\('),
        RegExp(r'\bint\s+main\s*\('),
      ],
      'HTML': [
        RegExp(r'<!DOCTYPE\s+html>', caseSensitive: false),
        RegExp(r'<html'),
        RegExp(r'<div'),
        RegExp(r'<body'),
      ],
      'CSS': [
        RegExp(r'\.\w+\s*\{'),
        RegExp(r'#\w+\s*\{'),
        RegExp(r'\w+\s*:\s*[^;]+;'),
      ],
      'SQL': [
        RegExp(r'\bSELECT\s+', caseSensitive: false),
        RegExp(r'\bFROM\s+', caseSensitive: false),
        RegExp(r'\bWHERE\s+', caseSensitive: false),
        RegExp(r'\bINSERT\s+INTO\s+', caseSensitive: false),
      ],
      'JSON': [
        RegExp(r'^\s*\{'),
        RegExp(r'"\w+"\s*:'),
      ],
      'Bash': [
        RegExp(r'^#!/bin/bash'),
        RegExp(r'\becho\s+'),
        RegExp(r'\$\w+'),
      ],
    };

    Map<String, int> scores = {};

    for (var entry in patterns.entries) {
      int score = 0;
      for (var pattern in entry.value) {
        if (pattern.hasMatch(code)) {
          score++;
        }
      }
      if (score > 0) {
        scores[entry.key] = score;
      }
    }

    if (scores.isEmpty) return null;

    var maxEntry = scores.entries.reduce((a, b) => a.value > b.value ? a : b);
    return maxEntry.value >= 2 ? maxEntry.key : null;
  }
}
