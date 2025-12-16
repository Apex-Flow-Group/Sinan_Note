// Copyright © 2025 Apex Flow Group. All rights reserved.

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
    'XML': '.xml',
    'Bash': '.sh',
  };

  static String getFileExtension(String language) {
    return _extensions[language] ?? '.txt';
  }

  static String getExtensionForLanguage(String language) {
    return _extensions[language] ?? '.txt';
  }

  /// البحث العكسي: من الامتداد إلى اسم اللغة
  static String? getLanguageFromExtension(String extension) {
    // توحيد الصيغة: التأكد من وجود النقطة
    final normalizedExt = extension.startsWith('.') ? extension : '.$extension';
    
    // البحث في الـ Map عن المفتاح الذي يملك هذه القيمة
    for (var entry in _extensions.entries) {
      if (entry.value == normalizedExt) {
        return entry.key; // إرجاع اسم اللغة (مثلاً Python)
      }
    }
    return null; // لم يتم العثور عليها
  }

  static String? detectLanguage(String code) {
    if (code.trim().isEmpty) return null;

    final patterns = <String, List<MapEntry<RegExp, int>>>{
      // --- اللغات الرئيسية (تمت مراجعتها) ---
      'Dart': [
        MapEntry(RegExp(r'import\s+package:'), 10), // علامة قوية جداً لدارت/فلاتر
        MapEntry(RegExp(r'void\s+main\(\)'), 3),
        MapEntry(RegExp(r'class\s+\w+\s+extends\s+State'), 8),
        MapEntry(RegExp(r'Widget\s+build'), 8),
        MapEntry(RegExp(r'setState\s*\('), 5),
        MapEntry(RegExp(r'@override'), 2),
      ],
      'Python': [
        MapEntry(RegExp(r'def\s+\w+\s*\(.*\)\s*:'), 6), // النقطتان : مهمة
        MapEntry(RegExp(r'if __name__ == "__main__"'), 10),
        MapEntry(RegExp(r'from\s+[\w.]+\s+import'), 4),
        MapEntry(RegExp(r'elif\s+'), 5), // خاصة ببايثون
        MapEntry(RegExp(r'print\s*\('), 1), // ضعيفة (مشتركة مع سويفت وغيرها)
      ],
      'JavaScript': [
        MapEntry(RegExp(r'console\.log'), 5),
        MapEntry(RegExp(r'const\s+\w+\s*='), 2),
        MapEntry(RegExp(r'function\s+\w+\s*\('), 2), // مشتركة
        MapEntry(RegExp(r'document\.getElementById'), 5),
        MapEntry(RegExp(r'export\s+default'), 4),
        MapEntry(RegExp(r'=>'), 2), // Arrow function
      ],
      'TypeScript': [
        MapEntry(RegExp(r'interface\s+\w+\s*\{'), 5),
        MapEntry(RegExp(r':\s*(string|number|boolean|any)'), 4), // تحديد الأنواع
        MapEntry(RegExp(r'implements\s+\w+'), 3),
      ],
      
      // --- عائلة C ---
      'Java': [
        MapEntry(RegExp(r'public\s+static\s+void\s+main'), 10),
        MapEntry(RegExp(r'System\.out\.println'), 10),
        MapEntry(RegExp(r'package\s+[\w.]+;'), 3),
        MapEntry(RegExp(r'extends\s+\w+'), 2),
      ],
      'C#': [
        MapEntry(RegExp(r'using\s+System;'), 10),
        MapEntry(RegExp(r'Console\.WriteLine'), 10),
        MapEntry(RegExp(r'namespace\s+\w+'), 5),
        MapEntry(RegExp(r'public\s+class\s+\w+'), 2),
      ],
      'C++': [
        MapEntry(RegExp(r'#include\s*<iostream>'), 10),
        MapEntry(RegExp(r'std::'), 6),
        MapEntry(RegExp(r'cout\s*<<'), 6),
        MapEntry(RegExp(r'using\s+namespace\s+std;'), 5),
      ],
      'C': [
        MapEntry(RegExp(r'#include\s*<stdio\.h>'), 10),
        MapEntry(RegExp(r'#include\s*<stdlib\.h>'), 5),
        MapEntry(RegExp(r'printf\s*\('), 3),
        MapEntry(RegExp(r'struct\s+\w+\s*\{'), 2),
      ],

      // --- تطوير الويب والبيانات ---
      'HTML': [
        MapEntry(RegExp(r'<!DOCTYPE\s+html>', caseSensitive: false), 20),
        MapEntry(RegExp(r'</div>'), 5),
        MapEntry(RegExp(r'<body'), 5),
        MapEntry(RegExp(r'<script'), 3),
      ],
      'CSS': [
        MapEntry(RegExp(r'\.[\w-]+\s*\{'), 3), // Classes
        MapEntry(RegExp(r'#[\w-]+\s*\{'), 3), // IDs
        MapEntry(RegExp(r'color:\s*#'), 4),
        MapEntry(RegExp(r'margin:\s*'), 2),
        MapEntry(RegExp(r'!important'), 5),
      ],
      'JSON': [
        // JSON صعب لأنه يشبه JS Object، لذا نبحث عن المفاتيح المقتبسة بدقة
        MapEntry(RegExp(r'"\w+"\s*:\s*'), 5), 
        MapEntry(RegExp(r'^\s*[\{\[]'), 2), // يبدأ بقوس
        MapEntry(RegExp(r'[\}\]]\s*\$'), 2), // ينتهي بقوس
        MapEntry(RegExp(r'true|false|null'), 2),
      ],
      'XML': [
        MapEntry(RegExp(r'<\?xml\s+version'), 20),
        MapEntry(RegExp(r'xmlns:'), 5),
        MapEntry(RegExp(r'</\w+>'), 3), // Closing tag
      ],
      'SQL': [
        MapEntry(RegExp(r'SELECT\s+.*\s+FROM', caseSensitive: false), 8),
        MapEntry(RegExp(r'INSERT\s+INTO', caseSensitive: false), 8),
        MapEntry(RegExp(r'CREATE\s+TABLE', caseSensitive: false), 8),
        MapEntry(RegExp(r'PRIMARY\s+KEY', caseSensitive: false), 5),
        MapEntry(RegExp(r'WHERE\s+'), 2),
      ],

      // --- لغات السيرفر والسكربت ---
      'PHP': [
        MapEntry(RegExp(r'<\?php'), 20), // علامة مؤكدة
        MapEntry(RegExp(r'\$\w+'), 4), // المتغيرات تبدأ بـ \$
        MapEntry(RegExp(r'echo\s+'), 2),
        MapEntry(RegExp(r'->'), 2), // Object operator
      ],
      'Ruby': [
        MapEntry(RegExp(r'def\s+\w+'), 2),
        MapEntry(RegExp(r'end'), 1), // كلمة end شائعة جداً في روبي
        MapEntry(RegExp(r'puts\s+'), 4),
        MapEntry(RegExp(r'require_relative'), 5),
        MapEntry(RegExp(r'attr_accessor'), 8),
      ],
      'Bash': [
        MapEntry(RegExp(r'^#!/bin/bash'), 20),
        MapEntry(RegExp(r'^#!/bin/sh'), 20),
        MapEntry(RegExp(r'echo\s+'), 1),
        MapEntry(RegExp(r'fi\$'), 5), // إغلاق if
        MapEntry(RegExp(r'esac\$'), 5), // إغلاق case
        MapEntry(RegExp(r'sudo\s+'), 3),
      ],

      // --- لغات حديثة (Modern Systems) ---
      'Go': [
        MapEntry(RegExp(r'package\s+main'), 10),
        MapEntry(RegExp(r'fmt\.Print'), 8),
        MapEntry(RegExp(r'func\s+\w+\('), 3),
        MapEntry(RegExp(r':='), 4), // تعريف قصير
      ],
      'Rust': [
        MapEntry(RegExp(r'fn\s+main'), 5),
        MapEntry(RegExp(r'let\s+mut\s+'), 6), // تعريف متغير قابل للتغيير
        MapEntry(RegExp(r'println!'), 8), // الماكرو ! مميز جداً
        MapEntry(RegExp(r'impl\s+\w+'), 5),
        MapEntry(RegExp(r'pub\s+fn'), 4),
      ],
      'Kotlin': [
        MapEntry(RegExp(r'fun\s+main'), 5),
        MapEntry(RegExp(r'val\s+\w+'), 2),
        MapEntry(RegExp(r'data\s+class'), 6),
        MapEntry(RegExp(r'companion\s+object'), 8),
        MapEntry(RegExp(r'override\s+fun'), 4),
      ],
      'Swift': [
        MapEntry(RegExp(r'import\s+UIKit'), 10),
        MapEntry(RegExp(r'import\s+SwiftUI'), 10),
        MapEntry(RegExp(r'var\s+\w+:\s*'), 2),
        MapEntry(RegExp(r'let\s+\w+'), 1),
        MapEntry(RegExp(r'func\s+\w+'), 2),
        MapEntry(RegExp(r'struct\s+\w+\s*:\s*View'), 8), // SwiftUI
      ],
    };

    Map<String, int> scores = {};

    for (var entry in patterns.entries) {
      int score = 0;
      for (var patternEntry in entry.value) {
        if (patternEntry.key.hasMatch(code)) {
          score += patternEntry.value; // إضافة الوزن
        }
      }
      if (score > 0) {
        scores[entry.key] = score;
      }
    }

    if (scores.isEmpty) return null;

    var maxEntry = scores.entries.reduce((a, b) => a.value > b.value ? a : b);
    return maxEntry.value >= 5 ? maxEntry.key : null; // رفع العتبة إلى 5
  }
}