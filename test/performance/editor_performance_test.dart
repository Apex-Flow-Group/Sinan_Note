// Copyright © 2025 Apex Flow Group. All rights reserved.

// ignore_for_file: avoid_print

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/widgets/editor/paste_handler.dart';

// ── مولّد نصوص ─────────────────────────────────────────────────────────────

String _generateText(int chars, {bool arabic = true}) {
  final sentence = arabic
      ? 'هذا نص تجريبي طويل يُستخدم لاختبار أداء المحرر مع النصوص الكبيرة. '
      : 'This is a long test text used to benchmark editor performance with large content. ';
  final buf = StringBuffer();
  while (buf.length < chars) {
    buf.write(sentence);
  }
  return buf.toString().substring(0, chars);
}

String _generateMixedText(int chars) {
  const ar = 'هذا نص عربي في المحرر يحتوي على كلمات ومعاني مختلفة. ';
  const en = 'This is English text mixed with Arabic content. ';
  final buf = StringBuffer();
  var toggle = true;
  while (buf.length < chars) {
    buf.write(toggle ? ar : en);
    toggle = !toggle;
  }
  return buf.toString().substring(0, chars);
}

// ── الاختبارات ──────────────────────────────────────────────────────────────

void main() {
  group('Editor Performance — buildDeltaInIsolate', () {
    for (final size in [20000, 50000, 100000]) {
      test('Arabic $size chars', () async {
        final text = _generateText(size, arabic: true);
        final sw = Stopwatch()..start();
        final delta = await buildDeltaInIsolate(text);
        sw.stop();

        expect(delta.length, greaterThan(0));
        print('buildDeltaInIsolate | Arabic | $size chars → ${sw.elapsedMilliseconds}ms');
      });

      test('English $size chars', () async {
        final text = _generateText(size, arabic: false);
        final sw = Stopwatch()..start();
        final delta = await buildDeltaInIsolate(text);
        sw.stop();

        expect(delta.length, greaterThan(0));
        print('buildDeltaInIsolate | English | $size chars → ${sw.elapsedMilliseconds}ms');
      });

      test('Mixed AR+EN $size chars', () async {
        final text = _generateMixedText(size);
        final sw = Stopwatch()..start();
        final delta = await buildDeltaInIsolate(text);
        sw.stop();

        expect(delta.length, greaterThan(0));
        print('buildDeltaInIsolate | Mixed | $size chars → ${sw.elapsedMilliseconds}ms');
      });
    }
  });

  group('Editor Performance — Document.fromJson', () {
    for (final size in [20000, 50000, 100000]) {
      test('load delta $size chars', () async {
        final text = _generateText(size, arabic: true);
        final delta = await buildDeltaInIsolate(text);
        final json = delta.toJson();

        final sw = Stopwatch()..start();
        final doc = Document.fromJson(json);
        sw.stop();

        expect(doc.length, greaterThan(0));
        print('Document.fromJson | $size chars → ${sw.elapsedMilliseconds}ms');
      });
    }
  });

  group('Editor Performance — toPlainText', () {
    for (final size in [20000, 50000, 100000]) {
      test('toPlainText $size chars', () async {
        final text = _generateText(size, arabic: true);
        final delta = await buildDeltaInIsolate(text);
        final doc = Document.fromJson(delta.toJson());

        final sw = Stopwatch()..start();
        final plain = doc.toPlainText();
        sw.stop();

        expect(plain.length, greaterThan(0));
        print('toPlainText | $size chars → ${sw.elapsedMilliseconds}ms');
      });
    }
  });
}
