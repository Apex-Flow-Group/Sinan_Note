// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/domain/models/note_category.dart';

enum CategoryIssue { empty, tooLong, duplicate, limitReached }

/// قواعد التصنيفات — بلا حالة.
abstract final class CategoryPolicy {
  static const maxCategories = 20;
  static const maxNameLength = 20;

  /// تصنيف وهمي للملاحظات البرمجية؛ لا يُخزَّن.
  static const proCategoryId = -1;

  /// أول ما يمنع الاسم، أو null إن كان مقبولاً. [renaming] يُستثنى من
  /// فحص التكرار والحد.
  static CategoryIssue? check(String name, List<NoteCategory> existing,
      {int? renaming}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return CategoryIssue.empty;
    if (trimmed.length > maxNameLength) return CategoryIssue.tooLong;
    final key = sameNameKey(trimmed);
    if (existing.any((c) => c.id != renaming && sameNameKey(c.name) == key)) {
      return CategoryIssue.duplicate;
    }
    if (renaming == null && existing.length >= maxCategories) {
      return CategoryIssue.limitReached;
    }
    return null;
  }

  /// الاسم كما يُقارن: بلا مسافات طرفية ولا اعتبار لحالة الأحرف.
  static String sameNameKey(String name) => name.trim().toLowerCase();
}
