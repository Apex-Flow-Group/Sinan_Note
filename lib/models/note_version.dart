// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:isar/isar.dart';

part 'note_version.g.dart';

@collection
class NoteVersion {
  Id id = Isar.autoIncrement;

  @Index()
  late int noteId;
  
  late String title;
  late String content;
  late DateTime timestamp;
  late String action; // 'created', 'updated', 'archived', 'restored'
  String noteType = 'simple'; // نوع الملاحظة وقت التسجيل

  NoteVersion();

  NoteVersion.create({
    required this.noteId,
    required this.title,
    required this.content,
    required this.timestamp,
    this.action = 'update',
    this.noteType = 'simple',
  });
}
