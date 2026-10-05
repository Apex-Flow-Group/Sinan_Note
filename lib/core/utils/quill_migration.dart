// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Top-level function — تعمل في isolate منفصل عبر compute()
/// تبني Delta JSON من محتوى النوت (نص عادي أو Delta موجود)
String buildDeltaJsonForIsolate(String content) =>
    jsonEncode(QuillMigration.deltaFromContent(content).toJson());

/// Converts plain text or existing Delta JSON to a Quill Document
class QuillMigration {
  /// Returns a QuillController from note content (plain text or Delta JSON)
  static QuillController controllerFromContent(String content) =>
      QuillController(
        document: Document.fromDelta(deltaFromContent(content)),
        selection: const TextSelection.collapsed(offset: 0),
      );

  /// Delta المستند من محتوى الملاحظة. اتجاه النص لا يُخزَّن: يُحسب عند الرسم
  /// من النص نفسه، وما خزّنته الإصدارات السابقة (`direction`، `align: right`)
  /// يُزال هنا فيختفي من الملاحظة عند أول حفظ.
  static Delta deltaFromContent(String content) {
    if (content.trimLeft().startsWith('[')) {
      try {
        return _withoutStoredDirection(
            Delta.fromJson(jsonDecode(content) as List));
      } catch (_) {
        // ليس Delta صالحاً — يُعامل كنص
      }
    }
    return Delta()..insert(content.endsWith('\n') ? content : '$content\n');
  }

  static Delta _withoutStoredDirection(Delta delta) {
    final result = Delta();
    for (final op in delta.toList()) {
      final attrs = op.attributes;
      if (!op.isInsert || attrs == null) {
        result.push(op);
        continue;
      }
      final kept = Map<String, dynamic>.from(attrs)
        ..remove('direction')
        ..removeWhere((k, v) => k == 'align' && v == 'right');
      result.insert(op.data, kept.isEmpty ? null : kept);
    }
    return result;
  }

  /// Converts a Quill document to plain text for storage
  static String toPlainText(QuillController controller) {
    return controller.document.toPlainText().trimRight();
  }

  static String toDeltaJson(QuillController controller) {
    return jsonEncode(controller.document.toDelta().toJson());
  }

  /// يرجع أول [maxLines] سطر من المحتوى كنص عادي
  /// يُستخدم لبناء QuillController خفيف للانيميشن
  static String previewContent(String content, {int maxLines = 20}) {
    if (content.isEmpty) return '';
    // Delta JSON — استخرج النص العادي أولاً
    String text = content;
    if (content.trimLeft().startsWith('[')) {
      try {
        final ctrl = controllerFromContent(content);
        text = toPlainText(ctrl);
        ctrl.dispose();
      } catch (_) {}
    }
    final lines = text.split('\n');
    if (lines.length <= maxLines) return content; // قصير — أرجع الأصل
    return lines.take(maxLines).join('\n');
  }

  /// Checks if content is already Delta JSON
  static bool isDelta(String content) {
    if (!content.trimLeft().startsWith('[')) return false;
    try {
      final decoded = jsonDecode(content);
      return decoded is List;
    } catch (_) {
      return false;
    }
  }
}
