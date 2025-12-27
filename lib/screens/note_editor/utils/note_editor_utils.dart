// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import '../../../utils/adaptive_color.dart';

/// Utility methods for NoteEditor (pure functions, no state)
class NoteEditorUtils {
  /// Map note type string to language name
  static String? mapNoteTypeToLanguage(String noteType) {
    final languageMap = {
      'python': 'Python',
      'javascript': 'JavaScript',
      'java': 'Java',
      'cpp': 'C++',
      'c': 'C',
      'csharp': 'C#',
      'php': 'PHP',
      'ruby': 'Ruby',
      'go': 'Go',
      'rust': 'Rust',
      'kotlin': 'Kotlin',
      'swift': 'Swift',
      'typescript': 'TypeScript',
      'html': 'HTML',
      'css': 'CSS',
      'sql': 'SQL',
      'shell': 'Shell',
      'dart': 'Dart',
      'json': 'JSON',
      'xml': 'XML',
    };
    return languageMap[noteType.toLowerCase()];
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
