// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// ألوان ثابتة في الشاشة الرئيسية ليس لها معنى دلالي في الثيم.
abstract final class HomePalette {
  /// أزرق Google الرسمي لأيقونة Google Drive في القائمة الجانبية.
  static const googleBlue = Color(0xFF4285F4);

  /// عنوان الملاحظة فوق لون بطاقة فاتح. يتبع إضاءة لون الملاحظة الذي اختاره
  /// المستخدم، لا سطوع الثيم، لذلك ليس رمزاً في الثيم.
  static const noteTitleOnLight = Color(0xDD000000);

  /// عنوان الملاحظة فوق لون بطاقة داكن.
  static const noteTitleOnDark = Color(0xFFFFFFFF);

  /// نص معاينة الملاحظة فوق لون بطاقة فاتح.
  static const noteBodyOnLight = Color(0xFF616161);

  /// نص معاينة الملاحظة فوق لون بطاقة داكن.
  static const noteBodyOnDark = Color(0xFFE0E0E0);
}
