import 'package:refactoring_tool/gate/answer_validator.dart';
import 'package:refactoring_tool/models/evaluation_record.dart';
import 'package:test/test.dart';

void main() {
  late AnswerValidator validator;

  setUp(() {
    validator = AnswerValidator();
  });

  group('AnswerValidator', () {
    group('validates answer count', () {
      test('rejects empty list', () {
        final result = validator.validate([]);
        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(1));
        expect(result.errors.first, contains('0'));
      });

      test('rejects fewer than 4 answers', () {
        final answers = [
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
        ];
        final result = validator.validate(answers);
        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('2'));
      });

      test('rejects more than 4 answers', () {
        final answers = List.generate(
          5,
          (_) => const EvaluationAnswer(type: AnswerType.no),
        );
        final result = validator.validate(answers);
        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('5'));
      });
    });

    group('validates justification for yes answers', () {
      test('rejects yes answer without justification', () {
        final answers = [
          const EvaluationAnswer(type: AnswerType.yes),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.unsure),
        ];
        final result = validator.validate(answers);
        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('السؤال 1'));
      });

      test('rejects yes answer with empty justification', () {
        final answers = [
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.yes, justification: ''),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
        ];
        final result = validator.validate(answers);
        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('السؤال 2'));
      });

      test('rejects yes answer with whitespace-only justification', () {
        final answers = [
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.yes, justification: '   '),
          const EvaluationAnswer(type: AnswerType.no),
        ];
        final result = validator.validate(answers);
        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('السؤال 3'));
      });

      test('rejects yes answer with justification exceeding 500 chars', () {
        final longText = 'أ' * 501;
        final answers = [
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
          EvaluationAnswer(type: AnswerType.yes, justification: longText),
        ];
        final result = validator.validate(answers);
        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('السؤال 4'));
        expect(result.errors.first, contains('500'));
      });

      test('collects multiple errors for multiple invalid answers', () {
        final answers = [
          const EvaluationAnswer(type: AnswerType.yes),
          const EvaluationAnswer(type: AnswerType.yes, justification: ''),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.yes),
        ];
        final result = validator.validate(answers);
        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(3));
      });
    });

    group('accepts valid answers', () {
      test('accepts all no answers', () {
        final answers = List.generate(
          4,
          (_) => const EvaluationAnswer(type: AnswerType.no),
        );
        final result = validator.validate(answers);
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('accepts all unsure answers', () {
        final answers = List.generate(
          4,
          (_) => const EvaluationAnswer(type: AnswerType.unsure),
        );
        final result = validator.validate(answers);
        expect(result.isValid, isTrue);
      });

      test('accepts yes with valid justification', () {
        final answers = [
          const EvaluationAnswer(
            type: AnswerType.yes,
            justification: 'يمكن تحسين الأداء',
          ),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.unsure),
          const EvaluationAnswer(
            type: AnswerType.yes,
            justification: 'فصل المنطق',
          ),
        ];
        final result = validator.validate(answers);
        expect(result.isValid, isTrue);
      });

      test('accepts yes with justification at exactly 500 chars', () {
        final exactText = 'أ' * 500;
        final answers = [
          EvaluationAnswer(type: AnswerType.yes, justification: exactText),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
        ];
        final result = validator.validate(answers);
        expect(result.isValid, isTrue);
      });

      test('accepts yes with single character justification', () {
        final answers = [
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.yes, justification: 'أ'),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
        ];
        final result = validator.validate(answers);
        expect(result.isValid, isTrue);
      });
    });

    group('no/unsure answers do not require justification', () {
      test('no answer without justification is valid', () {
        final answers = [
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
          const EvaluationAnswer(type: AnswerType.no),
        ];
        final result = validator.validate(answers);
        expect(result.isValid, isTrue);
      });

      test('unsure answer without justification is valid', () {
        final answers = [
          const EvaluationAnswer(type: AnswerType.unsure),
          const EvaluationAnswer(type: AnswerType.unsure),
          const EvaluationAnswer(type: AnswerType.unsure),
          const EvaluationAnswer(type: AnswerType.unsure),
        ];
        final result = validator.validate(answers);
        expect(result.isValid, isTrue);
      });
    });
  });
}
