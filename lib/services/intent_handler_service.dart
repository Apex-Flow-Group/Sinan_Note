// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:sinan_note/core/utils/checklist_formatter.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';

/// خدمة معالجة الـ Intents الخارجية — منطق صرف بدون UI
///
/// تستخرج النص، تكتشف نوع الملاحظة، تنظف النص القادم من المتصفح.
/// لا تعتمد على BuildContext أو أي Flutter widget.
class IntentHandlerService {
  const IntentHandlerService();

  /// تنظيف النص القادم من المتصفح / التطبيقات الخارجية
  /// يُرجع {'text': النص النظيف, 'url': الرابط أو null}
  ///
  /// يتعامل مع حالة خاصة: إذا كان النص هو Delta JSON كامل
  /// (مثل [{"insert":"النص\n"}]) يستخلص النص الصافي منه.
  Map<String, String?> cleanSharedText(String raw) {
    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );

    String text = raw.trim();
    String? url;

    // إزالة أحرف التحكم غير المرئية (Zero-width space, BOM, etc.)
    text = text.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u00AD]'), '');

    // ═══ الحالة الخاصة: النص هو Delta JSON (Quill) ═══
    // يحدث عند المشاركة من تطبيقات تنسخ المحتوى الداخلي بدلاً من النص المرئي
    text = _extractPlainFromDeltaIfNeeded(text);

    // ═══ الحالة الخاصة: النص هو Checklist JSON ═══
    if (ChecklistFormatter.isValidChecklist(text)) {
      text = ChecklistFormatter.toPlainText(text);
    }

    // استخرج أول رابط في النص
    final urlMatch = urlRegex.firstMatch(text);
    if (urlMatch != null) {
      url = urlMatch.group(0);

      // أزل الرابط من النص
      text = text.replaceAll(url!, '').trim();

      // أزل prefix غريب مثل "insert:" أو "انسريت:" أو بيانات HTML مبتورة
      text =
          text.replaceAll(RegExp(r'^insert\s*:\s*', caseSensitive: false), '');
    }

    // تنظيف فراغات نهاية الأسطر
    text = text.replaceAll(RegExp(r'[ \t]+$', multiLine: true), '');

    // أزل أسطر فارغة زائدة (3+ → 2)
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

    return {'text': text, 'url': url};
  }

  /// إذا كان النص Delta JSON كامل، يستخلص النص الصافي منه.
  /// مثال: [{"insert":"مرحبا\n"},{"insert":"سطر ثاني\n"}] → "مرحبا\nسطر ثاني"
  String _extractPlainFromDeltaIfNeeded(String text) {
    if (!text.trimLeft().startsWith('[')) return text;

    try {
      final decoded = jsonDecode(text);
      if (decoded is! List) return text;

      // تحقق أنه Delta JSON حقيقي (يحتوي على 'insert')
      if (decoded.isEmpty) return text;
      final first = decoded.first;
      if (first is! Map || !first.containsKey('insert')) return text;

      // استخلص النص من كل عنصر insert
      final buffer = StringBuffer();
      for (final op in decoded) {
        if (op is Map && op.containsKey('insert')) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          }
        }
      }

      final extracted = buffer.toString().trimRight();
      return extracted.isNotEmpty ? extracted : text;
    } catch (_) {
      return text;
    }
  }

  /// استخراج عنوان من أول سطر من النص
  String extractTitle(String text) {
    final firstLine = text.split('\n').first.trim();
    if (firstLine.isEmpty) return '';
    return firstLine.length > 60
        ? '${firstLine.substring(0, 60)}...'
        : firstLine;
  }

  /// اكتشاف نوع الملاحظة بناءً على محتوى النص
  NoteMode detectNoteMode(String text) {
    // Checklist patterns
    final checklistPatterns = [
      RegExp(r'^\s*[-*]\s*\[[ xX]\]', multiLine: true),
      RegExp(r'^\s*\d+\.\s*\[[ xX]\]', multiLine: true),
    ];
    for (final pattern in checklistPatterns) {
      if (pattern.hasMatch(text)) return NoteMode.checklist;
    }

    // Code patterns
    final codePatterns = [
      RegExp(r'(function|const|let|var|class|import|export)\s'),
      RegExp(r'(def|class|import|from|if __name__)\s'),
      RegExp(r'(public|private|void|int|String)\s'),
      RegExp(r'[{};]\s*$', multiLine: true),
    ];
    for (final pattern in codePatterns) {
      if (pattern.hasMatch(text)) return NoteMode.code;
    }

    // Rich text patterns
    final richPatterns = [
      RegExp(r'<[^>]+>'),
      RegExp(r'\*\*[^*]+\*\*'),
      RegExp(r'__[^_]+__'),
      RegExp(r'^#{1,6}\s', multiLine: true),
    ];
    for (final pattern in richPatterns) {
      if (pattern.hasMatch(text)) return NoteMode.rich;
    }
    return NoteMode.simple;
  }

  /// تحويل NoteMode إلى string للإعدادات
  String getModeString(NoteMode mode) {
    switch (mode) {
      case NoteMode.code:
        return 'professional';
      case NoteMode.rich:
        return 'rich';
      case NoteMode.reminder:
        return 'reminder';
      case NoteMode.checklist:
        return 'checklist';
      default:
        return 'simple';
    }
  }

  /// قراءة وتحليل ملف .sinan — يُرجع Note أو null
  /// يدعم الصيغة الكاملة (toMap) والصيغة القديمة (title/content فقط)
  Future<Note?> parseSinanFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      Note note;

      // الصيغة الكاملة (من toMap) — تحتوي 'updatedAt'
      if (json.containsKey('updatedAt')) {
        // أزل id لأن النوت سيُنشأ جديد في الداتابيز
        json.remove('id');
        note = Note.fromMap(json);
        // حدّث التواريخ لأنها نسخة جديدة
        note.createdAt = DateTime.now();
        note.updatedAt = DateTime.now();
      } else {
        // الصيغة القديمة (title + content + noteType + colorIndex)
        String content = json['content'] as String? ?? '';
        String title = json['title'] as String? ?? '';

        // تنظيف العنوان (قد يكون Delta JSON خام من نسخ قديمة)
        title = _extractPlainFromDeltaIfNeeded(title);
        title = _cleanFileContent(title);

        // المحتوى: إذا كان Delta JSON أو Checklist JSON — اتركه
        if (!content.trimLeft().startsWith('[') &&
            !content.trimLeft().startsWith('{')) {
          content = _cleanFileContent(content);
        }

        note = Note(
          title: title,
          content: content,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          colorIndex: json['colorIndex'] as int? ?? 0,
          noteType: json['noteType'] as String? ?? 'simple',
          isProfessional: json['noteType'] == 'code',
          isChecklist: json['noteType'] == 'checklist',
        );
      }

      // حاول حذف الملف المؤقت بعد القراءة
      try {
        await file.delete();
      } catch (_) {}

      return note;
    } catch (_) {
      return null;
    }
  }

  /// تنظيف النص القادم من ملف مشترك
  /// - إزالة الأسطر الفارغة الزائدة (3+ → 2)
  /// - إزالة prefix "insert:" أو بيانات HTML مبتورة
  /// - إزالة فراغات بداية ونهاية كل سطر الزائدة
  /// - إزالة أحرف التحكم غير المرئية (zero-width spaces, etc.)
  String _cleanFileContent(String raw) {
    String text = raw;

    // إزالة أحرف التحكم غير المرئية (Zero-width space, BOM, etc.)
    text = text.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u00AD]'), '');

    // إزالة prefix "insert:" الذي يظهر أحياناً من Chrome/WebView
    text = text.replaceAll(
        RegExp(r'^insert\s*:\s*', caseSensitive: false, multiLine: true), '');

    // إزالة أسطر فارغة زائدة (3 أو أكثر → 2)
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // إزالة فراغات نهاية الأسطر (trailing whitespace)
    text = text.replaceAll(RegExp(r'[ \t]+$', multiLine: true), '');

    // إزالة فراغات البداية والنهاية الكلية
    text = text.trim();

    return text;
  }

  /// تحديد ما إذا كان الـ intent يحتوي محتوى حقيقي
  bool hasValidContent(Map data) {
    final action = data['action'] as String?;
    final noteId = (data['note_id'] ?? 0) as int;
    final sharedText = data['shared_text'] as String?;
    final filePath = data['file_path'] as String?;

    return (sharedText != null && sharedText.isNotEmpty) ||
        (filePath != null && filePath.isNotEmpty) ||
        (action == 'com.apexflow.app.sinan.ACTION_VIEW_NOTE' && noteId > 0) ||
        (action == 'com.apexflow.app.sinan.ACTION_SELECT_NOTE_FOR_WIDGET') ||
        (action == 'com.apexflow.app.sinan.ACTION_NEW_NOTE');
  }
}
