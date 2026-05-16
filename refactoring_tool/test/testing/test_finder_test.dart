import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:refactoring_tool/models/call_source.dart';
import 'package:refactoring_tool/testing/test_finder.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String projectRoot;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('test_finder_test_');
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

  group('TestFinder', () {
    test('يجد ملفات اختبار تستورد الملف المعدّل مباشرة', () {
      // إنشاء ملف المصدر
      createDartFile('lib/services/note_service.dart', '''
class NoteService {
  void loadNotes() {}
}
''');

      // إنشاء ملف اختبار يستورد الملف المعدّل
      createDartFile('test/services/note_service_test.dart', '''
import '../../lib/services/note_service.dart';
import 'package:test/test.dart';

void main() {
  test('loads notes', () {});
}
''');

      final finder = TestFinder(projectRoot: projectRoot);
      final results = finder.findRelatedTests(
        modifiedFilePath: 'lib/services/note_service.dart',
        callSources: [],
      );

      expect(results, contains('test/services/note_service_test.dart'));
    });

    test('يجد ملفات اختبار تستورد عبر package import', () {
      createDartFile('lib/services/note_service.dart', '''
class NoteService {}
''');

      createDartFile('test/services/note_service_test.dart', '''
import 'package:sinan_note/services/note_service.dart';
import 'package:test/test.dart';

void main() {}
''');

      final finder = TestFinder(projectRoot: projectRoot);
      final results = finder.findRelatedTests(
        modifiedFilePath: 'lib/services/note_service.dart',
        callSources: [],
      );

      expect(results, contains('test/services/note_service_test.dart'));
    });

    test('يجد ملفات اختبار تستورد ملفات تحتوي على Call_Sources', () {
      createDartFile('lib/services/note_service.dart', '''
class NoteService {
  void loadNotes() {}
}
''');

      createDartFile('lib/controllers/notes_controller.dart', '''
import '../services/note_service.dart';

class NotesController {
  void init() {
    NoteService().loadNotes();
  }
}
''');

      // ملف اختبار يستورد الـ controller (الذي يحتوي على call source)
      createDartFile('test/controllers/notes_controller_test.dart', '''
import 'package:sinan_note/controllers/notes_controller.dart';
import 'package:test/test.dart';

void main() {}
''');

      final finder = TestFinder(projectRoot: projectRoot);
      final results = finder.findRelatedTests(
        modifiedFilePath: 'lib/services/note_service.dart',
        callSources: [
          const CallSource(
            callingFunction: 'init',
            filePath: 'lib/controllers/notes_controller.dart',
            lineNumber: 5,
            callType: CallType.direct,
          ),
        ],
      );

      expect(results, contains('test/controllers/notes_controller_test.dart'));
    });

    test('يُرجع قائمة فارغة عند عدم وجود مجلد test/', () {
      // لا ننشئ مجلد test/

      final finder = TestFinder(projectRoot: projectRoot);
      final results = finder.findRelatedTests(
        modifiedFilePath: 'lib/services/note_service.dart',
        callSources: [],
      );

      expect(results, isEmpty);
    });

    test('يُرجع قائمة فارغة عند عدم وجود ملفات اختبار مرتبطة', () {
      createDartFile('lib/services/note_service.dart', '''
class NoteService {}
''');

      // ملف اختبار لا يستورد الملف المعدّل
      createDartFile('test/other/other_test.dart', '''
import 'package:sinan_note/models/note.dart';
import 'package:test/test.dart';

void main() {}
''');

      final finder = TestFinder(projectRoot: projectRoot);
      final results = finder.findRelatedTests(
        modifiedFilePath: 'lib/services/note_service.dart',
        callSources: [],
      );

      expect(results, isEmpty);
    });

    test('لا يُكرر ملفات الاختبار في النتائج', () {
      createDartFile('lib/services/note_service.dart', '''
class NoteService {}
''');

      createDartFile('lib/controllers/notes_controller.dart', '''
class NotesController {}
''');

      // ملف اختبار يستورد كلا الملفين
      createDartFile('test/integration_test.dart', '''
import 'package:sinan_note/services/note_service.dart';
import 'package:sinan_note/controllers/notes_controller.dart';
import 'package:test/test.dart';

void main() {}
''');

      final finder = TestFinder(projectRoot: projectRoot);
      final results = finder.findRelatedTests(
        modifiedFilePath: 'lib/services/note_service.dart',
        callSources: [
          const CallSource(
            callingFunction: 'init',
            filePath: 'lib/controllers/notes_controller.dart',
            lineNumber: 3,
            callType: CallType.direct,
          ),
        ],
      );

      // يجب أن يظهر مرة واحدة فقط
      expect(results.length, equals(1));
      expect(results, contains('test/integration_test.dart'));
    });

    test('يُرجع النتائج مرتبة أبجدياً', () {
      createDartFile('lib/services/note_service.dart', '''
class NoteService {}
''');

      createDartFile('test/z_test.dart', '''
import 'package:sinan_note/services/note_service.dart';
void main() {}
''');

      createDartFile('test/a_test.dart', '''
import 'package:sinan_note/services/note_service.dart';
void main() {}
''');

      createDartFile('test/m_test.dart', '''
import 'package:sinan_note/services/note_service.dart';
void main() {}
''');

      final finder = TestFinder(projectRoot: projectRoot);
      final results = finder.findRelatedTests(
        modifiedFilePath: 'lib/services/note_service.dart',
        callSources: [],
      );

      expect(results.length, equals(3));
      expect(results[0], equals('test/a_test.dart'));
      expect(results[1], equals('test/m_test.dart'));
      expect(results[2], equals('test/z_test.dart'));
    });

    test('يتعامل مع relative imports بشكل صحيح', () {
      createDartFile('lib/services/note_service.dart', '''
class NoteService {}
''');

      createDartFile('test/services/note_service_test.dart', '''
import '../../lib/services/note_service.dart';
void main() {}
''');

      final finder = TestFinder(projectRoot: projectRoot);
      final results = finder.findRelatedTests(
        modifiedFilePath: 'lib/services/note_service.dart',
        callSources: [],
      );

      expect(results, contains('test/services/note_service_test.dart'));
    });

    test('يجد اختبارات في مجلدات فرعية عميقة', () {
      createDartFile('lib/services/note_service.dart', '''
class NoteService {}
''');

      createDartFile('test/unit/services/deep/note_service_test.dart', '''
import 'package:sinan_note/services/note_service.dart';
void main() {}
''');

      final finder = TestFinder(projectRoot: projectRoot);
      final results = finder.findRelatedTests(
        modifiedFilePath: 'lib/services/note_service.dart',
        callSources: [],
      );

      expect(
          results, contains('test/unit/services/deep/note_service_test.dart'));
    });

    test('يتجاهل ملفات غير .dart في مجلد test/', () {
      createDartFile('lib/services/note_service.dart', '''
class NoteService {}
''');

      // ملف غير dart
      final nonDartFile = File(p.join(projectRoot, 'test', 'readme.md'));
      nonDartFile.parent.createSync(recursive: true);
      nonDartFile
          .writeAsStringSync('# Tests\nimport services/note_service.dart');

      final finder = TestFinder(projectRoot: projectRoot);
      final results = finder.findRelatedTests(
        modifiedFilePath: 'lib/services/note_service.dart',
        callSources: [],
      );

      expect(results, isEmpty);
    });

    test('يتعامل مع مصادر استدعاء متعددة من ملفات مختلفة', () {
      createDartFile('lib/services/note_service.dart', '''
class NoteService {}
''');

      createDartFile('lib/controllers/notes_controller.dart', '''
class NotesController {}
''');

      createDartFile('lib/providers/notes_provider.dart', '''
class NotesProvider {}
''');

      createDartFile('test/controllers/ctrl_test.dart', '''
import 'package:sinan_note/controllers/notes_controller.dart';
void main() {}
''');

      createDartFile('test/providers/prov_test.dart', '''
import 'package:sinan_note/providers/notes_provider.dart';
void main() {}
''');

      final finder = TestFinder(projectRoot: projectRoot);
      final results = finder.findRelatedTests(
        modifiedFilePath: 'lib/services/note_service.dart',
        callSources: [
          const CallSource(
            callingFunction: 'init',
            filePath: 'lib/controllers/notes_controller.dart',
            lineNumber: 3,
            callType: CallType.direct,
          ),
          const CallSource(
            callingFunction: 'watch',
            filePath: 'lib/providers/notes_provider.dart',
            lineNumber: 5,
            callType: CallType.providerWatch,
          ),
        ],
      );

      expect(results.length, equals(2));
      expect(results, contains('test/controllers/ctrl_test.dart'));
      expect(results, contains('test/providers/prov_test.dart'));
    });
  });
}
