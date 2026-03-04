// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// حدود أمان المحتوى
const int _kMaxTextLength = 100000;
const int _kMaxCodeLength = 50000;

/// الحد الأقصى للنص المستقبَل من المشاركة الخارجية
const int kMaxSharedTextLength = _kMaxTextLength;

/// صمام أمان يعمل بعد اللصق مباشرة — يقتطع المحتوى إذا تجاوز الحد
class ContentGuard {
  ContentGuard._();

  static bool _guardingText = false;
  static bool _guardingQuill = false;
  static bool _guardingCode = false;

  /// صمام TextEditingController (simple / reminder / checklist)
  static void guardText(TextEditingController ctrl) {
    if (_guardingText) return;
    if (ctrl.text.length <= _kMaxTextLength) return;
    _guardingText = true;
    final truncated = ctrl.text.substring(0, _kMaxTextLength);
    ctrl.value = TextEditingValue(
      text: truncated,
      selection: const TextSelection.collapsed(offset: _kMaxTextLength),
    );
    _guardingText = false;
  }

  /// صمام QuillController (rich / reminder)
  static void guardQuill(QuillController ctrl) {
    if (_guardingQuill) return;
    final plain = ctrl.document.toPlainText();
    if (plain.length <= _kMaxTextLength) return;
    _guardingQuill = true;
    // احذف الزيادة من نهاية الـ document
    final excess = plain.length - _kMaxTextLength;
    final docLen = ctrl.document.length;
    ctrl.document.delete(docLen - 1 - excess, excess);
    _guardingQuill = false;
  }

  /// صمام CodeController (code)
  static void guardCode(CodeController ctrl) {
    if (_guardingCode) return;
    if (ctrl.text.length <= _kMaxCodeLength) return;
    _guardingCode = true;
    ctrl.text = ctrl.text.substring(0, _kMaxCodeLength);
    _guardingCode = false;
  }
}
