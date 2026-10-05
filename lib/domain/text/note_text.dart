// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:sinan_note/domain/text/checklist.dart';

/// نقطة واحدة لتحويل محتوى النوت لنص قابل للعرض
/// يحل مشكلة Delta JSON الخام الذي يظهر بشكل غير مقروء
class NoteText {
  NoteText._();

  /// يحول أي محتوى (Delta JSON / Checklist / نص عادي) لنص قابل للعرض
  /// [maxChars] للتقليص في البطاقات، اتركه null للنص الكامل
  ///
  /// يُستدعى لكل بطاقة تظهر أثناء التمرير ولكل حفظ، لذا:
  /// - النص العادي لا يمر بـ jsonDecode أصلاً.
  /// - Delta يُقرأ من الـ ops مباشرة دون بناء Document/QuillController.
  static String toDisplayText(String content, {int? maxChars}) {
    String result = content;

    final trimmed = content.trimLeft();
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      Object? decoded;
      try {
        decoded = jsonDecode(content);
      } catch (_) {
        decoded = null;
      }
      if (_isDeltaOps(decoded)) {
        result = _deltaToText(decoded as List);
      } else if (ChecklistFormatter.isValidChecklist(content)) {
        result = ChecklistFormatter.toDisplayText(content);
      }
    }

    if (maxChars != null && result.length > maxChars) {
      final runes = result.runes.toList();
      if (runes.length > maxChars) {
        return String.fromCharCodes(runes.take(maxChars));
      }
    }

    return result;
  }

  static bool _isDeltaOps(Object? decoded) {
    if (decoded is! List) return false;
    if (decoded.isEmpty) return true;
    final first = decoded.first;
    return first is Map && first.containsKey('insert');
  }

  /// نفس ناتج `Document.toPlainText().trimRight()`: النصوص كما هي،
  /// والعناصر المضمّنة (صور…) بمحرف الاستبدال U+FFFC.
  static String _deltaToText(List ops) {
    final buffer = StringBuffer();
    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      if (insert is String) {
        buffer.write(insert);
      } else if (insert != null) {
        buffer.write('￼');
      }
    }
    return buffer.toString().trimRight();
  }
}
