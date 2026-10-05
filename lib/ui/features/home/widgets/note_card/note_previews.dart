// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui' as ui;

import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/text/checklist.dart';
import 'package:sinan_note/ui/core/direction/text_direction.dart';
import 'package:sinan_note/ui/features/home/widgets/note_card_utils.dart';

/// معاينات البطاقات: نسخة واحدة للتطبيق (تُحقن من main) لأن البطاقات تُبنى
/// من جديد مع كل تمرير.
class NotePreviews {
  /// ما يُشتق من محتوى الملاحظة يُحسب مرة لكل (id, updatedAt) ويبقى بعد خروج
  /// البطاقة من الشاشة — البطاقات لا تحتفظ بحالتها أثناء التمرير.
  final _cache = <int, CardPreview>{};
  static const limit = 3000;

  /// [cache] = false لبطاقات الخزنة: نسخها مفكوكة، ولا يجوز أن يبقى نصها في
  /// ذاكرة ثابتة بعد إغلاق الخزنة.
  CardPreview of(Note note, {required bool cache}) {
    final id = cache ? note.id : null;
    final cached = id == null ? null : _cache[id];
    if (cached != null &&
        cached.updatedAt == note.updatedAt &&
        cached.contentLength == note.content.length &&
        cached.title == note.title) {
      return cached;
    }

    final title = NoteCardUtils.getDisplayTitle(note);
    final content = NoteCardUtils.fixNoteContent(note.content);
    final showExt = NoteCardUtils.shouldShowExtension(note.noteType);
    final preview = CardPreview(
      updatedAt: note.updatedAt,
      contentLength: note.content.length,
      title: note.title,
      displayTitle: title,
      displayContent: content,
      isChecklist: ChecklistFormatter.isValidChecklist(note.content),
      shouldShowExt: showExt,
      fileExtension: showExt
          ? NoteCardUtils.getFileExtension(note.content, note.noteType)
          : '',
      titleDirection: directionOf(title),
      contentDirection: directionOf(content),
    );
    if (id != null) {
      if (_cache.length >= limit) {
        _cache.remove(_cache.keys.first);
      }
      _cache[id] = preview;
    }
    return preview;
  }
}

class CardPreview {
  const CardPreview({
    required this.updatedAt,
    required this.contentLength,
    required this.title,
    required this.displayTitle,
    required this.displayContent,
    required this.isChecklist,
    required this.shouldShowExt,
    required this.fileExtension,
    required this.titleDirection,
    required this.contentDirection,
  });

  final DateTime updatedAt;
  final int contentLength;
  final String title;
  final String displayTitle;
  final String displayContent;
  final bool isChecklist;
  final bool shouldShowExt;
  final String fileExtension;
  final ui.TextDirection titleDirection;
  final ui.TextDirection contentDirection;
}
