// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

/// معالجة اتجاه النص — مصدر واحد للعارض والمحرر
/// يستخدم Bidi.detectRtlDirectionality من حزمة intl الرسمية
/// تتجاهل تلقائياً: أرقام، رموز، ترقيم (#، -، •، :)، فراغات
class TextDirectionUtils {
  /// يحدد اتجاه النص بناءً على أول حرف أبجدي قوي
  static TextDirection getDirection(String text) {
    if (text.isEmpty) return TextDirection.rtl;
    return Bidi.detectRtlDirectionality(text)
        ? TextDirection.rtl
        : TextDirection.ltr;
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
