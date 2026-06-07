// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/core/utils/adaptive_color.dart';

/// Utility methods for NoteEditor (pure functions, no state)
class NoteEditorUtils {
  /// Map note type string to language name
  static String? mapNoteTypeToLanguage(String noteType) {
    final type = noteType.toLowerCase();

    // Custom extension: return as-is for display
    if (type.startsWith('custom:')) return type;

    const languageMap = {
      'python': 'Python',
      'javascript': 'JavaScript',
      'typescript': 'TypeScript',
      'java': 'Java',
      'dart': 'Dart',
      'html': 'HTML',
      'css': 'CSS',
      'svg': 'SVG',
      'sql': 'SQL',
      'cpp': 'C++',
      'c': 'C',
      'csharp': 'C#',
      'php': 'PHP',
      'ruby': 'Ruby',
      'go': 'Go',
      'rust': 'Rust',
      'kotlin': 'Kotlin',
      'swift': 'Swift',
      'bash': 'Bash',
      'shell': 'Bash',
      'json': 'JSON',
      'yaml': 'YAML',
      'toml': 'TOML',
      'xml': 'XML',
      'lua': 'Lua',
      'r': 'R',
      'dockerfile': 'Dockerfile',
      'markdown': 'Markdown',
    };
    return languageMap[type];
  }

  /// Get background color from color index
  static Color getBackgroundColor(int colorIndex, Brightness brightness) {
    return AppColorPalette.palette[colorIndex].getColor(brightness);
  }

  /// Generate current title from content
  static String generateTitle({
    String? customTitle,
    String? checklistTitle,
    required String content,
    required bool isChecklist,
    String fallback = 'New Note',
  }) {
    if (customTitle != null && customTitle.isNotEmpty) {
      return customTitle;
    }
    
    if (isChecklist) {
      if (checklistTitle != null && checklistTitle.isNotEmpty) {
        return checklistTitle;
      }
      return 'Checklist';
    }
    
    if (content.isNotEmpty) {
      final end = content.indexOf('\n');
      if (end != -1 && end < 40) {
        return content.substring(0, end);
      }
      return content.length > 40 ? "${content.substring(0, 40)}..." : content;
    }
    
    return fallback;
  }
}

