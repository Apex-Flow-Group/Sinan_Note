// Copyright © 2025 Apex Flow Group. All rights reserved.

/// نسخة سابقة من ملاحظة — نموذج مجال غير قابل للتعديل. [id] = 0 قبل الحفظ.
class NoteVersion {
  const NoteVersion({
    this.id = 0,
    required this.noteId,
    required this.title,
    required this.content,
    required this.timestamp,
    this.action = 'update',
    this.noteType = 'simple',
  });

  final int id;
  final int noteId;
  final String title;
  final String content;
  final DateTime timestamp;
  final String action;
  final String noteType;
}
