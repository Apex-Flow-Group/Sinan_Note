import 'dart:io';

import 'package:refactoring_tool/models/evaluation_record.dart';

/// واجهة مجردة للتعامل مع الإدخال/الإخراج - تسهل الاختبار
abstract class IOAdapter {
  /// كتابة نص إلى المخرجات (بدون سطر جديد)
  void write(String text);

  /// كتابة سطر إلى المخرجات (مع سطر جديد)
  void writeln(String text);

  /// قراءة سطر من المدخلات
  String? readLine();
}

/// محول الإدخال/الإخراج الافتراضي باستخدام dart:io stdin/stdout
class StdIOAdapter implements IOAdapter {
  @override
  void write(String text) {
    stdout.write(text);
  }

  @override
  void writeln(String text) {
    stdout.writeln(text);
  }

  @override
  String? readLine() {
    try {
      return stdin.readLineSync();
    } catch (_) {
      return null;
    }
  }
}

/// عارض أسئلة التقييم عبر CLI
class EvaluationPresenter {
  final IOAdapter _io;

  /// الأسئلة التقييمية الأربعة
  static const List<String> questions = [
    'هل هذا ما يجب أن تفعله هذه الدالة؟',
    'هل يمكن تحسينها؟',
    'هل يمكن نقل أجزاء منها لشجرة/دالة أخرى؟',
    'هل يمكن تفويض بعض المهام لدوال مساعدة؟',
  ];

  /// الإجابات المقبولة
  static const List<String> validAnswers = ['نعم', 'لا', 'غير متأكد'];

  /// الحد الأدنى لطول المبرر
  static const int minJustificationLength = 1;

  /// الحد الأقصى لطول المبرر
  static const int maxJustificationLength = 500;

  EvaluationPresenter({IOAdapter? io}) : _io = io ?? StdIOAdapter();

  /// عرض جميع أسئلة التقييم وجمع الإجابات
  /// يعرض الأسئلة الأربعة بالتتابع ويجمع الإجابات
  /// يُرجع قائمة من 4 عناصر [EvaluationAnswer]
  List<EvaluationAnswer> presentQuestions() {
    final answers = <EvaluationAnswer>[];

    _io.writeln('');
    _io.writeln('━━━ أسئلة التقييم ━━━');
    _io.writeln('  الإجابات المتاحة: نعم | لا | غير متأكد');
    _io.writeln('');

    for (var i = 0; i < questions.length; i++) {
      final answer = _askQuestion(i + 1, questions[i]);
      answers.add(answer);
    }

    _io.writeln('');
    _io.writeln('━━━ تم جمع جميع الإجابات ━━━');
    _io.writeln('');

    return answers;
  }

  /// طرح سؤال واحد وجمع الإجابة
  EvaluationAnswer _askQuestion(int number, String question) {
    while (true) {
      _io.write('  $number. $question [نعم/لا/غير متأكد]: ');
      final input = _io.readLine()?.trim();

      if (input == null || input.isEmpty) {
        _io.writeln(
            '  ⚠️ يجب إدخال إجابة. الإجابات المتاحة: نعم، لا، غير متأكد');
        continue;
      }

      final answerType = _parseAnswer(input);
      if (answerType == null) {
        _io.writeln(
            '  ⚠️ إجابة غير صالحة: "$input". الإجابات المتاحة: نعم، لا، غير متأكد');
        continue;
      }

      // إذا كانت الإجابة "نعم"، اطلب المبرر
      if (answerType == AnswerType.yes) {
        final justification = _askJustification();
        if (justification == null) {
          // المستخدم لم يقدم مبرراً صالحاً، أعد طرح السؤال
          continue;
        }
        return EvaluationAnswer(type: answerType, justification: justification);
      }

      return EvaluationAnswer(type: answerType);
    }
  }

  /// طلب المبرر عند الإجابة بـ "نعم"
  /// يُرجع النص أو null إذا فشل التحقق
  String? _askJustification() {
    while (true) {
      _io.write('     المبرر (1-500 حرف): ');
      final input = _io.readLine()?.trim();

      if (input == null || input.isEmpty) {
        _io.writeln(
            '     ⚠️ المبرر مطلوب عند الإجابة بـ "نعم". أدخل نصاً بين 1-500 حرف.');
        _io.writeln('     (اكتب "رجوع" للعودة واختيار إجابة أخرى)');

        // اقرأ مرة أخرى
        _io.write('     المبرر (1-500 حرف): ');
        final retry = _io.readLine()?.trim();

        if (retry == null || retry.isEmpty || retry == 'رجوع') {
          return null;
        }

        if (retry.length > maxJustificationLength) {
          _io.writeln(
              '     ⚠️ المبرر طويل جداً (${retry.length} حرف). الحد الأقصى 500 حرف.');
          return null;
        }

        return retry;
      }

      if (input == 'رجوع') {
        return null;
      }

      if (input.length > maxJustificationLength) {
        _io.writeln(
            '     ⚠️ المبرر طويل جداً (${input.length} حرف). الحد الأقصى 500 حرف.');
        continue;
      }

      return input;
    }
  }

  /// تحويل النص إلى نوع الإجابة
  AnswerType? _parseAnswer(String input) {
    switch (input) {
      case 'نعم':
        return AnswerType.yes;
      case 'لا':
        return AnswerType.no;
      case 'غير متأكد':
        return AnswerType.unsure;
      default:
        return null;
    }
  }
}
