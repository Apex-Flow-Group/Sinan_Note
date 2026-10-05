// Copyright © 2025 Apex Flow Group. All rights reserved.

/// الحركات العربية (التشكيل) جزء من حرفها: لا يقف المؤشر بينهما، ولا يُحذف
/// الحرف ويترك حركاته.
abstract final class ArabicMarks {
  /// المؤشر بين حرف وحركاته (بعد لمس، أو من لوحة المفاتيح) يُنقل إلى ما بعد
  /// الحركات: الكتابة هناك تبدأ حرفاً جديداً بدل أن تأخذ حركة الحرف السابق.
  static int caretOutsideMarks(String text, int caret) {
    if (caret <= 0 || caret >= text.length) return caret;
    var end = caret;
    while (end < text.length && isMark(text.codeUnitAt(end))) {
      end++;
    }
    return end;
  }

  /// الحذف للخلف: تُحذف آخر حركة أولاً، ثم التي قبلها، ثم الحرف حين لا تبقى
  /// حركات. المدى الذي يُحذف عند [caret]، أو null حين لا حركات عنده (الحذف
  /// المعتاد: حرف كامل).
  static ({int start, int end})? backspace(String text, int caret) {
    if (caret <= 0 || caret > text.length) return null;
    final end = caretOutsideMarks(text, caret);
    if (!isMark(text.codeUnitAt(end - 1))) return null;
    return (start: end - 1, end: end);
  }

  /// علامة تُركَّب على الحرف قبلها (Mn) في كتل العربية: الحركات والتنوين
  /// والشدة والسكون والمدة والهمزة والألف الخنجرية وعلامات المصحف.
  static bool isMark(int unit) =>
      (unit >= 0x0610 && unit <= 0x061A) ||
      (unit >= 0x064B && unit <= 0x065F) ||
      unit == 0x0670 ||
      (unit >= 0x06D6 && unit <= 0x06DC) ||
      (unit >= 0x06DF && unit <= 0x06E4) ||
      (unit >= 0x06E7 && unit <= 0x06E8) ||
      (unit >= 0x06EA && unit <= 0x06ED) ||
      (unit >= 0x08D3 && unit <= 0x08FF && unit != 0x08E2);
}
