// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'apex_diagnostics_engine.dart';

/// مدير الأخطاء - واجهة بسيطة للاستخدام مع تغذية راجعة للمستخدم
class ApexErrorManager {
  // ✅ الإيميل الرسمي للفريق
  static const String developerEmail = 'contact.apex.flow@gmail.com';
  static final _engine = ApexDiagnosticsEngine();
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Set the navigator key for UI feedback
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Show error feedback to user
  static void _showErrorFeedback(String errorMessage) {
    final context = _navigatorKey?.currentState?.context;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'REPORT',
          textColor: Colors.yellow,
          onPressed: () => _shareErrorLog(),
        ),
      ),
    );
  }

  /// Share error log with user
  static Future<void> _shareErrorLog() async {
    try {
      final log = await _engine.getErrorLog();
      await Share.share(
        'Error Report for Apex Flow Group\n\n$log\n\nSend to: $developerEmail',
        subject: 'Sinan Note - Error Report',
      );
    } catch (e) {
      debugPrint('Failed to share error log: $e');
    }
  }

  /// تغليف عمليات قاعدة البيانات (إلزامي)
  static Future<T> monitorDB<T>(
    Future<T> Function() operation, {
    String name = 'DB_Op',
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      await _engine.logError(
        error: e,
        stackTrace: stack,
        context: 'DATABASE::$name',
      );
      _showErrorFeedback('حدث خطأ في قاعدة البيانات! (Database Error)');
      rethrow;
    }
  }

  /// تغليف العمليات الحرجة (اختياري)
  static Future<T> monitorCritical<T>(
    Future<T> Function() operation,
    String context,
  ) async {
    try {
      return await operation();
    } catch (e, stack) {
      await _engine.logError(
        error: e,
        stackTrace: stack,
        context: 'CRITICAL::$context',
      );
      _showErrorFeedback('حدث خطأ غير متوقع! (Unexpected Error)');
      rethrow;
    }
  }
}
