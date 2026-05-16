import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;
import 'package:refactoring_tool/models/call_source.dart';

/// يمسح جميع ملفات .dart في المشروع للعثور على استدعاءات مباشرة لدالة محددة.
///
/// يستبعد: `.dart_tool/`, `build/`, الملفات المولدة (`*.g.dart`, `*.freezed.dart`).
/// يُرجع النتائج مجمعة حسب مسار الملف بترتيب أبجدي.
class CallScanner {
  /// أسماء المجلدات المستبعدة من المسح
  static const List<String> excludedDirectories = [
    '.dart_tool',
    'build',
    'generated',
    '.dart_tool',
  ];

  /// أنماط الملفات المستبعدة
  static const List<String> excludedFilePatterns = [
    '.g.dart',
    '.freezed.dart',
  ];

  final String projectRoot;

  CallScanner({required this.projectRoot});

  /// يمسح المشروع للعثور على جميع الاستدعاءات المباشرة لدالة [targetFunction].
  ///
  /// يُرجع قائمة [CallSource] مرتبة حسب [filePath] أبجدياً.
  List<CallSource> scanForDirectCalls(String targetFunction) {
    final dartFiles = _collectDartFiles();
    final List<CallSource> results = [];

    for (final file in dartFiles) {
      final calls = _scanFileForCalls(file, targetFunction);
      results.addAll(calls);
    }

    // ترتيب حسب مسار الملف أبجدياً
    results.sort((a, b) => a.filePath.compareTo(b.filePath));

    return results;
  }

  /// يجمع جميع ملفات .dart المؤهلة في المشروع
  List<File> _collectDartFiles() {
    final rootDir = Directory(projectRoot);
    if (!rootDir.existsSync()) return [];

    final List<File> dartFiles = [];

    final entities = rootDir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (_isExcludedFile(entity.path)) continue;
      if (_isInExcludedDirectory(entity.path)) continue;

      dartFiles.add(entity);
    }

    return dartFiles;
  }

  /// يتحقق إذا كان الملف مستبعداً بناءً على اسمه
  bool _isExcludedFile(String filePath) {
    final fileName = p.basename(filePath);
    return excludedFilePatterns.any((pattern) => fileName.endsWith(pattern));
  }

  /// يتحقق إذا كان الملف في مجلد مستبعد
  bool _isInExcludedDirectory(String filePath) {
    final relativePath = p.relative(filePath, from: projectRoot);
    final parts = p.split(relativePath);
    return parts.any((part) => excludedDirectories.contains(part));
  }

  /// يمسح ملف واحد للعثور على استدعاءات مباشرة للدالة المستهدفة
  List<CallSource> _scanFileForCalls(File file, String targetFunction) {
    final String source;
    try {
      source = file.readAsStringSync();
    } catch (_) {
      // تخطي الملفات غير القابلة للقراءة
      return [];
    }

    // تحقق سريع: هل يحتوي الملف على اسم الدالة أصلاً؟
    if (!source.contains(targetFunction)) {
      return [];
    }

    final relativePath = p.relative(file.path, from: projectRoot);
    final normalizedPath = relativePath.replaceAll(r'\', '/');

    try {
      return _scanWithAst(source, normalizedPath, targetFunction);
    } catch (_) {
      // إذا فشل تحليل AST، نستخدم grep كبديل
      return _scanWithGrep(source, normalizedPath, targetFunction);
    }
  }

  /// يمسح باستخدام AST للعثور على استدعاءات مباشرة
  List<CallSource> _scanWithAst(
    String source,
    String filePath,
    String targetFunction,
  ) {
    final parseResult = parseString(content: source);
    final unit = parseResult.unit;

    final visitor = _CallScanVisitor(
      source: source,
      filePath: filePath,
      targetFunction: targetFunction,
    );
    unit.visitChildren(visitor);

    return visitor.calls;
  }

  /// يمسح باستخدام regex كبديل عند فشل AST
  List<CallSource> _scanWithGrep(
    String source,
    String filePath,
    String targetFunction,
  ) {
    final List<CallSource> calls = [];
    final lines = source.split('\n');

    // نمط يطابق استدعاء الدالة المباشر: functionName(
    final pattern = RegExp(
      '\\b${RegExp.escape(targetFunction)}\\s*\\(',
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // تخطي التعليقات
      if (line.startsWith('//') ||
          line.startsWith('/*') ||
          line.startsWith('*')) {
        continue;
      }

      // تخطي تعريفات الدوال (نريد الاستدعاءات فقط)
      if (_isFunctionDeclaration(line, targetFunction)) {
        continue;
      }

      if (pattern.hasMatch(line)) {
        calls.add(CallSource(
          callingFunction: _inferCallingFunction(lines, i),
          filePath: filePath,
          lineNumber: i + 1,
          callType: CallType.direct,
        ));
      }
    }

    return calls;
  }

  /// يتحقق إذا كان السطر تعريف دالة وليس استدعاء
  bool _isFunctionDeclaration(String line, String functionName) {
    // أنماط تعريف الدوال
    final declarationPatterns = [
      // void functionName(
      RegExp('^\\w+\\s+${RegExp.escape(functionName)}\\s*\\('),
      // Future<void> functionName(
      RegExp('^\\w+<[^>]+>\\s+${RegExp.escape(functionName)}\\s*\\('),
      // static void functionName(
      RegExp('^static\\s+\\w+\\s+${RegExp.escape(functionName)}\\s*\\('),
      // functionName( at start of line with return type keywords
      RegExp(
          '^(void|int|double|String|bool|Future|Stream|List|Map|Set|dynamic)\\s+${RegExp.escape(functionName)}\\s*\\('),
    ];

    return declarationPatterns.any((p) => p.hasMatch(line));
  }

  /// يستنتج اسم الدالة المحيطة من السياق (grep fallback)
  String _inferCallingFunction(List<String> lines, int lineIndex) {
    // ابحث للأعلى عن أقرب تعريف دالة
    final funcPattern = RegExp(
      r'(?:void|int|double|String|bool|Future|Stream|List|Map|Set|dynamic|[\w<>]+)\s+(\w+)\s*\(',
    );

    for (int i = lineIndex; i >= 0; i--) {
      final line = lines[i].trim();
      final match = funcPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)!;
        // تأكد أنه تعريف وليس استدعاء (يحتوي على { أو => بعده)
        if (line.contains('{') ||
            line.contains('=>') ||
            (i + 1 < lines.length && lines[i + 1].trim().startsWith('{'))) {
          return name;
        }
      }
    }

    return '<unknown>';
  }
}

/// AST visitor يبحث عن استدعاءات مباشرة لدالة محددة
class _CallScanVisitor extends RecursiveAstVisitor<void> {
  final String source;
  final String filePath;
  final String targetFunction;
  final List<CallSource> calls = [];

  /// يتتبع الدالة المحيطة الحالية
  String _currentFunction = '<top-level>';

  _CallScanVisitor({
    required this.source,
    required this.filePath,
    required this.targetFunction,
  });

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final previousFunction = _currentFunction;
    _currentFunction = node.name.lexeme;

    // لا نسجل تعريف الدالة المستهدفة نفسها
    if (node.name.lexeme != targetFunction) {
      node.functionExpression.body.accept(this);
    }

    _currentFunction = previousFunction;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final previousFunction = _currentFunction;

    // اسم الدالة مع اسم الكلاس إذا كانت method
    final className = _getEnclosingClassName(node);
    _currentFunction =
        className != null ? '$className.${node.name.lexeme}' : node.name.lexeme;

    // لا نسجل تعريف الدالة المستهدفة نفسها
    if (node.name.lexeme != targetFunction) {
      node.body.accept(this);
    }

    _currentFunction = previousFunction;
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final previousFunction = _currentFunction;
    final className = (node.parent as ClassDeclaration?)?.name.lexeme ?? '';
    final constructorName = node.name?.lexeme;
    _currentFunction =
        constructorName != null ? '$className.$constructorName' : className;

    node.body.accept(this);

    _currentFunction = previousFunction;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == targetFunction) {
      final lineNumber = _getLineNumber(node.offset);
      calls.add(CallSource(
        callingFunction: _currentFunction,
        filePath: filePath,
        lineNumber: lineNumber,
        callType: CallType.direct,
      ));
    }

    // استمر في زيارة العقد الفرعية
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // التحقق من استدعاء دالة عبر identifier مباشر
    final function = node.function;
    if (function is SimpleIdentifier && function.name == targetFunction) {
      final lineNumber = _getLineNumber(node.offset);
      calls.add(CallSource(
        callingFunction: _currentFunction,
        filePath: filePath,
        lineNumber: lineNumber,
        callType: CallType.direct,
      ));
    }

    super.visitFunctionExpressionInvocation(node);
  }

  /// يحصل على اسم الكلاس المحيط بالـ method
  String? _getEnclosingClassName(MethodDeclaration node) {
    final parent = node.parent;
    if (parent is ClassDeclaration) {
      return parent.name.lexeme;
    }
    if (parent is MixinDeclaration) {
      return parent.name.lexeme;
    }
    if (parent is ExtensionDeclaration) {
      return parent.name?.lexeme;
    }
    return null;
  }

  /// يحسب رقم السطر من offset
  int _getLineNumber(int offset) {
    int line = 1;
    for (int i = 0; i < offset && i < source.length; i++) {
      if (source[i] == '\n') line++;
    }
    return line;
  }
}
