// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/text/backspace.dart';

const _ba = 'ب';
const _fatha = 'َ';
const _kasra = 'ِ';
const _shadda = 'ّ';
const _tanween = 'ً';
const _sukun = 'ْ';

/// يطبّق الحذف كما يطبّقه المحرر: المدى، أو حرف واحد قبل المؤشر.
(String, int) _backspace(String text, int caret) {
  final r = Backspace.range(text, caret) ?? (start: caret - 1, end: caret);
  return (text.replaceRange(r.start, r.end, ''), r.start);
}

void main() {
  test('a letter with one mark: the mark first, then the letter', () {
    var (text, caret) = ('$_ba$_fatha', 2);
    (text, caret) = _backspace(text, caret);
    expect(text, _ba);
    (text, caret) = _backspace(text, caret);
    expect(text, '');
  });

  test('shadda with a vowel: the vowel, then the shadda, then the letter', () {
    var (text, caret) = ('$_ba$_shadda$_fatha', 3);
    (text, caret) = _backspace(text, caret);
    expect(text, '$_ba$_shadda');
    (text, caret) = _backspace(text, caret);
    expect(text, _ba);
    (text, caret) = _backspace(text, caret);
    expect(text, '');
  });

  test('tanween and sukun are marks too', () {
    expect(Backspace.range('$_ba$_tanween', 2), (start: 1, end: 2));
    expect(Backspace.range('$_ba$_sukun', 2), (start: 1, end: 2));
    expect(Backspace.range('$_ba$_kasra', 2), (start: 1, end: 2));
  });

  test('a caret between a letter and its marks never orphans them', () {
    // المؤشر بعد الباء وقبل حركاتها
    var (text, caret) = ('ك$_ba$_shadda$_fatha', 2);
    (text, caret) = _backspace(text, caret);
    expect(text, 'ك$_ba$_shadda');
    (text, caret) = _backspace(text, caret);
    expect(text, 'ك$_ba');
    (text, caret) = _backspace(text, caret);
    expect(text, 'ك');
  });

  test('no marks at the caret: the usual deletion', () {
    expect(Backspace.range('كتب', 3), isNull);
    expect(Backspace.range('abc', 2), isNull);
    expect(Backspace.range('$_ba$_fatha ك', 4), isNull);
  });

  test('at the start, or out of range, nothing special', () {
    expect(Backspace.range('$_ba$_fatha', 0), isNull);
    expect(Backspace.range(_ba, 5), isNull);
    expect(Backspace.range('', 0), isNull);
  });

  test('marks are recognised, letters are not', () {
    for (final m in [0x064B, 0x064E, 0x0650, 0x0651, 0x0652, 0x0670, 0x0654]) {
      expect(Backspace.isMark(m), isTrue, reason: m.toRadixString(16));
    }
    for (final c in 'بتثاأإآءىي٠١ ab'.codeUnits) {
      expect(Backspace.isMark(c), isFalse, reason: c.toRadixString(16));
    }
  });
}
