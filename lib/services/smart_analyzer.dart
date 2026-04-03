// Copyright © 2025 Apex Flow Group. All rights reserved.

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

  /// استخرج الفقرة التي يقع فيها الكرسر (محدودة بالأسطر الفارغة)
  /// يُرجع {text, start, end} بالنسبة للنص الكامل
  static Map<String, dynamic> extractParagraph(String fullText, int cursorPos) {
    final pos = cursorPos.clamp(0, fullText.length);

    // ابحث عن بداية الفقرة (سطر فارغ قبل الكرسر أو بداية النص)
    int start = 0;
    int searchFrom = pos > 0 ? pos - 1 : 0;
    final beforeCursor = fullText.substring(0, searchFrom + 1);
    final emptyLineBefore = beforeCursor.lastIndexOf('\n\n');
    if (emptyLineBefore != -1) {
      start = emptyLineBefore + 2;
    }

    // ابحث عن نهاية الفقرة (سطر فارغ بعد الكرسر أو نهاية النص)
    int end = fullText.length;
    final emptyLineAfter = fullText.indexOf('\n\n', pos);
    if (emptyLineAfter != -1) {
      end = emptyLineAfter;
    }

    return {
      'text': fullText.substring(start, end).trim(),
      'start': start,
      'end': end,
    };
  }

  /// Extract and sum all numbers from text (Aggregation Mode)
  double? sumAllNumbers(String text) {
    try {
      final normalized = normalizeNumbers(text);
      final numbers = RegExp(r'(?<![%\w])(\d+(?:\.\d+)?)(?!\s*%)').allMatches(normalized);
      if (numbers.isEmpty) return null;
      double sum = 0;
      for (final match in numbers) {
        sum += double.parse(match.group(1)!);
      }
      return sum;
    } catch (e) {
      return null;
    }
  }

  /// تحليل فقرة كاملة:
  /// - إذا تحتوي عمليات → evaluateExpression على كل سطر وتجمع النتائج أو تُرجع أول نتيجة
  /// - إذا أرقام فقط → sumAllNumbers
  /// يُرجع {type: 'calculated'|'sum', result, expression}
  Map<String, dynamic>? analyzeParagraph(String paragraphText) {
    if (paragraphText.trim().isEmpty) return null;

    final normalized = normalizeNumbers(paragraphText)
        .replaceAll('×', '*')
        .replaceAll('÷', '/');

    // هل تحتوي على عمليات حسابية؟
    final hasOperators = RegExp(r'\d+(?:\.\d+)?\s*[+\-*/]\s*\d+').hasMatch(normalized);

    if (hasOperators) {
      // حاول تقييم كل سطر وجمع النتائج
      final lines = paragraphText.split('\n').where((l) => l.trim().isNotEmpty).toList();

      if (lines.length == 1) {
        // سطر واحد — أرجع التعبير والنتيجة
        final result = evaluateExpression(lines[0]);
        if (result != null) {
          // استخرج التعبير الرياضي فقط للعرض
          final exprMatch = RegExp(r'[\d\.]+(?:\s*[+\-*/]\s*[\d\.]+)+')
              .firstMatch(normalizeNumbers(lines[0]).replaceAll('×', '*').replaceAll('÷', '/'));
          final displayExpr = exprMatch?.group(0)?.trim() ?? lines[0].trim();
          return {
            'type': 'calculated',
            'result': result,
            'expression': displayExpr,
          };
        }
      } else {
        // أسطر متعددة — جمع نتائج كل سطر
        double total = 0;
        bool anyResult = false;
        for (final line in lines) {
          final result = evaluateExpression(line);
          if (result != null) {
            total += double.tryParse(result) ?? 0;
            anyResult = true;
          } else {
            // سطر فيه أرقام بدون عمليات — أضفها للمجموع
            final nums = RegExp(r'(?<![%\w])(\d+(?:\.\d+)?)(?!\s*%)')
                .allMatches(normalizeNumbers(line));
            for (final m in nums) {
              total += double.parse(m.group(1)!);
              anyResult = true;
            }
          }
        }
        if (anyResult) {
          final formatted = total == total.toInt()
              ? total.toInt().toString()
              : total.toStringAsFixed(2);
          return {
            'type': 'sum',
            'result': formatted,
            'expression': '${lines.length} ${lines.length == 1 ? "سطر" : "أسطر"}',
          };
        }
      }
    }

    // أرقام فقط بدون عمليات — جمع
    final sum = sumAllNumbers(paragraphText);
    if (sum != null) {
      final formatted = sum == sum.toInt()
          ? sum.toInt().toString()
          : sum.toStringAsFixed(2);
      final nums = RegExp(r'(?<![%\w])(\d+(?:\.\d+)?)(?!\s*%)').allMatches(normalizeNumbers(paragraphText));
      final numList = nums.map((m) => m.group(1)!).toList();
      final displayExpr = numList.length <= 5 ? numList.join(' + ') : '${numList.length} رقم';
      return {
        'type': 'sum',
        'result': formatted,
        'expression': displayExpr,
      };
    }

    return null;
  }

  /// Evaluate math expression from a single line
  String? evaluateExpression(String line) {
    try {
      final normalized = normalizeNumbers(line)
          .replaceAll('×', '*')
          .replaceAll('÷', '/');

      final exprMatch =
          RegExp(r'\d+(?:\.\d+)?(?:\s*[+\-*/]\s*\d+(?:\.\d+)?)+')
              .firstMatch(normalized);
      if (exprMatch == null) return null;

      final expr = exprMatch.group(0)!.replaceAll(' ', '');
      final result = _evalExpr(expr);
      if (result == null) return null;

      return result == result.toInt()
          ? result.toInt().toString()
          : result.toStringAsFixed(2);
    } catch (e) {
      return null;
    }
  }

  double? _evalExpr(String expr) {
    try {
      final List<String> parts = [];
      int prev = 0;
      for (int i = 1; i < expr.length; i++) {
        if (expr[i] == '+' || expr[i] == '-') {
          parts.add(expr.substring(prev, i));
          prev = i;
        }
      }
      parts.add(expr.substring(prev));

      double total = 0;
      for (final part in parts) {
        if (part.isEmpty) continue;
        final val = _evalMulDiv(part);
        if (val == null) return null;
        total += val;
      }
      return total;
    } catch (_) {
      return null;
    }
  }

  double? _evalMulDiv(String expr) {
    try {
      final tokens = RegExp(r'([+\-]?\d+(?:\.\d+)?)([*/]?)').allMatches(expr).toList();
      if (tokens.isEmpty) return null;
      double result = double.parse(tokens[0].group(1)!);
      for (int i = 0; i < tokens.length - 1; i++) {
        final op = tokens[i].group(2)!;
        final next = double.parse(tokens[i + 1].group(1)!);
        if (op == '*') result *= next;
        if (op == '/') {
          if (next == 0) return null;
          result /= next;
        }
      }
      return result;
    } catch (_) {
      return null;
    }
  }

  String? analyzeDate(String text) {
    DateTime now = DateTime.now();
    if (text.contains("غدا") || text.contains("بكره")) {
      return " (${DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)))})";
    } else if (text.contains("بعد اسبوع")) {
      return " (${DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 7)))})";
    } else if (text.contains("اليوم")) {
      return " (${DateFormat('yyyy-MM-dd').format(now)})";
    }
    return null;
  }

  @Deprecated('Use evaluateExpression instead')
  String calculateLine(String textLine) => evaluateExpression(textLine) ?? '';

  @Deprecated('Use evaluateExpression instead')
  String? analyzeMath(String text) {
    final result = evaluateExpression(text);
    return result != null ? ' = $result' : null;
  }
}
