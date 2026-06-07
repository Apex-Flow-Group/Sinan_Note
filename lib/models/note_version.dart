// Copyright © 2025 Apex Flow Group. All rights reserved.

class NoteVersion {
  int id;
  int noteId;
  String title;
  String content;
  DateTime timestamp;
  String action;
  String noteType;

  NoteVersion()
      : id = 0,
        noteId = 0,
        title = '',
        content = '',
        timestamp = DateTime.now(),
        action = 'updated',
        noteType = 'simple';

  NoteVersion.create({
    required this.noteId,
    required this.title,
    required this.content,
    required this.timestamp,
    this.action = 'update',
    this.noteType = 'simple',
  }) : id = 0;
}




