// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/domain/errors.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/text/text_normalizer.dart';

/// تحويل [Note] من وإلى صف SQLite / خريطة JSON (نفس الشكل في القاعدة
/// والنسخ الاحتياطية وملفات المشاركة).
///
/// الصيغ القديمة مقبولة عند القراءة: ملف بلا `uuid` يأخذ هوية جديدة،
/// و`colorValue` القديم، وأنواع `pro`/`professional`.
abstract final class NoteMapper {
  static Map<String, Object?> toMap(Note note) => {
        if (note.id != null) 'id': note.id,
        'uuid': note.uuid,
        'title': note.title,
        'content': note.content,
        'normalizedTitle': TextNormalizer.normalize(note.title),
        'normalizedContent': TextNormalizer.normalize(note.plainText),
        'createdAt': note.createdAt.toUtc().toIso8601String(),
        'updatedAt': note.updatedAt.toUtc().toIso8601String(),
        'colorIndex': note.colorIndex,
        'isArchived': note.isArchived ? 1 : 0,
        'isTrashed': note.isTrashed ? 1 : 0,
        'reminderDateTime': note.reminderDateTime?.toUtc().toIso8601String(),
        'isLocked': note.isLocked ? 1 : 0,
        'noteType': note.noteType,
        'recurrenceRule': note.recurrenceRule,
        'isCompleted': note.isCompleted ? 1 : 0,
        'isProfessional': note.isProfessional ? 1 : 0,
        'isPinned': note.isPinned ? 1 : 0,
        'isChecklist': note.isChecklist ? 1 : 0,
        'categoryIds': note.categoryIds.join(','),
        'isHiddenFromHome': note.isHiddenFromHome ? 1 : 0,
      };

  static Note fromMap(Map<String, Object?> map) {
    try {
      var noteType = map['noteType'] as String? ?? 'simple';
      if (noteType == 'pro' || noteType == 'professional') noteType = 'code';

      final categories = map['categoryIds'] as String?;
      final reminder = map['reminderDateTime'] as String?;
      bool flag(String key) => (map[key] ?? 0) == 1 || map[key] == true;

      return Note(
        id: map['id'] as int?,
        uuid: map['uuid'] as String?,
        title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
        colorIndex: _colorIndex(map['colorIndex'] ?? map['colorValue']),
        isArchived: flag('isArchived'),
        isTrashed: flag('isTrashed'),
        reminderDateTime: reminder == null ? null : DateTime.parse(reminder),
        isLocked: flag('isLocked'),
        noteType: noteType,
        recurrenceRule: map['recurrenceRule'] as String?,
        isCompleted: flag('isCompleted'),
        isProfessional: flag('isProfessional'),
        isPinned: flag('isPinned'),
        isChecklist: flag('isChecklist'),
        categoryIds: categories == null || categories.isEmpty
            ? const []
            : categories.split(',').map(int.parse).toList(),
        isHiddenFromHome: flag('isHiddenFromHome'),
      );
    } catch (e) {
      throw ValidationException('Invalid note data', e);
    }
  }

  static int _colorIndex(Object? value) =>
      value is int && value >= 0 && value < 12 ? value : 0;
}
