// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/domain/text/edit_distance.dart';
import 'package:sinan_note/domain/text/note_text.dart';
import 'package:sinan_note/domain/text/text_normalizer.dart';
import 'package:uuid/uuid.dart';

/// ملاحظة — نموذج مجال غير قابل للتعديل.
///
/// [uuid] هوية الملاحظة الثابتة عبر الأجهزة والنسخ الاحتياطية. [id] رقم الصف
/// المحلي فقط (null قبل الحفظ الأول) ولا يُستخدم للمطابقة بين قواعد مختلفة.
///
/// [title] و[content] نص واضح دائماً: التشفير شأن طبقة البيانات. الملاحظة
/// المقفلة تبقى `isLocked == true` حتى وهي مفكوكة في الذاكرة.
class Note {
  Note({
    this.id,
    String? uuid,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.colorIndex = 0,
    this.isArchived = false,
    this.isTrashed = false,
    this.reminderDateTime,
    this.isLocked = false,
    this.noteType = 'simple',
    this.recurrenceRule,
    this.isCompleted = false,
    this.isProfessional = false,
    this.isPinned = false,
    this.isChecklist = false,
    List<int> categoryIds = const [],
    this.isHiddenFromHome = false,
  })  : uuid = uuid ?? _uuid.v4(),
        categoryIds = List.unmodifiable(categoryIds);

  static const _uuid = Uuid();

  final int? id;
  final String uuid;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int colorIndex;
  final bool isArchived;
  final bool isTrashed;
  final DateTime? reminderDateTime;
  final bool isLocked;
  final String noteType;
  final String? recurrenceRule;
  final bool isCompleted;
  final bool isProfessional;
  final bool isPinned;
  final bool isChecklist;
  final List<int> categoryIds;
  final bool isHiddenFromHome;

  /// النص المقروء (Delta وقوائم المهام محوّلة). يُحسب مرة لكل نسخة.
  late final String plainText = NoteText.toDisplayText(content);

  late final String _searchIndex =
      TextNormalizer.normalize('$title\n$plainText');

  late final List<String> _searchWords = [
    ...TextNormalizer.normalize(title).split(' '),
    ...TextNormalizer.normalize(plainText).split(' ').take(50),
  ];

  /// بحث بالعنوان والنص المقروء بعد تطبيع العربية.
  /// [typoTolerant]: كلمة من 4 أحرف فأكثر تطابق كلمة تختلف بحرف واحد.
  bool matches(String query, {bool typoTolerant = false}) {
    final q = TextNormalizer.normalize(query.trim());
    if (q.isEmpty || _searchIndex.contains(q)) return true;
    if (!typoTolerant || q.length < 4) return false;
    return _searchWords
        .any((word) => word.length >= 3 && editDistance(q, word) <= 1);
  }

  Note copyWith({
    Object? id = _keep,
    String? uuid,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? colorIndex,
    bool? isArchived,
    bool? isTrashed,
    Object? reminderDateTime = _keep,
    bool? isLocked,
    String? noteType,
    Object? recurrenceRule = _keep,
    bool? isCompleted,
    bool? isProfessional,
    bool? isPinned,
    bool? isChecklist,
    List<int>? categoryIds,
    bool? isHiddenFromHome,
  }) {
    return Note(
      id: identical(id, _keep) ? this.id : id as int?,
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorIndex: colorIndex ?? this.colorIndex,
      isArchived: isArchived ?? this.isArchived,
      isTrashed: isTrashed ?? this.isTrashed,
      reminderDateTime: identical(reminderDateTime, _keep)
          ? this.reminderDateTime
          : reminderDateTime as DateTime?,
      isLocked: isLocked ?? this.isLocked,
      noteType: noteType ?? this.noteType,
      recurrenceRule: identical(recurrenceRule, _keep)
          ? this.recurrenceRule
          : recurrenceRule as String?,
      isCompleted: isCompleted ?? this.isCompleted,
      isProfessional: isProfessional ?? this.isProfessional,
      isPinned: isPinned ?? this.isPinned,
      isChecklist: isChecklist ?? this.isChecklist,
      categoryIds: categoryIds ?? this.categoryIds,
      isHiddenFromHome: isHiddenFromHome ?? this.isHiddenFromHome,
    );
  }

  /// نسخة جديدة بهوية جديدة (للتكرار والاستيراد كملاحظة مستقلة).
  Note asNew({DateTime? at}) {
    final now = at ?? DateTime.now();
    return Note(
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      colorIndex: colorIndex,
      isArchived: isArchived,
      isTrashed: isTrashed,
      reminderDateTime: reminderDateTime,
      isLocked: isLocked,
      noteType: noteType,
      recurrenceRule: recurrenceRule,
      isCompleted: isCompleted,
      isProfessional: isProfessional,
      isPinned: isPinned,
      isChecklist: isChecklist,
      categoryIds: categoryIds,
      isHiddenFromHome: isHiddenFromHome,
    );
  }
}

const _keep = Object();
