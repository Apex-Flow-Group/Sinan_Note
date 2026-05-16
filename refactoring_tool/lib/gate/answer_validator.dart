import 'package:refactoring_tool/models/evaluation_record.dart';

/// نتيجة التحقق من الإجابات
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult._({required this.isValid, required this.errors});

  factory ValidationResult.valid() =>
      const ValidationResult._(isValid: true, errors: []);

  factory ValidationResult.invalid(List<String> errors) =>
      ValidationResult._(isValid: false, errors: errors);

  @override
  String toString() => isValid
      ? 'ValidationResult(valid)'
      : 'ValidationResult(invalid: ${errors.join(", ")})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationResult &&
          runtimeType == other.runtimeType &&
          isValid == other.isValid &&
          _listEquals(errors, other.errors);

  @override
  int get hashCode => Object.hash(isValid, Object.hashAll(errors));

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// التحقق من صحة إجابات بوابة التقييم
class AnswerValidator {
  /// عدد الأسئلة المطلوبة
  static const int requiredQuestionCount = 4;

  /// الحد الأدنى لطول نص التبرير
  static const int minJustificationLength = 1;

  /// الحد الأقصى لطول نص التبرير
  static const int maxJustificationLength = 500;

  /// التحقق من صحة قائمة الإجابات
  ///
  /// يتحقق من:
  /// - وجود 4 إجابات بالضبط
  /// - عدم وجود إجابات فارغة
  /// - وجود نص تبرير (1-500 حرف) لكل إجابة "نعم"
  ValidationResult validate(List<EvaluationAnswer> answers) {
    final errors = <String>[];

    // التحقق من وجود 4 إجابات
    if (answers.length != requiredQuestionCount) {
      errors.add(
        'يجب الإجابة على جميع الأسئلة الأربعة. '
        'تم تقديم ${answers.length} من $requiredQuestionCount',
      );
      return ValidationResult.invalid(errors);
    }

    // التحقق من كل إجابة
    for (var i = 0; i < answers.length; i++) {
      final answer = answers[i];
      final questionNumber = i + 1;

      if (answer.type == AnswerType.yes) {
        if (answer.justification == null || answer.justification!.isEmpty) {
          errors.add(
            'السؤال $questionNumber: نص التبرير مطلوب عند الإجابة بـ "نعم"',
          );
        } else if (answer.justification!.trim().isEmpty) {
          errors.add(
            'السؤال $questionNumber: نص التبرير لا يمكن أن يكون فارغاً',
          );
        } else if (answer.justification!.length > maxJustificationLength) {
          errors.add(
            'السؤال $questionNumber: نص التبرير يتجاوز الحد الأقصى '
            '($maxJustificationLength حرف). '
            'الطول الحالي: ${answer.justification!.length}',
          );
        }
      }
    }

    if (errors.isEmpty) {
      return ValidationResult.valid();
    }

    return ValidationResult.invalid(errors);
  }
}
