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

  /// Extract signed numbers from a single line of mixed text+number content.
  ///
  /// Handles all common patterns:
  ///   "بصل 10"   → +10
  ///   "محمد -5"  → -5   (sign before number)
  ///   "خالد 4-"  → -4   (sign after number)
  ///   "لحمة +9"  → +9
  ///   "ضريبة 15%" → ignored (percentage)
  ///
  /// Returns null if no number found on this line.
  double? extractSignedNumber(String line) {
    final normalized = normalizeNumbers(line).trim();

    // Skip percentage-only values
    // Pattern: optional sign, digits, optional decimal, then % (possibly with spaces)
    // We'll handle this during extraction below.

    // 1. Sign AFTER number: "4-" or "4.5-"
    final afterSign = RegExp(r'(\d+(?:\.\d+)?)\s*(-)\s*(?!\d)');
    final afterMatch = afterSign.firstMatch(normalized);
    if (afterMatch != null) {
      // Make sure it's not a percentage
      final rest = normalized.substring(afterMatch.end).trimLeft();
      if (!rest.startsWith('%')) {
        return -double.parse(afterMatch.group(1)!);
      }
    }

    // 2. Sign BEFORE number: "-5", "+9", or plain "10"
    // Exclude percentages: number followed by %
    final beforeSign = RegExp(r'([+\-]?\s*\d+(?:\.\d+)?)(?!\s*%)');
    for (final match in beforeSign.allMatches(normalized)) {
      final raw = match.group(1)!.replaceAll(' ', '');
      // Skip if this is part of a larger expression like "3*4" or "3/4"
      final start = match.start;
      final end = match.end;
      final before = start > 0 ? normalized[start - 1] : ' ';
      final after = end < normalized.length ? normalized[end] : ' ';
      if ('*/'.contains(before) || '*/'.contains(after)) continue;
      // Skip if preceded by a digit (part of a larger number)
      if (before.contains(RegExp(r'\d'))) continue;
      return double.tryParse(raw);
    }

    return null;
  }

  /// Extract and sum all numbers from text (Aggregation Mode).
  /// Each line is treated independently — sign attached to number is respected.
  double? sumAllNumbers(String text) {
    try {
      final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

      if (lines.length == 1) {
        // Single line: extract all signed numbers and sum them
        final normalized = normalizeNumbers(lines[0]);
        final numbers =
            RegExp(r'[+\-]?\s*\d+(?:\.\d+)?(?!\s*%)').allMatches(normalized);
        if (numbers.isEmpty) return null;
        double sum = 0;
        for (final match in numbers) {
          final raw = match.group(0)!.replaceAll(' ', '');
          sum += double.parse(raw);
        }
        return sum;
      }

      // Multiple lines: one signed number per line
      double sum = 0;
      bool anyFound = false;
      for (final line in lines) {
        final val = extractSignedNumber(line);
        if (val != null) {
          sum += val;
          anyFound = true;
        }
      }
      return anyFound ? sum : null;
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

    // هل تحتوي على عمليات حسابية حقيقية (رقم ثم عملية ثم رقم)؟
    // نتجنب الخلط مع الأرقام الموقّعة مثل "-5" أو "4-"
    // lookbehind: العامل يجب أن يكون مسبوقاً برقم وليس بمسافة أو نص
    final hasOperators =
        RegExp(r'\d+(?:\.\d+)?\s*[+\-*/]\s*\d+').hasMatch(normalized) &&
            RegExp(r'(?<=\d)\s*[+\-*/]\s*\d').hasMatch(normalized);

    if (hasOperators) {
      // حاول تقييم كل سطر وجمع النتائج
      final lines =
          paragraphText.split('\n').where((l) => l.trim().isNotEmpty).toList();

      if (lines.length == 1) {
        // سطر واحد — أرجع التعبير والنتيجة
        final result = evaluateExpression(lines[0]);
        if (result != null) {
          // استخرج التعبير الرياضي فقط للعرض
          final exprMatch = RegExp(r'[\d\.]+(?:\s*[+\-*/]\s*[\d\.]+)+')
              .firstMatch(normalizeNumbers(lines[0])
                  .replaceAll('×', '*')
                  .replaceAll('÷', '/'));
          final displayExpr = exprMatch?.group(0)?.trim() ?? lines[0].trim();
          return {
            'type': 'calculated',
            'result': result,
            'expression': displayExpr,
          };
        }
      } else {
        // أسطر متعددة — جمع نتائج كل سطر مع مراعاة الإشارات
        double total = 0;
        bool anyResult = false;
        final expressionParts = <String>[];
        for (final line in lines) {
          final result = evaluateExpression(line);
          if (result != null) {
            final val = double.tryParse(result) ?? 0;
            total += val;
            anyResult = true;
            expressionParts.add(result);
          } else {
            // سطر فيه رقم مع إشارة (أو بدون) — استخرج الرقم الموقّع
            final val = extractSignedNumber(normalizeNumbers(line));
            if (val != null) {
              total += val;
              anyResult = true;
              final formatted = val == val.toInt()
                  ? val.toInt().toString()
                  : val.toStringAsFixed(2);
              expressionParts.add(formatted);
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
            'expression': expressionParts.join(' + '),
          };
        }
      }
    }

    // أرقام فقط بدون عمليات — جمع مع مراعاة الإشارات
    final sum = sumAllNumbers(paragraphText);
    if (sum != null) {
      final formatted =
          sum == sum.toInt() ? sum.toInt().toString() : sum.toStringAsFixed(2);
      // بناء تعبير العرض مع الإشارات
      final lines2 =
          paragraphText.split('\n').where((l) => l.trim().isNotEmpty).toList();
      String displayExpr;
      if (lines2.length > 1) {
        final parts = <String>[];
        for (final line in lines2) {
          final val = extractSignedNumber(normalizeNumbers(line));
          if (val != null) {
            final f = val == val.toInt()
                ? val.toInt().toString()
                : val.toStringAsFixed(2);
            parts.add(f);
          }
        }
        displayExpr =
            parts.length <= 8 ? parts.join(' + ') : '${parts.length} رقم';
      } else {
        final nums = RegExp(r'[+\-]?\s*\d+(?:\.\d+)?(?!\s*%)')
            .allMatches(normalizeNumbers(paragraphText));
        final numList =
            nums.map((m) => m.group(0)!.replaceAll(' ', '')).toList();
        displayExpr =
            numList.length <= 8 ? numList.join(' + ') : '${numList.length} رقم';
      }
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
      final normalized =
          normalizeNumbers(line).replaceAll('×', '*').replaceAll('÷', '/');

      final exprMatch = RegExp(r'\d+(?:\.\d+)?(?:\s*[+\-*/]\s*\d+(?:\.\d+)?)+')
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
      final tokens =
          RegExp(r'([+\-]?\d+(?:\.\d+)?)([*/]?)').allMatches(expr).toList();
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
