// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:apex_note/core/utils/text_direction_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Converts plain text or existing Delta JSON to a Quill Document
class QuillMigration {
  /// Returns a QuillController from note content (plain text or Delta JSON)
  static QuillController controllerFromContent(String content) {
    if (content.isEmpty) {
      // ملاحظة جديدة — فقرة فارغة بدون direction ترث rtl من الأب
      final delta = Delta()..insert('\n');
      final doc = Document.fromDelta(delta);
      return QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Try to parse as Delta JSON
    if (content.trimLeft().startsWith('[')) {
      try {
        final rawDelta = Delta.fromJson(jsonDecode(content) as List);
        final delta = _fixDeltaDirections(rawDelta);
        final doc = Document.fromDelta(delta);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // Fall through to plain text
      }
    }

    // Plain text → Delta with per-paragraph direction
    final delta = _buildDeltaWithDirections(content);
    final doc = Document.fromDelta(delta);
    return QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  /// إصلاح اتجاهات فقرات Delta محفوظة مسبقاً
  /// يمر على كل op من نوع \n ويصحح direction/align بناءً على نص الفقرة
  /// يُنظف أيضاً align:right المتبقية من إصدارات قديمة
  static Delta _fixDeltaDirections(Delta original) {
    final ops = original.toList();
    final fixed = Delta();
    String paragraphText = '';
    String lastNonEmptyDir =
        ''; // آخر فقرة غير فارغة — لتوريث اتجاه الأسطر الفارغة

    for (final op in ops) {
      if (!op.isInsert) {
        if (op.isDelete) fixed.delete(op.length!);
        if (op.isRetain) fixed.retain(op.length!, op.attributes);
        continue;
      }

      final data = op.data;

      // embed (صورة، إلخ) — نمررها كما هي
      if (data is! String) {
        fixed.insert(data, op.attributes);
        continue;
      }

      // تنظيف align:right من attributes النصية (إرث من إصدارات قديمة)
      Map<String, dynamic>? cleanAttrs;
      if (op.attributes != null) {
        cleanAttrs = Map<String, dynamic>.from(op.attributes!);
        if (cleanAttrs['align'] == 'right') cleanAttrs.remove('align');
        if (cleanAttrs.isEmpty) cleanAttrs = null;
      }

      // نص عادي — نقسمه على \n
      final segments = data.split('\n');
      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i];
        if (seg.isNotEmpty) {
          paragraphText += seg;
          fixed.insert(seg, cleanAttrs);
        }

        if (i < segments.length - 1) {
          // هذا \n — نصحح اتجاه الفقرة
          // إذا كانت الفقرة فارغة — نرث اتجاه آخر فقرة غير فارغة
          final dirText =
              paragraphText.isNotEmpty ? paragraphText : lastNonEmptyDir;
          final isRtl =
              TextDirectionUtils.getDirection(dirText) == TextDirection.rtl;
          final attrs = Map<String, dynamic>.from(op.attributes ?? {});
          if (isRtl) {
            attrs.remove('direction');
            attrs.remove('align');
          } else {
            attrs['direction'] = 'rtl';
            attrs.remove('align');
          }
          fixed.insert('\n', attrs.isEmpty ? null : attrs);
          if (paragraphText.isNotEmpty) lastNonEmptyDir = paragraphText;
          paragraphText = '';
        }
      }
    }

    return fixed;
  }

  /// بناء Delta مع اتجاه لكل فقرة
  static Delta _buildDeltaWithDirections(String content) {
    final delta = Delta();
    final paragraphs = content.split('\n');

    for (int i = 0; i < paragraphs.length; i++) {
      final paragraph = paragraphs[i];
      final dir = TextDirectionUtils.getDirection(paragraph);
      final isRtl = dir == TextDirection.rtl;

      if (paragraph.isNotEmpty) {
        delta.insert(paragraph);
      }
      // مع Directionality(rtl): عربي=null يرث rtl، إنجليزي=direction:rtl يعكس
      delta.insert(
        '\n',
        isRtl ? null : {'direction': 'rtl'},
      );
    }

    return delta;
  }

  /// Converts a Quill document to plain text for storage
  static String toPlainText(QuillController controller) {
    return controller.document.toPlainText().trimRight();
  }

  /// Converts a Quill document to Delta JSON string for storage
  /// يحتفظ بالأسطر الفارغة من نهاية النص
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
