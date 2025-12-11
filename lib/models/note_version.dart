// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'exceptions.dart';

class NoteVersion {
  final int? id;
  final int noteId;
  final String title;
  final String content;
  final DateTime timestamp;
  final String action;

  NoteVersion({
    this.id,
    required this.noteId,
    required this.title,
    required this.content,
    required this.timestamp,
    this.action = 'update',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note_id': noteId,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'action': action,
    };
  }

  factory NoteVersion.fromMap(Map<String, dynamic> map) {
    try {
      return NoteVersion(
        id: map['id'],
        noteId: map['note_id'],
        title: map['title'],
        content: map['content'],
        timestamp: DateTime.parse(map['timestamp']),
        action: map['action'] ?? 'update',
      );
    } catch (e) {
      if (e is ValidationException) rethrow;
      throw ValidationException('Invalid note version data', e);
    }
  }
}
