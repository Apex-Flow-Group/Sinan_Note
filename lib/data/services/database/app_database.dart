// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sinan_note/data/services/database/notes_schema.dart';
import 'package:sqflite/sqflite.dart';

/// فتح قاعدة الملاحظات. يُستدعى مرة واحدة في نقطة التركيب (main) ويُحقن
/// الناتج في المستودعات.
abstract final class AppDatabase {
  static const fileName = 'sinan_notes.db';

  static Future<String> defaultPath() async => p.join(
        Platform.isAndroid
            ? await getDatabasesPath()
            : (await getApplicationDocumentsDirectory()).path,
        fileName,
      );

  static Future<Database> open([String? path]) async => openDatabase(
        path ?? await defaultPath(),
        version: NotesSchema.version,
        onCreate: (db, _) => NotesSchema.create(db),
        onUpgrade: (db, from, _) => NotesSchema.upgrade(db, from),
        onOpen: NotesSchema.onOpen,
      );
}
