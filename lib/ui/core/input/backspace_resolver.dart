// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/services.dart' show TextRange;
import 'package:sinan_note/domain/text/backspace.dart';

/// قاعدة [Backspace] بصيغة المحرر (`QuillEditorConfig.backspaceResolver`):
/// تُطبَّق على مفتاح الحذف وعلى ما ترسله لوحة مفاتيح الهاتف.
TextRange? backspaceResolver(String text, int caret) {
  final range = Backspace.range(text, caret);
  return range == null ? null : TextRange(start: range.start, end: range.end);
}
