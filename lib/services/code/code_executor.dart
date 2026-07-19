// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sinan_note/services/code/language_detector.dart';

/// تنفيذ الكود محلياً معطّل لأسباب أمنية.
/// جميع دوال التنفيذ ترجع رسالة توجيه للمستخدم.
/// التنفيذ السحابي قادم عبر Judge0 API.
class CodeExecutor {
  static Future<String> executeDart(String code) async => _securityMessage;
  static Future<String> executePython(String code) async => _securityMessage;
  static Future<String> executeJavaScript(String code) async =>
      _securityMessage;
  static Future<String> executeCode(String code, String language) async =>
      _securityMessage;

  /// Save code as executable file
  static Future<String> saveAsExecutable(
      String code, String language, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final extension = LanguageDetector.getFileExtension(language);
      final file = File('${directory.path}/$filename$extension');
      await file.writeAsString(code);
      if (language == 'Bash' && (Platform.isLinux || Platform.isMacOS)) {
        await Process.run('chmod', ['+x', file.path]);
      }
      return 'Saved to: ${file.path}';
    } catch (e) {
      return 'Error saving file: $e';
    }
  }

  static const _securityMessage =
      '🔒 Running code locally is disabled for security.\n'
      '\n'
      '☁️ Cloud execution coming soon via Judge0 API.\n'
      '\n'
      'For now, you can:\n'
      '• Save code as file and run externally\n'
      '• Use online compilers (repl.it, jdoodle.com)\n'
      '• Copy code to your development environment';
}
