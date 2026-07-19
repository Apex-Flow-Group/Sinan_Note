// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

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
  Map<String, String?> cleanSharedText(String raw) {
    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );

    String text = raw.trim();
    String? url;

    // استخرج أول رابط في النص
    final urlMatch = urlRegex.firstMatch(text);
    if (urlMatch != null) {
      url = urlMatch.group(0);

      // أزل الرابط من النص
      text = text.replaceAll(url!, '').trim();

      // أزل أسطر فارغة زائدة
      text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

      // أزل prefix غريب مثل "insert:" أو "انسريت:" أو بيانات HTML مبتورة
      text =
          text.replaceAll(RegExp(r'^insert\s*:\s*', caseSensitive: false), '');
    }

    return {'text': text, 'url': url};
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
  Future<Note?> parseSinanFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      final note = Note(
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        colorIndex: json['colorIndex'] as int? ?? 0,
        noteType: json['noteType'] as String? ?? 'simple',
        isProfessional: json['noteType'] == 'code',
        isChecklist: json['noteType'] == 'checklist',
      );

      // حاول حذف الملف المؤقت بعد القراءة
      try {
        await file.delete();
      } catch (_) {}

      return note;
    } catch (_) {
      return null;
    }
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
