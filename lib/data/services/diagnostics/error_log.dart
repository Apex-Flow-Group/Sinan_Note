// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:sinan_note/domain/logger.dart';

/// سجل الأخطاء غير الملتقطة في ملف، يشاركه المستخدم مع المطوّر من الإعدادات.
/// يُنشأ مرة في نقطة التركيب وتغذّيه معالجات الأخطاء العامة.
class ErrorLog {
  ErrorLog(String directory) : _file = File('$directory/apex_errors.log');

  /// فوقه يُبقى النصف الأحدث فقط.
  static const maxBytes = 512 * 1024;

  final File _file;

  Future<void> record(Object error, StackTrace? stack, String context) async {
    final memory = (ProcessInfo.currentRss / 1024 / 1024).toStringAsFixed(2);
    final trace = (stack?.toString() ?? '').split('\n').take(5).join('\n');
    final report = '''
=== APEX DIAGNOSTICS ===
Time: ${DateTime.now().toIso8601String()}
Context: $context
Memory: $memory MB
Error: $error
Stack: $trace
========================
''';
    AppLogger.debug(report);
    try {
      if (await _file.exists() && await _file.length() > maxBytes) {
        final text = await _file.readAsString();
        await _file.writeAsString(text.substring(text.length - maxBytes ~/ 2));
      }
      await _file.writeAsString('$report\n', mode: FileMode.append);
    } on FileSystemException catch (_) {
      // السجل لا يُسقط التطبيق
    }
  }

  /// السجل، أو null إن لم يُسجَّل شيء.
  Future<String?> read() async {
    try {
      if (await _file.exists()) return await _file.readAsString();
    } on FileSystemException catch (_) {}
    return null;
  }

  Future<void> clear() async {
    try {
      if (await _file.exists()) await _file.delete();
    } on FileSystemException catch (_) {}
  }
}
