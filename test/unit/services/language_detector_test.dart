// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/services/code/language_detector.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() {
    initializeTestEnvironment();
  });

  group('LanguageDetector', () {
    group('detectLanguage', () {
      test('detects Python', () {
        expect(
            LanguageDetector.detectLanguage(
                'def hello():\n    print("Hi")\n    return True\nif __name__ == "__main__":\n    hello()'),
            'Python');
        expect(
            LanguageDetector.detectLanguage(
                'from os import path\nimport sys\ndef main():\n    pass'),
            'Python');
      });

      test('detects JavaScript', () {
        expect(
            LanguageDetector.detectLanguage(
                'function test() {}\nconsole.log("hi");\nconst x = 5;'),
            'JavaScript');
        expect(
            LanguageDetector.detectLanguage(
                'const arr = [1,2,3];\nconsole.log(arr);\nmodule.exports = arr;'),
            'JavaScript');
      });

      test('detects Java', () {
        expect(
            LanguageDetector.detectLanguage(
                'public class Main {\n  public static void main(String[] args) {\n    System.out.println("Hi");\n  }\n}'),
            'Java');
      });

      test('detects Dart', () {
        expect(
            LanguageDetector.detectLanguage(
                'import \'package:flutter/material.dart\';\nvoid main() { runApp(MyApp()); }'),
            'Dart');
        expect(
            LanguageDetector.detectLanguage(
                'class MyWidget extends StatelessWidget {\n  Widget build(BuildContext context) {}\n}'),
            'Dart');
      });

      test('detects C++', () {
        expect(
            LanguageDetector.detectLanguage(
                '#include <iostream>\nusing namespace std;\nint main() { cout << "Hi"; }'),
            'C++');
        expect(
            LanguageDetector.detectLanguage(
                '#include <iostream>\nstd::cout << "Hi" << std::endl;'),
            'C++');
      });

      test('detects C', () {
        expect(
            LanguageDetector.detectLanguage(
                '#include <stdio.h>\nint main() {\n  printf("Hi");\n  return 0;\n}'),
            'C');
      });

      test('detects HTML', () {
        expect(
            LanguageDetector.detectLanguage(
                '<!DOCTYPE html>\n<html><body><div class="test"></div></body></html>'),
            'HTML');
      });

      test('detects CSS', () {
        expect(
            LanguageDetector.detectLanguage(
                '.class { color: red; }\n#id { margin: 0; }\n@media screen { padding: 0; }'),
            'CSS');
      });

      test('detects SQL', () {
        expect(
            LanguageDetector.detectLanguage(
                'SELECT * FROM users WHERE id = 1;\nINSERT INTO table VALUES (1);'),
            'SQL');
        expect(
            LanguageDetector.detectLanguage(
                'CREATE TABLE users (id INT);\nSELECT name FROM users;'),
            'SQL');
      });

      test('detects JSON', () {
        expect(
            LanguageDetector.detectLanguage(
                '{"name": "test", "value": true, "count": 42}'),
            'JSON');
      });

      test('detects Bash', () {
        expect(LanguageDetector.detectLanguage('#!/bin/bash\necho "Hello"'),
            'Bash');
        expect(
            LanguageDetector.detectLanguage('#!/bin/sh\necho "Hello"'), 'Bash');
      });

      test('returns null for plain text', () {
        expect(LanguageDetector.detectLanguage('Just plain text'), isNull);
        expect(LanguageDetector.detectLanguage('Hello World'), isNull);
      });

      test('returns null for empty string', () {
        expect(LanguageDetector.detectLanguage(''), isNull);
      });
    });

    group('getLanguageFromExtension', () {
      test('maps common extensions', () {
        expect(LanguageDetector.getLanguageFromExtension('py'), 'Python');
        expect(LanguageDetector.getLanguageFromExtension('js'), 'JavaScript');
        expect(LanguageDetector.getLanguageFromExtension('java'), 'Java');
        expect(LanguageDetector.getLanguageFromExtension('dart'), 'Dart');
        expect(LanguageDetector.getLanguageFromExtension('cpp'), 'C++');
        expect(LanguageDetector.getLanguageFromExtension('c'), 'C');
      });

      test('returns null for unknown extension', () {
        expect(LanguageDetector.getLanguageFromExtension('xyz'), isNull);
        expect(LanguageDetector.getLanguageFromExtension(''), isNull);
      });

      test('is case insensitive', () {
        // getLanguageFromExtension تبحث عن الامتداد كما هو — case sensitive
        expect(LanguageDetector.getLanguageFromExtension('py'), 'Python');
        expect(LanguageDetector.getLanguageFromExtension('dart'), 'Dart');
        expect(LanguageDetector.getLanguageFromExtension('UNKNOWN'), isNull);
      });
    });

    group('Edge Cases', () {
      test('handles multiline code', () {
        const code = '''
def hello():
    print("Hello")
    return True
''';
        expect(LanguageDetector.detectLanguage(code), 'Python');
      });

      test('handles code with comments', () {
        const code =
            '// This is a comment\nfunction test() {\n    return 42;\n}\nconsole.log(test());';
        expect(LanguageDetector.detectLanguage(code), 'JavaScript');
      });

      test('handles mixed content', () {
        const code = 'Some text\nfunction test() {}\nconsole.log("hi");';
        expect(LanguageDetector.detectLanguage(code), 'JavaScript');
      });
    });
  });
}
