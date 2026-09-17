// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:sinan_note/core/utils/checklist_formatter.dart';

/// نقطة واحدة لتحويل محتوى النوت لنص قابل للعرض
/// يحل مشكلة Delta JSON الخام الذي يظهر بشكل غير مقروء
class NoteContentUtils {
  NoteContentUtils._();

  /// يكفي 4 أسطر في البطاقة — لا نمرّر JSON طويل لـ Text
  static const int previewMaxChars = 180;
  static const int cardTitleChars = 42;

  static final _insertRe = RegExp(r'"insert"\s*:\s*"((?:\\.|[^"\\])*)"');

  /// يحول أي محتوى (Delta JSON / Checklist / نص عادي) لنص قابل للعرض
  /// [maxChars] للتقليص في البطاقات، اتركه null للنص الكامل
  ///
  /// البطاقات لا تفك Delta كاملاً — تمسح عمليات insert حتى الحد فقط.
  static String toDisplayText(String content, {int? maxChars}) {
    if (content.isEmpty) return '';

    String result;
    if (ChecklistFormatter.isValidChecklist(content)) {
      result = ChecklistFormatter.toDisplayText(content);
    } else if (looksLikeDeltaJson(content)) {
      result = maxChars != null
          ? _scanInsertStrings(content, maxChars: maxChars)
          : _plainFromDelta(content);
    } else {
      result = content;
    }

    result = _limitRunes(result, maxChars);
    if (looksLikeDeltaJson(result)) return '';
    return result;
  }

  static bool looksLikeDeltaJson(String text) {
    final t = text.trimLeft();
    if (!t.startsWith('[')) return false;
    final head = t.length > 240 ? t.substring(0, 240) : t;
    return head.contains('"insert"');
  }

  static String limitRunes(String text, int maxChars) =>
      _limitRunes(text, maxChars);

  static String _limitRunes(String text, int? maxChars) {
    if (maxChars == null || text.isEmpty) return text;
    final runes = text.runes;
    if (runes.length <= maxChars) return text;
    return String.fromCharCodes(runes.take(maxChars));
  }

  static String _plainFromDelta(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        return _scanInsertStrings(content);
      }
      final buf = StringBuffer();
      for (final op in decoded) {
        if (op is! Map) continue;
        final insert = op['insert'];
        if (insert is String) {
          buf.write(insert);
        } else if (insert != null) {
          buf.write(' ');
        }
      }
      final text = buf.toString().trimRight();
      if (text.isEmpty) return _scanInsertStrings(content);
      return text;
    } catch (_) {
      return _scanInsertStrings(content);
    }
  }

  static String _scanInsertStrings(String content, {int? maxChars}) {
    final buf = StringBuffer();
    final window =
        content.length > 16000 ? content.substring(0, 16000) : content;
    for (final match in _insertRe.allMatches(window)) {
      buf.write(_unescapeJsonString(match.group(1)!));
      if (maxChars != null && buf.length >= maxChars) break;
    }
    return buf.toString().trimRight();
  }

  static String _unescapeJsonString(String value) {
    final out = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final ch = value[i];
      if (ch != r'\' || i + 1 >= value.length) {
        out.write(ch);
        continue;
      }
      final next = value[++i];
      switch (next) {
        case 'n':
          out.write('\n');
          break;
        case 'r':
          break;
        case 't':
          out.write(' ');
          break;
        case '"':
        case r'\':
        case '/':
          out.write(next);
          break;
        case 'u':
          if (i + 4 < value.length) {
            final hex = value.substring(i + 1, i + 5);
            final code = int.tryParse(hex, radix: 16);
            if (code != null) {
              out.writeCharCode(code);
              i += 4;
              break;
            }
          }
          out.write(next);
          break;
        default:
          out.write(next);
      }
    }
    return out.toString();
  }
}
