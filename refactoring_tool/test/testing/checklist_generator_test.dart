import 'package:refactoring_tool/models/call_source.dart';
import 'package:refactoring_tool/models/function_unit.dart';
import 'package:refactoring_tool/testing/checklist_generator.dart';
import 'package:test/test.dart';

void main() {
  late ChecklistGenerator generator;

  setUp(() {
    generator = ChecklistGenerator();
  });

  group('ChecklistGenerator', () {
    test('generates checklist with function name and file path', () {
      const functionUnit = FunctionUnit(
        name: 'loadNotes',
        filePath: 'lib/controllers/notes_provider.dart',
        startLine: 10,
        endLine: 30,
        lineCount: 20,
        signature: 'Future<void> loadNotes({String? category})',
        returnType: 'Future<void>',
        params: [
          Parameter(
            name: 'category',
            type: 'String?',
            isRequired: false,
            isNamed: true,
          ),
        ],
        body: '// body',
        type: FunctionType.method,
      );

      final checklist = generator.generate(
        functionUnit: functionUnit,
        callSources: [],
      );

      expect(checklist.functionName, equals('loadNotes'));
      expect(checklist.filePath, equals('lib/controllers/notes_provider.dart'));
      expect(checklist.returnType, equals('Future<void>'));
      expect(checklist.signature,
          equals('Future<void> loadNotes({String? category})'));
    });

    test('generates parameter test items for each parameter', () {
      const functionUnit = FunctionUnit(
        name: 'addNote',
        filePath: 'lib/services/note_service.dart',
        startLine: 5,
        endLine: 25,
        lineCount: 20,
        signature: 'Future<bool> addNote(String title, int priority)',
        returnType: 'Future<bool>',
        params: [
          Parameter(name: 'title', type: 'String', isRequired: true),
          Parameter(name: 'priority', type: 'int', isRequired: true),
        ],
        body: '// body',
        type: FunctionType.method,
      );

      final checklist = generator.generate(
        functionUnit: functionUnit,
        callSources: [],
      );

      expect(checklist.parameterTests.length, equals(2));

      final titleTest = checklist.parameterTests[0];
      expect(titleTest.parameterName, equals('title'));
      expect(titleTest.parameterType, equals('String'));
      expect(titleTest.isRequired, isTrue);
      expect(titleTest.sampleValidValue, isNotEmpty);
      expect(titleTest.sampleInvalidValue, isNotEmpty);

      final priorityTest = checklist.parameterTests[1];
      expect(priorityTest.parameterName, equals('priority'));
      expect(priorityTest.parameterType, equals('int'));
      expect(priorityTest.isRequired, isTrue);
    });

    test('generates call source verification items', () {
      const functionUnit = FunctionUnit(
        name: 'deleteNote',
        filePath: 'lib/services/note_service.dart',
        startLine: 30,
        endLine: 45,
        lineCount: 15,
        signature: 'Future<void> deleteNote(String id)',
        returnType: 'Future<void>',
        params: [
          Parameter(name: 'id', type: 'String', isRequired: true),
        ],
        body: '// body',
        type: FunctionType.method,
      );

      final callSources = [
        const CallSource(
          callingFunction: 'onDeletePressed',
          filePath: 'lib/screens/note_detail.dart',
          lineNumber: 45,
          callType: CallType.direct,
        ),
        const CallSource(
          callingFunction: 'build',
          filePath: 'lib/widgets/note_card.dart',
          lineNumber: 78,
          callType: CallType.providerWatch,
        ),
      ];

      final checklist = generator.generate(
        functionUnit: functionUnit,
        callSources: callSources,
      );

      expect(checklist.callSourceVerifications.length, equals(2));

      final firstVerification = checklist.callSourceVerifications[0];
      expect(firstVerification.callingFunction, equals('onDeletePressed'));
      expect(
          firstVerification.filePath, equals('lib/screens/note_detail.dart'));
      expect(firstVerification.lineNumber, equals(45));
      expect(firstVerification.callType, equals('direct'));
      expect(firstVerification.verificationStep, isNotEmpty);

      final secondVerification = checklist.callSourceVerifications[1];
      expect(secondVerification.callingFunction, equals('build'));
      expect(secondVerification.callType, equals('providerWatch'));
    });

    test('generates expected output based on return type', () {
      const voidFunction = FunctionUnit(
        name: 'init',
        filePath: 'lib/core/app.dart',
        startLine: 1,
        endLine: 5,
        lineCount: 5,
        signature: 'void init()',
        returnType: 'void',
        params: [],
        body: '// body',
        type: FunctionType.method,
      );

      final checklist = generator.generate(
        functionUnit: voidFunction,
        callSources: [],
      );

      expect(checklist.expectedOutput, contains('لا تُرجع قيمة'));
    });

    test('handles function with no parameters', () {
      const functionUnit = FunctionUnit(
        name: 'getCount',
        filePath: 'lib/models/counter.dart',
        startLine: 1,
        endLine: 3,
        lineCount: 3,
        signature: 'int getCount()',
        returnType: 'int',
        params: [],
        body: '// body',
        type: FunctionType.getter,
      );

      final checklist = generator.generate(
        functionUnit: functionUnit,
        callSources: [],
      );

      expect(checklist.parameterTests, isEmpty);
    });

    test('handles nullable parameter types', () {
      const functionUnit = FunctionUnit(
        name: 'search',
        filePath: 'lib/services/search_service.dart',
        startLine: 10,
        endLine: 30,
        lineCount: 20,
        signature: 'List<String> search(String? query)',
        returnType: 'List<String>',
        params: [
          Parameter(
            name: 'query',
            type: 'String?',
            isRequired: false,
            isNamed: false,
          ),
        ],
        body: '// body',
        type: FunctionType.method,
      );

      final checklist = generator.generate(
        functionUnit: functionUnit,
        callSources: [],
      );

      expect(checklist.parameterTests.length, equals(1));
      expect(checklist.parameterTests[0].sampleInvalidValue, contains('null'));
    });

    test('toFormattedString produces readable output', () {
      const functionUnit = FunctionUnit(
        name: 'saveNote',
        filePath: 'lib/services/note_service.dart',
        startLine: 50,
        endLine: 70,
        lineCount: 20,
        signature: 'Future<bool> saveNote(String title, String content)',
        returnType: 'Future<bool>',
        params: [
          Parameter(name: 'title', type: 'String', isRequired: true),
          Parameter(name: 'content', type: 'String', isRequired: true),
        ],
        body: '// body',
        type: FunctionType.method,
      );

      final callSources = [
        const CallSource(
          callingFunction: 'onSavePressed',
          filePath: 'lib/screens/editor.dart',
          lineNumber: 100,
          callType: CallType.direct,
        ),
      ];

      final checklist = generator.generate(
        functionUnit: functionUnit,
        callSources: callSources,
      );

      final formatted = checklist.toFormattedString();

      expect(formatted, contains('saveNote'));
      expect(formatted, contains('قائمة الاختبار اليدوية'));
      expect(formatted, contains('اختبارات المعاملات'));
      expect(formatted, contains('مصادر الاستدعاء للتحقق'));
      expect(formatted, contains('onSavePressed'));
    });

    test('toJson produces valid JSON structure', () {
      const functionUnit = FunctionUnit(
        name: 'getData',
        filePath: 'lib/core/data.dart',
        startLine: 1,
        endLine: 10,
        lineCount: 10,
        signature: 'Map<String, dynamic> getData(int id)',
        returnType: 'Map<String, dynamic>',
        params: [
          Parameter(name: 'id', type: 'int', isRequired: true),
        ],
        body: '// body',
        type: FunctionType.method,
      );

      final checklist = generator.generate(
        functionUnit: functionUnit,
        callSources: [],
      );

      final json = checklist.toJson();

      expect(json['functionName'], equals('getData'));
      expect(json['filePath'], equals('lib/core/data.dart'));
      expect(json['returnType'], equals('Map<String, dynamic>'));
      expect(json['parameterTests'], isA<List>());
      expect(json['callSourceVerifications'], isA<List>());
      expect(json['expectedOutput'], isA<String>());
    });

    test('uses default value as sample valid value when available', () {
      const functionUnit = FunctionUnit(
        name: 'fetchItems',
        filePath: 'lib/services/item_service.dart',
        startLine: 1,
        endLine: 10,
        lineCount: 10,
        signature: 'List<Item> fetchItems({int limit = 10})',
        returnType: 'List<Item>',
        params: [
          Parameter(
            name: 'limit',
            type: 'int',
            isRequired: false,
            isNamed: true,
            defaultValue: '10',
          ),
        ],
        body: '// body',
        type: FunctionType.method,
      );

      final checklist = generator.generate(
        functionUnit: functionUnit,
        callSources: [],
      );

      expect(checklist.parameterTests[0].sampleValidValue, equals('10'));
    });

    test('generates verification steps for all call types', () {
      const functionUnit = FunctionUnit(
        name: 'notify',
        filePath: 'lib/core/notifier.dart',
        startLine: 1,
        endLine: 5,
        lineCount: 5,
        signature: 'void notify()',
        returnType: 'void',
        params: [],
        body: '// body',
        type: FunctionType.method,
      );

      final callSources = [
        const CallSource(
          callingFunction: 'directCaller',
          filePath: 'lib/a.dart',
          lineNumber: 1,
          callType: CallType.direct,
        ),
        const CallSource(
          callingFunction: 'providerReader',
          filePath: 'lib/b.dart',
          lineNumber: 2,
          callType: CallType.providerRead,
        ),
        const CallSource(
          callingFunction: 'providerWatcher',
          filePath: 'lib/c.dart',
          lineNumber: 3,
          callType: CallType.providerWatch,
        ),
        const CallSource(
          callingFunction: 'callbackUser',
          filePath: 'lib/d.dart',
          lineNumber: 4,
          callType: CallType.callback,
        ),
        const CallSource(
          callingFunction: 'streamListener',
          filePath: 'lib/e.dart',
          lineNumber: 5,
          callType: CallType.streamListen,
        ),
        const CallSource(
          callingFunction: 'channelHandler',
          filePath: 'lib/f.dart',
          lineNumber: 6,
          callType: CallType.methodChannel,
        ),
      ];

      final checklist = generator.generate(
        functionUnit: functionUnit,
        callSources: callSources,
      );

      expect(checklist.callSourceVerifications.length, equals(6));

      // Each verification step should be non-empty and specific
      for (final v in checklist.callSourceVerifications) {
        expect(v.verificationStep, isNotEmpty);
      }
    });
  });
}
