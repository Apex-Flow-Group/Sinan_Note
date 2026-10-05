// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:sinan_note/domain/models/note.dart';

/// ما تعرضه قائمة الرئيسية فعلاً: ترتيب البطاقات (بعد الفلترة والتثبيت)
/// وارتفاع كل بطاقة بعد قياسها. تملكه الشاشة الرئيسية؛ الشبكة تكتبه،
/// وشريط التاريخ وزر تحديد الموضع يقرآنه.
class NoteListLayout {
  static const fallbackHeight = 72.0;

  List<Note> _order = const [];
  final _heights = <int, double>{};

  set order(List<Note> displayed) => _order = displayed;

  Map<int, double> get heights => _heights;

  void recordHeight(int noteId, double height) => _heights[noteId] = height;

  bool contains(int noteId) => _order.any((n) => n.id == noteId);

  /// الإزاحة التقديرية لبداية البطاقة، أو null إن لم تكن معروضة.
  double? offsetOf(int noteId) {
    var offset = 0.0;
    for (final note in _order) {
      if (note.id == noteId) return offset;
      offset += _heights[note.id] ?? fallbackHeight;
    }
    return null;
  }

  bool isVisible(int noteId, ScrollController scroll) {
    final offset = offsetOf(noteId);
    if (offset == null || !scroll.hasClients) return false;
    final height = _heights[noteId] ?? fallbackHeight;
    final top = scroll.offset;
    return offset >= top &&
        offset + height <= top + scroll.position.viewportDimension;
  }
}
