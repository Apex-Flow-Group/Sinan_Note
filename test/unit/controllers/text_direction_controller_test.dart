// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/editor/text_direction_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextDirectionController', () {
    late TextDirectionController controller;

    setUp(() {
      controller = TextDirectionController();
    });

    group('detectParagraphDirection', () {
      test('detects RTL for Arabic text', () {
        final arabicTexts = [
          'مرحبا بك',
          'هذا نص عربي',
          'السلام عليكم',
          'مرحباً بكم في التطبيق',
        ];

        for (final text in arabicTexts) {
          final direction = controller.detectParagraphDirection(text);
          expect(direction, TextDirection.rtl, reason: 'Failed for: $text');
        }
      });

      test('detects LTR for English text', () {
        final englishTexts = [
          'Hello World',
          'This is English text',
          'Welcome to the app',
          'Flutter Development',
        ];

        for (final text in englishTexts) {
          final direction = controller.detectParagraphDirection(text);
          expect(direction, TextDirection.ltr, reason: 'Failed for: $text');
        }
      });

      test('detects RTL for mixed text with Arabic majority', () {
        final mixedTexts = [
          'مرحبا Hello',
          'هذا نص عربي with English',
          'السلام عليكم 123',
        ];

        for (final text in mixedTexts) {
          final direction = controller.detectParagraphDirection(text);
          expect(direction, TextDirection.rtl, reason: 'Failed for: $text');
        }
      });

      test('detects LTR for mixed text with English majority', () {
        final mixedTexts = [
          'Hello World مرحبا', // Starts with English
          'English text with some عربي', // Starts with English
          'The quick brown fox مرحبا', // Starts with English
        ];

        for (final text in mixedTexts) {
          final direction = controller.detectParagraphDirection(text);
          expect(direction, TextDirection.ltr, reason: 'Failed for: $text');
        }
      });

      test('returns LTR for empty text', () {
        expect(controller.detectParagraphDirection(''), TextDirection.ltr);
        expect(controller.detectParagraphDirection('   '), TextDirection.ltr);
        expect(controller.detectParagraphDirection('\n'), TextDirection.ltr);
      });

      test('handles numbers and special characters', () {
        expect(
            controller.detectParagraphDirection('123456'), TextDirection.ltr);
        expect(controller.detectParagraphDirection('!@#\$%^&*()'),
            TextDirection.ltr);
        expect(controller.detectParagraphDirection('123 مرحبا'),
            TextDirection.rtl);
      });

      test('handles emojis', () {
        expect(
            controller.detectParagraphDirection('😀😁😂'), TextDirection.ltr);
        expect(
            controller.detectParagraphDirection('مرحبا 😀'), TextDirection.rtl);
        expect(
            controller.detectParagraphDirection('Hello 😀'), TextDirection.ltr);
      });
    });

    group('getParagraphDirections', () {
      test('returns correct directions for multi-paragraph content', () {
        const content = 'مرحبا بك\nHello World\nهذا نص عربي';
        final directions = controller.getParagraphDirections(content);

        expect(directions.length, 3);
        expect(directions[0].direction, TextDirection.rtl);
        expect(directions[1].direction, TextDirection.ltr);
        expect(directions[2].direction, TextDirection.rtl);
      });

      test('returns correct text for each paragraph', () {
        const content = 'First line\nSecond line\nThird line';
        final directions = controller.getParagraphDirections(content);

        expect(directions[0].text, 'First line');
        expect(directions[1].text, 'Second line');
        expect(directions[2].text, 'Third line');
      });

      test('returns correct offsets for each paragraph', () {
        const content = 'First\nSecond\nThird';
        final directions = controller.getParagraphDirections(content);

        // First: 0-5 (5 chars)
        expect(directions[0].startOffset, 0);
        expect(directions[0].endOffset, 5);

        // Second: 6-12 (6 chars, +1 for newline)
        expect(directions[1].startOffset, 6);
        expect(directions[1].endOffset, 12);

        // Third: 13-18 (5 chars, +1 for newline)
        expect(directions[2].startOffset, 13);
        expect(directions[2].endOffset, 18);
      });

      test('handles empty content', () {
        final directions = controller.getParagraphDirections('');
        expect(directions.length, 1);
        expect(directions[0].text, '');
        expect(directions[0].direction, TextDirection.ltr);
      });

      test('handles single paragraph', () {
        const content = 'Single paragraph';
        final directions = controller.getParagraphDirections(content);

        expect(directions.length, 1);
        expect(directions[0].text, 'Single paragraph');
        expect(directions[0].direction, TextDirection.ltr);
      });

      test('handles empty lines', () {
        const content = 'First\n\nThird';
        final directions = controller.getParagraphDirections(content);

        expect(directions.length, 3);
        expect(directions[0].text, 'First');
        expect(directions[1].text, '');
        expect(directions[2].text, 'Third');
      });

      test('handles mixed Arabic and English paragraphs', () {
        const content = '''مرحبا بك في التطبيق
This is an English paragraph
هذا نص عربي آخر
Another English line''';

        final directions = controller.getParagraphDirections(content);

        expect(directions.length, 4);
        expect(directions[0].direction, TextDirection.rtl);
        expect(directions[1].direction, TextDirection.ltr);
        expect(directions[2].direction, TextDirection.rtl);
        expect(directions[3].direction, TextDirection.ltr);
      });
    });

    group('detectOverallDirection', () {
      test('detects RTL for predominantly Arabic content', () {
        const content = '''مرحبا بك في التطبيق
هذا نص عربي
Hello World''';

        final direction = controller.detectOverallDirection(content);
        expect(direction, TextDirection.rtl);
      });

      test('detects LTR for predominantly English content', () {
        const content = '''Hello World
This is English
مرحبا''';

        final direction = controller.detectOverallDirection(content);
        expect(direction, TextDirection.ltr);
      });

      test('returns LTR for empty content', () {
        expect(controller.detectOverallDirection(''), TextDirection.ltr);
      });

      test('returns LTR for equal mix', () {
        const content = 'مرحبا\nHello';
        final direction = controller.detectOverallDirection(content);
        expect(direction, TextDirection.ltr);
      });
    });

    group('Helper Methods', () {
      test('containsRtlCharacters detects Arabic characters', () {
        expect(controller.containsRtlCharacters('مرحبا'), true);
        expect(controller.containsRtlCharacters('Hello'), false);
        expect(controller.containsRtlCharacters('Hello مرحبا'), true);
        expect(controller.containsRtlCharacters(''), false);
      });

      test('containsLtrCharacters detects Latin characters', () {
        expect(controller.containsLtrCharacters('Hello'), true);
        expect(controller.containsLtrCharacters('مرحبا'), false);
        expect(controller.containsLtrCharacters('مرحبا Hello'), true);
        expect(controller.containsLtrCharacters(''), false);
      });

      test('isMixedDirection detects mixed content', () {
        expect(controller.isMixedDirection('مرحبا Hello'), true);
        expect(controller.isMixedDirection('Hello مرحبا'), true);
        expect(controller.isMixedDirection('Hello'), false);
        expect(controller.isMixedDirection('مرحبا'), false);
        expect(controller.isMixedDirection(''), false);
      });
    });

    group('Edge Cases', () {
      test('handles very long text', () {
        final longArabic = 'مرحبا ' * 1000;
        final direction = controller.detectParagraphDirection(longArabic);
        expect(direction, TextDirection.rtl);
      });

      test('handles text with only whitespace', () {
        expect(controller.detectParagraphDirection('     '), TextDirection.ltr);
        expect(
            controller.detectParagraphDirection('\t\t\t'), TextDirection.ltr);
      });

      test('handles text with only newlines', () {
        final directions = controller.getParagraphDirections('\n\n\n');
        expect(directions.length, 4);
        for (final dir in directions) {
          expect(dir.direction, TextDirection.ltr);
        }
      });

      test('handles text with mixed newline types', () {
        const content = 'First\nSecond\rThird\r\nFourth';
        final directions = controller.getParagraphDirections(content);
        // Split by \n only, so \r and \r\n are treated as part of text
        expect(directions.length, greaterThan(0));
      });

      test('handles Unicode characters', () {
        expect(controller.detectParagraphDirection('你好'), TextDirection.ltr);
        expect(
            controller.detectParagraphDirection('مرحبا 你好'), TextDirection.rtl);
      });

      test('handles RTL marks and LTR marks', () {
        // Right-to-Left Mark (U+200F)
        expect(controller.detectParagraphDirection('\u200Fمرحبا'),
            TextDirection.rtl);
        // Left-to-Right Mark (U+200E)
        expect(controller.detectParagraphDirection('\u200EHello'),
            TextDirection.ltr);
      });
    });

    group('Performance', () {
      test('handles large multi-paragraph content efficiently', () {
        final paragraphs = List.generate(1000, (i) {
          return i % 2 == 0 ? 'مرحبا بك $i' : 'Hello World $i';
        });
        final content = paragraphs.join('\n');

        final stopwatch = Stopwatch()..start();
        final directions = controller.getParagraphDirections(content);
        stopwatch.stop();

        expect(directions.length, 1000);
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('single paragraph detection is fast', () {
        final longText = 'مرحبا بك في التطبيق ' * 100;

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 100; i++) {
          controller.detectParagraphDirection(longText);
        }
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
