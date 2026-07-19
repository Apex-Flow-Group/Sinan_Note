// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';

import 'package:flutter/foundation.dart';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  Cloud Code Executor — Judge0 CE API                                    ║
// ║                                                                          ║
// ║  TODO: لإكمال الربط:                                                     ║
// ║  1. أضف http package في pubspec.yaml                                     ║
// ║  2. ضع API key في .env أو flutter_secure_storage                        ║
// ║  3. فعّل الاستدعاء في code_executor.dart بدل _securityMessage           ║
// ║  4. أضف package:http/http.dart في الـ imports أدناه                      ║
// ╚══════════════════════════════════════════════════════════════════════════╝

/// نتيجة تشغيل الكود سحابياً
class CodeExecutionResult {
  final String? stdout;
  final String? stderr;
  final String? compileOutput;
  final String? message;
  final int? statusId;
  final String? statusDescription;
  final String? time;
  final int? memory;

  const CodeExecutionResult({
    this.stdout,
    this.stderr,
    this.compileOutput,
    this.message,
    this.statusId,
    this.statusDescription,
    this.time,
    this.memory,
  });

  /// هل نجح التنفيذ؟
  bool get isSuccess => statusId == 3;

  /// هل يوجد خطأ تجميع؟
  bool get hasCompileError => statusId == 6;

  /// هل تجاوز الوقت المسموح؟
  bool get isTimeLimitExceeded => statusId == 5;

  /// هل تجاوز الذاكرة المسموحة؟
  bool get isMemoryLimitExceeded => statusId == 12;

  /// هل يوجد خطأ تشغيل؟
  bool get hasRuntimeError =>
      statusId == 7 ||
      statusId == 8 ||
      statusId == 9 ||
      statusId == 10 ||
      statusId == 11;

  /// الناتج المُنسّق للعرض
  String get displayOutput {
    if (isSuccess && stdout != null && stdout!.isNotEmpty) {
      return stdout!;
    }
    if (hasCompileError && compileOutput != null) {
      return '❌ Compile Error:\n$compileOutput';
    }
    if (hasRuntimeError && stderr != null) {
      return '❌ Runtime Error:\n$stderr';
    }
    if (isTimeLimitExceeded) {
      return '⏱️ Time Limit Exceeded (${time ?? "?"}s)';
    }
    if (isMemoryLimitExceeded) {
      return '💾 Memory Limit Exceeded (${memory ?? "?"}KB)';
    }
    if (message != null && message!.isNotEmpty) {
      return '⚠️ $message';
    }
    if (stderr != null && stderr!.isNotEmpty) {
      return stderr!;
    }
    return statusDescription ?? 'No output';
  }

  /// تحليل استجابة JSON من Judge0
  factory CodeExecutionResult.fromJson(Map<String, dynamic> json) {
    String? decodeBase64(String? encoded) {
      if (encoded == null || encoded.isEmpty) return null;
      try {
        return utf8.decode(base64Decode(encoded));
      } catch (_) {
        return encoded;
      }
    }

    final status = json['status'] as Map<String, dynamic>?;

    return CodeExecutionResult(
      stdout: decodeBase64(json['stdout'] as String?),
      stderr: decodeBase64(json['stderr'] as String?),
      compileOutput: decodeBase64(json['compile_output'] as String?),
      message: decodeBase64(json['message'] as String?),
      statusId: status?['id'] as int?,
      statusDescription: status?['description'] as String?,
      time: json['time'] as String?,
      memory: json['memory'] as int?,
    );
  }
}

/// إعدادات التنفيذ السحابي
class CloudExecutionConfig {
  /// الحد الأقصى لوقت التنفيذ (ثوانٍ)
  final double cpuTimeLimit;

  /// الحد الأقصى للذاكرة (كيلوبايت)
  final int memoryLimit;

  /// هل نستخدم base64 في الإرسال والاستقبال
  final bool useBase64;

  /// الحد الأقصى لعدد محاولات جلب النتيجة (polling)
  final int maxPollAttempts;

  /// المدة بين كل محاولة polling (ملي ثانية)
  final int pollIntervalMs;

  const CloudExecutionConfig({
    this.cpuTimeLimit = 5.0,
    this.memoryLimit = 128000,
    this.useBase64 = true,
    this.maxPollAttempts = 20,
    this.pollIntervalMs = 1000,
  });
}

/// خدمة تنفيذ الكود سحابياً عبر Judge0 CE API
///
/// ## الاستخدام:
/// ```dart
/// final executor = CloudCodeExecutor(
///   apiUrl: 'https://judge0-ce.p.rapidapi.com',
///   apiKey: 'YOUR_API_KEY',
/// );
/// final result = await executor.execute(
///   sourceCode: 'print("Hello")',
///   languageId: 71, // Python 3
/// );
/// print(result.displayOutput);
/// ```
class CloudCodeExecutor {
  // TODO: ضع API URL و Key هنا أو مرّرهما من الخارج
  final String apiUrl;
  final String? apiKey;
  final String? apiHost;
  final CloudExecutionConfig config;

  const CloudCodeExecutor({
    this.apiUrl = 'https://judge0-ce.p.rapidapi.com',
    this.apiKey,
    this.apiHost = 'judge0-ce.p.rapidapi.com',
    this.config = const CloudExecutionConfig(),
  });

  /// تنفيذ الكود وإرجاع النتيجة
  ///
  /// [sourceCode] — الكود المراد تنفيذه
  /// [languageId] — رقم اللغة في Judge0 (راجع [languageIds])
  /// [stdin] — المدخلات (اختياري)
  Future<CodeExecutionResult> execute({
    required String sourceCode,
    required int languageId,
    String? stdin,
  }) async {
    // TODO: فعّل هذا الكود عند إضافة package:http
    // ─────────────────────────────────────────────────────────────────────
    //
    // import 'package:http/http.dart' as http;
    //
    // final headers = {
    //   'Content-Type': 'application/json',
    //   if (apiKey != null) 'X-RapidAPI-Key': apiKey!,
    //   if (apiHost != null) 'X-RapidAPI-Host': apiHost!,
    // };
    //
    // // 1. إرسال الكود
    // final body = jsonEncode({
    //   'source_code': config.useBase64
    //       ? base64Encode(utf8.encode(sourceCode))
    //       : sourceCode,
    //   'language_id': languageId,
    //   if (stdin != null)
    //     'stdin': config.useBase64
    //         ? base64Encode(utf8.encode(stdin))
    //         : stdin,
    //   'cpu_time_limit': config.cpuTimeLimit,
    //   'memory_limit': config.memoryLimit,
    // });
    //
    // final submitUrl = Uri.parse(
    //   '$apiUrl/submissions?base64_encoded=${config.useBase64}&wait=false',
    // );
    //
    // final submitResponse = await http.post(
    //   submitUrl,
    //   headers: headers,
    //   body: body,
    // );
    //
    // if (submitResponse.statusCode != 201) {
    //   return CodeExecutionResult(
    //     message: 'Submission failed: ${submitResponse.statusCode}',
    //     statusId: -1,
    //     statusDescription: 'HTTP Error',
    //   );
    // }
    //
    // final token = jsonDecode(submitResponse.body)['token'] as String;
    //
    // // 2. Polling للنتيجة
    // for (int i = 0; i < config.maxPollAttempts; i++) {
    //   await Future.delayed(Duration(milliseconds: config.pollIntervalMs));
    //
    //   final resultUrl = Uri.parse(
    //     '$apiUrl/submissions/$token?base64_encoded=${config.useBase64}&fields=*',
    //   );
    //
    //   final resultResponse = await http.get(resultUrl, headers: headers);
    //
    //   if (resultResponse.statusCode != 200) continue;
    //
    //   final json = jsonDecode(resultResponse.body) as Map<String, dynamic>;
    //   final status = json['status'] as Map<String, dynamic>?;
    //   final statusId = status?['id'] as int? ?? 0;
    //
    //   // 1=In Queue, 2=Processing — ننتظر
    //   if (statusId <= 2) continue;
    //
    //   // 3+ = انتهى التنفيذ
    //   return CodeExecutionResult.fromJson(json);
    // }
    //
    // return const CodeExecutionResult(
    //   message: 'Execution timed out — no result after polling',
    //   statusId: -2,
    //   statusDescription: 'Poll Timeout',
    // );
    //
    // ─────────────────────────────────────────────────────────────────────

    // Placeholder حتى يُفعّل الكود أعلاه
    debugPrint('[CloudCodeExecutor] execute() called but not connected yet.');
    return const CodeExecutionResult(
      message: '☁️ Cloud execution is built but not connected yet.\n'
          'Set API key and enable HTTP calls to activate.',
      statusId: -1,
      statusDescription: 'Not Connected',
    );
  }

  /// أرقام اللغات في Judge0 CE — الأكثر استخداماً
  ///
  /// القائمة الكاملة: GET $apiUrl/languages
  static const Map<String, int> languageIds = {
    'python': 71, // Python 3.8.1
    'javascript': 63, // Node.js 12.14.0
    'typescript': 74, // TypeScript 3.7.4
    'java': 62, // Java OpenJDK 13.0.1
    'c': 50, // C GCC 9.2.0
    'cpp': 54, // C++ GCC 9.2.0
    'csharp': 51, // C# Mono 6.6.0.161
    'go': 60, // Go 1.13.5
    'rust': 73, // Rust 1.40.0
    'swift': 83, // Swift 5.2.3
    'kotlin': 78, // Kotlin 1.3.70
    'ruby': 72, // Ruby 2.7.0
    'php': 68, // PHP 7.4.1
    'dart': 90, // Dart 2.19.2
    'bash': 46, // Bash 5.0.0
    'sql': 82, // SQL SQLite 3.27.2
    'r': 80, // R 4.0.0
    'perl': 85, // Perl 5.28.1
    'lua': 64, // Lua 5.3.5
    'haskell': 61, // Haskell GHC 8.8.1
    'scala': 81, // Scala 2.13.2
  };

  /// الحصول على language_id من اسم اللغة (case insensitive)
  static int? getLanguageId(String language) {
    return languageIds[language.toLowerCase()];
  }

  /// هل اللغة مدعومة سحابياً؟
  static bool isSupported(String language) {
    return languageIds.containsKey(language.toLowerCase());
  }
}
