// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/note_content_utils.dart';
import 'package:apex_note/models/note.dart';
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/services/language_detector.dart';
import 'package:flutter/material.dart';

class NoteCardUtils {
  static NoteMode getNoteMode(Note note) {
    if (note.isChecklist) {
      return NoteMode.checklist;
    }

    final codeTypes = [
      'python',
      'javascript',
      'typescript',
      'java',
      'dart',
      'html',
      'css',
      'svg',
      'sql',
      'cpp',
      'c',
      'csharp',
      'swift',
      'kotlin',
      'go',
      'rust',
      'php',
      'ruby',
      'bash',
      'json',
      'yaml',
      'toml',
      'xml',
      'lua',
      'r',
      'dockerfile',
      'code',
      'pro',
      'professional'
    ];

    if (codeTypes.contains(note.noteType)) {
      return NoteMode.code;
    } else {
      return NoteMode.values.firstWhere(
        (m) => m.name == note.noteType,
        orElse: () => NoteMode.simple,
      );
    }
  }

  static Color getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  static String fixNoteContent(String content, {int maxChars = 300}) =>
      NoteContentUtils.toDisplayText(content, maxChars: maxChars);

  static String getDisplayTitle(Note note) {
    if (note.isChecklist && ChecklistFormatter.isValidChecklist(note.content)) {
      try {
        final decoded = jsonDecode(note.content);
        if (decoded is Map && decoded['title'] != null) {
          final title = decoded['title'].toString().trim();
          if (title.isNotEmpty) return title;
        }
      } catch (e) {
        // Invalid JSON, fall through to default
      }
      return 'Checklist';
    }
    return note.title.isEmpty ? 'Untitled' : note.title;
  }

  static bool shouldShowExtension(String noteType) {
    // Custom extensions always show
    if (noteType.startsWith('custom:')) return true;
    final codeTypes = [
      'pro',
      'code',
      'markdown',
      'python',
      'javascript',
      'typescript',
      'java',
      'dart',
      'html',
      'css',
      'svg',
      'sql',
      'cpp',
      'c',
      'csharp',
      'swift',
      'kotlin',
      'go',
      'rust',
      'php',
      'ruby',
      'bash',
      'json',
      'yaml',
      'toml',
      'xml',
      'lua',
      'r',
      'dockerfile',
      'professional'
    ];
    return codeTypes.contains(noteType);
  }

  static String getFileExtension(String content, String noteType) {
    // Custom extension stored as "custom:ext"
    if (noteType.startsWith('custom:')) {
      return '.${noteType.substring(7)}';
    }

    // Known noteType → direct mapping (no re-detection)
    final typeToExt = {
      'markdown': '.md',
      'python': '.py',
      'javascript': '.js',
      'typescript': '.ts',
      'java': '.java',
      'dart': '.dart',
      'html': '.html',
      'css': '.css',
      'svg': '.svg',
      'sql': '.sql',
      'cpp': '.cpp',
      'c': '.c',
      'csharp': '.cs',
      'swift': '.swift',
      'kotlin': '.kt',
      'go': '.go',
      'rust': '.rs',
      'php': '.php',
      'ruby': '.rb',
      'bash': '.sh',
      'json': '.json',
      'yaml': '.yaml',
      'toml': '.toml',
      'xml': '.xml',
      'lua': '.lua',
      'r': '.r',
      'dockerfile': '.dockerfile',
    };

    if (typeToExt.containsKey(noteType)) {
      return typeToExt[noteType]!;
    }

    // Only auto-detect for unknown/generic types (new notes)
    if (noteType == 'code' || noteType == 'pro' || noteType == 'professional') {
      final detectedLang = LanguageDetector.detectLanguage(content);
      if (detectedLang != null) {
        return LanguageDetector.getFileExtension(detectedLang);
      }
    }

    return '.txt';
  }

  static Widget buildChecklistPreview(String content, Color titleColor) {
    final items = ChecklistFormatter.parseJson(content).take(3).toList();
    if (items.isEmpty) {
      return Text(
        content,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style:
            TextStyle(fontSize: 14, color: titleColor.withValues(alpha: 0.7)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                size: 18,
                color: item.isDone
                    ? Colors.green
                    : titleColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.text.isEmpty ? 'Mission...' : item.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: item.isDone
                        ? titleColor.withValues(alpha: 0.5)
                        : titleColor.withValues(alpha: 0.8),
                    decoration: item.isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
