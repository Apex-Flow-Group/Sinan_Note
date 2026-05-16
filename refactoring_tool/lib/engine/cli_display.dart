import 'dart:io';

import 'package:refactoring_tool/mapper/dead_code_detector.dart';
import 'package:refactoring_tool/models/call_source.dart';
import 'package:refactoring_tool/models/core_file_entry.dart';
import 'package:refactoring_tool/models/dependency_map.dart';
import 'package:refactoring_tool/models/event_sheet.dart';
import 'package:refactoring_tool/models/function_unit.dart';
import 'package:refactoring_tool/models/progress_tracker.dart';
import 'package:refactoring_tool/testing/test_executor.dart';

/// يعرض المعلومات التفاعلية أثناء عملية إعادة الهيكلة عبر CLI.
///
/// يستخدم أحرف رسم الصناديق (box-drawing characters) ونصوص عربية
/// لعرض تفاصيل الملفات والدوال ومصادر الاستدعاء وخرائط الأحداث
/// وأسئلة التقييم ونتائج الاختبارات.
class CliDisplay {
  /// مخرج الكتابة (قابل للاستبدال في الاختبارات)
  final IOSink _output;

  CliDisplay({IOSink? output}) : _output = output ?? stdout;

  // ===========================================================================
  // عرض رأس الملف مع التقدم
  // ===========================================================================

  /// يعرض رأس الملف الحالي مع نسبة التقدم.
  ///
  /// ```
  /// ═══════════════════════════════════════════════════════
  ///   📁 الملف: lib/controllers/notes/notes_provider.dart
  ///   📊 التقدم: 15/180 دالة (8.33%)
  /// ═══════════════════════════════════════════════════════
  /// ```
  void displayFileHeader(String filePath, double progressPercentage,
      {int reviewedFunctions = 0, int totalFunctions = 0}) {
    final separator = '═' * 55;
    _output.writeln('');
    _output.writeln(separator);
    _output.writeln('  📁 الملف: $filePath');
    _output.writeln(
        '  📊 التقدم: $reviewedFunctions/$totalFunctions دالة (${progressPercentage.toStringAsFixed(2)}%)');
    _output.writeln(separator);
    _output.writeln('');
  }

  // ===========================================================================
  // عرض تفاصيل الدالة
  // ===========================================================================

  /// يعرض تفاصيل دالة واحدة: الاسم، النوع، المعاملات، الإرجاع، الأسطر.
  ///
  /// ```
  /// ━━━ الدالة: loadNotes ━━━
  ///   النوع: method
  ///   المعاملات: {String? category}
  ///   الإرجاع: Future<void>
  ///   الأسطر: 45 سطر (سطر 23 → 67)
  /// ```
  void displayFunctionDetails(FunctionUnit function) {
    _output.writeln('━━━ الدالة: ${function.name} ━━━');
    _output.writeln('  النوع: ${_functionTypeLabel(function.type)}');
    _output.writeln('  المعاملات: ${_formatParams(function.params)}');
    _output.writeln('  الإرجاع: ${function.returnType}');
    _output.writeln(
        '  الأسطر: ${function.lineCount} سطر (سطر ${function.startLine} → ${function.endLine})');
    _output.writeln('');
  }

  // ===========================================================================
  // عرض مصادر الاستدعاء
  // ===========================================================================

  /// يعرض مصادر الاستدعاء مجمّعة حسب الملف.
  ///
  /// ```
  /// ━━━ مصادر الاستدعاء (5) ━━━
  ///   📍 lib/screens/mobile/home_screen.dart
  ///      → initState() [سطر 34] (مباشر)
  ///      → _onCategoryChanged() [سطر 89] (مباشر)
  ///   📍 lib/widgets/home/note_list.dart
  ///      → build() [سطر 12] (Provider.watch)
  /// ```
  void displayCallSources(List<CallSource> callSources) {
    _output.writeln('━━━ مصادر الاستدعاء (${callSources.length}) ━━━');

    if (callSources.isEmpty) {
      _output.writeln('  لا توجد مصادر استدعاء (قد يكون كود ميت)');
      _output.writeln('');
      return;
    }

    // تجميع حسب الملف (ترتيب أبجدي)
    final grouped = <String, List<CallSource>>{};
    for (final source in callSources) {
      grouped.putIfAbsent(source.filePath, () => []).add(source);
    }

    final sortedFiles = grouped.keys.toList()..sort();

    for (final filePath in sortedFiles) {
      _output.writeln('  📍 $filePath');
      for (final source in grouped[filePath]!) {
        _output.writeln(
            '     → ${source.callingFunction}() [سطر ${source.lineNumber}] (${_callTypeLabel(source.callType)})');
      }
    }
    _output.writeln('');
  }

  // ===========================================================================
  // عرض خريطة الأحداث
  // ===========================================================================

  /// يعرض خريطة الأحداث الواردة والصادرة.
  ///
  /// ```
  /// ━━━ خريطة الأحداث ━━━
  ///   ⬇️ واردة: initState, _onCategoryChanged, Provider.watch
  ///   ⬆️ صادرة: notifyListeners()
  /// ```
  void displayEventSheet(EventSheet eventSheet) {
    _output.writeln('━━━ خريطة الأحداث ━━━');

    if (eventSheet.isEventIsolated) {
      _output.writeln('  ⚠️ الدالة معزولة عن الأحداث (لا واردة ولا صادرة)');
      _output.writeln('');
      return;
    }

    // الأحداث الواردة
    if (eventSheet.incomingEvents.isNotEmpty) {
      final incomingLabels =
          eventSheet.incomingEvents.map((e) => e.targetOrSource).toList();
      _output.writeln('  ⬇️ واردة: ${incomingLabels.join(', ')}');

      // تفاصيل الأحداث الواردة
      for (final event in eventSheet.incomingEvents) {
        _output.writeln(
            '     ├─ ${_eventTypeLabel(event.type)}: ${event.targetOrSource} (${event.filePath}:${event.lineNumber})');
      }
    } else {
      _output.writeln('  ⬇️ واردة: لا يوجد');
    }

    // الأحداث الصادرة
    if (eventSheet.outgoingEvents.isNotEmpty) {
      final outgoingLabels =
          eventSheet.outgoingEvents.map((e) => e.targetOrSource).toList();
      _output.writeln('  ⬆️ صادرة: ${outgoingLabels.join(', ')}');

      // تفاصيل الأحداث الصادرة
      for (final event in eventSheet.outgoingEvents) {
        _output.writeln(
            '     ├─ ${_eventTypeLabel(event.type)}: ${event.targetOrSource} (${event.filePath}:${event.lineNumber})');
      }
    } else {
      _output.writeln('  ⬆️ صادرة: لا يوجد');
    }

    _output.writeln('');
  }

  // ===========================================================================
  // عرض خريطة التبعيات
  // ===========================================================================

  /// يعرض خريطة التبعيات (upstream و downstream) حتى 3 مستويات.
  ///
  /// ```
  /// ━━━ خريطة التبعيات ━━━
  ///   🔼 من يستدعيها (upstream):
  ///     ├─ [1] initState() ← home_screen.dart
  ///     │  ├─ [2] main() ← main.dart
  ///   🔽 من تستدعيه (downstream):
  ///     ├─ [1] _filterNotes() ← notes_provider.dart
  ///   ⚠️ تبعية دائرية: loadNotes ↔ refreshNotes
  /// ```
  void displayDependencyMap(DependencyMap dependencyMap) {
    _output.writeln('━━━ خريطة التبعيات ━━━');

    // Upstream callers
    if (dependencyMap.upstreamCallers.isNotEmpty) {
      _output.writeln('  🔼 من يستدعيها (upstream):');
      for (final node in dependencyMap.upstreamCallers) {
        _displayDependencyNode(node, '    ');
      }
    } else {
      _output.writeln('  🔼 من يستدعيها: لا يوجد');
    }

    // Downstream callees
    if (dependencyMap.downstreamCallees.isNotEmpty) {
      _output.writeln('  🔽 من تستدعيه (downstream):');
      for (final node in dependencyMap.downstreamCallees) {
        _displayDependencyNode(node, '    ');
      }
    } else {
      _output.writeln('  🔽 من تستدعيه: لا يوجد');
    }

    // تحذير التبعية الدائرية
    if (dependencyMap.hasCircularChain) {
      _output.writeln(
          '  ⚠️ تبعية دائرية: ${dependencyMap.circularParticipants.join(' ↔ ')}');
    }

    _output.writeln('');
  }

  // ===========================================================================
  // عرض أسئلة التقييم
  // ===========================================================================

  /// يعرض أسئلة التقييم الأربعة مع تعليمات الإدخال.
  ///
  /// ```
  /// ━━━ أسئلة التقييم ━━━
  ///   1. هل هذا ما يجب أن تفعله هذه الدالة؟ [نعم/لا/غير متأكد]:
  ///   2. هل يمكن تحسينها؟ [نعم/لا/غير متأكد]:
  ///   3. هل يمكن نقل أجزاء منها لشجرة/دالة أخرى؟ [نعم/لا/غير متأكد]:
  ///   4. هل يمكن تفويض بعض المهام لدوال مساعدة؟ [نعم/لا/غير متأكد]:
  /// ```
  void displayEvaluationQuestions() {
    _output.writeln('━━━ أسئلة التقييم ━━━');
    _output
        .writeln('  1. هل هذا ما يجب أن تفعله هذه الدالة؟ [نعم/لا/غير متأكد]:');
    _output.writeln('  2. هل يمكن تحسينها؟ [نعم/لا/غير متأكد]:');
    _output.writeln(
        '  3. هل يمكن نقل أجزاء منها لشجرة/دالة أخرى؟ [نعم/لا/غير متأكد]:');
    _output.writeln(
        '  4. هل يمكن تفويض بعض المهام لدوال مساعدة؟ [نعم/لا/غير متأكد]:');
    _output.writeln('');
  }

  /// يعرض سؤال تقييم واحد مع رقمه ويطلب الإدخال.
  void displayEvaluationQuestion(int questionNumber, String questionText) {
    _output.write('  $questionNumber. $questionText [نعم/لا/غير متأكد]: ');
  }

  /// يعرض طلب إدخال المبرر عند الإجابة بـ "نعم".
  void displayJustificationPrompt() {
    _output.write('     ↳ المبرر (1-500 حرف): ');
  }

  // ===========================================================================
  // عرض نتائج الاختبارات
  // ===========================================================================

  /// يعرض نتيجة تنفيذ الاختبارات.
  ///
  /// ```
  /// ━━━ نتائج الاختبارات ━━━
  ///   ✅ جميع الاختبارات نجحت (5 اختبارات في 2.3 ثانية)
  /// ```
  /// أو:
  /// ```
  /// ━━━ نتائج الاختبارات ━━━
  ///   ❌ فشلت 2 اختبارات من أصل 7
  ///   ├─ test_name: Expected X, Actual Y
  ///   ⏪ تم إرجاع التعديلات
  /// ```
  void displayTestResult(TestExecutionResult result) {
    _output.writeln('━━━ نتائج الاختبارات ━━━');

    switch (result.status) {
      case TestExecutionStatus.passed:
        _output.writeln(
            '  ✅ جميع الاختبارات نجحت (${result.passedCount} اختبار في ${result.elapsedSeconds.toStringAsFixed(1)} ثانية)');
        if (result.markedAsRefactored) {
          _output.writeln('  ✨ تم تعليم الدالة كمُعاد هيكلتها بنجاح');
        }
        break;

      case TestExecutionStatus.failed:
        _output.writeln(
            '  ❌ فشلت ${result.failedCount} اختبار من أصل ${result.passedCount + result.failedCount}');
        for (final failure in result.failures) {
          _output.writeln('  ├─ ${failure.testName}');
          _output.writeln('  │  المتوقع: ${failure.expected}');
          _output.writeln('  │  الفعلي: ${failure.actual}');
        }
        if (result.revertTriggered) {
          _output.writeln('  ⏪ تم إرجاع التعديلات');
        }
        break;

      case TestExecutionStatus.timeout:
        _output.writeln(
            '  ⏱️ تجاوز الوقت المحدد (${result.elapsedSeconds.toStringAsFixed(1)} ثانية)');
        if (result.functionName != null) {
          _output.writeln('  │  الدالة: ${result.functionName}');
        }
        if (result.revertTriggered) {
          _output.writeln('  ⏪ تم إرجاع التعديلات');
        }
        break;

      case TestExecutionStatus.noTests:
        _output.writeln('  ⚠️ لم يتم العثور على اختبارات آلية');
        _output.writeln('  │  سيتم توليد قائمة اختبار يدوية');
        break;

      case TestExecutionStatus.executionError:
        _output.writeln('  🚫 خطأ في تشغيل الاختبارات');
        _output.writeln('  │  ${result.message}');
        break;
    }

    _output.writeln('');
  }

  // ===========================================================================
  // عرض التقدم العام
  // ===========================================================================

  /// يعرض ملخص التقدم العام لعملية إعادة الهيكلة.
  ///
  /// ```
  /// ╔══════════════════════════════════════════════╗
  /// ║         📊 تقدم إعادة الهيكلة              ║
  /// ╠══════════════════════════════════════════════╣
  /// ║  الملفات: 2/25 مكتمل                       ║
  /// ║  الدوال: 15/180 مراجعة                     ║
  /// ║  النسبة: ████████░░░░░░░░░░░░ 8.33%        ║
  /// ╚══════════════════════════════════════════════╝
  /// ```
  void displayProgress(ProgressTracker progress) {
    const width = 50;
    final topBorder = '╔${'═' * width}╗';
    final midBorder = '╠${'═' * width}╣';
    final bottomBorder = '╚${'═' * width}╝';

    _output.writeln('');
    _output.writeln(topBorder);
    _output.writeln('║${_centerText('📊 تقدم إعادة الهيكلة', width)}║');
    _output.writeln(midBorder);
    _output.writeln(
        '║  الملفات: ${progress.completedCoreFiles}/${progress.totalCoreFiles} مكتمل${_pad(width - _arabicLength('  الملفات: ${progress.completedCoreFiles}/${progress.totalCoreFiles} مكتمل'))}║');
    _output.writeln(
        '║  الدوال: ${progress.reviewedFunctionUnits}/${progress.totalFunctionUnits} مراجعة${_pad(width - _arabicLength('  الدوال: ${progress.reviewedFunctionUnits}/${progress.totalFunctionUnits} مراجعة'))}║');
    _output.writeln(
        '║  النسبة: ${_progressBar(progress.completionPercentage, 20)} ${progress.completionPercentage.toStringAsFixed(2)}%${_pad(width - _arabicLength('  النسبة: ${_progressBar(progress.completionPercentage, 20)} ${progress.completionPercentage.toStringAsFixed(2)}%'))}║');
    _output.writeln(
        '║  البداية: ${_formatDate(progress.startDate)}${_pad(width - _arabicLength('  البداية: ${_formatDate(progress.startDate)}'))}║');
    _output.writeln(
        '║  آخر تحديث: ${_formatDate(progress.lastUpdated)}${_pad(width - _arabicLength('  آخر تحديث: ${_formatDate(progress.lastUpdated)}'))}║');
    _output.writeln(bottomBorder);

    // عرض تفاصيل الملفات
    if (progress.fileProgress.isNotEmpty) {
      _output.writeln('');
      _output.writeln('  تفاصيل الملفات:');
      for (final file in progress.fileProgress) {
        final statusIcon = _fileStatusIcon(file.status);
        _output.writeln(
            '  $statusIcon ${file.filePath} (${file.reviewedFunctions}/${file.totalFunctions})');
      }
    }

    _output.writeln('');
  }

  // ===========================================================================
  // عرض تقرير الكود الميت
  // ===========================================================================

  /// يعرض تقرير الكود الميت.
  ///
  /// ```
  /// ━━━ تقرير الكود الميت ━━━
  ///   تم العثور على 3 دوال غير مستخدمة:
  ///   ├─ _oldHelper() ← lib/services/note_service.dart:45
  ///   ├─ _unusedMethod() ← lib/models/note.dart:89
  ///   └─ deprecatedFunc() ← lib/core/utils.dart:12
  /// ```
  void displayDeadCodeReport(DeadCodeReport report) {
    _output.writeln('━━━ تقرير الكود الميت ━━━');

    if (report.entries.isEmpty) {
      _output.writeln('  ✅ لم يتم العثور على كود ميت');
      _output.writeln('');
      return;
    }

    _output
        .writeln('  تم العثور على ${report.entries.length} دالة غير مستخدمة:');

    for (var i = 0; i < report.entries.length; i++) {
      final entry = report.entries[i];
      final connector = (i == report.entries.length - 1) ? '└─' : '├─';
      _output.writeln(
          '  $connector ${entry.functionName}() ← ${entry.filePath}:${entry.lineNumber}');
    }

    _output.writeln('  تاريخ التوليد: ${_formatDate(report.generatedAt)}');
    _output.writeln('');
  }

  // ===========================================================================
  // عرض نتيجة التعديل
  // ===========================================================================

  /// يعرض نتيجة تطبيق تعديل على دالة.
  void displayModificationOutcome({
    required String functionName,
    required bool success,
    String? description,
    int? lineCountBefore,
    int? lineCountAfter,
  }) {
    _output.writeln('━━━ نتيجة التعديل ━━━');

    if (success) {
      _output.writeln('  ✅ تم تعديل الدالة: $functionName');
      if (lineCountBefore != null && lineCountAfter != null) {
        final diff = lineCountBefore - lineCountAfter;
        final diffLabel = diff > 0
            ? '(−$diff سطر)'
            : diff < 0
                ? '(+${-diff} سطر)'
                : '(بدون تغيير)';
        _output.writeln(
            '  │  الأسطر: $lineCountBefore → $lineCountAfter $diffLabel');
      }
      if (description != null) {
        _output.writeln('  │  الوصف: $description');
      }
    } else {
      _output.writeln('  ❌ فشل تعديل الدالة: $functionName');
      if (description != null) {
        _output.writeln('  │  السبب: $description');
      }
    }

    _output.writeln('');
  }

  // ===========================================================================
  // عرض رسائل عامة
  // ===========================================================================

  /// يعرض رسالة معلومات.
  void displayInfo(String message) {
    _output.writeln('  ℹ️ $message');
  }

  /// يعرض رسالة تحذير.
  void displayWarning(String message) {
    _output.writeln('  ⚠️ $message');
  }

  /// يعرض رسالة خطأ.
  void displayError(String message) {
    _output.writeln('  🚫 $message');
  }

  /// يعرض رسالة نجاح.
  void displaySuccess(String message) {
    _output.writeln('  ✅ $message');
  }

  /// يعرض فاصل بين الأقسام.
  void displaySeparator() {
    _output.writeln('─' * 55);
  }

  // ===========================================================================
  // مساعدات خاصة
  // ===========================================================================

  /// يحول نوع الدالة إلى تسمية عربية.
  String _functionTypeLabel(FunctionType type) {
    switch (type) {
      case FunctionType.method:
        return 'method';
      case FunctionType.constructor:
        return 'constructor';
      case FunctionType.topLevel:
        return 'top-level function';
      case FunctionType.buildMethod:
        return 'build method';
      case FunctionType.getter:
        return 'getter';
      case FunctionType.setter:
        return 'setter';
    }
  }

  /// يحول نوع الاستدعاء إلى تسمية عربية.
  String _callTypeLabel(CallType type) {
    switch (type) {
      case CallType.direct:
        return 'مباشر';
      case CallType.providerRead:
        return 'Provider.read';
      case CallType.providerWatch:
        return 'Provider.watch';
      case CallType.callback:
        return 'callback';
      case CallType.streamListen:
        return 'Stream.listen';
      case CallType.methodChannel:
        return 'MethodChannel';
    }
  }

  /// يحول نوع الحدث إلى تسمية.
  String _eventTypeLabel(EventType type) {
    switch (type) {
      case EventType.directCall:
        return 'استدعاء مباشر';
      case EventType.providerRebuild:
        return 'Provider rebuild';
      case EventType.streamSubscription:
        return 'Stream subscription';
      case EventType.methodChannelIncoming:
        return 'MethodChannel وارد';
      case EventType.navigatorCallback:
        return 'Navigator callback';
      case EventType.lifecycleCallback:
        return 'Lifecycle callback';
      case EventType.notifyListeners:
        return 'notifyListeners()';
      case EventType.streamEmission:
        return 'Stream emission';
      case EventType.navigatorCall:
        return 'Navigator call';
      case EventType.methodChannelOutgoing:
        return 'MethodChannel صادر';
    }
  }

  /// يُنسق قائمة المعاملات.
  String _formatParams(List<Parameter> params) {
    if (params.isEmpty) return '()';

    final parts = params.map((p) {
      final prefix = p.isRequired ? '' : '?';
      if (p.isNamed) {
        return '${p.type}$prefix ${p.name}';
      }
      return '${p.type}$prefix ${p.name}';
    }).toList();

    final hasNamed = params.any((p) => p.isNamed);
    if (hasNamed) {
      return '{${parts.join(', ')}}';
    }
    return '(${parts.join(', ')})';
  }

  /// يعرض عقدة تبعية بشكل شجري.
  void _displayDependencyNode(DependencyNode node, String indent) {
    final fileName = node.filePath.split('/').last;
    _output.writeln(
        '$indent├─ [${node.depth}] ${node.functionName}() ← $fileName');
    for (final child in node.children) {
      _displayDependencyNode(child, '$indent│  ');
    }
  }

  /// يولد شريط تقدم نصي.
  String _progressBar(double percentage, int width) {
    final filled = (percentage / 100 * width).round();
    final empty = width - filled;
    return '${'█' * filled}${'░' * empty}';
  }

  /// يُنسق التاريخ بشكل مقروء.
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// يحسب طول النص التقريبي (للمحاذاة).
  int _arabicLength(String text) {
    // تقدير بسيط: كل حرف = 1
    return text.length;
  }

  /// يولد مسافات للمحاذاة.
  String _pad(int count) {
    if (count <= 0) return '';
    return ' ' * count;
  }

  /// يوسط النص ضمن عرض محدد.
  String _centerText(String text, int width) {
    final textLen = text.length;
    if (textLen >= width) return text;
    final leftPad = (width - textLen) ~/ 2;
    final rightPad = width - textLen - leftPad;
    return '${' ' * leftPad}$text${' ' * rightPad}';
  }

  /// يُرجع أيقونة حالة الملف.
  String _fileStatusIcon(CoreFileStatus status) {
    switch (status) {
      case CoreFileStatus.notStarted:
        return '⬜';
      case CoreFileStatus.inProgress:
        return '🔄';
      case CoreFileStatus.completed:
        return '✅';
    }
  }
}
