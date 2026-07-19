// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/services/code/code_executor.dart';
import 'package:sinan_note/services/code/language_detector.dart';
import 'package:sinan_note/services/code/smart_analyzer.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';

class EditorSmartController {
  final SmartAnalyzer _analyzer = SmartAnalyzer();

  String getTimeRemaining(DateTime? reminderDateTime) {
    if (reminderDateTime == null) return '';
    final now = DateTime.now();
    final difference = reminderDateTime.difference(now);
    if (difference.isNegative) return 'مضى الوقت';
    if (difference.inDays > 0) return 'بعد ${difference.inDays} يوم';
    if (difference.inHours > 0) return 'بعد ${difference.inHours} ساعة';
    if (difference.inMinutes > 0) return 'بعد ${difference.inMinutes} دقيقة';
    return 'الآن';
  }

  /// يحسب ويُرجع النتيجة فقط — بدون كتابة في المحرر
  /// يُرجع: {type, result, expression?, insertOffset?}
  Map<String, dynamic>? _computeFromText(TextEditingController controller) {
    final selection = controller.selection;
    final text = controller.text;

    // وضع التحديد
    if (selection.start != selection.end) {
      final selectedText = text.substring(selection.start, selection.end);
      final result = _analyzer.analyzeParagraph(selectedText);
      if (result != null) {
        return {
          ...result,
          'insertOffset': selection.end,
          'controller': controller
        };
      }
      return {'type': 'error', 'message': 'noNumbersFound'};
    }

    // وضع الفقرة
    final cursorPos = selection.baseOffset.clamp(0, text.length);
    final para = SmartAnalyzer.extractParagraph(text, cursorPos);
    final paraText = para['text'] as String;
    final result = _analyzer.analyzeParagraph(paraText);
    if (result != null) {
      // نهاية السطر الحالي (حيث الكرسر) لإدراج النتيجة بعده مباشرة
      int lineEnd = text.indexOf('\n', cursorPos);
      lineEnd = lineEnd == -1 ? text.length : lineEnd;
      return {...result, 'insertOffset': lineEnd, 'controller': controller};
    }
    return {'type': 'error', 'message': 'noValidExpression'};
  }

  Map<String, dynamic>? _computeFromQuill(QuillController quill) {
    final plainText = quill.document.toPlainText();
    final sel = quill.selection;

    // وضع التحديد
    if (!sel.isCollapsed) {
      final start = sel.start.clamp(0, plainText.length);
      final end = sel.end.clamp(0, plainText.length);
      final selectedText = plainText.substring(start, end);
      final result = _analyzer.analyzeParagraph(selectedText);
      if (result != null) {
        final safeEnd = end.clamp(0, quill.document.length - 1);
        return {...result, 'insertOffset': safeEnd, 'quill': quill};
      }
      return {'type': 'error', 'message': 'noNumbersFound'};
    }

    // وضع الفقرة
    final cursorPos = sel.baseOffset.clamp(0, plainText.length);
    final para = SmartAnalyzer.extractParagraph(plainText, cursorPos);
    final result = _analyzer.analyzeParagraph(para['text'] as String);
    if (result != null) {
      // نهاية الفقرة في Quill document = نفس offset في plainText
      // لكن نتجنب الـ \n الأخير الذي يضيفه toPlainText
      final paraEnd = (para['end'] as int).clamp(0, quill.document.length - 1);
      return {...result, 'insertOffset': paraEnd, 'quill': quill};
    }
    return {'type': 'error', 'message': 'noValidExpression'};
  }

  void showSmartCalculationResult(
    BuildContext context,
    dynamic controller,
    AppLocalizations l10n,
  ) {
    Map<String, dynamic>? result;

    if (controller is QuillController) {
      result = _computeFromQuill(controller);
    } else if (controller is TextEditingController) {
      result = _computeFromText(controller);
    } else {
      return;
    }

    if (result == null) return;
    final data = result;

    final scheme = Theme.of(context).colorScheme;

    if (data['type'] == 'error') {
      final msg = data['message'] == 'noNumbersFound'
          ? l10n.noNumbersFound
          : l10n.noValidExpression;
      UnifiedNotificationService().show(
        context: context,
        message: msg,
        type: NotificationType.warning,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (data['type'] == 'sum') {
      final sumResult = data['result'] as String;
      final sumExpression = data['expression'] as String? ?? '';
      final sumInsertText = sumResult;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.calculate_outlined, color: scheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(l10n.approximateSum.replaceAll(':', ''),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sumExpression.isNotEmpty)
                Text(
                  sumExpression,
                  style:
                      TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              if (sumExpression.isNotEmpty) const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sumResult,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: sumResult));
                        Navigator.pop(ctx);
                        UnifiedNotificationService().show(
                          context: context,
                          message: l10n.copied,
                          type: NotificationType.success,
                          duration: const Duration(seconds: 1),
                        );
                      },
                      child: Icon(Icons.copy_rounded,
                          size: 18,
                          color:
                              scheme.onPrimaryContainer.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.close),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                if (data['quill'] != null) {
                  final quill = data['quill'] as QuillController;
                  final offset = (data['insertOffset'] as int)
                      .clamp(0, quill.document.length - 1);
                  quill.replaceText(offset, 0, sumInsertText, null);
                  quill.moveCursorToPosition(offset + sumInsertText.length);
                } else if (data['controller'] != null) {
                  final ctrl = data['controller'] as TextEditingController;
                  final offset = data['insertOffset'] as int;
                  final newText =
                      ctrl.text.replaceRange(offset, offset, sumInsertText);
                  ctrl.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(
                        offset: offset + sumInsertText.length),
                  );
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.insert),
            ),
          ],
        ),
      );
      return;
    }

    // calculated — عرض التعبير والنتيجة مع زر إدراج
    final expression = data['expression'] as String;
    final resultValue = data['result'] as String;
    final insertText = ' = $resultValue';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.calculate_outlined, color: scheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(l10n.calculated,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              expression,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '= $resultValue',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: resultValue));
                      Navigator.pop(ctx);
                      UnifiedNotificationService().show(
                        context: context,
                        message: l10n.copied,
                        type: NotificationType.success,
                        duration: const Duration(seconds: 1),
                      );
                    },
                    child: Icon(Icons.copy_rounded,
                        size: 18,
                        color:
                            scheme.onPrimaryContainer.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.close),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              if (data['quill'] != null) {
                final quill = data['quill'] as QuillController;
                final offset = data['insertOffset'] as int;
                quill.replaceText(offset, 0, insertText, null);
                quill.moveCursorToPosition(offset + insertText.length);
              } else if (data['controller'] != null) {
                final ctrl = data['controller'] as TextEditingController;
                final offset = data['insertOffset'] as int;
                final newText =
                    ctrl.text.replaceRange(offset, offset, insertText);
                ctrl.value = TextEditingValue(
                  text: newText,
                  selection: TextSelection.collapsed(
                      offset: offset + insertText.length),
                );
              }
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.insert),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? analyzeMathAndDates(TextEditingController controller) {
    final text = controller.text;
    if (text.isEmpty) return null;
    final selection = controller.selection;
    if (!selection.isValid) return null;

    final lines = text.split('\n');
    int currentLineIndex = 0;
    int charCount = 0;

    for (int i = 0; i < lines.length; i++) {
      charCount += lines[i].length + 1;
      if (charCount >= selection.baseOffset) {
        currentLineIndex = i;
        break;
      }
    }

    if (currentLineIndex >= lines.length) return null;
    final currentLine = lines[currentLineIndex];

    if (currentLine.contains(RegExp(r'[\d\+\-\*\/]')) &&
        currentLine.endsWith('=')) {
      final result =
          _analyzer.evaluateExpression(currentLine.replaceAll('=', '').trim());
      if (result != null && !currentLine.contains(result)) {
        return {'type': 'math', 'result': result, 'line': currentLine};
      }
    }

    final dateResult = _analyzer.analyzeDate(currentLine);
    if (dateResult != null && !currentLine.contains(dateResult)) {
      return {'type': 'date', 'result': dateResult, 'line': currentLine};
    }

    return null;
  }

  Future<String> executeCode(String code, String? language) async {
    if (language == null) return 'Unable to detect language';
    return await CodeExecutor.executeCode(code, language);
  }

  String? detectLanguage(String code) => LanguageDetector.detectLanguage(code);

  String getExtensionForLanguage(String language) {
    if (language.startsWith('custom:')) return '.${language.substring(7)}';
    return LanguageDetector.getExtensionForLanguage(language);
  }

  String mapLanguageToNoteType(String? language) {
    if (language == null) return 'code';
    if (language.startsWith('custom:')) return language;
    const langToType = {
      'Markdown': 'markdown',
      'Python': 'python',
      'JavaScript': 'javascript',
      'TypeScript': 'typescript',
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
      'YAML': 'yaml',
      'TOML': 'toml',
      'XML': 'xml',
      'Lua': 'lua',
      'R': 'r',
      'Dockerfile': 'dockerfile',
      'SVG': 'svg',
    };
    return langToType[language] ?? 'code';
  }

  Future<void> showCodeExecutionDialog(
    BuildContext context,
    String code,
    String? detectedLanguage,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (detectedLanguage == null) {
      UnifiedNotificationService().show(
        context: context,
        message: l10n.unableToDetectLanguage,
        type: NotificationType.warning,
      );
      return;
    }
    UnifiedNotificationService().show(
      context: context,
      message: '${l10n.executingCode} ($detectedLanguage)',
      type: NotificationType.info,
      duration: const Duration(seconds: 1),
    );
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
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.close)),
        ],
      ),
    );
  }

  Future<String?> handleCodeExport(
      String code, String? detectedLanguage) async {
    final lang = detectedLanguage ?? detectLanguage(code);
    if (lang == null) return null;
    return getExtensionForLanguage(lang);
  }
}
