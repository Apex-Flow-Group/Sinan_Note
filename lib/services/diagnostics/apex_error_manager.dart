// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/services/diagnostics/apex_diagnostics_engine.dart';

/// خطورة الخطأ — تحدد السلوك
enum ApexErrorSeverity {
  /// خطأ متوقع ومعالج — يُسجَّل فقط بدون إزعاج المستخدم
  expected,

  /// خطأ غير متوقع — يُسجَّل ويُعرض للمستخدم
  unexpected,
}

class ApexErrorManager {
  static final _engine = ApexDiagnosticsEngine();

  /// يُعيَّن في نقطة التركيب: كيف يُبلَّغ المستخدم بخطأ غير متوقع ([context]
  /// يبدأ بنوع العملية: DB:: أو VAULT:: أو SYNC::). الخدمة لا تعرف الواجهة.
  static void Function(String context)? onUnexpected;

  // ── Core ──────────────────────────────────────────────────────────────────

  static Future<T> _run<T>(
    Future<T> Function() operation, {
    required String context,
    required ApexErrorSeverity severity,
    String? userMessage,
  }) async {
    try {
      return await operation();
    } catch (e, stack) {
      await _engine.logError(error: e, stackTrace: stack, context: context);
      if (severity == ApexErrorSeverity.unexpected) {
        onUnexpected?.call(context);
      }
      rethrow;
    }
  }

  // ── Public wrappers ───────────────────────────────────────────────────────

  /// عمليات قاعدة البيانات — خطأ غير متوقع
  static Future<T> monitorDB<T>(
    Future<T> Function() operation, {
    String name = 'Op',
  }) =>
      _run(operation,
          context: 'DB::$name', severity: ApexErrorSeverity.unexpected);

  /// عمليات الخزنة — VaultLockedException متوقع، باقي الأخطاء غير متوقعة
  static Future<T> monitorVault<T>(
    Future<T> Function() operation, {
    String name = 'Op',
    bool expectedLock = false,
  }) =>
      _run(
        operation,
        context: 'VAULT::$name',
        severity: expectedLock
            ? ApexErrorSeverity.expected
            : ApexErrorSeverity.unexpected,
      );

  /// عمليات المزامنة مع Google Drive
  static Future<T> monitorSync<T>(
    Future<T> Function() operation, {
    String name = 'Op',
  }) =>
      _run(operation,
          context: 'SYNC::$name', severity: ApexErrorSeverity.unexpected);

  /// العمليات الحرجة العامة — backward compatible
  /// [expectedError]: إذا true لا يعرض snackbar (للأخطاء المتوقعة كـ VaultLockedException)
  static Future<T> monitorCritical<T>(
    Future<T> Function() operation,
    String context, {
    bool expectedError = false,
  }) =>
      _run(
        operation,
        context: 'CRITICAL::$context',
        severity: expectedError
            ? ApexErrorSeverity.expected
            : ApexErrorSeverity.unexpected,
      );
}
