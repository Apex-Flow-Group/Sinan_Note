import 'package:refactoring_tool/engine/function_extractor.dart';
import 'package:refactoring_tool/models/function_unit.dart';
import 'package:test/test.dart';

void main() {
  late FunctionExtractor extractor;

  setUp(() {
    extractor = FunctionExtractor();
  });

  group('FunctionExtractor', () {
    test('extracts class methods', () {
      const source = '''
class MyService {
  void doSomething(String input) {
    print(input);
  }

  int calculate(int a, int b) {
    return a + b;
  }
}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions.length, 2);
      expect(result.functions[0].name, 'doSomething');
      expect(result.functions[0].type, FunctionType.method);
      expect(result.functions[0].returnType, 'void');
      expect(result.functions[0].params.length, 1);
      expect(result.functions[0].params[0].name, 'input');
      expect(result.functions[0].params[0].type, 'String');

      expect(result.functions[1].name, 'calculate');
      expect(result.functions[1].returnType, 'int');
      expect(result.functions[1].params.length, 2);
    });

    test('extracts constructors', () {
      const source = '''
class MyClass {
  final String name;
  final int age;

  MyClass(this.name, this.age);

  MyClass.named({required this.name, this.age = 0});
}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions.length, 2);
      expect(result.functions[0].name, 'MyClass');
      expect(result.functions[0].type, FunctionType.constructor);
      expect(result.functions[1].name, 'MyClass.named');
      expect(result.functions[1].type, FunctionType.constructor);
    });

    test('extracts top-level functions', () {
      const source = '''
void main() {
  print('hello');
}

String greet(String name) {
  return 'Hello, \$name!';
}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions.length, 2);
      expect(result.functions[0].name, 'main');
      expect(result.functions[0].type, FunctionType.topLevel);
      expect(result.functions[1].name, 'greet');
      expect(result.functions[1].type, FunctionType.topLevel);
      expect(result.functions[1].returnType, 'String');
    });

    test('extracts build methods', () {
      const source = '''
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions.length, 1);
      expect(result.functions[0].name, 'build');
      expect(result.functions[0].type, FunctionType.buildMethod);
    });

    test('extracts getters and setters', () {
      const source = '''
class MyClass {
  String _name = '';

  String get name => _name;

  set name(String value) {
    _name = value;
  }
}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions.length, 2);
      expect(result.functions[0].name, 'name');
      expect(result.functions[0].type, FunctionType.getter);
      expect(result.functions[1].name, 'name');
      expect(result.functions[1].type, FunctionType.setter);
    });

    test('excludes anonymous closures and inline lambdas', () {
      const source = '''
class MyClass {
  void doWork() {
    final list = [1, 2, 3];
    list.forEach((item) {
      print(item);
    });
    final mapped = list.map((x) => x * 2);
    final callback = () {
      return 42;
    };
  }
}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      // Should only extract doWork, not the lambdas/closures inside
      expect(result.functions.length, 1);
      expect(result.functions[0].name, 'doWork');
    });

    test('sorts by startLine ascending', () {
      const source = '''
void third() {}

void first() {}

void second() {}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions.length, 3);
      // They should be in declaration order (by line)
      expect(result.functions[0].name, 'third');
      expect(result.functions[1].name, 'first');
      expect(result.functions[2].name, 'second');
      // Verify startLine ordering
      expect(result.functions[0].startLine < result.functions[1].startLine,
          isTrue);
      expect(result.functions[1].startLine < result.functions[2].startLine,
          isTrue);
    });

    test('returns empty list with notification for file with no functions', () {
      const source = '''
// Just a file with constants
const String appName = 'MyApp';
const int version = 1;
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions, isEmpty);
      expect(result.notification, isNotNull);
      expect(result.notification, contains('No extractable functions'));
    });

    test('extracts annotations and doc comments', () {
      const source = '''
class MyClass {
  /// This is a doc comment
  @override
  @deprecated
  void myMethod() {
    // body
  }
}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions.length, 1);
      expect(result.functions[0].body, contains('/// This is a doc comment'));
      expect(result.functions[0].body, contains('@override'));
      expect(result.functions[0].body, contains('@deprecated'));
    });

    test('calculates lineCount correctly', () {
      const source = '''
void multiLine(
  String a,
  String b,
) {
  print(a);
  print(b);
  return;
}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions.length, 1);
      // Function spans from line 1 to line 8
      expect(result.functions[0].lineCount, 8);
    });

    test('extracts named and positional parameters', () {
      const source = '''
void mixed(String positional, {required int named, bool optional = false}) {
  // body
}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions.length, 1);
      final params = result.functions[0].params;
      expect(params.length, 3);

      expect(params[0].name, 'positional');
      expect(params[0].type, 'String');
      expect(params[0].isNamed, false);
      expect(params[0].isRequired, true);

      expect(params[1].name, 'named');
      expect(params[1].type, 'int');
      expect(params[1].isNamed, true);
      expect(params[1].isRequired, true);

      expect(params[2].name, 'optional');
      expect(params[2].type, 'bool');
      expect(params[2].isNamed, true);
      expect(params[2].defaultValue, 'false');
    });

    test('handles file not found gracefully', () {
      final result = extractor.extractFromFile('/nonexistent/path/file.dart');
      expect(result.functions, isEmpty);
      expect(result.notification, contains('File not found'));
    });

    test('extracts async methods correctly', () {
      const source = '''
class MyService {
  Future<List<String>> fetchData() async {
    return [];
  }
}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions.length, 1);
      expect(result.functions[0].name, 'fetchData');
      expect(result.functions[0].returnType, 'Future<List<String>>');
    });

    test('extracts static methods', () {
      const source = '''
class Utils {
  static String format(String input) {
    return input.trim();
  }
}
''';
      final result = extractor.extractFromSource(source, 'test.dart');
      expect(result.functions.length, 1);
      expect(result.functions[0].name, 'format');
      expect(result.functions[0].signature, contains('static'));
    });
  });
}
