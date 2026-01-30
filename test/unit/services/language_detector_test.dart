// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:apex_note/services/language_detector.dart';
import '../../test_setup.dart';

void main() {
  setUpAll(() {
    initializeTestEnvironment();
  });

  group('LanguageDetector', () {
    group('detectLanguage', () {
      test('detects Python', () {
        expect(LanguageDetector.detectLanguage('def hello():\n    print("Hi")'), 'python');
        expect(LanguageDetector.detectLanguage('import numpy as np'), 'python');
        expect(LanguageDetector.detectLanguage('class MyClass:\n    pass'), 'python');
      });

      test('detects JavaScript', () {
        expect(LanguageDetector.detectLanguage('function test() {}'), 'javascript');
        expect(LanguageDetector.detectLanguage('const x = 5;'), 'javascript');
        expect(LanguageDetector.detectLanguage('let arr = [1, 2, 3];'), 'javascript');
      });

      test('detects Java', () {
        expect(LanguageDetector.detectLanguage('public class Main {}'), 'java');
        expect(LanguageDetector.detectLanguage('System.out.println("Hi");'), 'java');
        expect(LanguageDetector.detectLanguage('private void test() {}'), 'java');
      });

      test('detects Dart', () {
        expect(LanguageDetector.detectLanguage('void main() {}'), 'dart');
        expect(LanguageDetector.detectLanguage('class MyWidget extends StatelessWidget {}'), 'dart');
        expect(LanguageDetector.detectLanguage('final String name;'), 'dart');
      });

      test('detects C++', () {
        expect(LanguageDetector.detectLanguage('#include <iostream>'), 'cpp');
        expect(LanguageDetector.detectLanguage('std::cout << "Hi";'), 'cpp');
        expect(LanguageDetector.detectLanguage('using namespace std;'), 'cpp');
      });

      test('detects C', () {
        expect(LanguageDetector.detectLanguage('#include <stdio.h>'), 'c');
        expect(LanguageDetector.detectLanguage('printf("Hi");'), 'c');
      });

      test('detects HTML', () {
        expect(LanguageDetector.detectLanguage('<html><body></body></html>'), 'html');
        expect(LanguageDetector.detectLanguage('<div class="test">'), 'html');
      });

      test('detects CSS', () {
        expect(LanguageDetector.detectLanguage('.class { color: red; }'), 'css');
        expect(LanguageDetector.detectLanguage('#id { margin: 0; }'), 'css');
      });

      test('detects SQL', () {
        expect(LanguageDetector.detectLanguage('SELECT * FROM users'), 'sql');
        expect(LanguageDetector.detectLanguage('INSERT INTO table VALUES'), 'sql');
        expect(LanguageDetector.detectLanguage('CREATE TABLE users'), 'sql');
      });

      test('detects JSON', () {
        expect(LanguageDetector.detectLanguage('{"name": "test"}'), 'json');
        expect(LanguageDetector.detectLanguage('[1, 2, 3]'), 'json');
      });

      test('detects Bash', () {
        expect(LanguageDetector.detectLanguage('#!/bin/bash'), 'bash');
        expect(LanguageDetector.detectLanguage('echo "Hello"'), 'bash');
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
        expect(LanguageDetector.getLanguageFromExtension('py'), 'python');
        expect(LanguageDetector.getLanguageFromExtension('js'), 'javascript');
        expect(LanguageDetector.getLanguageFromExtension('java'), 'java');
        expect(LanguageDetector.getLanguageFromExtension('dart'), 'dart');
        expect(LanguageDetector.getLanguageFromExtension('cpp'), 'cpp');
        expect(LanguageDetector.getLanguageFromExtension('c'), 'c');
      });

      test('returns null for unknown extension', () {
        expect(LanguageDetector.getLanguageFromExtension('xyz'), isNull);
        expect(LanguageDetector.getLanguageFromExtension(''), isNull);
      });

      test('is case insensitive', () {
        expect(LanguageDetector.getLanguageFromExtension('PY'), 'python');
        expect(LanguageDetector.getLanguageFromExtension('JS'), 'javascript');
      });
    });

    group('Edge Cases', () {
      test('handles multiline code', () {
        const code = '''
def hello():
    print("Hello")
    return True
''';
        expect(LanguageDetector.detectLanguage(code), 'python');
      });

      test('handles code with comments', () {
        const code = '''
// This is a comment
function test() {
    return 42;
}
''';
        expect(LanguageDetector.detectLanguage(code), 'javascript');
      });

      test('handles mixed content', () {
        const code = 'Some text\nfunction test() {}';
        expect(LanguageDetector.detectLanguage(code), 'javascript');
      });
    });
  });
}
