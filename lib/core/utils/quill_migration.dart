// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:sinan_note/core/utils/text_direction_utils.dart';

/// Top-level function — تعمل في isolate منفصل عبر compute()
/// تبني Delta JSON من محتوى النوت (نص عادي أو Delta موجود)
String buildDeltaJsonForIsolate(String content) {
  if (content.isEmpty) {
    final delta = Delta()..insert('\n');
    return jsonEncode(delta.toJson());
  }

  if (content.trimLeft().startsWith('[')) {
    try {
      final rawDelta = Delta.fromJson(jsonDecode(content) as List);
      final fixed = QuillMigration.fixDeltaDirections(rawDelta);
      return jsonEncode(fixed.toJson());
    } catch (_) {
      // fall through to plain text
    }
  }

  final delta = QuillMigration.buildDeltaWithDirections(content);
  return jsonEncode(delta.toJson());
}

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
        final delta = fixDeltaDirections(rawDelta);
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
    final delta = buildDeltaWithDirections(content);
    final doc = Document.fromDelta(delta);
    return QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  /// إصلاح اتجاهات فقرات Delta محفوظة مسبقاً
  /// القواعد:
  /// - فقرات عادية: تأخذ اتجاهها من محتواها (Bidi)
  /// - قوائم (list) وعناوين (header): تأخذ اتجاههم من أول بند/سطر في المجموعة
  /// - مع Directionality(rtl): عربي=null، إنجليزي=direction:'rtl'
  static Delta fixDeltaDirections(Delta original) {
    final ops = original.toList();
    final result = Delta();

    final lineBuffer = StringBuffer();
    final pendingOps = <Operation>[];

    // اتجاه آخر قائمة مرقمة/نقطية — يستمر حتى تنتهي القائمة
    String? currentListType; // 'ordered', 'bullet', 'checked', 'unchecked'
    bool? listIsLtr; // اتجاه القائمة الحالية

    void flushLine(Operation newlineOp) {
      final lineText = lineBuffer.toString();

      Map<String, dynamic>? attrs;
      if (newlineOp.attributes != null) {
        attrs = Map<String, dynamic>.from(newlineOp.attributes!);
        if (attrs['align'] == 'right') attrs.remove('align');
      }

      final listType = attrs?['list'] as String?;
      final isListBlock = listType != null;

      bool isLtr;

      if (isListBlock) {
        // هل هذه قائمة جديدة أم استمرار لنفس القائمة؟
        if (currentListType != listType || listIsLtr == null) {
          // بند أول — حدد الاتجاه من محتوى هذا البند
          if (lineText.trim().isEmpty) {
            isLtr = listIsLtr ?? false; // ورّث من القائمة السابقة
          } else {
            isLtr =
                TextDirectionUtils.getDirection(lineText) == TextDirection.ltr;
          }
          currentListType = listType;
          listIsLtr = isLtr;
        } else {
          // استمرار القائمة — ورّث اتجاه القائمة
          isLtr = listIsLtr!;
        }
      } else {
        // ليست قائمة — أعد ضبط حالة القائمة
        currentListType = null;
        listIsLtr = null;

        if (lineText.trim().isEmpty) {
          // سطر فارغ — لا نغير اتجاهه
          for (final op in pendingOps) {
            result.insert(op.data, op.attributes);
          }
          result.insert('\n', attrs?.isEmpty == true ? null : attrs);
          lineBuffer.clear();
          pendingOps.clear();
          return;
        }

        isLtr = TextDirectionUtils.getDirection(lineText) == TextDirection.ltr;
      }

      // طبّق direction attribute
      if (lineText.trim().isNotEmpty || isListBlock) {
        if (isLtr) {
          attrs ??= {};
          attrs['direction'] = 'rtl'; // = LTR في سياق RTL parent
        } else {
          attrs?.remove('direction');
        }
      }

      for (final op in pendingOps) {
        result.insert(op.data, op.attributes);
      }
      result.insert('\n', attrs?.isEmpty == true ? null : attrs);

      lineBuffer.clear();
      pendingOps.clear();
    }

    for (final op in ops) {
      if (!op.isInsert) {
        if (op.isDelete) result.delete(op.length!);
        if (op.isRetain) result.retain(op.length!, op.attributes);
        continue;
      }

      final data = op.data;
      if (data is! String) {
        pendingOps.add(op);
        continue;
      }

      final parts = data.split('\n');
      for (int i = 0; i < parts.length; i++) {
        final text = parts[i];
        final isLastPart = i == parts.length - 1;

        if (text.isNotEmpty) {
          lineBuffer.write(text);
          pendingOps.add(Operation.insert(text, op.attributes));
        }

        if (!isLastPart) {
          flushLine(Operation.insert('\n', op.attributes));
        }
      }
    }

    // ما تبقى بدون newline
    if (pendingOps.isNotEmpty) {
      for (final op in pendingOps) {
        result.insert(op.data, op.attributes);
      }
      result.insert('\n');
    }

    return result;
  }

  /// بناء Delta مع اتجاه لكل فقرة
  static Delta buildDeltaWithDirections(String content) {
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
