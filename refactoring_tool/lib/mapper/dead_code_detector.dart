import 'package:refactoring_tool/models/call_source.dart';
import 'package:refactoring_tool/models/function_unit.dart';

/// تقرير كود ميت لدالة واحدة
class DeadCodeEntry {
  final String functionName;
  final String filePath;
  final int lineNumber;

  const DeadCodeEntry({
    required this.functionName,
    required this.filePath,
    required this.lineNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'functionName': functionName,
      'filePath': filePath,
      'lineNumber': lineNumber,
    };
  }

  factory DeadCodeEntry.fromJson(Map<String, dynamic> json) {
    return DeadCodeEntry(
      functionName: json['functionName'] as String,
      filePath: json['filePath'] as String,
      lineNumber: json['lineNumber'] as int,
    );
  }

  @override
  String toString() => 'DeadCodeEntry($functionName in $filePath:$lineNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeadCodeEntry &&
          runtimeType == other.runtimeType &&
          functionName == other.functionName &&
          filePath == other.filePath &&
          lineNumber == other.lineNumber;

  @override
  int get hashCode => Object.hash(functionName, filePath, lineNumber);
}

/// تقرير الكود الميت الكامل
class DeadCodeReport {
  final List<DeadCodeEntry> entries;
  final DateTime generatedAt;

  const DeadCodeReport({
    required this.entries,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((e) => e.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory DeadCodeReport.fromJson(Map<String, dynamic> json) {
    return DeadCodeReport(
      entries: (json['entries'] as List<dynamic>)
          .map((e) => DeadCodeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }
}

/// كاشف الكود الميت
///
/// يحدد الدوال التي لا تُستدعى من أي مكان (صفر استدعاءات مباشرة وغير مباشرة)
/// مع استثناء نقاط الدخول، دوال lifecycle، ومراجع جداول التوجيه.
class DeadCodeDetector {
  /// أسماء الدوال التي تُعتبر نقاط دخول ولا تُعد كود ميت
  static const _entryPointNames = {'main'};

  /// أسماء دوال lifecycle الشائعة في Flutter التي تحمل @override
  static const _lifecycleOverrides = {
    'initState',
    'dispose',
    'didChangeDependencies',
    'didUpdateWidget',
    'deactivate',
    'reassemble',
    'build',
    'createState',
    'createElement',
    'toStringShort',
    'debugFillProperties',
    'toString',
    'hashCode',
    'noSuchMethod',
  };

  /// أنماط أسماء الدوال المرتبطة بجداول التوجيه
  static const _routeTablePatterns = [
    'onGenerateRoute',
    'onUnknownRoute',
    'routes',
    'getRoutes',
    'generateRoute',
    'routeFactory',
  ];

  /// أسماء دوال إضافية مستثناة (مراجع route tables)
  final Set<String> _additionalExclusions;

  DeadCodeDetector({Set<String>? additionalExclusions})
      : _additionalExclusions = additionalExclusions ?? {};

  /// يتحقق مما إذا كانت الدالة كود ميت
  ///
  /// تُعتبر الدالة كود ميت إذا:
  /// - لديها صفر استدعاءات مباشرة وصفر استدعاءات غير مباشرة
  /// - ليست نقطة دخول (main)
  /// - ليست دالة lifecycle override (@override)
  /// - ليست مرجعاً في جدول توجيه
  bool isDeadCode({
    required FunctionUnit function,
    required List<CallSource> directCallSources,
    required List<CallSource> indirectCallSources,
    required bool hasOverrideAnnotation,
  }) {
    // إذا كان هناك أي استدعاء، فليست كود ميت
    if (directCallSources.isNotEmpty || indirectCallSources.isNotEmpty) {
      return false;
    }

    // تحقق من قائمة الاستثناءات
    if (_isExcluded(function, hasOverrideAnnotation)) {
      return false;
    }

    return true;
  }

  /// يولد تقرير الكود الميت من قائمة دوال مع مصادر استدعائها
  DeadCodeReport generateReport({
    required List<DeadCodeAnalysisInput> inputs,
  }) {
    final entries = <DeadCodeEntry>[];

    for (final input in inputs) {
      if (isDeadCode(
        function: input.function,
        directCallSources: input.directCallSources,
        indirectCallSources: input.indirectCallSources,
        hasOverrideAnnotation: input.hasOverrideAnnotation,
      )) {
        entries.add(DeadCodeEntry(
          functionName: input.function.name,
          filePath: input.function.filePath,
          lineNumber: input.function.startLine,
        ));
      }
    }

    return DeadCodeReport(
      entries: entries,
      generatedAt: DateTime.now(),
    );
  }

  /// يتحقق مما إذا كانت الدالة مستثناة من تصنيف الكود الميت
  bool _isExcluded(FunctionUnit function, bool hasOverrideAnnotation) {
    // 1. نقاط الدخول (main)
    if (_entryPointNames.contains(function.name)) {
      return true;
    }

    // 2. دوال lifecycle overrides (@override)
    if (hasOverrideAnnotation) {
      return true;
    }

    // 3. دوال lifecycle المعروفة (حتى بدون annotation صريح)
    if (_lifecycleOverrides.contains(function.name)) {
      return true;
    }

    // 4. مراجع جداول التوجيه
    for (final pattern in _routeTablePatterns) {
      if (function.name == pattern ||
          function.name.toLowerCase().contains('route')) {
        return true;
      }
    }

    // 5. استثناءات إضافية مخصصة
    if (_additionalExclusions.contains(function.name)) {
      return true;
    }

    return false;
  }
}

/// مدخلات تحليل الكود الميت لدالة واحدة
class DeadCodeAnalysisInput {
  final FunctionUnit function;
  final List<CallSource> directCallSources;
  final List<CallSource> indirectCallSources;
  final bool hasOverrideAnnotation;

  const DeadCodeAnalysisInput({
    required this.function,
    required this.directCallSources,
    required this.indirectCallSources,
    this.hasOverrideAnnotation = false,
  });
}
