/// نوع الإجابة
enum AnswerType { yes, no, unsure }

/// قرار التقييم
enum EvaluationDecision { keepUnchanged, modify, extract, remove }

/// يمثل إجابة على سؤال تقييمي
class EvaluationAnswer {
  final AnswerType type;
  final String? justification;

  const EvaluationAnswer({
    required this.type,
    this.justification,
  });

  /// التحقق من صحة الإجابة
  /// إذا كانت "نعم" يجب أن يكون هناك justification بين 1-500 حرف
  bool get isValid {
    if (type == AnswerType.yes) {
      return justification != null &&
          justification!.isNotEmpty &&
          justification!.length <= 500;
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (justification != null) 'justification': justification,
    };
  }

  factory EvaluationAnswer.fromJson(Map<String, dynamic> json) {
    return EvaluationAnswer(
      type: AnswerType.values.byName(json['type'] as String),
      justification: json['justification'] as String?,
    );
  }

  @override
  String toString() =>
      'EvaluationAnswer(${type.name}${justification != null ? ': $justification' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationAnswer &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          justification == other.justification;

  @override
  int get hashCode => Object.hash(type, justification);
}

/// سجل تقييم دالة
class EvaluationRecord {
  final String functionName;
  final String coreFilePath;
  final DateTime timestamp;
  final EvaluationAnswer question1; // هل هذا ما يجب أن تفعله؟
  final EvaluationAnswer question2; // هل يمكن تحسينها؟
  final EvaluationAnswer question3; // هل يمكن نقل أجزاء؟
  final EvaluationAnswer question4; // هل يمكن تفويض مهام؟
  final EvaluationDecision decision;

  const EvaluationRecord({
    required this.functionName,
    required this.coreFilePath,
    required this.timestamp,
    required this.question1,
    required this.question2,
    required this.question3,
    required this.question4,
    required this.decision,
  });

  /// التحقق من صحة جميع الإجابات
  bool get isValid =>
      question1.isValid &&
      question2.isValid &&
      question3.isValid &&
      question4.isValid;

  Map<String, dynamic> toJson() {
    return {
      'functionName': functionName,
      'coreFilePath': coreFilePath,
      'timestamp': timestamp.toIso8601String(),
      'question1': question1.toJson(),
      'question2': question2.toJson(),
      'question3': question3.toJson(),
      'question4': question4.toJson(),
      'decision': decision.name,
    };
  }

  factory EvaluationRecord.fromJson(Map<String, dynamic> json) {
    return EvaluationRecord(
      functionName: json['functionName'] as String,
      coreFilePath: json['coreFilePath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      question1:
          EvaluationAnswer.fromJson(json['question1'] as Map<String, dynamic>),
      question2:
          EvaluationAnswer.fromJson(json['question2'] as Map<String, dynamic>),
      question3:
          EvaluationAnswer.fromJson(json['question3'] as Map<String, dynamic>),
      question4:
          EvaluationAnswer.fromJson(json['question4'] as Map<String, dynamic>),
      decision: EvaluationDecision.values.byName(json['decision'] as String),
    );
  }

  @override
  String toString() => 'EvaluationRecord($functionName: ${decision.name})';
}
