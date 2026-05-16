import 'package:refactoring_tool/models/evaluation_record.dart';
import 'package:refactoring_tool/models/modification_log.dart';
import 'package:refactoring_tool/storage/storage_manager.dart';

/// سجل إزالة كود ميت
class DeadCodeRemovalRecord {
  final String functionName;
  final String coreFilePath;
  final String reason;
  final int lastCallSourceCount;
  final DateTime dateOfRemoval;

  const DeadCodeRemovalRecord({
    required this.functionName,
    required this.coreFilePath,
    required this.reason,
    required this.lastCallSourceCount,
    required this.dateOfRemoval,
  });

  Map<String, dynamic> toJson() {
    return {
      'functionName': functionName,
      'coreFilePath': coreFilePath,
      'reason': reason,
      'lastCallSourceCount': lastCallSourceCount,
      'dateOfRemoval': dateOfRemoval.toIso8601String(),
    };
  }

  factory DeadCodeRemovalRecord.fromJson(Map<String, dynamic> json) {
    return DeadCodeRemovalRecord(
      functionName: json['functionName'] as String,
      coreFilePath: json['coreFilePath'] as String,
      reason: json['reason'] as String,
      lastCallSourceCount: json['lastCallSourceCount'] as int,
      dateOfRemoval: DateTime.parse(json['dateOfRemoval'] as String),
    );
  }

  @override
  String toString() => 'DeadCodeRemovalRecord($functionName in $coreFilePath)';
}

/// مسجل القرارات - يحدد القرار من الإجابات ويحفظه عبر StorageManager
///
/// المسؤوليات:
/// - تحديد القرار بناءً على إجابات التقييم
/// - إنشاء سجل التقييم (EvaluationRecord)
/// - حفظ السجل عبر StorageManager
/// - تسجيل ملخص التعديلات (قبل/بعد)
/// - توثيق إزالة الكود الميت
class DecisionRecorder {
  final StorageManager _storageManager;

  DecisionRecorder({required StorageManager storageManager})
      : _storageManager = storageManager;

  /// يحدد القرار بناءً على إجابات التقييم الأربعة
  ///
  /// منطق القرار:
  /// - جميع الإجابات "لا" → keepUnchanged (لا تغييرات مطلوبة)
  /// - أي إجابة "نعم" → modify (فتح التعديل)
  /// - "غير متأكد" فقط (بدون "نعم") → extract (مراجعة لاحقة)
  EvaluationDecision determineDecision(List<EvaluationAnswer> answers) {
    final hasYes = answers.any((a) => a.type == AnswerType.yes);
    final hasUnsure = answers.any((a) => a.type == AnswerType.unsure);
    final allNo = answers.every((a) => a.type == AnswerType.no);

    if (allNo) {
      return EvaluationDecision.keepUnchanged;
    }

    if (hasYes) {
      return EvaluationDecision.modify;
    }

    // Only unsure answers (possibly mixed with no, but no yes)
    if (hasUnsure && !hasYes) {
      // "pending review" - using extract as the closest enum value
      // representing a state that needs further review
      return EvaluationDecision.extract;
    }

    // Fallback (should not reach here with valid inputs)
    return EvaluationDecision.keepUnchanged;
  }

  /// يسجل قرار التقييم لدالة معينة
  ///
  /// ينشئ EvaluationRecord ويحفظه عبر StorageManager
  Future<EvaluationRecord> recordDecision({
    required String functionName,
    required String coreFilePath,
    required EvaluationAnswer question1,
    required EvaluationAnswer question2,
    required EvaluationAnswer question3,
    required EvaluationAnswer question4,
    DateTime? timestamp,
  }) async {
    final answers = [question1, question2, question3, question4];
    final decision = determineDecision(answers);
    final now = timestamp ?? DateTime.now();

    final record = EvaluationRecord(
      functionName: functionName,
      coreFilePath: coreFilePath,
      timestamp: now,
      question1: question1,
      question2: question2,
      question3: question3,
      question4: question4,
      decision: decision,
    );

    // حفظ القرار عبر StorageManager
    await _storageManager.saveDecision(
      coreFilePath: coreFilePath,
      decisionEntry: record.toJson(),
    );

    return record;
  }

  /// يسجل ملخص التعديل (قبل/بعد) لدالة تم تعديلها
  ///
  /// يتضمن: التوقيع قبل وبعد، عدد الأسطر، وصف التغيير (حد أقصى 500 حرف)
  Future<void> recordModification({
    required String functionName,
    required String coreFilePath,
    required String signatureBefore,
    required String signatureAfter,
    required int lineCountBefore,
    required int lineCountAfter,
    required String changeDescription,
    required List<AnswerType> justifyingAnswers,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();

    // تقليص الوصف إلى 500 حرف كحد أقصى
    final truncatedDescription = changeDescription.length > 500
        ? changeDescription.substring(0, 500)
        : changeDescription;

    final modificationLog = ModificationLog(
      functionName: functionName,
      filePath: coreFilePath,
      timestamp: now,
      signatureBefore: signatureBefore,
      signatureAfter: signatureAfter,
      lineCountBefore: lineCountBefore,
      lineCountAfter: lineCountAfter,
      changeDescription: truncatedDescription,
      justifyingAnswers: justifyingAnswers,
    );

    await _storageManager.saveModification(
      coreFilePath: coreFilePath,
      modificationEntry: modificationLog.toJson(),
      timestamp: now,
    );
  }

  /// يوثق إزالة كود ميت
  ///
  /// يسجل: اسم الدالة، مسار الملف، سبب الإزالة، آخر عدد Call_Source (صفر)، تاريخ الإزالة
  Future<void> recordDeadCodeRemoval({
    required String functionName,
    required String coreFilePath,
    required String reason,
    int lastCallSourceCount = 0,
    DateTime? dateOfRemoval,
  }) async {
    final removalDate = dateOfRemoval ?? DateTime.now();

    final removalRecord = DeadCodeRemovalRecord(
      functionName: functionName,
      coreFilePath: coreFilePath,
      reason: reason,
      lastCallSourceCount: lastCallSourceCount,
      dateOfRemoval: removalDate,
    );

    // تحميل تقرير الكود الميت الحالي أو إنشاء واحد جديد
    final existingData = await _storageManager.loadDeadCode();
    final deadCodeData = existingData ?? {'removals': <dynamic>[]};

    if (deadCodeData['removals'] == null) {
      deadCodeData['removals'] = <dynamic>[];
    }

    (deadCodeData['removals'] as List<dynamic>).add(removalRecord.toJson());

    await _storageManager.saveDeadCode(deadCodeData);
  }
}
