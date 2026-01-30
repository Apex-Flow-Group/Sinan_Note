// Copyright © 2025 Apex Flow Group. All rights reserved.

import '../../core/utils/logger.dart';
import 'dart:io';

/// محرك التشخيص المركزي - أعمى 100% ومستقل تماماً
/// لا يعتمد على Flutter أو أي مكتبة خارجية
class ApexDiagnosticsEngine {
  static final ApexDiagnosticsEngine _instance =
      ApexDiagnosticsEngine._internal();
  factory ApexDiagnosticsEngine() => _instance;
  ApexDiagnosticsEngine._internal();

  // مسار ثابت للوق (مستقل عن path_provider)
  static String? _logPath;

  /// تهيئة المسار مرة واحدة فقط
  void init(String appDir) {
    _logPath = '$appDir/apex_errors.log';
  }

  /// تسجيل خطأ مع تقرير تشخيصي كامل
  Future<String> logError({
    required dynamic error,
    required StackTrace stackTrace,
    required String context,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final memory = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);

    final report = '''
=== 🛑 APEX DIAGNOSTICS ===
Time: $timestamp
Context: $context
Memory: $memory MB
Error: $error
Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}
===========================
''';

    // طباعة للكونسول (Dart pure)
    AppLogger.debug(report);

    // حفظ في ملف (Dart I/O فقط)
    if (_logPath != null) {
      try {
        final logFile = File(_logPath!);
        await logFile.writeAsString('$report\n', mode: FileMode.append);
      } catch (_) {}
    }

    return report;
  }

  /// قراءة سجل الأخطاء
  Future<String> getErrorLog() async {
    if (_logPath == null) return 'Engine not initialized';
    try {
      final logFile = File(_logPath!);
      if (await logFile.exists()) {
        return await logFile.readAsString();
      }
    } catch (_) {}
    return 'لا توجد أخطاء مسجلة';
  }

  /// مسح السجل
  Future<void> clearLog() async {
    if (_logPath == null) return;
    try {
      final logFile = File(_logPath!);
      if (await logFile.exists()) await logFile.delete();
    } catch (_) {}
  }
}
