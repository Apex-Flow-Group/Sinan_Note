// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// حدود أمان المحتوى
const int _kMaxTextLength = 100000;
const int _kMaxCodeLength = 50000;

/// الحد الأقصى للنص المستقبَل من المشاركة الخارجية
const int kMaxSharedTextLength = _kMaxTextLength;

/// صمام أمان يعمل بعد اللصق مباشرة — يقتطع المحتوى إذا تجاوز الحد.
/// الاقتطاع يُطلق المستمع نفسه مرة أخرى، فيجد الطول ضمن الحد ويعود.
class ContentGuard {
  ContentGuard._();

  /// صمام TextEditingController (simple / reminder / checklist)
  static void guardText(TextEditingController ctrl) {
    if (ctrl.text.length <= _kMaxTextLength) return;
    final truncated = ctrl.text.substring(0, _kMaxTextLength);
    ctrl.value = TextEditingValue(
      text: truncated,
      selection: const TextSelection.collapsed(offset: _kMaxTextLength),
    );
  }

  /// صمام QuillController (rich / reminder)
  static void guardQuill(QuillController ctrl) {
    final plain = ctrl.document.toPlainText();
    if (plain.length <= _kMaxTextLength) return;
    // احذف الزيادة من نهاية الـ document
    final excess = plain.length - _kMaxTextLength;
    final docLen = ctrl.document.length;
    ctrl.document.delete(docLen - 1 - excess, excess);
  }

  /// صمام CodeController (code)
  static void guardCode(CodeController ctrl) {
    if (ctrl.text.length <= _kMaxCodeLength) return;
    ctrl.text = ctrl.text.substring(0, _kMaxCodeLength);
  }
}
