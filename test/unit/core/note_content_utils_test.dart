import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/text/note_text.dart';
import 'package:sinan_note/ui/core/quill/quill_migration.dart';

/// المسار القديم: بناء QuillController كامل ثم toPlainText.
String _viaController(String content) =>
    QuillMigration.toPlainText(QuillMigration.controllerFromContent(content));

String _delta(List<Map<String, Object?>> ops) => jsonEncode(ops);

void main() {
  group('NoteText.toDisplayText', () {
    final deltas = {
      'arabic + english lines': _delta([
        {'insert': 'مرحبا بالعالم\n'},
        {'insert': 'Hello world'},
        {
          'insert': '\n',
          'attributes': {'direction': 'rtl'}
        },
      ]),
      'formatting and lists': _delta([
        {
          'insert': 'Bold',
          'attributes': {'bold': true}
        },
        {'insert': ' text\nitem one'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'}
        },
        {'insert': 'item two'},
        {
          'insert': '\n',
          'attributes': {'list': 'ordered'}
        },
      ]),
      'embed': _delta([
        {'insert': 'before\n'},
        {
          'insert': {'image': 'file:///x.png'}
        },
        {'insert': '\nafter\n'},
      ]),
      'trailing blank lines': _delta([
        {'insert': 'text\n\n\n'},
      ]),
      'numbers and mixed': _delta([
        {'insert': '١٢٣ عدد 456 mixed نص\n'},
      ]),
    };

    deltas.forEach((name, content) {
      test('matches the full Quill document for $name', () {
        expect(NoteText.toDisplayText(content), _viaController(content));
      });
    });

    test('plain text is returned as is', () {
      expect(NoteText.toDisplayText('just text'), 'just text');
      expect(NoteText.toDisplayText('[not json'), '[not json');
    });

    test('checklists keep their display format', () {
      final checklist = jsonEncode({
        'title': 'T',
        'items': [
          {'text': 'a', 'isDone': true},
          {'text': 'b', 'isDone': false},
        ],
      });
      expect(NoteText.toDisplayText(checklist), '☑ a\n☐ b');
    });

    test('empty delta is empty text', () {
      expect(NoteText.toDisplayText('[]'), '');
    });

    test('maxChars truncates by characters', () {
      final content = _delta([
        {'insert': 'abcdefghij\n'},
      ]);
      expect(NoteText.toDisplayText(content, maxChars: 4), 'abcd');
    });
  });
}
