// Copyright © 2025 Apex Flow Group. All rights reserved.

/// تصنيف — نموذج مجال غير قابل للتعديل. [id] = 0 قبل الحفظ الأول.
class NoteCategory {
  const NoteCategory({this.id = 0, required this.name, this.sortOrder = 0});

  final int id;
  final String name;
  final int sortOrder;

  NoteCategory copyWith({int? id, String? name, int? sortOrder}) =>
      NoteCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
