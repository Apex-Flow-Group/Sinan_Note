import 'package:refactoring_tool/models/call_source.dart';
import 'package:refactoring_tool/models/function_unit.dart';

/// عنصر اختبار لمعامل واحد
class ParameterTestItem {
  final String parameterName;
  final String parameterType;
  final bool isRequired;
  final String sampleValidValue;
  final String sampleInvalidValue;
  final String expectedBehavior;

  const ParameterTestItem({
    required this.parameterName,
    required this.parameterType,
    required this.isRequired,
    required this.sampleValidValue,
    required this.sampleInvalidValue,
    required this.expectedBehavior,
  });

  Map<String, dynamic> toJson() {
    return {
      'parameterName': parameterName,
      'parameterType': parameterType,
      'isRequired': isRequired,
      'sampleValidValue': sampleValidValue,
      'sampleInvalidValue': sampleInvalidValue,
      'expectedBehavior': expectedBehavior,
    };
  }
}

/// عنصر تحقق من مصدر استدعاء
class CallSourceVerificationItem {
  final String callingFunction;
  final String filePath;
  final int lineNumber;
  final String callType;
  final String verificationStep;

  const CallSourceVerificationItem({
    required this.callingFunction,
    required this.filePath,
    required this.lineNumber,
    required this.callType,
    required this.verificationStep,
  });

  Map<String, dynamic> toJson() {
    return {
      'callingFunction': callingFunction,
      'filePath': filePath,
      'lineNumber': lineNumber,
      'callType': callType,
      'verificationStep': verificationStep,
    };
  }
}

/// قائمة الاختبار اليدوية الكاملة
class TestChecklist {
  final String functionName;
  final String filePath;
  final String returnType;
  final String signature;
  final List<ParameterTestItem> parameterTests;
  final List<CallSourceVerificationItem> callSourceVerifications;
  final String expectedOutput;

  const TestChecklist({
    required this.functionName,
    required this.filePath,
    required this.returnType,
    required this.signature,
    required this.parameterTests,
    required this.callSourceVerifications,
    required this.expectedOutput,
  });

  Map<String, dynamic> toJson() {
    return {
      'functionName': functionName,
      'filePath': filePath,
      'returnType': returnType,
      'signature': signature,
      'parameterTests': parameterTests.map((p) => p.toJson()).toList(),
      'callSourceVerifications':
          callSourceVerifications.map((c) => c.toJson()).toList(),
      'expectedOutput': expectedOutput,
    };
  }

  /// تنسيق القائمة كنص مقروء
  String toFormattedString() {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('  📋 قائمة الاختبار اليدوية');
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('  الدالة: $functionName');
    buffer.writeln('  الملف: $filePath');
    buffer.writeln('  التوقيع: $signature');
    buffer.writeln('  نوع الإرجاع: $returnType');
    buffer.writeln();

    if (parameterTests.isNotEmpty) {
      buffer.writeln('━━━ اختبارات المعاملات ━━━');
      for (var i = 0; i < parameterTests.length; i++) {
        final test = parameterTests[i];
        buffer.writeln('  ${i + 1}. المعامل: ${test.parameterName} '
            '(${test.parameterType})'
            '${test.isRequired ? " [مطلوب]" : " [اختياري]"}');
        buffer.writeln('     ✅ قيمة صالحة: ${test.sampleValidValue}');
        buffer.writeln('     ❌ قيمة غير صالحة: ${test.sampleInvalidValue}');
        buffer.writeln('     📌 السلوك المتوقع: ${test.expectedBehavior}');
        buffer.writeln();
      }
    } else {
      buffer.writeln('━━━ اختبارات المعاملات ━━━');
      buffer.writeln('  لا توجد معاملات لهذه الدالة');
      buffer.writeln();
    }

    buffer.writeln('━━━ المخرجات المتوقعة ━━━');
    buffer.writeln('  $expectedOutput');
    buffer.writeln();

    if (callSourceVerifications.isNotEmpty) {
      buffer.writeln(
          '━━━ مصادر الاستدعاء للتحقق (${callSourceVerifications.length}) ━━━');
      for (var i = 0; i < callSourceVerifications.length; i++) {
        final verification = callSourceVerifications[i];
        buffer.writeln('  ${i + 1}. ${verification.callingFunction} '
            '[${verification.callType}]');
        buffer.writeln(
            '     📁 ${verification.filePath}:${verification.lineNumber}');
        buffer.writeln('     🔍 ${verification.verificationStep}');
        buffer.writeln();
      }
    } else {
      buffer.writeln('━━━ مصادر الاستدعاء للتحقق ━━━');
      buffer.writeln('  لا توجد مصادر استدعاء معروفة');
      buffer.writeln();
    }

    buffer.writeln('═══════════════════════════════════════════════════════');

    return buffer.toString();
  }
}

/// مولد قائمة الاختبار اليدوية
///
/// يُستخدم عندما لا توجد اختبارات آلية لدالة معدلة.
/// ينتج قائمة منظمة تحتوي على حالات اختبار لكل معامل
/// وعناصر تحقق لكل مصدر استدعاء.
class ChecklistGenerator {
  /// توليد قائمة اختبار يدوية لدالة ومصادر استدعائها
  TestChecklist generate({
    required FunctionUnit functionUnit,
    required List<CallSource> callSources,
  }) {
    final parameterTests = _generateParameterTests(functionUnit.params);
    final callSourceVerifications =
        _generateCallSourceVerifications(callSources);
    final expectedOutput = _generateExpectedOutput(functionUnit);

    return TestChecklist(
      functionName: functionUnit.name,
      filePath: functionUnit.filePath,
      returnType: functionUnit.returnType,
      signature: functionUnit.signature,
      parameterTests: parameterTests,
      callSourceVerifications: callSourceVerifications,
      expectedOutput: expectedOutput,
    );
  }

  /// توليد عناصر اختبار لكل معامل
  List<ParameterTestItem> _generateParameterTests(List<Parameter> params) {
    return params.map((param) {
      final validValue = _getSampleValidValue(param.type, param.defaultValue);
      final invalidValue = _getSampleInvalidValue(param.type);
      final expectedBehavior = _getExpectedBehavior(param);

      return ParameterTestItem(
        parameterName: param.name,
        parameterType: param.type,
        isRequired: param.isRequired,
        sampleValidValue: validValue,
        sampleInvalidValue: invalidValue,
        expectedBehavior: expectedBehavior,
      );
    }).toList();
  }

  /// توليد عناصر تحقق لكل مصدر استدعاء
  List<CallSourceVerificationItem> _generateCallSourceVerifications(
    List<CallSource> callSources,
  ) {
    return callSources.map((source) {
      final verificationStep = _getVerificationStep(source);

      return CallSourceVerificationItem(
        callingFunction: source.callingFunction,
        filePath: source.filePath,
        lineNumber: source.lineNumber,
        callType: source.callType.name,
        verificationStep: verificationStep,
      );
    }).toList();
  }

  /// توليد وصف المخرجات المتوقعة بناءً على نوع الإرجاع
  String _generateExpectedOutput(FunctionUnit functionUnit) {
    final returnType = functionUnit.returnType;

    if (returnType == 'void') {
      return 'الدالة لا تُرجع قيمة - تحقق من الآثار الجانبية '
          '(تغيير حالة، إرسال إشعارات، كتابة بيانات)';
    }

    if (returnType.startsWith('Future<void>')) {
      return 'الدالة غير متزامنة ولا تُرجع قيمة - تحقق من اكتمال العملية '
          'والآثار الجانبية بعد await';
    }

    if (returnType.startsWith('Future<')) {
      final innerType = returnType.substring(7, returnType.length - 1);
      return 'الدالة تُرجع Future<$innerType> - تحقق من القيمة المُرجعة '
          'بعد await وتحقق من عدم رمي استثناءات غير متوقعة';
    }

    if (returnType.startsWith('Stream<')) {
      return 'الدالة تُرجع Stream - تحقق من أن البيانات المُرسلة صحيحة '
          'وأن Stream يُغلق بشكل صحيح';
    }

    if (returnType == 'bool') {
      return 'تحقق من إرجاع true للحالات الصحيحة و false للحالات الخاطئة';
    }

    if (returnType == 'String' || returnType == 'String?') {
      return 'تحقق من إرجاع نص صحيح غير فارغ للمدخلات الصالحة';
    }

    if (returnType.startsWith('List<')) {
      return 'تحقق من إرجاع قائمة بالعناصر المتوقعة وبالترتيب الصحيح';
    }

    if (returnType.startsWith('Map<')) {
      return 'تحقق من إرجاع خريطة تحتوي المفاتيح والقيم المتوقعة';
    }

    if (returnType == 'int' || returnType == 'double' || returnType == 'num') {
      return 'تحقق من إرجاع قيمة رقمية صحيحة ضمن النطاق المتوقع';
    }

    return 'تحقق من إرجاع قيمة من نوع $returnType صحيحة ومتوافقة مع المدخلات';
  }

  /// الحصول على قيمة صالحة نموذجية بناءً على النوع
  String _getSampleValidValue(String type, String? defaultValue) {
    if (defaultValue != null) {
      return defaultValue;
    }

    final baseType = type.replaceAll('?', '').trim();

    switch (baseType) {
      case 'String':
        return '"نص تجريبي صالح"';
      case 'int':
        return '1';
      case 'double':
        return '1.0';
      case 'num':
        return '42';
      case 'bool':
        return 'true';
      case 'DateTime':
        return 'DateTime.now()';
      case 'Duration':
        return 'Duration(seconds: 1)';
      default:
        if (baseType.startsWith('List')) {
          return '[$baseType عنصر واحد على الأقل]';
        }
        if (baseType.startsWith('Map')) {
          return '{مفتاح: قيمة}';
        }
        if (baseType.startsWith('Future')) {
          return 'Future.value(قيمة صالحة)';
        }
        return '$baseType() // كائن صالح من النوع';
    }
  }

  /// الحصول على قيمة غير صالحة نموذجية بناءً على النوع
  String _getSampleInvalidValue(String type) {
    final isNullable = type.endsWith('?');
    final baseType = type.replaceAll('?', '').trim();

    if (isNullable) {
      return 'null';
    }

    switch (baseType) {
      case 'String':
        return '"" (نص فارغ)';
      case 'int':
        return '-1 (قيمة سالبة)';
      case 'double':
        return 'double.nan';
      case 'num':
        return '-999 (قيمة خارج النطاق)';
      case 'bool':
        return 'لا يوجد قيمة غير صالحة لـ bool';
      case 'DateTime':
        return 'DateTime(0) (تاريخ غير منطقي)';
      case 'Duration':
        return 'Duration(seconds: -1) (مدة سالبة)';
      default:
        if (baseType.startsWith('List')) {
          return '[] (قائمة فارغة)';
        }
        if (baseType.startsWith('Map')) {
          return '{} (خريطة فارغة)';
        }
        return 'null (إذا أمكن) أو كائن بحالة غير صالحة';
    }
  }

  /// الحصول على السلوك المتوقع لمعامل
  String _getExpectedBehavior(Parameter param) {
    if (param.isRequired) {
      return 'يجب أن تعمل الدالة بشكل صحيح مع قيمة صالحة '
          'وترمي استثناء أو تتعامل بأمان مع قيمة غير صالحة';
    }

    if (param.defaultValue != null) {
      return 'عند عدم التمرير تستخدم القيمة الافتراضية: ${param.defaultValue}';
    }

    return 'المعامل اختياري - تحقق من السلوك عند تمريره وعند عدم تمريره';
  }

  /// الحصول على خطوة التحقق لمصدر استدعاء
  String _getVerificationStep(CallSource source) {
    switch (source.callType) {
      case CallType.direct:
        return 'تحقق من أن ${source.callingFunction} لا تزال تعمل بشكل صحيح '
            'بعد التعديل';
      case CallType.providerRead:
        return 'تحقق من أن قراءة Provider في ${source.callingFunction} '
            'تحصل على القيمة الصحيحة';
      case CallType.providerWatch:
        return 'تحقق من أن مراقبة Provider في ${source.callingFunction} '
            'تُعيد البناء عند التغيير';
      case CallType.callback:
        return 'تحقق من أن callback في ${source.callingFunction} '
            'يُستدعى بالمعاملات الصحيحة';
      case CallType.streamListen:
        return 'تحقق من أن الاشتراك في Stream بـ ${source.callingFunction} '
            'يستقبل البيانات الصحيحة';
      case CallType.methodChannel:
        return 'تحقق من أن MethodChannel في ${source.callingFunction} '
            'يرسل/يستقبل الرسائل بشكل صحيح';
    }
  }
}
