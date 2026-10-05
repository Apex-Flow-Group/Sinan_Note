// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/text/arabic_marks.dart';

const _ba = 'ب';
const _fatha = '\u064E';
const _kasra = '\u0650';
const _shadda = '\u0651';
const _tanween = '\u064B';
const _sukun = '\u0652';

/// يطبّق الحذف كما يطبّقه المحرر: المدى، أو حرف واحد قبل المؤشر.
(String, int) _backspace(String text, int caret) {
  final r =
      ArabicMarks.backspace(text, caret) ?? (start: caret - 1, end: caret);
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
    expect(ArabicMarks.backspace('$_ba$_tanween', 2), (start: 1, end: 2));
    expect(ArabicMarks.backspace('$_ba$_sukun', 2), (start: 1, end: 2));
    expect(ArabicMarks.backspace('$_ba$_kasra', 2), (start: 1, end: 2));
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
    expect(ArabicMarks.backspace('كتب', 3), isNull);
    expect(ArabicMarks.backspace('abc', 2), isNull);
    expect(ArabicMarks.backspace('$_ba$_fatha ك', 4), isNull);
  });

  test('at the start, or out of range, nothing special', () {
    expect(ArabicMarks.backspace('$_ba$_fatha', 0), isNull);
    expect(ArabicMarks.backspace(_ba, 5), isNull);
    expect(ArabicMarks.backspace('', 0), isNull);
  });

  group('the caret never sits between a letter and its marks', () {
    test('it moves past all the marks', () {
      // كَتب: بعد الكاف وقبل فتحتها
      expect(ArabicMarks.caretOutsideMarks('ك$_fatha' 'تب', 1), 2);
      expect(ArabicMarks.caretOutsideMarks('ب$_shadda$_fatha' 'ك', 1), 3);
      expect(ArabicMarks.caretOutsideMarks('ب$_shadda$_fatha' 'ك', 2), 3);
    });

    test('so a letter typed there keeps the mark on its letter', () {
      const text = 'ك$_fatha' 'تب';
      final caret = ArabicMarks.caretOutsideMarks(text, 1);
      expect(text.replaceRange(caret, caret, 'ل'), 'ك$_fatha' 'لتب');
    });

    test('anywhere else it stays', () {
      expect(ArabicMarks.caretOutsideMarks('ك$_fatha' 'تب', 2), 2);
      expect(ArabicMarks.caretOutsideMarks('كتب', 1), 1);
      expect(ArabicMarks.caretOutsideMarks('ك$_fatha', 0), 0);
      expect(ArabicMarks.caretOutsideMarks('ك$_fatha', 2), 2);
      expect(ArabicMarks.caretOutsideMarks('', 0), 0);
    });
  });

  test('marks are recognised, letters are not', () {
    for (final m in [0x064B, 0x064E, 0x0650, 0x0651, 0x0652, 0x0670, 0x0654]) {
      expect(ArabicMarks.isMark(m), isTrue, reason: m.toRadixString(16));
    }
    for (final c in 'بتثاأإآءىي٠١ ab'.codeUnits) {
      expect(ArabicMarks.isMark(c), isFalse, reason: c.toRadixString(16));
    }
  });
}
