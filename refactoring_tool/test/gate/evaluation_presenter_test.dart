import 'package:refactoring_tool/gate/evaluation_presenter.dart';
import 'package:refactoring_tool/models/evaluation_record.dart';
import 'package:test/test.dart';

/// محول IO وهمي للاختبار
class MockIOAdapter implements IOAdapter {
  final List<String> inputs;
  final List<String> outputs = [];
  int _inputIndex = 0;

  MockIOAdapter(this.inputs);

  @override
  void write(String text) {
    outputs.add(text);
  }

  @override
  void writeln(String text) {
    outputs.add(text);
  }

  @override
  String? readLine() {
    if (_inputIndex < inputs.length) {
      return inputs[_inputIndex++];
    }
    return null;
  }
}

void main() {
  group('EvaluationPresenter', () {
    test('presents all 4 questions and collects "لا" answers', () {
      final mockIO = MockIOAdapter([
        'لا', // Q1
        'لا', // Q2
        'لا', // Q3
        'لا', // Q4
      ]);

      final presenter = EvaluationPresenter(io: mockIO);
      final answers = presenter.presentQuestions();

      expect(answers.length, equals(4));
      for (final answer in answers) {
        expect(answer.type, equals(AnswerType.no));
        expect(answer.justification, isNull);
      }
    });

    test('collects "نعم" answers with justification', () {
      final mockIO = MockIOAdapter([
        'نعم', // Q1
        'تحتاج فصل منطق التحميل عن التصفية', // justification for Q1
        'لا', // Q2
        'نعم', // Q3
        'يمكن نقل التصفية لدالة مساعدة', // justification for Q3
        'لا', // Q4
      ]);

      final presenter = EvaluationPresenter(io: mockIO);
      final answers = presenter.presentQuestions();

      expect(answers.length, equals(4));
      expect(answers[0].type, equals(AnswerType.yes));
      expect(answers[0].justification,
          equals('تحتاج فصل منطق التحميل عن التصفية'));
      expect(answers[1].type, equals(AnswerType.no));
      expect(answers[2].type, equals(AnswerType.yes));
      expect(answers[2].justification, equals('يمكن نقل التصفية لدالة مساعدة'));
      expect(answers[3].type, equals(AnswerType.no));
    });

    test('collects "غير متأكد" answers', () {
      final mockIO = MockIOAdapter([
        'غير متأكد', // Q1
        'غير متأكد', // Q2
        'لا', // Q3
        'غير متأكد', // Q4
      ]);

      final presenter = EvaluationPresenter(io: mockIO);
      final answers = presenter.presentQuestions();

      expect(answers.length, equals(4));
      expect(answers[0].type, equals(AnswerType.unsure));
      expect(answers[0].justification, isNull);
      expect(answers[1].type, equals(AnswerType.unsure));
      expect(answers[2].type, equals(AnswerType.no));
      expect(answers[3].type, equals(AnswerType.unsure));
    });

    test('rejects invalid answers and re-prompts', () {
      final mockIO = MockIOAdapter([
        'ربما', // invalid answer for Q1
        'لا', // valid answer for Q1 (re-prompt)
        'لا', // Q2
        'لا', // Q3
        'لا', // Q4
      ]);

      final presenter = EvaluationPresenter(io: mockIO);
      final answers = presenter.presentQuestions();

      expect(answers.length, equals(4));
      expect(answers[0].type, equals(AnswerType.no));
      // Check that error message was shown
      expect(mockIO.outputs.any((o) => o.contains('إجابة غير صالحة')), isTrue);
    });

    test('rejects empty input and re-prompts', () {
      final mockIO = MockIOAdapter([
        '', // empty for Q1
        'لا', // valid answer for Q1 (re-prompt)
        'لا', // Q2
        'لا', // Q3
        'لا', // Q4
      ]);

      final presenter = EvaluationPresenter(io: mockIO);
      final answers = presenter.presentQuestions();

      expect(answers.length, equals(4));
      expect(answers[0].type, equals(AnswerType.no));
      expect(mockIO.outputs.any((o) => o.contains('يجب إدخال إجابة')), isTrue);
    });

    test('rejects justification over 500 characters', () {
      final longText = 'أ' * 501;
      final mockIO = MockIOAdapter([
        'نعم', // Q1
        longText, // too long justification - loops back in _askJustification
        'مبرر قصير', // valid justification on retry
        'لا', // Q2
        'لا', // Q3
        'لا', // Q4
      ]);

      final presenter = EvaluationPresenter(io: mockIO);
      final answers = presenter.presentQuestions();

      expect(answers.length, equals(4));
      expect(answers[0].type, equals(AnswerType.yes));
      expect(answers[0].justification, equals('مبرر قصير'));
      expect(mockIO.outputs.any((o) => o.contains('المبرر طويل جداً')), isTrue);
    });

    test('allows going back from justification prompt', () {
      final mockIO = MockIOAdapter([
        'نعم', // Q1 - answer yes
        '', // empty justification
        'رجوع', // go back
        'لا', // Q1 re-prompt - answer no this time
        'لا', // Q2
        'لا', // Q3
        'لا', // Q4
      ]);

      final presenter = EvaluationPresenter(io: mockIO);
      final answers = presenter.presentQuestions();

      expect(answers.length, equals(4));
      expect(answers[0].type, equals(AnswerType.no));
    });

    test('has correct question texts', () {
      expect(EvaluationPresenter.questions.length, equals(4));
      expect(EvaluationPresenter.questions[0],
          equals('هل هذا ما يجب أن تفعله هذه الدالة؟'));
      expect(EvaluationPresenter.questions[1], equals('هل يمكن تحسينها؟'));
      expect(EvaluationPresenter.questions[2],
          equals('هل يمكن نقل أجزاء منها لشجرة/دالة أخرى؟'));
      expect(EvaluationPresenter.questions[3],
          equals('هل يمكن تفويض بعض المهام لدوال مساعدة؟'));
    });

    test('mixed answers scenario', () {
      final mockIO = MockIOAdapter([
        'نعم', // Q1
        'الدالة تقوم بأكثر من مهمة واحدة', // justification
        'نعم', // Q2
        'يمكن تقليل التعقيد', // justification
        'غير متأكد', // Q3
        'نعم', // Q4
        'فصل التصفية لدالة مساعدة', // justification
      ]);

      final presenter = EvaluationPresenter(io: mockIO);
      final answers = presenter.presentQuestions();

      expect(answers.length, equals(4));
      expect(answers[0].type, equals(AnswerType.yes));
      expect(
          answers[0].justification, equals('الدالة تقوم بأكثر من مهمة واحدة'));
      expect(answers[1].type, equals(AnswerType.yes));
      expect(answers[1].justification, equals('يمكن تقليل التعقيد'));
      expect(answers[2].type, equals(AnswerType.unsure));
      expect(answers[3].type, equals(AnswerType.yes));
      expect(answers[3].justification, equals('فصل التصفية لدالة مساعدة'));
    });

    test('all answers are valid EvaluationAnswer objects', () {
      final mockIO = MockIOAdapter([
        'نعم',
        'مبرر صالح',
        'لا',
        'غير متأكد',
        'نعم',
        'مبرر آخر',
      ]);

      final presenter = EvaluationPresenter(io: mockIO);
      final answers = presenter.presentQuestions();

      for (final answer in answers) {
        expect(answer.isValid, isTrue);
      }
    });
  });
}
