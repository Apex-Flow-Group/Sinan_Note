import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:refactoring_tool/engine/file_scanner.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String projectRoot;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('file_scanner_test_');
    projectRoot = tempDir.path;
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  /// ينشئ ملف Dart في المسار المحدد مع المحتوى
  void createDartFile(String relativePath, String content) {
    final file = File(p.join(projectRoot, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  group('FileScanner', () {
    test('يكتشف ملفات Core في المجلدات المحددة', () {
      createDartFile('lib/controllers/notes_controller.dart', '''
import 'dart:async';

class NotesController {}
''');
      createDartFile('lib/services/note_service.dart', '''
import 'dart:async';

class NoteService {}
''');
      createDartFile('lib/models/note.dart', '''
class Note {}
''');

      final scanner = FileScanner(projectRoot: projectRoot);
      final results = scanner.scan();

      expect(results.length, equals(3));
      final paths = results.map((e) => e.filePath).toList();
      expect(paths, contains('lib/controllers/notes_controller.dart'));
      expect(paths, contains('lib/services/note_service.dart'));
      expect(paths, contains('lib/models/note.dart'));
    });

    test('يستبعد ملفات .g.dart المولدة', () {
      createDartFile('lib/models/note.dart', 'class Note {}');
      createDartFile('lib/models/note.g.dart', '// GENERATED CODE');

      final scanner = FileScanner(projectRoot: projectRoot);
      final results = scanner.scan();

      expect(results.length, equals(1));
      expect(results.first.filePath, equals('lib/models/note.dart'));
    });

    test('يستبعد ملفات .freezed.dart المولدة', () {
      createDartFile('lib/models/note.dart', 'class Note {}');
      createDartFile('lib/models/note.freezed.dart', '// GENERATED CODE');

      final scanner = FileScanner(projectRoot: projectRoot);
      final results = scanner.scan();

      expect(results.length, equals(1));
      expect(results.first.filePath, equals('lib/models/note.dart'));
    });

    test('يستبعد مجلدات generated', () {
      createDartFile('lib/models/note.dart', 'class Note {}');
      createDartFile('lib/models/generated/auto.dart', '// GENERATED');

      final scanner = FileScanner(projectRoot: projectRoot);
      final results = scanner.scan();

      expect(results.length, equals(1));
      expect(results.first.filePath, equals('lib/models/note.dart'));
    });

    test('يحسب imports المباشرة لمجلدات Core بشكل صحيح', () {
      createDartFile('lib/models/note.dart', 'class Note {}');
      createDartFile('lib/controllers/notes_controller.dart', '''
import '../models/note.dart';
import '../services/note_service.dart';
import 'dart:async';

class NotesController {}
''');
      createDartFile('lib/services/note_service.dart', '''
import '../models/note.dart';

class NoteService {}
''');

      final scanner = FileScanner(projectRoot: projectRoot);
      final results = scanner.scan();

      final controller = results.firstWhere(
        (e) => e.filePath.contains('notes_controller'),
      );
      final service = results.firstWhere(
        (e) => e.filePath.contains('note_service'),
      );
      final model = results.firstWhere(
        (e) => e.filePath == 'lib/models/note.dart',
      );

      expect(controller.directImportCount, equals(2));
      expect(service.directImportCount, equals(1));
      expect(model.directImportCount, equals(0));
    });

    test('يحسب package imports لمجلدات Core', () {
      createDartFile('lib/controllers/notes_controller.dart', '''
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/note_service.dart';
import 'package:flutter/material.dart';

class NotesController {}
''');

      final scanner = FileScanner(projectRoot: projectRoot);
      final results = scanner.scan();

      expect(results.first.directImportCount, equals(2));
    });

    test('يرمي استثناء عند عدم وجود ملفات Core', () {
      // لا ننشئ أي ملفات

      final scanner = FileScanner(projectRoot: projectRoot);

      expect(
        () => scanner.scan(),
        throwsA(isA<FileScannerException>()),
      );
    });

    test('يتعامل مع مجلدات غير موجودة بدون خطأ', () {
      // ننشئ ملف واحد فقط في مجلد واحد
      createDartFile('lib/models/note.dart', 'class Note {}');

      final scanner = FileScanner(projectRoot: projectRoot);
      final results = scanner.scan();

      // يجب أن يعمل بدون خطأ حتى لو بعض المجلدات غير موجودة
      expect(results.length, equals(1));
    });

    test('dependencyDepth يساوي directImportCount', () {
      createDartFile('lib/services/note_service.dart', '''
import '../models/note.dart';
import '../core/base.dart';

class NoteService {}
''');
      createDartFile('lib/models/note.dart', 'class Note {}');
      createDartFile('lib/core/base.dart', 'class Base {}');

      final scanner = FileScanner(projectRoot: projectRoot);
      final results = scanner.scan();

      for (final entry in results) {
        expect(entry.dependencyDepth, equals(entry.directImportCount));
      }
    });

    test('يمسح المجلدات الفرعية بشكل متكرر', () {
      createDartFile('lib/controllers/notes/notes_provider.dart', '''
class NotesProvider {}
''');
      createDartFile('lib/controllers/notes/sub/deep_file.dart', '''
class DeepFile {}
''');

      final scanner = FileScanner(projectRoot: projectRoot);
      final results = scanner.scan();

      expect(results.length, equals(2));
    });

    test('لا يحسب imports لحزم خارجية', () {
      createDartFile('lib/controllers/notes_controller.dart', '''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';

class NotesController {}
''');

      final scanner = FileScanner(projectRoot: projectRoot);
      final results = scanner.scan();

      expect(results.first.directImportCount, equals(0));
    });
  });
}
