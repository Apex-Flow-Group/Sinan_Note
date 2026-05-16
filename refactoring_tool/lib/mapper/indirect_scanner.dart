import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:refactoring_tool/models/call_source.dart';

/// يمسح المشروع بحثاً عن الاستدعاءات غير المباشرة لدالة معينة
///
/// يكتشف أربعة أنواع من الاستدعاءات غير المباشرة:
/// - Provider: `context.read<T>().func`, `context.watch<T>().func`, `Provider.of<T>().func`
/// - Callbacks: الدالة تُمرر كمرجع (parameter reference)
/// - Streams: `.listen(func)` أو `.listen((e) => func(e))`
/// - MethodChannel: `setMethodCallHandler` يشير إلى الدالة
class IndirectScanner {
  /// المجلدات المستبعدة من المسح
  static const List<String> excludedDirectories = [
    '.dart_tool',
    'build',
    'generated',
    '.git',
  ];

  /// أنماط الملفات المستبعدة
  static const List<String> excludedFilePatterns = [
    '.g.dart',
    '.freezed.dart',
  ];

  final String projectRoot;

  IndirectScanner({required this.projectRoot});

  /// يمسح المشروع بحثاً عن استدعاءات غير مباشرة للدالة المحددة
  ///
  /// [targetFunction] اسم الدالة المراد البحث عن استدعاءاتها غير المباشرة
  ///
  /// يُرجع قائمة [CallSource] مرتبة حسب مسار الملف أبجدياً
  List<CallSource> scan(String targetFunction) {
    final List<CallSource> results = [];
    final dartFiles = _collectDartFiles();

    for (final file in dartFiles) {
      final content = _safeReadFile(file);
      if (content == null) continue;

      final relativePath =
          p.relative(file.path, from: projectRoot).replaceAll(r'\', '/');
      final lines = content.split('\n');

      // مسح كل نوع من الاستدعاءات غير المباشرة
      results.addAll(_scanProviderCalls(lines, relativePath, targetFunction));
      results.addAll(_scanCallbacks(lines, relativePath, targetFunction));
      results.addAll(_scanStreamListens(lines, relativePath, targetFunction));
      results.addAll(
          _scanMethodChannelHandlers(lines, relativePath, targetFunction));
    }

    // ترتيب النتائج حسب مسار الملف أبجدياً
    results.sort((a, b) {
      final pathCompare = a.filePath.compareTo(b.filePath);
      if (pathCompare != 0) return pathCompare;
      return a.lineNumber.compareTo(b.lineNumber);
    });

    return results;
  }

  /// يجمع جميع ملفات .dart المؤهلة في المشروع
  List<File> _collectDartFiles() {
    final List<File> files = [];
    final rootDir = Directory(projectRoot);

    if (!rootDir.existsSync()) return files;

    final entities = rootDir.listSync(recursive: true);

    for (final entity in entities) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (_isExcludedFile(entity.path)) continue;
      if (_isInExcludedDirectory(entity.path)) continue;

      files.add(entity);
    }

    return files;
  }

  /// يتحقق إذا كان الملف مستبعداً بناءً على اسمه
  bool _isExcludedFile(String filePath) {
    final fileName = p.basename(filePath);
    return excludedFilePatterns.any((pattern) => fileName.endsWith(pattern));
  }

  /// يتحقق إذا كان الملف في مجلد مستبعد
  bool _isInExcludedDirectory(String filePath) {
    final parts = p.split(filePath);
    return parts.any((part) => excludedDirectories.contains(part));
  }

  /// يقرأ محتوى الملف بأمان، يُرجع null عند الفشل
  String? _safeReadFile(File file) {
    try {
      return file.readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  /// يمسح استدعاءات Provider غير المباشرة
  ///
  /// يكتشف الأنماط:
  /// - `context.read<T>().targetFunction`
  /// - `context.watch<T>().targetFunction`
  /// - `Provider.of<T>(context).targetFunction`
  List<CallSource> _scanProviderCalls(
    List<String> lines,
    String filePath,
    String targetFunction,
  ) {
    final List<CallSource> results = [];

    // أنماط Provider read
    final providerReadPatterns = [
      // context.read<Type>().func or context.read<Type>().func(
      RegExp(
          'context\\.read<[^>]*>\\(\\)\\.${RegExp.escape(targetFunction)}\\b'),
      // ref.read(provider).func
      RegExp('ref\\.read\\([^)]*\\)\\.${RegExp.escape(targetFunction)}\\b'),
    ];

    // أنماط Provider watch
    final providerWatchPatterns = [
      // context.watch<Type>().func or context.watch<Type>().func(
      RegExp(
          'context\\.watch<[^>]*>\\(\\)\\.${RegExp.escape(targetFunction)}\\b'),
      // ref.watch(provider).func
      RegExp('ref\\.watch\\([^)]*\\)\\.${RegExp.escape(targetFunction)}\\b'),
    ];

    // أنماط Provider.of
    final providerOfPatterns = [
      // Provider.of<Type>(context).func
      RegExp(
          'Provider\\.of<[^>]*>\\([^)]*\\)\\.${RegExp.escape(targetFunction)}\\b'),
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // تخطي التعليقات
      if (trimmed.startsWith('//') || trimmed.startsWith('/*')) continue;

      final callingFunction = _findEnclosingFunction(lines, i);

      // فحص Provider.read
      for (final pattern in providerReadPatterns) {
        if (pattern.hasMatch(line)) {
          results.add(CallSource(
            callingFunction: callingFunction,
            filePath: filePath,
            lineNumber: i + 1,
            callType: CallType.providerRead,
          ));
          break;
        }
      }

      // فحص Provider.watch
      for (final pattern in providerWatchPatterns) {
        if (pattern.hasMatch(line)) {
          results.add(CallSource(
            callingFunction: callingFunction,
            filePath: filePath,
            lineNumber: i + 1,
            callType: CallType.providerWatch,
          ));
          break;
        }
      }

      // فحص Provider.of
      for (final pattern in providerOfPatterns) {
        if (pattern.hasMatch(line)) {
          // تحديد نوع الاستدعاء بناءً على listen parameter
          final callType = line.contains('listen: false')
              ? CallType.providerRead
              : CallType.providerWatch;
          results.add(CallSource(
            callingFunction: callingFunction,
            filePath: filePath,
            lineNumber: i + 1,
            callType: callType,
          ));
          break;
        }
      }
    }

    return results;
  }

  /// يمسح الدوال المُمررة كـ callbacks (مراجع دوال)
  ///
  /// يكتشف الأنماط:
  /// - `onPressed: targetFunction`
  /// - `callback: targetFunction`
  /// - `then(targetFunction)`
  /// - `map(targetFunction)`
  /// - `forEach(targetFunction)`
  /// - `Widget(onTap: targetFunction)`
  List<CallSource> _scanCallbacks(
    List<String> lines,
    String filePath,
    String targetFunction,
  ) {
    final List<CallSource> results = [];

    // أنماط callback: الدالة تُمرر كمرجع بدون استدعاء ()
    final callbackPatterns = [
      // Named parameter: onPressed: func, callback: func, onTap: func
      RegExp('\\w+:\\s*${RegExp.escape(targetFunction)}\\b(?!\\s*[.(])'),
      // Positional argument: .then(func), .map(func), .forEach(func), .where(func)
      RegExp('\\.\\w+\\(\\s*${RegExp.escape(targetFunction)}\\s*\\)'),
      // Passed as argument in function call: someFunc(func)
      // but NOT direct invocation like func() or func(args)
      RegExp('\\(\\s*${RegExp.escape(targetFunction)}\\s*[,)]'),
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // تخطي التعليقات
      if (trimmed.startsWith('//') || trimmed.startsWith('/*')) continue;

      // تخطي إذا كان استدعاء مباشر (func() أو func(args))
      // هذا يُعالج بواسطة call_scanner
      final directCallPattern =
          RegExp('\\b${RegExp.escape(targetFunction)}\\s*\\(');
      if (directCallPattern.hasMatch(line)) continue;

      // تخطي تعريف الدالة نفسها
      if (_isFunctionDefinition(line, targetFunction)) continue;

      for (final pattern in callbackPatterns) {
        if (pattern.hasMatch(line)) {
          // تأكد أنه ليس استدعاء stream listen (يُعالج بشكل منفصل)
          if (line.contains('.listen(') && line.contains(targetFunction)) {
            break;
          }

          final callingFunction = _findEnclosingFunction(lines, i);
          results.add(CallSource(
            callingFunction: callingFunction,
            filePath: filePath,
            lineNumber: i + 1,
            callType: CallType.callback,
          ));
          break;
        }
      }
    }

    return results;
  }

  /// يمسح اشتراكات Stream التي تستدعي الدالة
  ///
  /// يكتشف الأنماط:
  /// - `.listen(targetFunction)`
  /// - `.listen((e) => targetFunction(e))`
  /// - `.listen((event) { targetFunction(event); })`
  List<CallSource> _scanStreamListens(
    List<String> lines,
    String filePath,
    String targetFunction,
  ) {
    final List<CallSource> results = [];

    final streamPatterns = [
      // .listen(func) - مرجع مباشر
      RegExp('\\.listen\\(\\s*${RegExp.escape(targetFunction)}\\s*\\)'),
      // .listen((e) => func(e)) - lambda يستدعي الدالة
      RegExp(
          '\\.listen\\(\\s*\\([^)]*\\)\\s*=>\\s*${RegExp.escape(targetFunction)}\\s*\\('),
      // .listen((e) { func(e); }) - block body يستدعي الدالة
      RegExp(
          '\\.listen\\(\\s*\\([^)]*\\)\\s*\\{[^}]*${RegExp.escape(targetFunction)}\\s*\\('),
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // تخطي التعليقات
      if (trimmed.startsWith('//') || trimmed.startsWith('/*')) continue;

      for (final pattern in streamPatterns) {
        if (pattern.hasMatch(line)) {
          final callingFunction = _findEnclosingFunction(lines, i);
          results.add(CallSource(
            callingFunction: callingFunction,
            filePath: filePath,
            lineNumber: i + 1,
            callType: CallType.streamListen,
          ));
          break;
        }
      }
    }

    return results;
  }

  /// يمسح تسجيلات MethodChannel التي تشير إلى الدالة
  ///
  /// يكتشف الأنماط:
  /// - `setMethodCallHandler(targetFunction)`
  /// - `setMethodCallHandler((call) => targetFunction(call))`
  /// - `setMethodCallHandler((call) { ... targetFunction ... })`
  List<CallSource> _scanMethodChannelHandlers(
    List<String> lines,
    String filePath,
    String targetFunction,
  ) {
    final List<CallSource> results = [];

    final methodChannelPatterns = [
      // setMethodCallHandler(func) - مرجع مباشر
      RegExp(
          'setMethodCallHandler\\(\\s*${RegExp.escape(targetFunction)}\\s*\\)'),
      // setMethodCallHandler((call) => func(call))
      RegExp(
          'setMethodCallHandler\\(\\s*\\([^)]*\\)\\s*=>\\s*${RegExp.escape(targetFunction)}\\s*\\('),
      // setMethodCallHandler((call) { ... func ... })
      RegExp(
          'setMethodCallHandler\\(\\s*\\([^)]*\\)\\s*\\{[^}]*${RegExp.escape(targetFunction)}'),
      // setMethodCallHandler with async
      RegExp(
          'setMethodCallHandler\\(\\s*\\([^)]*\\)\\s*async\\s*\\{[^}]*${RegExp.escape(targetFunction)}'),
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // تخطي التعليقات
      if (trimmed.startsWith('//') || trimmed.startsWith('/*')) continue;

      for (final pattern in methodChannelPatterns) {
        if (pattern.hasMatch(line)) {
          final callingFunction = _findEnclosingFunction(lines, i);
          results.add(CallSource(
            callingFunction: callingFunction,
            filePath: filePath,
            lineNumber: i + 1,
            callType: CallType.methodChannel,
          ));
          break;
        }
      }
    }

    return results;
  }

  /// يبحث عن اسم الدالة المحيطة بسطر معين
  ///
  /// يبحث للأعلى من السطر الحالي حتى يجد تعريف دالة
  String _findEnclosingFunction(List<String> lines, int lineIndex) {
    // أنماط تعريف الدوال
    final functionPatterns = [
      // method: returnType methodName(params) {
      RegExp(r'^\s*(?:\w+\s+)*(\w+)\s*\([^)]*\)\s*(?:async\s*)?(?:\{|=>|$)'),
      // getter: returnType get name {
      RegExp(r'^\s*(?:\w+\s+)*get\s+(\w+)\s*(?:\{|=>)'),
      // setter: set name(param) {
      RegExp(r'^\s*set\s+(\w+)\s*\('),
      // constructor: ClassName(params) or ClassName.named(params)
      RegExp(r'^\s*(\w+(?:\.\w+)?)\s*\([^)]*\)\s*(?::|{)'),
    ];

    // البحث للأعلى من السطر الحالي
    for (int i = lineIndex; i >= 0; i--) {
      final line = lines[i];

      for (final pattern in functionPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final name = match.group(1);
          if (name != null &&
              name != 'if' &&
              name != 'for' &&
              name != 'while' &&
              name != 'switch' &&
              name != 'catch' &&
              name != 'class' &&
              name != 'return' &&
              name != 'import' &&
              name != 'export') {
            return name;
          }
        }
      }
    }

    return '<top-level>';
  }

  /// يتحقق إذا كان السطر يحتوي على تعريف الدالة المستهدفة
  bool _isFunctionDefinition(String line, String targetFunction) {
    final defPattern = RegExp(
        '\\b${RegExp.escape(targetFunction)}\\s*\\([^)]*\\)\\s*(?:async\\s*)?(?:\\{|=>|;)');
    // تعريف الدالة عادة يبدأ بنوع الإرجاع أو كلمة void/Future
    final fullDefPattern = RegExp(
        '(?:void|Future|\\w+)\\s+${RegExp.escape(targetFunction)}\\s*\\(');
    return defPattern.hasMatch(line) && fullDefPattern.hasMatch(line);
  }
}
