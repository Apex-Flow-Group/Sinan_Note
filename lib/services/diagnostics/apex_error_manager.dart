// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sinan_note/core/utils/logger.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/services/diagnostics/apex_diagnostics_engine.dart';

/// خطورة الخطأ — تحدد السلوك
enum ApexErrorSeverity {
  /// خطأ متوقع ومعالج — يُسجَّل فقط بدون إزعاج المستخدم
  expected,

  /// خطأ غير متوقع — يُسجَّل ويُعرض للمستخدم
  unexpected,
}

class ApexErrorManager {
  static const String developerEmail = 'contact.apex.flow@gmail.com';
  static final _engine = ApexDiagnosticsEngine();
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

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
        _showSnackbar(userMessage, context);
      }
      rethrow;
    }
  }

  /// الرسالة الافتراضية حسب بادئة سياق العملية، بلغة الواجهة.
  static String _defaultMessage(AppLocalizations l10n, String ctx) {
    if (ctx.startsWith('DB::')) return l10n.databaseError;
    if (ctx.startsWith('VAULT::')) return l10n.vaultError;
    if (ctx.startsWith('SYNC::')) return l10n.googleDriveSyncFailed;
    return l10n.unexpectedError;
  }

  static void _showSnackbar(String? userMessage, String errorContext) {
    final context = _navigatorKey?.currentState?.context;
    if (context == null) return;
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userMessage ?? _defaultMessage(l10n, errorContext)),
        backgroundColor: scheme.error,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: l10n.errorReportAction,
          textColor: scheme.onError,
          onPressed: _shareErrorLog,
        ),
      ),
    );
  }

  static Future<void> _shareErrorLog() async {
    try {
      final log = await _engine.getErrorLog() ?? '-';
      await Share.share(
        'Error Report for Apex Flow Group\n\n$log\n\nSend to: $developerEmail',
        subject: 'Sinan Note - Error Report',
      );
    } catch (e) {
      AppLogger.debug('Failed to share error log: $e');
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
