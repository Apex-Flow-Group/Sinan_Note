import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// حالة نتيجة تنفيذ الاختبارات
enum TestExecutionStatus {
  /// جميع الاختبارات نجحت
  passed,

  /// فشل واحد أو أكثر من الاختبارات
  failed,

  /// تجاوز الوقت المحدد (120 ثانية)
  timeout,

  /// لم يتم العثور على اختبارات لتنفيذها
  noTests,

  /// خطأ في تشغيل الاختبارات (مثل عدم وجود dart)
  executionError,
}

/// تفاصيل فشل اختبار واحد
class TestFailureDetail {
  /// اسم الاختبار الذي فشل
  final String testName;

  /// التأكيد (assertion) الذي فشل
  final String assertion;

  /// القيمة المتوقعة
  final String expected;

  /// القيمة الفعلية
  final String actual;

  const TestFailureDetail({
    required this.testName,
    required this.assertion,
    required this.expected,
    required this.actual,
  });

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'assertion': assertion,
      'expected': expected,
      'actual': actual,
    };
  }

  factory TestFailureDetail.fromJson(Map<String, dynamic> json) {
    return TestFailureDetail(
      testName: json['testName'] as String? ?? 'Unknown test',
      assertion: json['assertion'] as String? ?? 'Assertion failed',
      expected: json['expected'] as String? ?? 'N/A',
      actual: json['actual'] as String? ?? 'N/A',
    );
  }

  @override
  String toString() =>
      'TestFailure($testName: expected=$expected, actual=$actual)';
}

/// نتيجة تنفيذ الاختبارات
class TestExecutionResult {
  /// حالة التنفيذ
  final TestExecutionStatus status;

  /// رسالة وصفية
  final String message;

  /// تفاصيل الفشل (عند وجود اختبارات فاشلة)
  final List<TestFailureDetail> failures;

  /// اسم الدالة المعنية (للاستخدام في تقارير timeout)
  final String? functionName;

  /// الوقت المنقضي بالثواني
  final double elapsedSeconds;

  /// عدد الاختبارات التي نجحت
  final int passedCount;

  /// عدد الاختبارات التي فشلت
  final int failedCount;

  /// هل تم تفعيل الإرجاع (revert) بعد الفشل أو timeout
  final bool revertTriggered;

  /// هل تم تعليم الدالة كمُعاد هيكلتها بنجاح
  final bool markedAsRefactored;

  const TestExecutionResult({
    required this.status,
    required this.message,
    this.failures = const [],
    this.functionName,
    this.elapsedSeconds = 0.0,
    this.passedCount = 0,
    this.failedCount = 0,
    this.revertTriggered = false,
    this.markedAsRefactored = false,
  });

  bool get isSuccess => status == TestExecutionStatus.passed;
  bool get isTimeout => status == TestExecutionStatus.timeout;
  bool get isFailed => status == TestExecutionStatus.failed;

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'message': message,
      'failures': failures.map((f) => f.toJson()).toList(),
      if (functionName != null) 'functionName': functionName,
      'elapsedSeconds': elapsedSeconds,
      'passedCount': passedCount,
      'failedCount': failedCount,
      'revertTriggered': revertTriggered,
      'markedAsRefactored': markedAsRefactored,
    };
  }

  factory TestExecutionResult.fromJson(Map<String, dynamic> json) {
    return TestExecutionResult(
      status: TestExecutionStatus.values.byName(json['status'] as String),
      message: json['message'] as String,
      failures: (json['failures'] as List<dynamic>?)
              ?.map(
                  (f) => TestFailureDetail.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      functionName: json['functionName'] as String?,
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toDouble() ?? 0.0,
      passedCount: json['passedCount'] as int? ?? 0,
      failedCount: json['failedCount'] as int? ?? 0,
      revertTriggered: json['revertTriggered'] as bool? ?? false,
      markedAsRefactored: json['markedAsRefactored'] as bool? ?? false,
    );
  }

  TestExecutionResult copyWith({
    TestExecutionStatus? status,
    String? message,
    List<TestFailureDetail>? failures,
    String? functionName,
    double? elapsedSeconds,
    int? passedCount,
    int? failedCount,
    bool? revertTriggered,
    bool? markedAsRefactored,
  }) {
    return TestExecutionResult(
      status: status ?? this.status,
      message: message ?? this.message,
      failures: failures ?? this.failures,
      functionName: functionName ?? this.functionName,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      passedCount: passedCount ?? this.passedCount,
      failedCount: failedCount ?? this.failedCount,
      revertTriggered: revertTriggered ?? this.revertTriggered,
      markedAsRefactored: markedAsRefactored ?? this.markedAsRefactored,
    );
  }

  @override
  String toString() =>
      'TestExecutionResult($status: passed=$passedCount, failed=$failedCount, '
      'revert=$revertTriggered, refactored=$markedAsRefactored)';
}

/// واجهة لإرجاع التعديلات عند فشل الاختبارات.
///
/// يُنفذ بواسطة [Reverter] أو أي مكون يدير حالة الملفات.
abstract class RevertHandler {
  /// إرجاع التعديلات على الملف المحدد.
  /// يُرجع true إذا نجح الإرجاع، false إذا فشل.
  Future<bool> revert(String filePath);
}

/// واجهة لتعليم الدالة كمُعاد هيكلتها بنجاح.
///
/// يُنفذ بواسطة [ProgressManager] أو أي مكون يدير التقدم.
abstract class RefactorMarker {
  /// تعليم الدالة كمُعاد هيكلتها بنجاح.
  Future<void> markAsRefactored(String filePath, String functionName);
}

/// ينفذ الاختبارات المرتبطة بدالة معدلة ويتحقق من نجاحها.
///
/// المسؤوليات:
/// - تشغيل `dart test` على ملفات الاختبار المحددة
/// - فرض timeout بـ 120 ثانية
/// - تحليل مخرجات الاختبار لتحديد النجاح/الفشل
/// - عند النجاح: تعليم الدالة كمُعاد هيكلتها بنجاح (Req 7.5)
/// - عند الفشل: تفعيل الإرجاع وتقرير الفشل (Req 7.4)
/// - عند timeout: إنهاء، تفعيل الإرجاع، تقرير timeout (Req 7.7)
class TestExecutor {
  /// مسار جذر المشروع
  final String projectRoot;

  /// مدة timeout بالثواني (افتراضي 120)
  final int timeoutSeconds;

  /// معالج الإرجاع (اختياري - يُستخدم لإرجاع التعديلات عند الفشل)
  final RevertHandler? revertHandler;

  /// معالج تعليم الدالة (اختياري - يُستخدم لتعليم الدالة عند النجاح)
  final RefactorMarker? refactorMarker;

  const TestExecutor({
    required this.projectRoot,
    this.timeoutSeconds = 120,
    this.revertHandler,
    this.refactorMarker,
  });

  /// ينفذ الاختبارات ويعالج النتيجة بالكامل.
  ///
  /// هذه الدالة الرئيسية التي تنسق العملية الكاملة:
  /// 1. تنفيذ الاختبارات مع timeout
  /// 2. عند النجاح: تعليم الدالة كمُعاد هيكلتها
  /// 3. عند الفشل: تفعيل الإرجاع وتقرير التفاصيل
  /// 4. عند timeout: إنهاء، تفعيل الإرجاع، تقرير timeout
  ///
  /// [testFilePaths] - قائمة مسارات ملفات الاختبار (نسبية أو مطلقة)
  /// [functionName] - اسم الدالة المعدلة (للتقارير)
  /// [filePath] - مسار الملف المعدل (للإرجاع والتعليم)
  Future<TestExecutionResult> executeTests({
    required List<String> testFilePaths,
    required String functionName,
    String? filePath,
  }) async {
    // التحقق من وجود اختبارات
    if (testFilePaths.isEmpty) {
      return TestExecutionResult(
        status: TestExecutionStatus.noTests,
        message: 'لم يتم العثور على اختبارات لتنفيذها للدالة: $functionName',
        functionName: functionName,
      );
    }

    // التحقق من وجود ملفات الاختبار
    final validPaths = <String>[];
    for (final testPath in testFilePaths) {
      final resolvedPath = _resolvePath(testPath);
      if (await File(resolvedPath).exists()) {
        validPaths.add(testPath);
      }
    }

    if (validPaths.isEmpty) {
      return TestExecutionResult(
        status: TestExecutionStatus.noTests,
        message: 'ملفات الاختبار المحددة غير موجودة للدالة: $functionName',
        functionName: functionName,
      );
    }

    // تنفيذ الاختبارات مع timeout
    final stopwatch = Stopwatch()..start();

    try {
      final result = await _runDartTest(validPaths, functionName);
      stopwatch.stop();
      final elapsed = stopwatch.elapsed.inMilliseconds / 1000.0;
      final resultWithElapsed = result.copyWith(elapsedSeconds: elapsed);

      // معالجة النتيجة
      return await _handleResult(resultWithElapsed, functionName, filePath);
    } on TimeoutException {
      stopwatch.stop();
      final elapsed = stopwatch.elapsed.inMilliseconds / 1000.0;

      // Timeout: إنهاء، تفعيل الإرجاع، تقرير timeout (Req 7.7)
      final revertSuccess = await _triggerRevert(filePath);

      return TestExecutionResult(
        status: TestExecutionStatus.timeout,
        message: 'تجاوز تنفيذ الاختبارات الحد الزمني ($timeoutSeconds ثانية) '
            'للدالة: $functionName. الوقت المنقضي: ${elapsed.toStringAsFixed(1)} ثانية',
        functionName: functionName,
        elapsedSeconds: elapsed,
        revertTriggered: revertSuccess,
      );
    } catch (e) {
      stopwatch.stop();
      final elapsed = stopwatch.elapsed.inMilliseconds / 1000.0;

      return TestExecutionResult(
        status: TestExecutionStatus.executionError,
        message: 'خطأ في تشغيل الاختبارات: $e',
        functionName: functionName,
        elapsedSeconds: elapsed,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private: معالجة النتيجة
  // ---------------------------------------------------------------------------

  /// يعالج نتيجة التنفيذ: تعليم عند النجاح، إرجاع عند الفشل.
  Future<TestExecutionResult> _handleResult(
    TestExecutionResult result,
    String functionName,
    String? filePath,
  ) async {
    switch (result.status) {
      case TestExecutionStatus.passed:
        // النجاح: تعليم الدالة كمُعاد هيكلتها (Req 7.5)
        final marked = await _markAsRefactored(filePath, functionName);
        return result.copyWith(markedAsRefactored: marked);

      case TestExecutionStatus.failed:
        // الفشل: تفعيل الإرجاع (Req 7.4)
        final revertSuccess = await _triggerRevert(filePath);
        return result.copyWith(revertTriggered: revertSuccess);

      default:
        return result;
    }
  }

  /// يفعّل إرجاع التعديلات عبر [RevertHandler].
  Future<bool> _triggerRevert(String? filePath) async {
    if (revertHandler == null || filePath == null) return false;
    try {
      return await revertHandler!.revert(filePath);
    } catch (_) {
      return false;
    }
  }

  /// يعلّم الدالة كمُعاد هيكلتها عبر [RefactorMarker].
  Future<bool> _markAsRefactored(String? filePath, String functionName) async {
    if (refactorMarker == null || filePath == null) return false;
    try {
      await refactorMarker!.markAsRefactored(filePath, functionName);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private: تشغيل dart test
  // ---------------------------------------------------------------------------

  /// يشغل `dart test` على ملفات الاختبار المحددة مع timeout.
  Future<TestExecutionResult> _runDartTest(
    List<String> testFilePaths,
    String functionName,
  ) async {
    final args = ['test', '--reporter=expanded', ...testFilePaths];

    final process = await Process.start(
      'dart',
      args,
      workingDirectory: projectRoot,
    );

    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    // جمع المخرجات
    final stdoutFuture = process.stdout
        .transform(const SystemEncoding().decoder)
        .forEach((data) => stdoutBuffer.write(data));
    final stderrFuture = process.stderr
        .transform(const SystemEncoding().decoder)
        .forEach((data) => stderrBuffer.write(data));

    // انتظار مع timeout
    final exitCode = await process.exitCode.timeout(
      Duration(seconds: timeoutSeconds),
      onTimeout: () {
        // إنهاء العملية عند timeout
        process.kill(ProcessSignal.sigterm);
        // محاولة قتل العملية بالقوة بعد 5 ثوانٍ
        Future.delayed(const Duration(seconds: 5), () {
          try {
            process.kill(ProcessSignal.sigkill);
          } catch (_) {}
        });
        throw TimeoutException(
          'تجاوز الحد الزمني: $timeoutSeconds ثانية',
          Duration(seconds: timeoutSeconds),
        );
      },
    );

    // انتظار اكتمال قراءة المخرجات
    await Future.wait([stdoutFuture, stderrFuture]);

    final stdout = stdoutBuffer.toString();
    final stderr = stderrBuffer.toString();

    // تحليل النتائج
    if (exitCode == 0) {
      final passedCount = _countPassedTests(stdout);
      return TestExecutionResult(
        status: TestExecutionStatus.passed,
        message: 'جميع الاختبارات نجحت للدالة: $functionName',
        functionName: functionName,
        passedCount: passedCount,
        failedCount: 0,
      );
    } else {
      // تحليل الفشل
      final failures = _parseFailures(stdout, stderr);
      final passedCount = _countPassedTests(stdout);
      final failedCount =
          failures.isNotEmpty ? failures.length : _countFailedTests(stdout);

      return TestExecutionResult(
        status: TestExecutionStatus.failed,
        message:
            'فشلت ${failedCount > 0 ? failedCount : "بعض"} الاختبارات للدالة: $functionName',
        functionName: functionName,
        failures: failures,
        passedCount: passedCount,
        failedCount: failedCount > 0 ? failedCount : 1,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private: تحليل مخرجات الاختبار
  // ---------------------------------------------------------------------------

  /// يحسب عدد الاختبارات الناجحة من المخرجات.
  int _countPassedTests(String output) {
    // نمط expanded reporter: ✓ أو +1 أو "passed"
    final passedPattern = RegExp(r'[✓✔]|^\s*\+\d+:', multiLine: true);
    final matches = passedPattern.allMatches(output);

    if (matches.isNotEmpty) return matches.length;

    // بديل: البحث عن ملخص النتائج
    final summaryPattern = RegExp(r'(\d+) tests? passed');
    final summaryMatch = summaryPattern.firstMatch(output);
    if (summaryMatch != null) {
      return int.tryParse(summaryMatch.group(1) ?? '0') ?? 0;
    }

    return 0;
  }

  /// يحسب عدد الاختبارات الفاشلة من المخرجات.
  int _countFailedTests(String output) {
    // نمط expanded reporter: ✗ أو -1 أو "failed"
    final failedPattern = RegExp(r'[✗✘×]|^\s*-\d+:', multiLine: true);
    final matches = failedPattern.allMatches(output);

    if (matches.isNotEmpty) return matches.length;

    // بديل: البحث عن ملخص النتائج
    final summaryPattern = RegExp(r'(\d+) tests? failed');
    final summaryMatch = summaryPattern.firstMatch(output);
    if (summaryMatch != null) {
      return int.tryParse(summaryMatch.group(1) ?? '0') ?? 0;
    }

    return 0;
  }

  /// يحلل تفاصيل الفشل من مخرجات الاختبار.
  List<TestFailureDetail> _parseFailures(String stdout, String stderr) {
    final failures = <TestFailureDetail>[];
    final output = '$stdout\n$stderr';

    // تحليل أنماط فشل dart test (expanded reporter)
    // النمط: اسم الاختبار يظهر قبل الخطأ
    final testBlockPattern = RegExp(
      r'(?:✗|✘|×|FAILED:?)\s*(.+?)(?:\n|\r\n)'
      r'([\s\S]*?)(?=(?:✗|✘|×|FAILED:?|\Z|^\s*\d+ tests?))',
      multiLine: true,
    );

    final blockMatches = testBlockPattern.allMatches(output);

    for (final match in blockMatches) {
      final testName = match.group(1)?.trim() ?? 'Unknown test';
      final errorBlock = match.group(2) ?? '';

      final detail = _parseErrorBlock(testName, errorBlock);
      failures.add(detail);
    }

    // إذا لم نجد بالنمط الأول، نحاول نمطاً بديلاً
    if (failures.isEmpty) {
      final altFailures = _parseAlternativeFormat(output);
      failures.addAll(altFailures);
    }

    // إذا لا يزال فارغاً ولكن هناك خطأ واضح
    if (failures.isEmpty &&
        (output.contains('FAILED') ||
            output.contains('Error') ||
            output.contains('Expected:'))) {
      failures.add(_extractGenericFailure(output));
    }

    return failures;
  }

  /// يحلل كتلة خطأ واحدة لاستخراج التفاصيل.
  TestFailureDetail _parseErrorBlock(String testName, String errorBlock) {
    String assertion = '';
    String expected = '';
    String actual = '';

    // البحث عن Expected/Actual
    final expectedPattern = RegExp(r'Expected:\s*(.+)', multiLine: true);
    final actualPattern = RegExp(r'Actual:\s*(.+)', multiLine: true);
    final whichPattern = RegExp(r'Which:\s*(.+)', multiLine: true);

    final expectedMatch = expectedPattern.firstMatch(errorBlock);
    final actualMatch = actualPattern.firstMatch(errorBlock);
    final whichMatch = whichPattern.firstMatch(errorBlock);

    if (expectedMatch != null) {
      expected = expectedMatch.group(1)?.trim() ?? '';
    }
    if (actualMatch != null) {
      actual = actualMatch.group(1)?.trim() ?? '';
    }

    // استخراج assertion من "Which" أو من السطر الأول
    if (whichMatch != null) {
      assertion = whichMatch.group(1)?.trim() ?? '';
    } else {
      // أول سطر غير فارغ في كتلة الخطأ
      final lines = errorBlock.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty &&
            !trimmed.startsWith('Expected:') &&
            !trimmed.startsWith('Actual:')) {
          assertion = trimmed;
          break;
        }
      }
    }

    return TestFailureDetail(
      testName: testName,
      assertion: assertion.isNotEmpty ? assertion : 'Assertion failed',
      expected: expected.isNotEmpty ? expected : 'N/A',
      actual: actual.isNotEmpty ? actual : 'N/A',
    );
  }

  /// يحلل تنسيقاً بديلاً لمخرجات الاختبار.
  List<TestFailureDetail> _parseAlternativeFormat(String output) {
    final failures = <TestFailureDetail>[];

    // نمط: "Some tests failed." مع تفاصيل
    final lines = output.split('\n');
    String? currentTestName;
    String? currentExpected;
    String? currentActual;
    String? currentAssertion;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // كشف اسم اختبار فاشل
      if (line.contains('FAILED') || line.contains('✗') || line.contains('✘')) {
        // حفظ الاختبار السابق إن وجد
        if (currentTestName != null) {
          failures.add(TestFailureDetail(
            testName: currentTestName,
            assertion: currentAssertion ?? 'Assertion failed',
            expected: currentExpected ?? 'N/A',
            actual: currentActual ?? 'N/A',
          ));
        }
        currentTestName = line
            .replaceAll(RegExp(r'[✗✘×]'), '')
            .replaceAll('FAILED', '')
            .trim();
        currentExpected = null;
        currentActual = null;
        currentAssertion = null;
      }

      // كشف Expected/Actual
      if (line.startsWith('Expected:')) {
        currentExpected = line.replaceFirst('Expected:', '').trim();
      } else if (line.startsWith('Actual:')) {
        currentActual = line.replaceFirst('Actual:', '').trim();
      } else if (line.startsWith('Which:')) {
        currentAssertion = line.replaceFirst('Which:', '').trim();
      }
    }

    // حفظ آخر اختبار
    if (currentTestName != null) {
      failures.add(TestFailureDetail(
        testName: currentTestName,
        assertion: currentAssertion ?? 'Assertion failed',
        expected: currentExpected ?? 'N/A',
        actual: currentActual ?? 'N/A',
      ));
    }

    return failures;
  }

  /// يستخرج فشل عام عندما لا يمكن تحليل التنسيق المحدد.
  TestFailureDetail _extractGenericFailure(String output) {
    // محاولة استخراج أي معلومات مفيدة
    String testName = 'Unknown test';
    String assertion = 'Test failed';
    String expected = 'N/A';
    String actual = 'N/A';

    final expectedMatch = RegExp(r'Expected:\s*(.+)').firstMatch(output);
    final actualMatch = RegExp(r'Actual:\s*(.+)').firstMatch(output);

    if (expectedMatch != null) {
      expected = expectedMatch.group(1)?.trim() ?? 'N/A';
    }
    if (actualMatch != null) {
      actual = actualMatch.group(1)?.trim() ?? 'N/A';
    }

    // محاولة استخراج اسم الاختبار
    final testNamePattern = RegExp(r"test\(['" r'"' r"](.+?)['" r'"' r"]\)");
    final nameMatch = testNamePattern.firstMatch(output);
    if (nameMatch != null) {
      testName = nameMatch.group(1) ?? testName;
    }

    // محاولة استخراج assertion
    final errorPattern = RegExp(r'Expected .+? but .+');
    final errorMatch = errorPattern.firstMatch(output);
    if (errorMatch != null) {
      assertion = errorMatch.group(0) ?? assertion;
    }

    return TestFailureDetail(
      testName: testName,
      assertion: assertion,
      expected: expected,
      actual: actual,
    );
  }

  // ---------------------------------------------------------------------------
  // Private: مساعدات المسار
  // ---------------------------------------------------------------------------

  /// يحول المسار النسبي إلى مسار مطلق.
  String _resolvePath(String filePath) {
    if (p.isAbsolute(filePath)) return filePath;
    return p.join(projectRoot, filePath);
  }
}
