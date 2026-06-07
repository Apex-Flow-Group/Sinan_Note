// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';


enum DiffType { equal, added, removed }

class DiffSpan {
  final DiffType type;
  final String text;
  const DiffSpan(this.type, this.text);
}

List<DiffSpan> computeDiff(String oldText, String newText) {
  final a = oldText.split(RegExp(r'(?<=\s)|(?=\s)'));
  final b = newText.split(RegExp(r'(?<=\s)|(?=\s)'));
  final m = a.length, n = b.length;
  final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  for (var i = m - 1; i >= 0; i--) {
    for (var j = n - 1; j >= 0; j--) {
      if (a[i] == b[j]) {
        dp[i][j] = dp[i + 1][j + 1] + 1;
      } else {
        dp[i][j] = dp[i + 1][j] > dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1];
      }
    }
  }
  final spans = <DiffSpan>[];
  var i = 0, j = 0;
  while (i < m && j < n) {
    if (a[i] == b[j]) {
      spans.add(DiffSpan(DiffType.equal, a[i]));
      i++; j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      spans.add(DiffSpan(DiffType.removed, a[i]));
      i++;
    } else {
      spans.add(DiffSpan(DiffType.added, b[j]));
      j++;
    }
  }
  while (i < m) { spans.add(DiffSpan(DiffType.removed, a[i++])); }
  while (j < n) { spans.add(DiffSpan(DiffType.added, b[j++])); }
  return spans;
}

class DiffView extends StatelessWidget {
  final List<DiffSpan> spans;
  const DiffView({super.key, required this.spans});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: spans.map((s) {
          switch (s.type) {
            case DiffType.added:
              return TextSpan(
                text: s.text,
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  backgroundColor: Color(0xFFE8F5E9),
                  fontWeight: FontWeight.w500,
                ),
              );
            case DiffType.removed:
              return TextSpan(
                text: s.text,
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  backgroundColor: Color(0xFFFFEBEE),
                  decoration: TextDecoration.lineThrough,
                ),
              );
            case DiffType.equal:
              return TextSpan(text: s.text);
          }
        }).toList(),
      ),
      style: const TextStyle(fontSize: 14, height: 1.6),
    );
  }
}

