// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// ألوان ثابتة بلا مقابل دلالي في [ColorScheme] أو AppColors.
abstract final class CommonPalette {
  /// لون هوية إجراء النسخة «حفظ يدوي» في سجل النسخ.
  static const versionManualSave = Color(0xFF4CAF50);

  /// لون هوية إجراء النسخة «حفظ تلقائي» في سجل النسخ.
  static const versionAutoSave = Color(0xFF2196F3);

  /// لون هوية إجراء النسخة «إنشاء» في سجل النسخ.
  static const versionCreated = Color(0xFF9C27B0);

  /// لون هوية إجراء النسخة «أرشفة» في سجل النسخ.
  static const versionArchived = Color(0xFFFF9800);

  /// لون هوية إجراء النسخة «استعادة» في سجل النسخ.
  static const versionRestored = Color(0xFF009688);

  /// لون هوية أي إجراء نسخة آخر (تعديل) في سجل النسخ.
  static const versionOther = Color(0xFF9E9E9E);

  /// علامة/نص فوق لون ملاحظة فاتح يختاره المستخدم (لا يتبع الثيم لأن
  /// الخلفية لون محتوى ثابت).
  static const onLightSwatch = Color(0x8A000000);

  /// علامة/نص فوق لون ملاحظة داكن يختاره المستخدم.
  static const onDarkSwatch = Color(0xFFFFFFFF);

  /// أول لون في توهج حقل البحث المتدرج (سماوي).
  static const searchGlowStart = Color(0xFF00D4FF);

  /// ثاني لون في توهج حقل البحث المتدرج (بنفسجي).
  static const searchGlowEnd = Color(0xFF7B2FFF);
}
