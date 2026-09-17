// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:sinan_note/core/utils/checklist_formatter.dart';

/// نقطة واحدة لتحويل محتوى النوت لنص قابل للعرض
/// يحل مشكلة Delta JSON الخام الذي يظهر بشكل غير مقروء
class NoteContentUtils {
  NoteContentUtils._();

  static const int previewMaxChars = 300;

  /// يحول أي محتوى (Delta JSON / Checklist / نص عادي) لنص قابل للعرض
  /// [maxChars] للتقليص في البطاقات، اتركه null للنص الكامل
  ///
  /// لا يبني QuillController — يمرّ على عمليات insert فقط حتى لا يتجمّد السكرول.
  static String toDisplayText(String content, {int? maxChars}) {
    if (content.isEmpty) return '';

    String result;
    if (ChecklistFormatter.isValidChecklist(content)) {
      result = ChecklistFormatter.toDisplayText(content);
    } else if (_looksLikeDelta(content)) {
      result = _plainFromDelta(content, maxChars: maxChars);
    } else {
      result = content;
    }

    if (maxChars != null && result.length > maxChars) {
      final runes = result.runes;
      if (runes.length > maxChars) {
        return String.fromCharCodes(runes.take(maxChars));
      }
    }

    return result;
  }

  static bool _looksLikeDelta(String content) {
    final t = content.trimLeft();
    if (!t.startsWith('[')) return false;
    final head = t.length > 240 ? t.substring(0, 240) : t;
    return head.contains('"insert"');
  }

  static String _plainFromDelta(String content, {int? maxChars}) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! List) return content;
      final buf = StringBuffer();
      for (final op in decoded) {
        if (op is! Map) continue;
        final insert = op['insert'];
        if (insert is String) {
          buf.write(insert);
        } else if (insert != null) {
          buf.write(' ');
        }
        if (maxChars != null && buf.length >= maxChars) break;
      }
      return buf.toString().trimRight();
    } catch (_) {
      return content;
    }
  }
}
