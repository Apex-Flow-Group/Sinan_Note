// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// ألوان محتوى ثابتة في المحرر لا تتبع الثيم:
/// - حبر فوق لون خلفية الملاحظة الذي اختاره المستخدم (يُختار حسب سطوع
///   الخلفية لا حسب ثيم التطبيق).
/// - ألوان النص التي يختارها المستخدم وتُحفظ في المستند.
/// - لوحة عرض الكود والماركداون.
abstract final class EditorPalette {
  // ── حبر فوق خلفية الملاحظة ───────────────────────────────────────────────

  /// نص فوق خلفية ملاحظة داكنة.
  static const inkOnDark = Color(0xFFFFFFFF);

  /// نص فوق خلفية ملاحظة فاتحة.
  static const inkOnLight = Color(0xDD000000);

  /// نص ثانوي فوق خلفية ملاحظة داكنة (أبيض 70%).
  static const softInkOnDark = Color(0xB3FFFFFF);

  /// تلميح (hint) فوق خلفية ملاحظة داكنة.
  static const hintOnDark = Color(0x8AFFFFFF);

  /// تلميح (hint) فوق خلفية ملاحظة فاتحة.
  static const hintOnLight = Color(0x73000000);

  /// عناصر خافتة جداً (مؤشر التحميل، أرقام الأسطر) فوق خلفية داكنة.
  static const faintOnDark = Color(0x62FFFFFF);

  /// عناصر خافتة جداً فوق خلفية فاتحة.
  static const faintOnLight = Color(0x61000000);

  /// صبغة تُمزج (مع شفافية) فوق خلفية داكنة لتفتيحها.
  static const tintOnDark = Color(0xFFFFFFFF);

  /// صبغة تُمزج (مع شفافية) فوق خلفية فاتحة لتعتيمها.
  static const tintOnLight = Color(0xFF000000);

  /// سطح أبيض ثابت (المكبّر وخلفية الكود الافتراضية في الوضع الفاتح).
  static const paper = Color(0xFFFFFFFF);

  // ── ألوان النص التي يختارها المستخدم (تُحفظ قيمتها في المستند) ─────────

  /// قائمة ألوان النص في منتقي لون النص؛ القيم ثابتة لأنها تُكتب في المستند.
  static const textColors = <Color>[
    Color(0xFFF44336), // أحمر
    Color(0xFF2196F3), // أزرق
    Color(0xFF4CAF50), // أخضر
    Color(0xFFFF9800), // برتقالي
    Color(0xFF9C27B0), // بنفسجي
    Color(0xFFE91E63), // وردي
    Color(0xFF009688), // تركوازي
    Color(0xFFFBC02D), // أصفر داكن
    Color(0xFF00BCD4), // سماوي
    Color(0xFFFFFFFF), // أبيض
    Color(0xDD000000), // أسود
  ];

  // ── عرض الكود ──────────────────────────────────────────────────────────

  /// خلفية ورقة معاينة الكود في الوضع الداكن.
  static const codeSheetDark = Color(0xFF1E1E2E);

  /// خلفية كتلة الكود في معاينة الكود (داكن).
  static const codeBlockDark = Color(0xFF12121F);

  /// خلفية كتلة الكود في معاينة الكود (فاتح، على نمط GitHub).
  static const codeBlockLight = Color(0xFFF6F8FA);

  // ── عرض الماركداون ─────────────────────────────────────────────────────

  /// خلفية كتل الكود في الماركداون (داكن، One Dark).
  static const markdownCodeDark = Color(0xFF282C34);

  /// خلفية كتل الكود في الماركداون (فاتح).
  static const markdownCodeLight = Color(0xFFFAFAFA);

  /// لون الروابط في الماركداون (داكن).
  static const markdownLinkDark = Color(0xFF40C4FF);

  /// لون الروابط في الماركداون (فاتح).
  static const markdownLinkLight = Color(0xFF2196F3);

  /// لون الكود المضمّن في الماركداون (داكن).
  static const markdownInlineCodeDark = Color(0xFF69F0AE);

  /// لون الكود المضمّن في الماركداون (فاتح).
  static const markdownInlineCodeLight = Color(0xFF2E7D32);
}
