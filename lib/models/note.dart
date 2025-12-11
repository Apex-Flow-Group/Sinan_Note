// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'exceptions.dart';

class Note {
  final int? id;
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

  Note({
    this.id,
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
  });

  /// Check if content is encrypted (iv:ciphertext pattern)
  bool get isEncrypted {
    if (content.isEmpty) return false;
    final parts = content.split(':');
    return parts.length == 2 && parts[0].length >= 16;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'colorIndex': colorIndex,
      'isArchived': isArchived ? 1 : 0,
      'isTrashed': isTrashed ? 1 : 0,
      'reminderDateTime': reminderDateTime?.toIso8601String(),
      'isLocked': isLocked ? 1 : 0,
      'noteType': noteType,
      'recurrenceRule': recurrenceRule,
      'isCompleted': isCompleted ? 1 : 0,
      'isProfessional': isProfessional ? 1 : 0,
      'isPinned': isPinned ? 1 : 0,
      'isChecklist': isChecklist ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    try {
      // Backward compatibility: map old 'pro'/'professional' to 'code'
      String noteType = map['noteType'] ?? 'simple';
      if (noteType == 'pro' || noteType == 'professional') {
        noteType = 'code';
      }

      return Note(
        id: map['id'],
        title: map['title'] ?? '',
        content: map['content'] ?? '',
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
        colorIndex: _parseColorIndex(map['colorIndex'] ?? map['colorValue'] ?? 0),
        isArchived: (map['isArchived'] ?? 0) == 1,
        isTrashed: (map['isTrashed'] ?? 0) == 1,
        reminderDateTime: map['reminderDateTime'] != null
            ? DateTime.parse(map['reminderDateTime'])
            : null,
        isLocked: (map['isLocked'] ?? 0) == 1,
        noteType: noteType,
        recurrenceRule: map['recurrenceRule'],
        isCompleted: (map['isCompleted'] ?? 0) == 1,
        isProfessional: (map['isProfessional'] ?? 0) == 1,
        isPinned: (map['isPinned'] ?? 0) == 1,
        isChecklist: (map['isChecklist'] ?? 0) == 1,
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw ValidationException('Invalid note data', e);
    }
  }

  static int _parseColorIndex(dynamic value) {
    if (value is int) {
      // If value is large (old colorValue), default to 0
      if (value > 100) return 0;
      // If valid index (0-11), use it
      if (value >= 0 && value < 12) return value;
    }
    return 0;
  }
}
