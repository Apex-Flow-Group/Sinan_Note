import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:refactoring_tool/models/call_source.dart';
import 'package:refactoring_tool/models/evaluation_record.dart';
import 'package:refactoring_tool/models/function_unit.dart';
import 'package:refactoring_tool/models/modification_log.dart';
import 'package:refactoring_tool/storage/storage_manager.dart';

/// نتيجة تطبيق التعديل
enum ModificationStatus {
  /// تم التطبيق بنجاح
  success,

  /// فشل التطبيق (خطأ في الملف أو التحليل)
  failure,

  /// يحتاج موافقة المطور بسبب تغيير في السلوك الخارجي
  needsApproval,

  /// فشل التحقق من التجميع بعد التعديل
  compilationFailed,

  /// اسم الدالة المساعدة لا يتبع النمط المطلوب
  invalidHelperName,
}

/// نتيجة عملية تطبيق التعديل
class ModificationResult {
  final ModificationStatus status;
  final String message;
  final ModificationLog? log;
  final List<String> behaviorDifferences;
  final List<String> compilationErrors;
  final List<String> invalidHelperNames;

  const ModificationResult({
    required this.status,
    required this.message,
    this.log,
    this.behaviorDifferences = const [],
    this.compilationErrors = const [],
    this.invalidHelperNames = const [],
  });

  bool get isSuccess => status == ModificationStatus.success;
  bool get needsApproval => status == ModificationStatus.needsApproval;

  @override
  String toString() => 'ModificationResult($status: $message)';
}

/// يطبق التعديلات على Function_Unit واحدة في كل مرة.
///
/// المسؤوليات:
/// - حفظ حالة الملف الأصلية قبل التعديل (للإرجاع عند الحاجة)
/// - تطبيق الكود الجديد في النطاق الصحيح من الأسطر
/// - تحديث جميع Call_Source عند تغيير التوقيع
/// - التحقق من التجميع عبر `dart analyze`
/// - إنشاء وحفظ سجل التعديل (ModificationLog)
/// - التحقق من أسماء الدوال المساعدة (verbNoun / verbAdjectiveNoun)
/// - طلب موافقة المطور عند تغيير السلوك الخارجي
class ModificationApplier {
  final StorageManager _storage;
  final String _projectRoot;

  /// يحتفظ بحالة الملف الأصلية قبل التعديل للإرجاع
  String? _savedOriginalContent;
  String? _savedFilePath;

  ModificationApplier({
    required StorageManager storage,
    required String projectRoot,
  })  : _storage = storage,
        _projectRoot = projectRoot;

  /// يطبق تعديلاً على دالة واحدة.
  ///
  /// [original] - الدالة الأصلية المراد تعديلها
  /// [newCode] - الكود الجديد الذي سيحل محل الدالة
  /// [callSources] - مصادر الاستدعاء التي قد تحتاج تحديث
  /// [evaluation] - سجل التقييم الذي يبرر التعديل
  ///
  /// يعيد [ModificationResult] يوضح نتيجة العملية.
  Future<ModificationResult> applyModification({
    required FunctionUnit original,
    required String newCode,
    required List<CallSource> callSources,
    required EvaluationRecord evaluation,
  }) async {
    // 1. التحقق من أسماء الدوال المساعدة في الكود الجديد
    final invalidNames = _validateHelperFunctionNames(newCode);
    if (invalidNames.isNotEmpty) {
      return ModificationResult(
        status: ModificationStatus.invalidHelperName,
        message: 'أسماء دوال مساعدة لا تتبع نمط verbNoun أو verbAdjectiveNoun: '
            '${invalidNames.join(", ")}',
        invalidHelperNames: invalidNames,
      );
    }

    // 2. كشف تغييرات السلوك الخارجي
    final behaviorDiffs = _detectBehaviorChanges(original, newCode);
    if (behaviorDiffs.isNotEmpty) {
      return ModificationResult(
        status: ModificationStatus.needsApproval,
        message: 'التعديل يغير السلوك الخارجي للدالة. يحتاج موافقة المطور.',
        behaviorDifferences: behaviorDiffs,
      );
    }

    // 3. حفظ حالة الملف الأصلية
    final filePath = _resolveFilePath(original.filePath);
    final saveResult = await _saveOriginalState(filePath);
    if (!saveResult) {
      return const ModificationResult(
        status: ModificationStatus.failure,
        message: 'فشل في حفظ حالة الملف الأصلية.',
      );
    }

    // 4. تطبيق الكود الجديد على الملف
    final applyResult = await _applyNewCode(
      filePath: filePath,
      startLine: original.startLine,
      endLine: original.endLine,
      newCode: newCode,
    );
    if (!applyResult) {
      return const ModificationResult(
        status: ModificationStatus.failure,
        message: 'فشل في تطبيق الكود الجديد على الملف.',
      );
    }

    // 5. تحديث Call_Source إذا تغير التوقيع
    final signatureChanged = _hasSignatureChanged(original.signature, newCode);
    if (signatureChanged) {
      final updateResult = await _updateCallSources(
        original: original,
        newCode: newCode,
        callSources: callSources,
      );
      if (!updateResult) {
        // إرجاع الملف الأصلي عند فشل تحديث المراجع
        await revertLastModification();
        return const ModificationResult(
          status: ModificationStatus.failure,
          message: 'فشل في تحديث مراجع الاستدعاء بعد تغيير التوقيع.',
        );
      }
    }

    // 6. التحقق من التجميع
    final compilationErrors = await _verifyCompilation();
    if (compilationErrors.isNotEmpty) {
      // إرجاع عند فشل التجميع
      await revertLastModification();
      return ModificationResult(
        status: ModificationStatus.compilationFailed,
        message: 'فشل التحقق من التجميع بعد التعديل.',
        compilationErrors: compilationErrors,
      );
    }

    // 7. إنشاء وحفظ سجل التعديل
    final modLog = _createModificationLog(
      original: original,
      newCode: newCode,
      evaluation: evaluation,
    );

    await _storage.saveModification(
      coreFilePath: original.filePath,
      modificationEntry: modLog.toJson(),
    );

    return ModificationResult(
      status: ModificationStatus.success,
      message: 'تم تطبيق التعديل بنجاح.',
      log: modLog,
    );
  }

  /// يرجع آخر تعديل تم تطبيقه.
  ///
  /// يستخدم الحالة المحفوظة لاستعادة الملف الأصلي.
  Future<bool> revertLastModification() async {
    if (_savedOriginalContent == null || _savedFilePath == null) {
      return false;
    }

    try {
      await File(_savedFilePath!).writeAsString(_savedOriginalContent!);
      _savedOriginalContent = null;
      _savedFilePath = null;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// يعيد المحتوى الأصلي المحفوظ (للاستخدام من Test Runner).
  String? get savedOriginalContent => _savedOriginalContent;

  /// يعيد مسار الملف المحفوظ.
  String? get savedFilePath => _savedFilePath;

  // ---------------------------------------------------------------------------
  // Private: حفظ الحالة الأصلية
  // ---------------------------------------------------------------------------

  Future<bool> _saveOriginalState(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      _savedOriginalContent = await file.readAsString();
      _savedFilePath = filePath;
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private: تطبيق الكود الجديد
  // ---------------------------------------------------------------------------

  Future<bool> _applyNewCode({
    required String filePath,
    required int startLine,
    required int endLine,
    required String newCode,
  }) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final lines = content.split('\n');

      // التحقق من صحة نطاق الأسطر (1-indexed)
      if (startLine < 1 || endLine > lines.length || startLine > endLine) {
        return false;
      }

      // استبدال الأسطر من startLine إلى endLine بالكود الجديد
      final before = lines.sublist(0, startLine - 1);
      final after = lines.sublist(endLine);
      final newLines = [...before, ...newCode.split('\n'), ...after];

      await file.writeAsString(newLines.join('\n'));
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private: كشف تغيير التوقيع
  // ---------------------------------------------------------------------------

  /// يتحقق مما إذا كان التوقيع قد تغير بمقارنة التوقيع الأصلي
  /// مع أول سطر غير فارغ في الكود الجديد.
  bool _hasSignatureChanged(String originalSignature, String newCode) {
    final newFirstLine = _extractSignatureFromCode(newCode);
    if (newFirstLine == null) return false;

    // مقارنة بعد إزالة المسافات الزائدة
    final normalizedOriginal =
        originalSignature.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalizedNew = newFirstLine.trim().replaceAll(RegExp(r'\s+'), ' ');

    return normalizedOriginal != normalizedNew;
  }

  /// يستخرج التوقيع من الكود الجديد (أول سطر يحتوي على تعريف دالة).
  String? _extractSignatureFromCode(String code) {
    final lines = code.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      // تخطي التعليقات والأسطر الفارغة والتعليقات التوضيحية
      if (trimmed.isEmpty ||
          trimmed.startsWith('//') ||
          trimmed.startsWith('///') ||
          trimmed.startsWith('@') ||
          trimmed.startsWith('/*') ||
          trimmed.startsWith('*')) {
        continue;
      }
      // أول سطر غير تعليق هو التوقيع
      // نأخذ حتى `{` أو نهاية السطر
      final braceIndex = trimmed.indexOf('{');
      if (braceIndex > 0) {
        return trimmed.substring(0, braceIndex).trim();
      }
      return trimmed;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Private: تحديث مصادر الاستدعاء
  // ---------------------------------------------------------------------------

  Future<bool> _updateCallSources({
    required FunctionUnit original,
    required String newCode,
    required List<CallSource> callSources,
  }) async {
    if (callSources.isEmpty) return true;

    final newSignature = _extractSignatureFromCode(newCode);
    if (newSignature == null) return true;

    // استخراج اسم الدالة الجديد والمعاملات
    final newFuncName = _extractFunctionName(newSignature);
    final originalFuncName = original.name;

    // إذا تغير اسم الدالة، نحدث جميع المراجع
    if (newFuncName != null && newFuncName != originalFuncName) {
      for (final callSource in callSources) {
        final callFilePath = _resolveFilePath(callSource.filePath);
        try {
          final file = File(callFilePath);
          if (!await file.exists()) continue;

          var content = await file.readAsString();
          // استبدال اسم الدالة القديم بالجديد في الاستدعاءات
          content = content.replaceAll(
            RegExp('\\b${RegExp.escape(originalFuncName)}\\b'),
            newFuncName,
          );
          await file.writeAsString(content);
        } catch (e) {
          return false;
        }
      }
    }

    return true;
  }

  /// يستخرج اسم الدالة من التوقيع.
  String? _extractFunctionName(String signature) {
    // أنماط شائعة: `ReturnType functionName(...)` أو `functionName(...)`
    final match = RegExp(r'(?:\w+\s+)?(\w+)\s*\(').firstMatch(signature);
    return match?.group(1);
  }

  // ---------------------------------------------------------------------------
  // Private: التحقق من التجميع
  // ---------------------------------------------------------------------------

  /// يشغل `dart analyze` على المشروع ويعيد قائمة الأخطاء.
  Future<List<String>> _verifyCompilation() async {
    try {
      final result = await Process.run(
        'dart',
        ['analyze', '--fatal-infos=false', '--fatal-warnings=false'],
        workingDirectory: _projectRoot,
      );

      if (result.exitCode == 0) {
        return [];
      }

      // تحليل مخرجات الأخطاء
      final output = '${result.stdout}\n${result.stderr}'.trim();
      final errors = <String>[];

      for (final line in output.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty &&
            (trimmed.contains('error') || trimmed.contains('Error'))) {
          errors.add(trimmed);
        }
      }

      // إذا لم نجد أخطاء محددة لكن exit code != 0
      if (errors.isEmpty && result.exitCode != 0) {
        errors.add('dart analyze exited with code ${result.exitCode}');
      }

      return errors;
    } catch (e) {
      return ['فشل تشغيل dart analyze: $e'];
    }
  }

  // ---------------------------------------------------------------------------
  // Private: كشف تغييرات السلوك الخارجي
  // ---------------------------------------------------------------------------

  /// يكشف التغييرات في السلوك الخارجي بمقارنة:
  /// - تغيير نوع الإرجاع
  /// - تغيير المعاملات (إضافة/حذف/تغيير نوع)
  /// - تغيير الاستثناءات المرمية
  /// - تغيير التأثيرات الجانبية (notifyListeners, emit, إلخ)
  List<String> _detectBehaviorChanges(FunctionUnit original, String newCode) {
    final differences = <String>[];

    final newSignature = _extractSignatureFromCode(newCode);
    if (newSignature == null) return differences;

    // كشف تغيير نوع الإرجاع
    final originalReturnType = original.returnType;
    final newReturnType = _extractReturnType(newSignature);
    if (newReturnType != null &&
        newReturnType != originalReturnType &&
        newReturnType != 'dynamic') {
      differences.add(
        'تغيير نوع الإرجاع: $originalReturnType → $newReturnType',
      );
    }

    // كشف تغيير المعاملات
    final originalParamCount = original.params.length;
    final newParamCount = _countParameters(newSignature);
    if (newParamCount != null && newParamCount != originalParamCount) {
      differences.add(
        'تغيير عدد المعاملات: $originalParamCount → $newParamCount',
      );
    }

    // كشف إزالة throw statements
    final originalThrows = _containsThrow(original.body);
    final newThrows = _containsThrow(newCode);
    if (originalThrows && !newThrows) {
      differences.add('تمت إزالة throw statements من الدالة');
    }
    if (!originalThrows && newThrows) {
      differences.add('تمت إضافة throw statements جديدة للدالة');
    }

    // كشف تغيير في التأثيرات الجانبية
    final originalSideEffects = _extractSideEffects(original.body);
    final newSideEffects = _extractSideEffects(newCode);
    final removedEffects = originalSideEffects.difference(newSideEffects);
    final addedEffects = newSideEffects.difference(originalSideEffects);

    if (removedEffects.isNotEmpty) {
      differences.add(
        'تمت إزالة تأثيرات جانبية: ${removedEffects.join(", ")}',
      );
    }
    if (addedEffects.isNotEmpty) {
      differences.add(
        'تمت إضافة تأثيرات جانبية: ${addedEffects.join(", ")}',
      );
    }

    return differences;
  }

  String? _extractReturnType(String signature) {
    // نمط: `ReturnType functionName(`
    final match =
        RegExp(r'^(\w[\w<>,\s\?]*?)\s+\w+\s*\(').firstMatch(signature);
    return match?.group(1)?.trim();
  }

  int? _countParameters(String signature) {
    final parenStart = signature.indexOf('(');
    final parenEnd = signature.lastIndexOf(')');
    if (parenStart < 0 || parenEnd < 0 || parenEnd <= parenStart + 1) {
      // أقواس فارغة = 0 معاملات
      if (parenStart >= 0 && parenEnd >= 0) {
        final content = signature.substring(parenStart + 1, parenEnd).trim();
        if (content.isEmpty) return 0;
      }
      return 0;
    }
    final content = signature.substring(parenStart + 1, parenEnd).trim();
    if (content.isEmpty) return 0;

    // عد المعاملات بتقسيم على الفواصل (مع مراعاة الأنواع المعقدة)
    var depth = 0;
    var count = 1;
    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '<' || char == '(' || char == '{' || char == '[') {
        depth++;
      } else if (char == '>' || char == ')' || char == '}' || char == ']') {
        depth--;
      } else if (char == ',' && depth == 0) {
        count++;
      }
    }
    return count;
  }

  bool _containsThrow(String code) {
    return RegExp(r'\bthrow\b').hasMatch(code);
  }

  Set<String> _extractSideEffects(String code) {
    final effects = <String>{};
    final patterns = [
      'notifyListeners',
      'setState',
      'add(', // StreamController.add
      'emit(',
      'sink.add',
      'Navigator.',
      'MethodChannel',
    ];

    for (final pattern in patterns) {
      if (code.contains(pattern)) {
        effects.add(pattern.replaceAll('(', '').replaceAll('.', ''));
      }
    }
    return effects;
  }

  // ---------------------------------------------------------------------------
  // Private: التحقق من أسماء الدوال المساعدة
  // ---------------------------------------------------------------------------

  /// يتحقق من أن أسماء الدوال المساعدة الجديدة تتبع نمط:
  /// - verbNoun (مثل: loadNotes, filterItems)
  /// - verbAdjectiveNoun (مثل: loadActiveNotes, filterExpiredItems)
  ///
  /// يبحث عن تعريفات دوال جديدة في الكود ويتحقق من أسمائها.
  List<String> _validateHelperFunctionNames(String newCode) {
    final invalidNames = <String>[];

    // البحث عن تعريفات دوال مساعدة (private functions تبدأ بـ _)
    final funcPattern = RegExp(
      r'(?:void|Future|Stream|bool|int|double|String|List|Map|Set|dynamic|\w+)\s+(_\w+)\s*[<(]',
    );

    final matches = funcPattern.allMatches(newCode);
    for (final match in matches) {
      final funcName = match.group(1);
      if (funcName == null) continue;

      // إزالة الـ _ من البداية للتحقق من النمط
      final nameWithoutUnderscore = funcName.substring(1);

      if (!_isValidHelperName(nameWithoutUnderscore)) {
        invalidNames.add(funcName);
      }
    }

    return invalidNames;
  }

  /// يتحقق من أن الاسم يتبع نمط verbNoun أو verbAdjectiveNoun.
  ///
  /// النمط المقبول: camelCase مع جزأين على الأقل (verb + noun)
  /// أمثلة صحيحة: loadNotes, filterActiveItems, calculateTotalPrice
  /// أمثلة خاطئة: notes, x, doIt
  bool _isValidHelperName(String name) {
    if (name.isEmpty) return false;

    // تقسيم camelCase إلى أجزاء
    final parts = _splitCamelCase(name);

    // يجب أن يكون هناك جزأين على الأقل (verb + noun)
    // verbNoun = 2 أجزاء، verbAdjectiveNoun = 3 أجزاء
    return parts.length >= 2;
  }

  /// يقسم اسم camelCase إلى أجزائه.
  ///
  /// مثال: "loadActiveNotes" → ["load", "Active", "Notes"]
  List<String> _splitCamelCase(String name) {
    final parts = <String>[];
    var current = StringBuffer();

    for (var i = 0; i < name.length; i++) {
      if (i > 0 &&
          name[i].toUpperCase() == name[i] &&
          name[i] != name[i].toLowerCase()) {
        if (current.isNotEmpty) {
          parts.add(current.toString());
          current = StringBuffer();
        }
      }
      current.write(name[i]);
    }
    if (current.isNotEmpty) {
      parts.add(current.toString());
    }

    return parts;
  }

  // ---------------------------------------------------------------------------
  // Private: إنشاء سجل التعديل
  // ---------------------------------------------------------------------------

  ModificationLog _createModificationLog({
    required FunctionUnit original,
    required String newCode,
    required EvaluationRecord evaluation,
  }) {
    final newLineCount = newCode.split('\n').length;
    final newSignature =
        _extractSignatureFromCode(newCode) ?? original.signature;

    // جمع الإجابات المبررة (التي كانت "نعم")
    final justifyingAnswers = <AnswerType>[];
    if (evaluation.question1.type == AnswerType.yes) {
      justifyingAnswers.add(evaluation.question1.type);
    }
    if (evaluation.question2.type == AnswerType.yes) {
      justifyingAnswers.add(evaluation.question2.type);
    }
    if (evaluation.question3.type == AnswerType.yes) {
      justifyingAnswers.add(evaluation.question3.type);
    }
    if (evaluation.question4.type == AnswerType.yes) {
      justifyingAnswers.add(evaluation.question4.type);
    }

    // بناء وصف التغيير من المبررات
    final justifications = <String>[];
    if (evaluation.question1.justification != null) {
      justifications.add(evaluation.question1.justification!);
    }
    if (evaluation.question2.justification != null) {
      justifications.add(evaluation.question2.justification!);
    }
    if (evaluation.question3.justification != null) {
      justifications.add(evaluation.question3.justification!);
    }
    if (evaluation.question4.justification != null) {
      justifications.add(evaluation.question4.justification!);
    }

    var description = justifications.join(' | ');
    // حد أقصى 500 حرف
    if (description.length > 500) {
      description = '${description.substring(0, 497)}...';
    }

    return ModificationLog(
      functionName: original.name,
      filePath: original.filePath,
      timestamp: DateTime.now(),
      signatureBefore: original.signature,
      signatureAfter: newSignature,
      lineCountBefore: original.lineCount,
      lineCountAfter: newLineCount,
      changeDescription: description,
      justifyingAnswers: justifyingAnswers,
    );
  }

  // ---------------------------------------------------------------------------
  // Private: مساعدات المسار
  // ---------------------------------------------------------------------------

  /// يحول المسار النسبي إلى مسار مطلق.
  String _resolveFilePath(String filePath) {
    if (p.isAbsolute(filePath)) return filePath;
    return p.join(_projectRoot, filePath);
  }
}
