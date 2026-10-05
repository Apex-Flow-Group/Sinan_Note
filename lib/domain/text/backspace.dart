// Copyright © 2025 Apex Flow Group. All rights reserved.

/// الحذف للخلف في نص عربي مُشكَّل: تُحذف آخر حركة أولاً، ثم التي قبلها،
/// ثم الحرف نفسه حين لا تبقى حركات.
///
/// المؤشر بين حرف وحركاته (بعد لمس، أو من لوحة المفاتيح) يُعامل كأنه بعد
/// الحركات: الحذف لا يُسقط الحرف ويترك حركاته معلّقة على الحرف السابق.
abstract final class Backspace {
  /// المدى الذي يُحذف عند المؤشر [caret]، أو null حين لا حركات عنده
  /// (الحذف المعتاد: حرف كامل).
  static ({int start, int end})? range(String text, int caret) {
    if (caret <= 0 || caret > text.length) return null;
    var end = caret;
    while (end < text.length && isMark(text.codeUnitAt(end))) {
      end++;
    }
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
