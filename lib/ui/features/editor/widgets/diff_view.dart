// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sinan_note/domain/text/word_diff.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';

/// الفرق بين نصين، يُحسب في isolate مرة لكل زوج نصوص.
class DiffView extends StatefulWidget {
  const DiffView({super.key, required this.oldText, required this.newText});

  final String oldText;
  final String newText;

  @override
  State<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends State<DiffView> {
  late Future<List<DiffSpan>> _spans;

  @override
  void initState() {
    super.initState();
    _spans = _compute();
  }

  @override
  void didUpdateWidget(DiffView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.oldText != widget.oldText ||
        oldWidget.newText != widget.newText) {
      _spans = _compute();
    }
  }

  Future<List<DiffSpan>> _compute() =>
      compute(WordDiff.ofPair, (widget.oldText, widget.newText));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DiffSpan>>(
      future: _spans,
      builder: (context, snapshot) {
        final spans = snapshot.data;
        if (spans == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final colors = context.colors;
        return Text.rich(
          TextSpan(
            children: [
              for (final s in spans)
                switch (s.type) {
                  DiffType.added => TextSpan(
                      text: s.text,
                      style: TextStyle(
                        color: colors.success,
                        backgroundColor: colors.successContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  DiffType.removed => TextSpan(
                      text: s.text,
                      style: TextStyle(
                        color: colors.danger,
                        backgroundColor: colors.dangerContainer,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  DiffType.equal => TextSpan(text: s.text),
                },
            ],
          ),
          style: TextStyle(
              fontSize: context.text.bodyMedium?.fontSize, height: 1.6),
        );
      },
    );
  }
}
