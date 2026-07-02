// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

/// معالجة اتجاه النص — مصدر واحد للعارض والمحرر
/// يستخدم Bidi.detectRtlDirectionality من حزمة intl الرسمية
/// مع معاملة خاصة للأرقام:
/// - أرقام إنجليزية (0-9) → LTR
/// - أرقام هندية عربية (٠-٩) → RTL
class TextDirectionUtils {
  /// أرقام إنجليزية
  static final _westernDigit = RegExp(r'[0-9]');

  /// أرقام هندية عربية
  static final _arabicIndicDigit = RegExp(r'[\u0660-\u0669]');

  /// حرف أبجدي قوي (عربي أو لاتيني)
  static final _strongChar =
      RegExp(r'[a-zA-Z\u0600-\u065F\u066A-\u06FF\u0750-\u077F]');

  /// يحدد اتجاه النص بناءً على أول حرف أبجدي قوي أو رقم
  static TextDirection getDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;

    // امسح من البداية: أول حرف قوي أو رقم يحدد الاتجاه
    for (int i = 0; i < text.length; i++) {
      final ch = text[i];

      // حرف أبجدي قوي — استخدم Bidi العادي من هذه النقطة
      if (_strongChar.hasMatch(ch)) {
        return Bidi.detectRtlDirectionality(text)
            ? TextDirection.rtl
            : TextDirection.ltr;
      }

      // رقم هندي عربي = RTL
      if (_arabicIndicDigit.hasMatch(ch)) {
        return TextDirection.rtl;
      }

      // رقم إنجليزي = LTR
      if (_westernDigit.hasMatch(ch)) {
        return TextDirection.ltr;
      }
    }

    // لا يوجد أي حرف أو رقم — افتراضي RTL
    return TextDirection.rtl;
  }

  /// يحدد اتجاه فقرة واحدة
  static TextDirection getDirectionForParagraph(String paragraph) {
    return getDirection(paragraph);
  }

  /// يحدد الاتجاه الغالب في النص كاملاً
  static TextDirection getDominantDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;
    return Bidi.detectRtlDirectionality(text)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}
