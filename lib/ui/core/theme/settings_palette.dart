// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// ألوان ثابتة في شاشات الإعدادات والنسخ والمزامنة ليس لها معنى في الثيم:
/// ألوان علامة Google التي تبقى كما هي في الفاتح والداكن.
abstract final class SettingsPalette {
  /// أزرق Google — أيقونة Google Drive وزر الدخول إليه.
  static const googleBlue = Color(0xFF4285F4);

  /// النص والأيقونة فوق [googleBlue].
  static const onGoogleBlue = Color(0xFFFFFFFF);
}
