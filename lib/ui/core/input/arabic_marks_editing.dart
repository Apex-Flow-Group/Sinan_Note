// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/services.dart' show TextRange;
import 'package:flutter_quill/flutter_quill.dart' show QuillControllerConfig;
import 'package:sinan_note/domain/text/arabic_marks.dart';

/// قواعد [ArabicMarks] بصيغة Quill.

/// إعداد كل متحكم ملاحظة: المؤشر لا يقف بين حرف وحركاته.
const noteControllerConfig =
    QuillControllerConfig(caretResolver: caretResolver);

/// `QuillControllerConfig.caretResolver`: لا يقف المؤشر بين حرف وحركاته.
int caretResolver(String text, int caret) =>
    ArabicMarks.caretOutsideMarks(text, caret);

/// `QuillEditorConfig.backspaceResolver`: الحركة تُحذف قبل حرفها، من مفتاح
/// الحذف ومن لوحة مفاتيح الهاتف.
TextRange? backspaceResolver(String text, int caret) {
  final range = ArabicMarks.backspace(text, caret);
  return range == null ? null : TextRange(start: range.start, end: range.end);
}
