import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/ui/core/direction/text_direction.dart';

void main() {
  const rtl = TextDirection.rtl;
  const ltr = TextDirection.ltr;

  group('strongDirectionOf: the first decisive character wins', () {
    final cases = <String, TextDirection?>{
      'مرحبا': rtl,
      'Hello': ltr,
      'مرحبا hello world how are you': rtl,
      'Hello مرحبا بكم جميعاً في التطبيق': ltr,
      '   - • مرحبا': rtl,
      '2025 سنة': ltr,
      '٢٠٢٥ year': rtl,
      '۱۲۳ Persian digits': rtl,
      'שלום': rtl,
      'Привет': ltr,
      'Ελληνικά': ltr,
      'Café': ltr,
      '': null,
      '   ': null,
      '!?.,-()': null,
      '😀👍': null,
    };
    cases.forEach((text, expected) {
      test('"$text" → $expected', () {
        expect(strongDirectionOf(text), expected);
      });
    });
  });

  test('directionOf falls back when nothing decides', () {
    expect(directionOf('...', fallback: ltr), ltr);
    expect(directionOf('...'), rtl);
  });
}
