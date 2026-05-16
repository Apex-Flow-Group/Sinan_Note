import 'package:refactoring_tool/models/evaluation_record.dart';

/// سجل تعديل
class ModificationLog {
  final String functionName;
  final String filePath;
  final DateTime timestamp;
  final String signatureBefore;
  final String signatureAfter;
  final int lineCountBefore;
  final int lineCountAfter;
  final String changeDescription;
  final List<AnswerType> justifyingAnswers;

  const ModificationLog({
    required this.functionName,
    required this.filePath,
    required this.timestamp,
    required this.signatureBefore,
    required this.signatureAfter,
    required this.lineCountBefore,
    required this.lineCountAfter,
    required this.changeDescription,
    this.justifyingAnswers = const [],
  });

  /// التحقق من أن وصف التغيير لا يتجاوز 500 حرف
  bool get isValid => changeDescription.length <= 500;

  Map<String, dynamic> toJson() {
    return {
      'functionName': functionName,
      'filePath': filePath,
      'timestamp': timestamp.toIso8601String(),
      'signatureBefore': signatureBefore,
      'signatureAfter': signatureAfter,
      'lineCountBefore': lineCountBefore,
      'lineCountAfter': lineCountAfter,
      'changeDescription': changeDescription,
      'justifyingAnswers': justifyingAnswers.map((a) => a.name).toList(),
    };
  }

  factory ModificationLog.fromJson(Map<String, dynamic> json) {
    return ModificationLog(
      functionName: json['functionName'] as String,
      filePath: json['filePath'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      signatureBefore: json['signatureBefore'] as String,
      signatureAfter: json['signatureAfter'] as String,
      lineCountBefore: json['lineCountBefore'] as int,
      lineCountAfter: json['lineCountAfter'] as int,
      changeDescription: json['changeDescription'] as String,
      justifyingAnswers: (json['justifyingAnswers'] as List<dynamic>?)
              ?.map((e) => AnswerType.values.byName(e as String))
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      'ModificationLog($functionName: $lineCountBefore → $lineCountAfter lines)';
}
