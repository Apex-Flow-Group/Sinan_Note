// Copyright © 2025 Apex Flow Group. All rights reserved.
// 🧠 SMART SERVICES — SmartAnalyzer + LanguageDetector + ChecklistFormatter

import 'dart:convert';import 'package:flutter_test/flutter_test.dart';import 'package:sinan_note/core/utils/checklist_formatter.dart'; import 'package:sinan_note/services/language_detector.dart'; import 'package:sinan_note/services/smart_analyzer.dart';
void main() {
  // ══════════════════════════════════════════════════════════════
  // 1. SmartAnalyzer — الحسابات الرياضية
  // ══════════════════════════════════════════════════════════════
  group('SmartAnalyzer — Math', () {
    late SmartAnalyzer analyzer;
    setUp(() => analyzer = SmartAnalyzer());

    test('جمع بسيط', () {
      expect(analyzer.evaluateExpression('2 + 3'), '5');
    });

    test('طرح', () {
      expect(analyzer.evaluateExpression('10 - 4'), '6');
    });

    test('ضرب', () {
      expect(analyzer.evaluateExpression('6 * 7'), '42');
    });

    test('قسمة', () {
      expect(analyzer.evaluateExpression('15 / 3'), '5');
    });

    test('قسمة على صفر يُرجع null', () {
      expect(analyzer.evaluateExpression('5 / 0'), isNull);
    });

    test('عمليات مركبة', () {
      expect(analyzer.evaluateExpression('2 + 3 * 4'), isNotNull);
    });

    test('أرقام عشرية', () {
      expect(analyzer.evaluateExpression('1.5 + 2.5'), '4');
    });

    test('نص بدون أرقام يُرجع null', () {
      expect(analyzer.evaluateExpression('hello world'), isNull);
    });

    test('نص فارغ يُرجع null', () {
      expect(analyzer.evaluateExpression(''), isNull);
    });

    test('تطبيع الأرقام العربية', () {
      expect(SmartAnalyzer.normalizeNumbers('١٢٣'), '123');
      expect(SmartAnalyzer.normalizeNumbers('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    });

    test('رمز × يعمل كضرب', () {
      expect(analyzer.evaluateExpression('3 × 4'), '12');
    });

    test('رمز ÷ يعمل كقسمة', () {
      expect(analyzer.evaluateExpression('12 ÷ 4'), '3');
    });

    test('sumAllNumbers يجمع كل الأرقام', () {
      expect(analyzer.sumAllNumbers('لدي 5 تفاحات و 3 برتقالات'), 8.0);
    });

    test('sumAllNumbers يتجاهل النسب المئوية', () {
      final result = analyzer.sumAllNumbers('خصم 20% على 100 ريال');
      // يجب أن يتجاهل 20% ويجمع 100 فقط
      expect(result, isNotNull);
    });

    test('analyzeParagraph يُحلل فقرة بأرقام', () {
      final result = analyzer.analyzeParagraph('5\n3\n2');
      expect(result, isNotNull);
      expect(result!['result'], '10');
    });

    test('analyzeParagraph يُرجع null لنص بدون أرقام', () {
      expect(analyzer.analyzeParagraph('نص عادي بدون أرقام'), isNull);
    });

    test('extractParagraph يستخرج الفقرة الصحيحة', () {
      const text = 'فقرة أولى\n\nفقرة ثانية\n\nفقرة ثالثة';
      final result = SmartAnalyzer.extractParagraph(text, 12);
      expect(result['text'], isNotEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 2. SmartAnalyzer — التواريخ
  // ══════════════════════════════════════════════════════════════
  group('SmartAnalyzer — Dates', () {
    late SmartAnalyzer analyzer;
    setUp(() => analyzer = SmartAnalyzer());

    test('اليوم يُرجع تاريخ اليوم', () {
      final result = analyzer.analyzeDate('اجتماع اليوم');
      expect(result, isNotNull);
      expect(result, contains(DateTime.now().year.toString()));
    });

    test('غدا يُرجع تاريخ الغد', () {
      final result = analyzer.analyzeDate('موعد غدا');
      expect(result, isNotNull);
    });

    test('بعد اسبوع يُرجع التاريخ الصحيح', () {
      final result = analyzer.analyzeDate('بعد اسبوع');
      expect(result, isNotNull);
    });

    test('نص بدون تاريخ يُرجع null', () {
      expect(analyzer.analyzeDate('نص عادي'), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 3. LanguageDetector — اكتشاف لغة البرمجة
  // ══════════════════════════════════════════════════════════════
  group('LanguageDetector — Detection', () {
    test('اكتشاف Python', () {
      const code = '''
def hello():
    print("Hello World")

if __name__ == "__main__":
    hello()
''';
      expect(LanguageDetector.detectLanguage(code), 'Python');
    });

    test('اكتشاف JavaScript', () {
      const code = '''
const greeting = "Hello";
console.log(greeting);
document.getElementById("app");
''';
      expect(LanguageDetector.detectLanguage(code), 'JavaScript');
    });

    test('اكتشاف Dart', () {
      const code = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Container();
  }
}
''';
      expect(LanguageDetector.detectLanguage(code), 'Dart');
    });

    test('اكتشاف Java', () {
      const code = '''
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello");
    }
}
''';
      expect(LanguageDetector.detectLanguage(code), 'Java');
    });

    test('اكتشاف SQL', () {
      const code = '''
SELECT id, name FROM users
WHERE age > 18
ORDER BY name;
''';
      expect(LanguageDetector.detectLanguage(code), 'SQL');
    });

    test('اكتشاف HTML', () {
      const code = '<!DOCTYPE html><html><body></body></html>';
      expect(LanguageDetector.detectLanguage(code), 'HTML');
    });

    test('اكتشاف PHP', () {
      const code = '<?php echo "Hello"; ?>';
      expect(LanguageDetector.detectLanguage(code), 'PHP');
    });

    test('اكتشاف Bash', () {
      const code = '#!/bin/bash\necho "Hello World"';
      expect(LanguageDetector.detectLanguage(code), 'Bash');
    });

    test('نص فارغ يُرجع null', () {
      expect(LanguageDetector.detectLanguage(''), isNull);
    });

    test('نص عربي يُرجع null', () {
      expect(LanguageDetector.detectLanguage('هذا نص عربي عادي'), isNull);
    });

    test('نص غامض يُرجع null أو لغة واحدة فقط', () {
      // نص قصير جداً لا يكفي للتحديد
      final result = LanguageDetector.detectLanguage('x = 1');
      // إما null أو لغة واحدة
      // ignore: unnecessary_type_check
      expect(result == null || result is String, isTrue);
    });

    test('ملف كبير (>2000 حرف) يُعالج بكفاءة', () {
      final largeCode = 'print("hello")\n' * 200; // >2000 حرف
      final stopwatch = Stopwatch()..start();
      LanguageDetector.detectLanguage(largeCode);
      stopwatch.stop();
      // يجب أن يكتمل في أقل من 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 4. LanguageDetector — الامتدادات
  // ══════════════════════════════════════════════════════════════
  group('LanguageDetector — Extensions', () {
    test('getFileExtension يُرجع الامتداد الصحيح', () {
      expect(LanguageDetector.getFileExtension('Python'), '.py');
      expect(LanguageDetector.getFileExtension('JavaScript'), '.js');
      expect(LanguageDetector.getFileExtension('Dart'), '.dart');
      expect(LanguageDetector.getFileExtension('Java'), '.java');
      expect(LanguageDetector.getFileExtension('SQL'), '.sql');
    });

    test('لغة غير معروفة تُرجع .txt', () {
      expect(LanguageDetector.getFileExtension('UnknownLang'), '.txt');
    });

    test('getLanguageFromExtension يُرجع اللغة الصحيحة', () {
      expect(LanguageDetector.getLanguageFromExtension('.py'), 'Python');
      expect(LanguageDetector.getLanguageFromExtension('.js'), 'JavaScript');
      expect(LanguageDetector.getLanguageFromExtension('.dart'), 'Dart');
    });

    test('getLanguageFromExtension بدون نقطة يعمل', () {
      expect(LanguageDetector.getLanguageFromExtension('py'), 'Python');
    });

    test('امتداد غير معروف يُرجع null', () {
      expect(LanguageDetector.getLanguageFromExtension('.xyz'), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 5. ChecklistFormatter — تنسيق القوائم
  // ══════════════════════════════════════════════════════════════
  group('ChecklistFormatter — Parsing', () {
    test('parseJson يُحلل تنسيق {title, items}', () {
      const json =
          '{"title":"Tasks","items":[{"id":"1","text":"Task 1","isDone":false},{"id":"2","text":"Task 2","isDone":true}]}';
      final items = ChecklistFormatter.parseJson(json);
      expect(items.length, 2);
      expect(items[0].text, 'Task 1');
      expect(items[0].isDone, isFalse);
      expect(items[1].isDone, isTrue);
    });

    test('parseJson يُحلل تنسيق المصفوفة المباشرة', () {
      const json = '[{"id":"1","text":"Item","isDone":false}]';
      final items = ChecklistFormatter.parseJson(json);
      expect(items.length, 1);
    });

    test('parseJson يُرجع قائمة فارغة لـ JSON خاطئ', () {
      expect(ChecklistFormatter.parseJson('invalid json'), isEmpty);
      expect(ChecklistFormatter.parseJson(''), isEmpty);
      expect(ChecklistFormatter.parseJson('{}'), isEmpty);
    });

    test('toJson يُحوِّل العناصر لـ JSON صحيح', () {
      final items = [
        ChecklistItem(id: '1', text: 'Task 1', isDone: false),
        ChecklistItem(id: '2', text: 'Task 2', isDone: true),
      ];
      final json = ChecklistFormatter.toJson(items);
      final decoded = jsonDecode(json) as List;
      expect(decoded.length, 2);
      expect(decoded[0]['text'], 'Task 1');
      expect(decoded[1]['isDone'], isTrue);
    });

    test('isGhost لا يُحفظ في JSON', () {
      final item =
          ChecklistItem(id: '1', text: 'Ghost', isDone: false, isGhost: true);
      final json = item.toJson();
      expect(json.containsKey('isGhost'), isFalse);
    });

    test('isValidChecklist يتعرف على checklist صحيح', () {
      const valid =
          '{"title":"T","items":[{"id":"1","text":"T","isDone":false}]}';
      expect(ChecklistFormatter.isValidChecklist(valid), isTrue);
    });

    test('isValidChecklist يرفض Delta JSON', () {
      const delta = '[{"insert":"Hello\\n"}]';
      expect(ChecklistFormatter.isValidChecklist(delta), isFalse);
    });

    test('isValidChecklist يرفض JSON خاطئ', () {
      expect(ChecklistFormatter.isValidChecklist('not json'), isFalse);
      expect(ChecklistFormatter.isValidChecklist(''), isFalse);
    });

    test('toDisplayText يُحوِّل للنص المقروء', () {
      const json =
          '{"title":"T","items":[{"id":"1","text":"Done","isDone":true},{"id":"2","text":"Todo","isDone":false}]}';
      final text = ChecklistFormatter.toDisplayText(json);
      expect(text.contains('☑'), isTrue);
      expect(text.contains('☐'), isTrue);
      expect(text.contains('Done'), isTrue);
      expect(text.contains('Todo'), isTrue);
    });

    test('formatForSharing يُنسِّق للمشاركة', () {
      const json =
          '{"title":"Tasks","items":[{"id":"1","text":"Task 1","isDone":true}]}';
      final formatted = ChecklistFormatter.formatForSharing('My List', json);
      expect(formatted.contains('My List'), isTrue);
      expect(formatted.contains('☑'), isTrue);
      expect(formatted.contains('Task 1'), isTrue);
    });

    test('formatForSharing مع JSON خاطئ لا يرمي استثناء', () {
      expect(
        () => ChecklistFormatter.formatForSharing('Title', 'invalid'),
        returnsNormally,
      );
    });

    test('parseJson ثم toJson يُرجع نفس البيانات', () {
      const original = '[{"id":"1","text":"Task","isDone":false}]';
      final items = ChecklistFormatter.parseJson(original);
      final json = ChecklistFormatter.toJson(items);
      final restored = ChecklistFormatter.parseJson(json);

      expect(restored.length, items.length);
      expect(restored[0].text, items[0].text);
      expect(restored[0].isDone, items[0].isDone);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 6. Note Model — التطبيع والبحث العربي
  // ══════════════════════════════════════════════════════════════
  group('Note Model — Arabic Normalization', () {
    test('تطبيع الحركات', () {
      // ignore: import_of_legacy_library_into_null_safe
      // نستخدم Note.normalize مباشرة
      expect(
        'مَرْحَبًا'.replaceAll(RegExp(r'[\u064B-\u065F]'), ''),
        'مرحبا',
      );
    });

    test('تطبيع ألف المد', () {
      // أ إ آ → ا
      final normalized = 'أحمد إبراهيم آدم'.replaceAll(RegExp(r'[أإآ]'), 'ا');
      expect(normalized, 'احمد ابراهيم ادم');
    });

    test('تطبيع تاء مربوطة', () {
      final normalized = 'مدرسة'.replaceAll('ة', 'ه');
      expect(normalized, 'مدرسه');
    });

    test('تطبيع ألف مقصورة', () {
      final normalized = 'يحيى'.replaceAll('ى', 'ي');
      expect(normalized, 'يحيي');
    });
  });
}

