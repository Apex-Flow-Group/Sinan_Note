// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/models/exceptions.dart';

class Note {
  int? id;
  late String title;
  late String content;
  late String normalizedTitle;
  late String normalizedContent;
  late DateTime createdAt;
  late DateTime updatedAt;
  late int colorIndex;
  late bool isArchived;
  late bool isTrashed;
  DateTime? reminderDateTime;
  late bool isLocked;
  late String noteType;
  String? recurrenceRule;
  late bool isCompleted;
  late bool isProfessional;
  late bool isPinned;
  late bool isChecklist;
  List<int> categoryIds;
  late bool isHiddenFromHome;

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
    this.categoryIds = const [],
    this.isHiddenFromHome = false,
  }) {
    // Auto-normalize on creation
    normalizedTitle = normalize(title);
    normalizedContent = normalize(content);
  }
  
  /// Normalize Arabic text for smart search
  static String normalize(String text) {
    if (text.isEmpty) return '';
    
    return text
        // Remove diacritics
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        // Normalize alef variants
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        // Normalize taa marbuta
        .replaceAll('ة', 'ه')
        // Normalize alef maksura
        .replaceAll('ى', 'ي')
        .toLowerCase();
  }

  /// Check if content is encrypted (iv:ciphertext pattern)
  bool get isEncrypted {
    if (content.isEmpty) return false;
    final parts = content.split(':');
    return parts.length == 2 && parts[0].length >= 16;
  }

  /// Immutable copy with updated fields
  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? colorIndex,
    bool? isArchived,
    bool? isTrashed,
    Object? reminderDateTime = _undefined,
    bool? isLocked,
    String? noteType,
    Object? recurrenceRule = _undefined,
    bool? isCompleted,
    bool? isProfessional,
    bool? isPinned,
    bool? isChecklist,
    List<int>? categoryIds,
    bool? isHiddenFromHome,
  }) {
    final newNote = Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorIndex: colorIndex ?? this.colorIndex,
      isArchived: isArchived ?? this.isArchived,
      isTrashed: isTrashed ?? this.isTrashed,
      reminderDateTime: reminderDateTime == _undefined ? this.reminderDateTime : reminderDateTime as DateTime?,
      isLocked: isLocked ?? this.isLocked,
      noteType: noteType ?? this.noteType,
      recurrenceRule: recurrenceRule == _undefined ? this.recurrenceRule : recurrenceRule as String?,
      isCompleted: isCompleted ?? this.isCompleted,
      isProfessional: isProfessional ?? this.isProfessional,
      isPinned: isPinned ?? this.isPinned,
      isChecklist: isChecklist ?? this.isChecklist,
      categoryIds: categoryIds ?? this.categoryIds,
      isHiddenFromHome: isHiddenFromHome ?? this.isHiddenFromHome,
    );
    // Auto-update normalized fields
    newNote.normalizedTitle = normalize(newNote.title);
    newNote.normalizedContent = normalize(newNote.content);
    return newNote;
  }

  // Backward compatibility with SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'normalizedTitle': normalizedTitle,
      'normalizedContent': normalizedContent,
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
      'categoryIds': categoryIds.join(','),
      'isHiddenFromHome': isHiddenFromHome ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    try {
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
        categoryIds: map['categoryIds'] != null && (map['categoryIds'] as String).isNotEmpty
            ? (map['categoryIds'] as String).split(',').map(int.parse).toList()
            : [],
        isHiddenFromHome: (map['isHiddenFromHome'] ?? 0) == 1,
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw ValidationException('Invalid note data', e);
    }
  }

  static int _parseColorIndex(dynamic value) {
    if (value is int) {
      if (value > 100) return 0;
      if (value >= 0 && value < 12) return value;
    }
    return 0;
  }
}

const _undefined = Object();
