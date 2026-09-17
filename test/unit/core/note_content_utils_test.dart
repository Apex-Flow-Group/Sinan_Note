// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/core/utils/note_content_utils.dart';

void main() {
  group('NoteContentUtils.toDisplayText', () {
    test('returns plain text unchanged', () {
      expect(NoteContentUtils.toDisplayText('hello world'), 'hello world');
    });

    test('extracts insert ops from Delta JSON without Quill', () {
      const delta = '[{"insert":"Hello "},{"insert":"world\\n"}]';
      expect(NoteContentUtils.toDisplayText(delta), 'Hello world');
    });

    test('truncates long Delta preview', () {
      final insert = 'a' * 500;
      final delta = '[{"insert":"$insert"}]';
      final preview = NoteContentUtils.toDisplayText(delta, maxChars: 300);
      expect(preview.length, 300);
      expect(preview, 'a' * 300);
    });

    test('checklist JSON becomes readable lines', () {
      const json =
          '{"title":"Tasks","items":[{"id":"1","text":"One","isDone":false},{"id":"2","text":"Two","isDone":true}]}';
      final text = NoteContentUtils.toDisplayText(json);
      expect(text.contains('One'), isTrue);
      expect(text.contains('Two'), isTrue);
    });

    test('malformed Delta still extracts insert text, never returns JSON', () {
      const broken =
          '[{"insert": "نجاحا لافتا في شباك التذاكر", "broken": }]';
      final text = NoteContentUtils.toDisplayText(broken, maxChars: 180);
      expect(text.startsWith('['), isFalse);
      expect(text.contains('نجاحا'), isTrue);
    });

    test('raw Delta JSON is never shown as the preview', () {
      const delta = '[{"insert":"Galaxy Movie"}]';
      final text = NoteContentUtils.toDisplayText(delta, maxChars: 180);
      expect(text, 'Galaxy Movie');
      expect(NoteContentUtils.looksLikeDeltaJson(text), isFalse);
    });
  });
}
