// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/services.dart';


/// حد أقصى آمن للصق: 50,000 حرف (~50KB نص عادي)
const int _kMaxPasteLength = 50000;

/// خدمة تأمين الحافظة — تعترض اللصق وتتحقق منه قبل وصوله للمحرر
class ClipboardGuard {
  ClipboardGuard._();

  /// يقرأ النص من الحافظة مع التحقق الأمني
  ///
  /// يُرجع:
  /// - النص المقتطع إذا تجاوز الحد
  /// - null إذا كانت الحافظة فارغة أو تحتوي صورة فقط
  static Future<ClipboardResult> getSafeText() async {
    ClipboardData? data;
    try {
      data = await Clipboard.getData(Clipboard.kTextPlain);
    } catch (_) {
      return ClipboardResult.empty();
    }

    final text = data?.text;

    // حافظة فارغة أو تحتوي صورة (text يكون null)
    if (text == null || text.isEmpty) {
      return ClipboardResult.empty();
    }

    // تجاوز الحد الأقصى
    if (text.length > _kMaxPasteLength) {
      return ClipboardResult.truncated(
        text.substring(0, _kMaxPasteLength),
        originalLength: text.length,
      );
    }

    return ClipboardResult.ok(text);
  }
}

enum ClipboardStatus { ok, truncated, empty }

class ClipboardResult {
  final String? text;
  final ClipboardStatus status;
  final int originalLength;

  const ClipboardResult._({
    required this.text,
    required this.status,
    this.originalLength = 0,
  });

  factory ClipboardResult.ok(String text) =>
      ClipboardResult._(text: text, status: ClipboardStatus.ok);

  factory ClipboardResult.truncated(String text, {required int originalLength}) =>
      ClipboardResult._(
        text: text,
        status: ClipboardStatus.truncated,
        originalLength: originalLength,
      );

  factory ClipboardResult.empty() =>
      const ClipboardResult._(text: null, status: ClipboardStatus.empty);

  bool get isOk => status == ClipboardStatus.ok;
  bool get isTruncated => status == ClipboardStatus.truncated;
  bool get isEmpty => status == ClipboardStatus.empty;
}

