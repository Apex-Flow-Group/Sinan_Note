// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:sinan_note/domain/models/note.dart';

/// ما يحرّره المستخدم في المحرر من الملاحظة — لقطة بلا حالة.
///
/// الأعلام التي لا يملكها المحرر (التثبيت، الأرشفة، السلة، القفل) ليست
/// هنا: تُؤخذ دائماً من المخزّن، فلا يرجعها حفظٌ من المحرر.
@immutable
class NoteDraft {
  const NoteDraft({
    required this.title,
    required this.content,
    required this.isEmpty,
    this.colorIndex = 0,
    this.reminderDateTime,
    this.recurrenceRule,
    this.noteType = 'simple',
    this.isChecklist = false,
    this.isProfessional = false,
    this.categoryIds = const [],
    this.isHiddenFromHome = false,
  });

  factory NoteDraft.of(Note note) => NoteDraft(
        title: note.title,
        content: note.content,
        isEmpty: note.title.trim().isEmpty && note.plainText.trim().isEmpty,
        colorIndex: note.colorIndex,
        reminderDateTime: note.reminderDateTime,
        recurrenceRule: note.recurrenceRule,
        noteType: note.noteType,
        isChecklist: note.isChecklist,
        isProfessional: note.isProfessional,
        categoryIds: note.categoryIds,
        isHiddenFromHome: note.isHiddenFromHome,
      );

  final String title;

  /// بصيغة التخزين (Delta JSON، JSON قائمة المهام، أو نص).
  final String content;

  /// لا عنوان ولا نص مقروء — يقرره المحرر لأنه يعرف الصيغة.
  final bool isEmpty;

  final int colorIndex;
  final DateTime? reminderDateTime;
  final String? recurrenceRule;
  final String noteType;
  final bool isChecklist;
  final bool isProfessional;
  final List<int> categoryIds;
  final bool isHiddenFromHome;

  /// ملاحظة جديدة من هذه المسودة.
  Note toNewNote({required DateTime now, required bool locked}) => Note(
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        isLocked: locked,
        colorIndex: colorIndex,
        reminderDateTime: reminderDateTime,
        recurrenceRule: recurrenceRule,
        noteType: noteType,
        isChecklist: isChecklist,
        isProfessional: isProfessional,
        categoryIds: categoryIds,
        isHiddenFromHome: isHiddenFromHome,
      );

  /// دمج ثلاثي: كل حقل غيّره المحرر منذ [base] (آخر ما فتحه أو حفظه) يُكتب؛
  /// وما لم يغيّره يبقى كما في [stored] الآن — فلا يمحو المحرر تثبيتاً أو
  /// لوناً أو تذكيراً غيّره غيره وهو مفتوح.
  Note mergeInto(Note stored, {required NoteDraft base, required DateTime now}) {
    T pick<T>(T mine, T opened, T current) => mine == opened ? current : mine;
    final categories = listEquals(categoryIds, base.categoryIds)
        ? stored.categoryIds
        : categoryIds;
    return stored.copyWith(
      title: pick(title, base.title, stored.title),
      content: pick(content, base.content, stored.content),
      colorIndex: pick(colorIndex, base.colorIndex, stored.colorIndex),
      reminderDateTime: pick(
          reminderDateTime, base.reminderDateTime, stored.reminderDateTime),
      recurrenceRule:
          pick(recurrenceRule, base.recurrenceRule, stored.recurrenceRule),
      noteType: pick(noteType, base.noteType, stored.noteType),
      isChecklist: pick(isChecklist, base.isChecklist, stored.isChecklist),
      isProfessional:
          pick(isProfessional, base.isProfessional, stored.isProfessional),
      categoryIds: categories,
      isHiddenFromHome:
          pick(isHiddenFromHome, base.isHiddenFromHome, stored.isHiddenFromHome),
      updatedAt: now,
    );
  }

  /// مسحه المستخدم: كان فيه شيء وأصبح فارغاً.
  bool emptiedSince(NoteDraft base) => isEmpty && !base.isEmpty;
}
