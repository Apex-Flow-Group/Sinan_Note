// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/checklist_formatter.dart';
import 'package:apex_note/core/utils/quill_migration.dart';

/// نقطة واحدة لتحويل محتوى النوت لنص قابل للعرض
/// يحل مشكلة Delta JSON الخام الذي يظهر بشكل غير مقروء
class NoteContentUtils {
  NoteContentUtils._();

  /// يحول أي محتوى (Delta JSON / Checklist / نص عادي) لنص قابل للعرض
  /// [maxChars] للتقليص في البطاقات، اتركه null للنص الكامل
  static String toDisplayText(String content, {int? maxChars}) {
    String result;

    if (ChecklistFormatter.isValidChecklist(content)) {
      result = ChecklistFormatter.toDisplayText(content);
    } else if (QuillMigration.isDelta(content)) {
      try {
        final controller = QuillMigration.controllerFromContent(content);
        result = QuillMigration.toPlainText(controller);
      } catch (_) {
        result = content;
      }
    } else {
      result = content;
    }

    if (maxChars != null && result.length > maxChars) {
      final runes = result.runes.toList();
      if (runes.length > maxChars) {
        return String.fromCharCodes(runes.take(maxChars));
      }
    }

    return result;
  }
}
