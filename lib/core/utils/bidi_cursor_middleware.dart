// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// BiDi cursor correction middleware.
/// Fixes cursor position when tapping on digit boundaries in Arabic text.
class BiDiCursorCorrectionMiddleware {
  final QuillController controller;

  bool _isCorrectingSelection = false;
  int _previousOffset = -1;

  /// يُوقف تدخل الـ middleware مؤقتاً (أثناء سحب الدمعة مثلاً)
  bool paused = false;

  /// static map — يسمح لأي كود يملك reference للـ controller بإيقاف الـ middleware
  static final Map<QuillController, BiDiCursorCorrectionMiddleware> _instances =
      {};

  /// يُوقف الـ middleware المرتبط بهذا الـ controller
  static void pauseFor(QuillController c) => _instances[c]?.paused = true;

  /// يُعيد تشغيل الـ middleware المرتبط بهذا الـ controller
  static void resumeFor(QuillController c) => _instances[c]?.paused = false;

  static final _digitRun = RegExp(r'^[\d٠-٩]+([.,،][\d٠-٩]+)*');
  static final _arabicOrSpace = RegExp(r'[\u0600-\u06FF\u0750-\u077F\s]');
  static final _digitChar = RegExp(r'[\d٠-٩]');

  BiDiCursorCorrectionMiddleware({required this.controller}) {
    _instances[controller] = this;
    controller.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    if (_isCorrectingSelection) return;
    if (paused) return;

    final selection = controller.selection;
    if (!selection.isCollapsed) return;

    final offset = selection.baseOffset;
    final plainText = controller.document.toPlainText();

    if (offset <= 0 || offset >= plainText.length) return;

    // إذا كان التغيير بمقدار 1 فقط = تنقل بالأسهم → لا تتدخل
    final delta = (offset - _previousOffset).abs();
    _previousOffset = offset;
    if (delta == 1) return;

    final charAtCursor = plainText[offset];
    final charBefore = plainText[offset - 1];

    // الكرسر عند بداية كتلة رقمية في سياق عربي
    if (!_digitChar.hasMatch(charAtCursor)) return;
    if (!_arabicOrSpace.hasMatch(charBefore)) return;

    // احسب طول الكتلة الرقمية
    final match = _digitRun.firstMatch(plainText.substring(offset));
    final runLength = match?.group(0)?.length ?? 0;
    if (runLength == 0) return;

    _isCorrectingSelection = true;
    Future.microtask(() {
      controller.updateSelection(
        TextSelection.collapsed(offset: offset + runLength),
        ChangeSource.local,
      );
      _isCorrectingSelection = false;
    });
  }

  void dispose() {
    _instances.remove(controller);
    controller.removeListener(_onSelectionChanged);
  }
}
