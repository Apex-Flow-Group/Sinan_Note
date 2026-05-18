// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/widgets.dart';


/// معالجة اتجاه النص — مصدر واحد للعارض والمحرر
class TextDirectionUtils {
  // RTL Unicode ranges: Arabic, Hebrew, Thaana, etc.
  static final _rtlRegex = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF'
    r'\u0590-\u05FF\u07C0-\u07FF\uFB1D-\uFDFF\uFE70-\uFEFF]',
  );

  // رموز وأحرف تُتجاهل عند تحديد الاتجاه
  static final _neutralRegex = RegExp(
    r'^[\s\n\r\t!@#$%^&*()+\-_=+\[\]{}|;:".,<>?/\\`~\d]*',
  );

  /// يحدد اتجاه النص بناءً على أول حرف مؤثر (يتجاهل الرموز والأرقام)
  static TextDirection getDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;
    final stripped = text.replaceAll(_neutralRegex, '');
    if (stripped.isEmpty) return TextDirection.rtl;
    return _rtlRegex.hasMatch(stripped[0])
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

