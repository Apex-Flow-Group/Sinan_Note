// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import '../../../services/smart_analyzer.dart';
import '../../../services/language_detector.dart';
import '../../../services/code_executor.dart';
import '../../../widgets/common/apex_snackbar.dart';

/// Handles smart features (calculations, code execution, date analysis)
class EditorSmartController {
  final SmartAnalyzer _analyzer = SmartAnalyzer();

  /// Get time remaining for reminder
  String getTimeRemaining(DateTime? reminderDateTime) {
    if (reminderDateTime == null) return '';

    final now = DateTime.now();
    final difference = reminderDateTime.difference(now);

    if (difference.isNegative) {
      return 'مضى الوقت';
    }

    if (difference.inDays > 0) {
      return 'بعد ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'بعد ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'بعد ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  /// Handle smart calculation (sum or inline math)
  Map<String, dynamic>? handleSmartCalculation(
    TextEditingController controller,
  ) {
    final selection = controller.selection;
    final text = controller.text;

    // Case A: Text is Selected (Aggregation Mode)
    if (selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      final sum = _analyzer.sumAllNumbers(selectedText);

      if (sum != null) {
        final formatted = sum == sum.toInt()
            ? sum.toInt().toString()
            : sum.toStringAsFixed(2);
        return {'type': 'sum', 'result': formatted};
      } else {
        return {'type': 'error', 'message': 'noNumbersFound'};
      }
    }

    // Case B: No Selection (Inline Math Mode)
    final cursorPos = selection.baseOffset;
    if (cursorPos < 0) return null;

    int lineStart = text.lastIndexOf('\n', cursorPos - 1);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;

    int lineEnd = text.indexOf('\n', cursorPos);
    lineEnd = lineEnd == -1 ? text.length : lineEnd;

    final currentLine = text.substring(lineStart, lineEnd);
    final result = _analyzer.evaluateExpression(currentLine);

    if (result != null) {
      final resultText = ' = $result';
      final newText = text.replaceRange(lineEnd, lineEnd, resultText);

      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: lineEnd + resultText.length),
      );

      return {'type': 'calculated', 'result': result};
    } else {
      return {'type': 'error', 'message': 'noValidExpression'};
    }
  }

  /// Analyze math and dates in current line
  Map<String, dynamic>? analyzeMathAndDates(
    TextEditingController controller,
  ) {
    final text = controller.text;
    if (text.isEmpty) return null;

    final selection = controller.selection;
    if (!selection.isValid) return null;

    final lines = text.split('\n');
    int currentLineIndex = 0;
    int charCount = 0;

    for (int i = 0; i < lines.length; i++) {
      charCount += lines[i].length + 1;
      if (charCount > selection.baseOffset) {
        currentLineIndex = i;
        break;
      }
    }

    if (currentLineIndex >= lines.length) return null;
    final currentLine = lines[currentLineIndex];

    // Check for math expression
    if (currentLine.contains(RegExp(r'[\d\+\-\*\/]')) &&
        currentLine.endsWith('=')) {
      final result =
          _analyzer.evaluateExpression(currentLine.replaceAll('=', '').trim());
      if (result != null && !currentLine.contains(result)) {
        return {'type': 'math', 'result': result, 'line': currentLine};
      }
    }

    // Check for date keywords
    final dateResult = _analyzer.analyzeDate(currentLine);
    if (dateResult != null && !currentLine.contains(dateResult)) {
      return {'type': 'date', 'result': dateResult, 'line': currentLine};
    }

    return null;
  }

  /// Execute code
  Future<String> executeCode(String code, String? language) async {
    if (language == null) {
      return 'Unable to detect language';
    }
    return await CodeExecutor.executeCode(code, language);
  }

  /// Detect programming language
  String? detectLanguage(String code) {
    return LanguageDetector.detectLanguage(code);
  }

  /// Get file extension for language
  String getExtensionForLanguage(String language) {
    return LanguageDetector.getExtensionForLanguage(language);
  }

  /// Map language to note type
  String mapLanguageToNoteType(String? language) {
    if (language == null) return 'code';

    final langToType = {
      'Markdown': 'markdown',
      'Python': 'python',
      'JavaScript': 'javascript',
      'Java': 'java',
      'Dart': 'dart',
      'HTML': 'html',
      'CSS': 'css',
      'SQL': 'sql',
      'C++': 'cpp',
      'C': 'c',
      'C#': 'csharp',
      'Swift': 'swift',
      'Kotlin': 'kotlin',
      'Go': 'go',
      'Rust': 'rust',
      'PHP': 'php',
      'Ruby': 'ruby',
      'Bash': 'bash',
      'JSON': 'json',
      'XML': 'xml',
    };

    return langToType[language] ?? 'code';
  }

  /// Show smart calculation result with snackbar
  void showSmartCalculationResult(
    BuildContext context,
    TextEditingController controller,
    AppLocalizations l10n,
  ) {
    final result = handleSmartCalculation(controller);
    if (result == null) return;

    if (result['type'] == 'sum') {
      ApexSnackBar.show(
        context,
        '${l10n.approximateSum} ${result['result']} (${l10n.experimental})',
        type: SnackBarType.success,
        duration: const Duration(seconds: 2),
        dismissible: true,
        opacity: 0.85,
        aboveToolbar: true,
      );
    } else if (result['type'] == 'calculated') {
      ApexSnackBar.show(
        context,
        '${l10n.calculated} (${l10n.experimental})',
        type: SnackBarType.success,
        duration: const Duration(seconds: 2),
        dismissible: true,
        opacity: 0.85,
        aboveToolbar: true,
      );
    } else if (result['type'] == 'error') {
      ApexSnackBar.show(
        context,
        result['message'] as String,
        type: SnackBarType.warning,
        duration: const Duration(seconds: 2),
        dismissible: true,
        opacity: 0.85,
        aboveToolbar: true,
      );
    }
  }

  /// Show code execution dialog
  Future<void> showCodeExecutionDialog(
    BuildContext context,
    String code,
    String? detectedLanguage,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    
    if (detectedLanguage == null) {
      ApexSnackBar.show(context, l10n.unableToDetectLanguage,
          type: SnackBarType.warning);
      return;
    }

    ApexSnackBar.show(context, '${l10n.executingCode} ($detectedLanguage)',
        type: SnackBarType.info, duration: const Duration(seconds: 1));

    final output = await executeCode(code, detectedLanguage);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.output),
        content: SingleChildScrollView(
          child: Text(output,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  /// Handle code export
  Future<String?> handleCodeExport(String code, String? detectedLanguage) async {
    final lang = detectedLanguage ?? detectLanguage(code);
    if (lang == null) return null;
    return getExtensionForLanguage(lang);
  }
}
