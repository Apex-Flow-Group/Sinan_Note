// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/text/word_diff.dart';

String _old(List<DiffSpan> s) =>
    s.where((x) => x.type != DiffType.added).map((x) => x.text).join();
String _new(List<DiffSpan> s) =>
    s.where((x) => x.type != DiffType.removed).map((x) => x.text).join();

void main() {
  test('identical texts are one equal span', () {
    expect(WordDiff.compute('a b c', 'a b c'),
        [const DiffSpan(DiffType.equal, 'a b c')]);
  });

  test('a changed word in the middle', () {
    final spans = WordDiff.compute('one two three', 'one TWO three');
    expect(spans, const [
      DiffSpan(DiffType.equal, 'one '),
      DiffSpan(DiffType.removed, 'two'),
      DiffSpan(DiffType.added, 'TWO'),
      DiffSpan(DiffType.equal, ' three'),
    ]);
  });

  test('empty sides', () {
    expect(WordDiff.compute('', 'new text'),
        [const DiffSpan(DiffType.added, 'new text')]);
    expect(
        WordDiff.compute('old', ''), [const DiffSpan(DiffType.removed, 'old')]);
    expect(WordDiff.compute('', ''), isEmpty);
  });

  test('both texts are always reconstructed exactly', () {
    const pairs = [
      ('مرحبا بالعالم الجميل', 'مرحبا بالعالم'),
      ('a\nb\nc', 'a\nx\nc\nd'),
      ('the quick brown fox', 'a quick red fox jumps'),
      ('  spaced   out  ', 'spaced out'),
    ];
    for (final (a, b) in pairs) {
      final spans = WordDiff.compute(a, b);
      expect(_old(spans), a);
      expect(_new(spans), b);
    }
  });

  test('consecutive spans of one type are merged', () {
    final spans = WordDiff.compute('x', 'a b c x');
    expect(spans.first, const DiffSpan(DiffType.added, 'a b c '));
    for (var i = 1; i < spans.length; i++) {
      expect(spans[i].type, isNot(spans[i - 1].type));
    }
  });

  test('a small edit in a huge text stays cheap and exact', () {
    final body = List.generate(50000, (i) => 'w$i').join(' ');
    final spans = WordDiff.compute('$body end', '$body END');
    expect(spans.length, 3);
    expect(spans[1], const DiffSpan(DiffType.removed, 'end'));
    expect(spans[2], const DiffSpan(DiffType.added, 'END'));
  });

  test('beyond the table limit: whole middle removed then added', () {
    final a = List.generate(3000, (i) => 'a$i').join(' ');
    final b = List.generate(3000, (i) => 'b$i').join(' ');
    final spans = WordDiff.compute(a, b);
    expect(spans, [
      DiffSpan(DiffType.removed, a),
      DiffSpan(DiffType.added, b),
    ]);
  });

  test('ofPair is compute for isolates', () {
    expect(WordDiff.ofPair(('a b', 'a c')), WordDiff.compute('a b', 'a c'));
  });
}
