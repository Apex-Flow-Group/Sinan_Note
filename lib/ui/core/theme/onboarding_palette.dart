// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// ألوان ثابتة لرسومات المقدمة والجولة وبطاقة GitHub في "ما الجديد".
/// هذه هوية بصرية ثابتة (ليلي + ذهبي) لا تتبع ثيم الفاتح/الداكن.
abstract final class OnboardingPalette {
  /// خلفية المقدمة والجولة (أزرق ليلي)، ولون النص فوق الذهبي.
  static const night = Color(0xFF0A1929);

  /// منتصف تدرّج خلفية المقدمة المتحرك.
  static const nightMid = Color(0xFF1A2332);

  /// نهاية تدرّج خلفية المقدمة المتحرك.
  static const nightDeep = Color(0xFF0F1B2A);

  /// بطاقات أقسام الجولة فوق الخلفية الليلية.
  static const card = Color(0xFF132F4C);

  /// الذهبي: الأيقونات والحدود وزر البدء ووميض العنوان.
  static const gold = Color(0xFFFFD700);

  /// الذهبي الداكن على أطراف وميض العنوان.
  static const goldDeep = Color(0xFFB8860B);

  /// قمة الوميض في وسط العنوان.
  static const goldHighlight = Color(0xFFFFF8DC);

  /// النص والأيقونات فوق الخلفية الليلية.
  static const ink = Color(0xFFFFFFFF);

  /// رابط شروط الخدمة فوق الخلفية الليلية.
  static const link = Color(0xFF64B5F6);

  /// زر البدء قبل الموافقة على الشروط.
  static const disabledButton = Color(0xFF444444);

  /// نص زر البدء قبل الموافقة على الشروط.
  static const disabledInk = Color(0xFF757575);

  /// حبر GitHub (نص بطاقة المصدر المفتوح في الفاتح).
  static const githubInk = Color(0xFF24292E);

  /// أزرق GitHub في تدرّج بطاقة المصدر المفتوح (الفاتح).
  static const githubBlue = Color(0xFF0366D6);

  /// بداية تدرّج بطاقة المصدر المفتوح في الداكن.
  static const githubNightStart = Color(0xFF1A1A2E);

  /// نهاية تدرّج بطاقة المصدر المفتوح في الداكن.
  static const githubNightEnd = Color(0xFF16213E);
}
