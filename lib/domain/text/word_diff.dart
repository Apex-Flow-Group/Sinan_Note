// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:typed_data';

enum DiffType { equal, added, removed }

class DiffSpan {
  const DiffSpan(this.type, this.text);
  final DiffType type;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is DiffSpan && other.type == type && other.text == text;

  @override
  int get hashCode => Object.hash(type, text);

  @override
  String toString() => '${type.name}(${text.replaceAll('\n', r'\n')})';
}

/// فرق على مستوى الكلمات (والمسافات كرموز مستقلة).
///
/// يُقص البادئ واللاحق المشتركان أولاً (التعديل المعتاد صغير وسط نص كبير)،
/// ثم LCS على الوسط فقط. إن تجاوز الوسط [maxCells] يُعرض محذوفاً ثم مضافاً
/// كما هو: فرق صحيح وإن كان أقل دقة، بدل ذاكرة بلا حد.
abstract final class WordDiff {
  static const maxCells = 4000000;

  static final _tokens = RegExp(r'(?<=\s)|(?=\s)');

  /// لـ `compute`: زوج (القديم، الجديد).
  static List<DiffSpan> ofPair((String, String) texts) =>
      compute(texts.$1, texts.$2);

  static List<DiffSpan> compute(String oldText, String newText) {
    final a = oldText.isEmpty ? const <String>[] : oldText.split(_tokens);
    final b = newText.isEmpty ? const <String>[] : newText.split(_tokens);

    var start = 0;
    while (start < a.length && start < b.length && a[start] == b[start]) {
      start++;
    }
    var endA = a.length, endB = b.length;
    while (endA > start && endB > start && a[endA - 1] == b[endB - 1]) {
      endA--;
      endB--;
    }

    final out = _Spans();
    out.add(DiffType.equal, a.sublist(0, start));
    _middle(a.sublist(start, endA), b.sublist(start, endB), out);
    out.add(DiffType.equal, a.sublist(endA));
    return out.spans;
  }

  static void _middle(List<String> a, List<String> b, _Spans out) {
    final m = a.length, n = b.length;
    if (m == 0 || n == 0 || (m + 1) * (n + 1) > maxCells) {
      out.add(DiffType.removed, a);
      out.add(DiffType.added, b);
      return;
    }
    // جدول LCS مسطّح: lcs[i][j] = lcs[i * w + j]
    final w = n + 1;
    final lcs = Int32List((m + 1) * w);
    for (var i = m - 1; i >= 0; i--) {
      for (var j = n - 1; j >= 0; j--) {
        lcs[i * w + j] = a[i] == b[j]
            ? lcs[(i + 1) * w + j + 1] + 1
            : (lcs[(i + 1) * w + j] > lcs[i * w + j + 1]
                ? lcs[(i + 1) * w + j]
                : lcs[i * w + j + 1]);
      }
    }
    var i = 0, j = 0;
    while (i < m && j < n) {
      if (a[i] == b[j]) {
        out.add(DiffType.equal, [a[i++]]);
        j++;
      } else if (lcs[(i + 1) * w + j] >= lcs[i * w + j + 1]) {
        out.add(DiffType.removed, [a[i++]]);
      } else {
        out.add(DiffType.added, [b[j++]]);
      }
    }
    out.add(DiffType.removed, a.sublist(i));
    out.add(DiffType.added, b.sublist(j));
  }
}

/// يدمج الرموز المتتالية من النوع نفسه في مقطع واحد.
class _Spans {
  final spans = <DiffSpan>[];

  void add(DiffType type, List<String> tokens) {
    if (tokens.isEmpty) return;
    final text = tokens.join();
    if (spans.isNotEmpty && spans.last.type == type) {
      spans.last = DiffSpan(type, spans.last.text + text);
    } else {
      spans.add(DiffSpan(type, text));
    }
  }
}
