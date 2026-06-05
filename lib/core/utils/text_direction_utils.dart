// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/widgets.dart';

/// معالجة اتجاه النص — مصدر واحد للعارض والمحرر
class TextDirectionUtils {
  // RTL Unicode ranges: Arabic, Hebrew, Thaana, etc.
  static final _rtlRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF'
    r'\u0590-\u05FF\u07C0-\u07FF\uFB1D-\uFDFF\uFE70-\uFEFF]',
  );

  // أول حرف أبجدي فعلي (عربي أو إنجليزي) — يتجاهل كل ما قبله
  static final _firstLetterRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF'
    r'\u0590-\u05FF\u07C0-\u07FF\uFB1D-\uFDFF\uFE70-\uFEFF'
    r'a-zA-Z]',
  );

  /// يحدد اتجاه النص بناءً على أول حرف أبجدي فعلي
  /// يتجاهل: أرقام، رموز، ترقيم (#، -، •، :)، فراغات
  static TextDirection getDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;
    final match = _firstLetterRegex.firstMatch(text);
    if (match == null) return TextDirection.rtl;
    return _rtlRegex.hasMatch(match.group(0)!)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// يحدد اتجاه فقرة واحدة
  static TextDirection getDirectionForParagraph(String paragraph) {
    return getDirection(paragraph);
  }

  /// يحدد الاتجاه الغالب في النص كاملاً (للعارض)
  static TextDirection getDominantDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;

    int rtlCount = 0;
    int ltrCount = 0;

    for (final char in text.runes) {
      final c = String.fromCharCode(char);
      if (_rtlRegex.hasMatch(c)) {
        rtlCount++;
      } else if (RegExp(r'[a-zA-Z]').hasMatch(c)) {
        ltrCount++;
      }
    }

    if (rtlCount == 0 && ltrCount == 0) return TextDirection.rtl;
    return rtlCount >= ltrCount ? TextDirection.rtl : TextDirection.ltr;
  }
}
