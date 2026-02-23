// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:apex_note/services/language_detector.dart';
import 'package:path_provider/path_provider.dart';

/// Code execution service for running code in a sandboxed environment
///
/// ⚠️ SECURITY WARNING: Local code execution is DISABLED for security reasons.
/// All execution methods now return a safe message directing users to future cloud execution.
///
/// Future implementation will use Judge0 API for secure cloud-based code execution.
class CodeExecutor {
  /// Execute Dart code (DISABLED for security)
  static Future<String> executeDart(String code) async {
    return _getSecurityMessage();

    // COMMENTED OUT FOR SECURITY - Local execution disabled
    // try {
    //   final tempDir = await getTemporaryDirectory();
    //   final file = File('${tempDir.path}/temp_code.dart');
    //   await file.writeAsString(code);
    //
    //   final result = await Process.run('dart', ['run', file.path]);
    //   await file.delete();
    //
    //   return result.stdout.toString() + result.stderr.toString();
    // } catch (e) {
    //   return 'Error: $e\nNote: Dart SDK required for execution';
    // }
  }

  /// Execute Python code (DISABLED for security)
  static Future<String> executePython(String code) async {
    return _getSecurityMessage();

    // COMMENTED OUT FOR SECURITY - Local execution disabled
    // try {
    //   final tempDir = await getTemporaryDirectory();
    //   final file = File('${tempDir.path}/temp_code.py');
    //   await file.writeAsString(code);
    //
    //   final result = await Process.run('python3', [file.path]);
    //   await file.delete();
    //
    //   return result.stdout.toString() + result.stderr.toString();
    // } catch (e) {
    //   return 'Error: $e\nNote: Python required for execution';
    // }
  }

  /// Execute JavaScript code (DISABLED for security)
  static Future<String> executeJavaScript(String code) async {
    return _getSecurityMessage();

    // COMMENTED OUT FOR SECURITY - Local execution disabled
    // try {
    //   final tempDir = await getTemporaryDirectory();
    //   final file = File('${tempDir.path}/temp_code.js');
    //   await file.writeAsString(code);
    //
    //   final result = await Process.run('node', [file.path]);
    //   await file.delete();
    //
    //   return result.stdout.toString() + result.stderr.toString();
    // } catch (e) {
    //   return 'Error: $e\nNote: Node.js required for execution';
    // }
  }

  /// Save code as executable file
  static Future<String> saveAsExecutable(
      String code, String language, String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final extension = LanguageDetector.getFileExtension(language);
      final file = File('${directory.path}/$filename$extension');

      await file.writeAsString(code);

      // For shell scripts, make executable (Unix-like systems)
      if ((language == 'Bash') && (Platform.isLinux || Platform.isMacOS)) {
        await Process.run('chmod', ['+x', file.path]);
      }

      return 'Saved to: ${file.path}';
    } catch (e) {
      return 'Error saving file: $e';
    }
  }

  /// Execute code based on detected language (DISABLED for security)
  static Future<String> executeCode(String code, String language) async {
    return _getSecurityMessage();

    // COMMENTED OUT FOR SECURITY - Local execution disabled
    // switch (language) {
    //   case 'Dart':
    //     return await executeDart(code);
    //   case 'Python':
    //     return await executePython(code);
    //   case 'JavaScript':
    //     return await executeJavaScript(code);
    //   default:
    //     return 'Execution not supported for $language.\nUse "Save as File" to export.';
    // }
  }

  /// Returns security message for disabled local execution
  static String _getSecurityMessage() {
    return '🔒 Running code locally is disabled for security.\n'
        '\n'
        '☁️ Cloud execution coming soon via Judge0 API.\n'
        '\n'
        'For now, you can:\n'
        '• Save code as file and run externally\n'
        '• Use online compilers (repl.it, jdoodle.com)\n'
        '• Copy code to your development environment';
  }
}

/// SECURITY NOTES FOR PRODUCTION:
///
/// 1. Sandboxing: Use Docker containers or isolated VMs for code execution
/// 2. Resource Limits: Set CPU, memory, and time limits
/// 3. Network Isolation: Disable network access during execution
/// 4. Input Validation: Sanitize code before execution
/// 5. User Permissions: Require explicit user consent
/// 6. API Alternative: Consider using online code execution APIs like:
///    - Judge0 API (https://judge0.com)
///    - Piston API (https://github.com/engineer-man/piston)
///    - JDoodle API (https://www.jdoodle.com/compiler-api)
///
/// Example API Integration:
/// ```dart
/// Future<String> executeViaAPI(String code, String language) async {
///   final response = await http.post(
///     Uri.parse('https://api.judge0.com/submissions'),
///     headers: {'Content-Type': 'application/json'},
///     body: jsonEncode({
///       'source_code': code,
///       'language_id': _getLanguageId(language),
///     }),
///   );
///   // Poll for result and return output
/// }
/// ```
