// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:math_expressions/math_expressions.dart';
import 'package:intl/intl.dart';

class SmartAnalyzer {
  /// Normalize Eastern Arabic numerals (٠-٩) to Western (0-9)
  static String normalizeNumbers(String text) {
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    const western = '0123456789';

    String result = text;
    for (int i = 0; i < eastern.length; i++) {
      result = result.replaceAll(eastern[i], western[i]);
    }
    return result;
  }

  /// Extract and sum all numbers from text (Aggregation Mode)
  double? sumAllNumbers(String text) {
    try {
      final normalized = normalizeNumbers(text);
      final numbers = RegExp(r'\d+(\.\d+)?').allMatches(normalized);

      if (numbers.isEmpty) return null;

      double sum = 0;
      for (final match in numbers) {
        sum += double.parse(match.group(0)!);
      }
      return sum;
    } catch (e) {
      return null;
    }
  }

  /// Evaluate math expression from current line (Inline Math Mode)
  String? evaluateExpression(String line) {
    try {
      final normalized = normalizeNumbers(line);

      // Extract math expression: numbers and operators only
      final mathPattern = RegExp(r'[\d\.\+\-\*\/\(\)\s]+');
      final match = mathPattern.firstMatch(normalized);

      if (match == null) return null;

      final expression = match.group(0)!.trim();

      // Must contain at least one operator
      if (!RegExp(r'[\+\-\*\/]').hasMatch(expression)) return null;

      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);

      // Format result
      if (result == result.toInt()) {
        return result.toInt().toString();
      }
      return result.toStringAsFixed(2);
    } catch (e) {
      return null;
    }
  }

  String? analyzeDate(String text) {
    DateTime now = DateTime.now();

    if (text.contains("غدا") || text.contains("بكره")) {
      DateTime tomorrow = now.add(const Duration(days: 1));
      return " (${DateFormat('yyyy-MM-dd').format(tomorrow)})";
    } else if (text.contains("بعد اسبوع")) {
      DateTime nextWeek = now.add(const Duration(days: 7));
      return " (${DateFormat('yyyy-MM-dd').format(nextWeek)})";
    } else if (text.contains("اليوم")) {
      return " (${DateFormat('yyyy-MM-dd').format(now)})";
    }
    return null;
  }

  @Deprecated('Use evaluateExpression instead')
  String calculateLine(String textLine) {
    return evaluateExpression(textLine) ?? '';
  }

  @Deprecated('Use evaluateExpression instead')
  String? analyzeMath(String text) {
    final result = evaluateExpression(text);
    return result != null ? ' = $result' : null;
  }
}
