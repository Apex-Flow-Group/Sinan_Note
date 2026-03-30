// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/quill_migration.dart';
import 'package:apex_note/core/utils/text_direction_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class NoteViewWidgets {
  static Widget buildChecklistView(String content, Color textColor) {
    final items = ChecklistFormatter.parseJson(content);
    if (items.isEmpty) {
      return Text(
        content,
        style: TextStyle(fontSize: 16, height: 1.5, color: textColor),
        maxLines: null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.isDone ? Icons.check_box : Icons.check_box_outline_blank,
                size: 24,
                color: item.isDone
                    ? Colors.green
                    : textColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.text.isEmpty ? 'Mission...' : item.text,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: item.isDone
                        ? textColor.withValues(alpha: 0.6)
                        : textColor,
                    decoration: item.isDone ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// كل فقرة تأخذ اتجاهها المستقل بناءً على أول حرف مؤثر
  static Widget buildDirectionalMarkdown(String content, Color textColor) {
    // إذا كان Delta JSON حوله لـ plain text أولاً
    String displayContent = content;
    if (QuillMigration.isDelta(content)) {
      try {
        final controller = QuillMigration.controllerFromContent(content);
        displayContent = QuillMigration.toPlainText(controller);
      } catch (_) {
        displayContent = content;
      }
    }

    final paragraphs = displayContent.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: paragraphs.map((paragraph) {
        final dir = TextDirectionUtils.getDirection(paragraph);
        return Directionality(
          textDirection: dir,
          child: MarkdownBody(
            data: paragraph.replaceAll('\n', '  \n'),
            checkboxBuilder: (bool checked) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                checked ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
                color: textColor,
              ),
            ),
            styleSheet: buildMarkdownStyle(textColor),
          ),
        );
      }).toList(),
    );
  }

  static MarkdownStyleSheet buildMarkdownStyle(Color textColor) {
    return MarkdownStyleSheet(
      p: TextStyle(fontSize: 16, height: 1.5, color: textColor),
      h1: TextStyle(
          fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
      h2: TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      h3: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      strong: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
      listBullet: TextStyle(color: textColor),
      checkbox: TextStyle(color: textColor),
      code: TextStyle(
        backgroundColor: textColor.withValues(alpha: 0.1),
        fontFamily: 'monospace',
        color: textColor,
      ),
    );
  }
}
