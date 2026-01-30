// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/foundation.dart';

/// نظام تسجيل موحد للتطبيق
class AppLogger {
  static const String _prefix = '🔷 Sinan Note';

  /// معلومات عامة
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('$_prefix ${tag != null ? "[$tag]" : ""} ℹ️ $message');
    }
  }

  /// تحذيرات
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('$_prefix ${tag != null ? "[$tag]" : ""} ⚠️ $message');
    }
  }

  /// أخطاء
  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$_prefix ${tag != null ? "[$tag]" : ""} ❌ $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }

  /// نجاح
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('$_prefix ${tag != null ? "[$tag]" : ""} ✅ $message');
    }
  }

  /// تصحيح
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('$_prefix ${tag != null ? "[$tag]" : ""} 🐛 $message');
    }
  }
}
