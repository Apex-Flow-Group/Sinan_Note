import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:refactoring_tool/engine/dependency_sorter.dart';
import 'package:refactoring_tool/engine/file_scanner.dart';
import 'package:refactoring_tool/engine/function_extractor.dart';
import 'package:refactoring_tool/engine/modification_applier.dart';
import 'package:refactoring_tool/engine/progress_manager.dart';
import 'package:refactoring_tool/gate/answer_validator.dart';
import 'package:refactoring_tool/gate/decision_recorder.dart';
import 'package:refactoring_tool/gate/evaluation_presenter.dart';
import 'package:refactoring_tool/mapper/call_scanner.dart';
import 'package:refactoring_tool/mapper/dead_code_detector.dart';
import 'package:refactoring_tool/mapper/dependency_grapher.dart';
import 'package:refactoring_tool/mapper/event_sheet_generator.dart';
import 'package:refactoring_tool/mapper/indirect_scanner.dart';
import 'package:refactoring_tool/models/call_source.dart';
import 'package:refactoring_tool/models/core_file_entry.dart';
import 'package:refactoring_tool/models/evaluation_record.dart';
import 'package:refactoring_tool/models/event_sheet.dart';
import 'package:refactoring_tool/models/function_unit.dart';
import 'package:refactoring_tool/storage/storage_manager.dart';
import 'package:refactoring_tool/testing/checklist_generator.dart';
import 'package:refactoring_tool/testing/reverter.dart';
import 'package:refactoring_tool/testing/test_executor.dart';
import 'package:refactoring_tool/testing/test_finder.dart';

/// CLI entry point for the Sinan Note refactoring tool.
///
/// ⚠️ ملاحظات دقة الكشف:
/// الأداة تكتشف الاستدعاءات بالبحث النصي عن اسم الدالة — وهذا يُفوّت:
///   1. context.select<T>((n) => n.getter) — استدعاء عبر Provider selector
///   2. الاستدعاء عبر callback مُسجَّل في constructor (مثل: onSyncCompleted = _fn)
///   3. الاستدعاء عبر alias (مثل: notes = activeNotes، كلاهما نفس الشيء)
///   4. الاستدعاء من داخل نفس الملف عبر this.method()
///   5. Private constructors في Singleton pattern (مثل: _internal، _) — طبيعية دائماً
/// → دائماً تحقق يدوياً قبل حذف أي دالة تُبلّغ عنها كـ "كود ميت".

/// Supports the following flags:
///   --progress       Display current refactoring progress
///   --dead-code      Display dead code report
///   --monthly-report Generate monthly summary report
///   --file <path>    Resume refactoring from a specific file
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(
      'progress',
      abbr: 'p',
      negatable: false,
      help: 'Display current refactoring progress.',
    )
    ..addFlag(
      'dead-code',
      abbr: 'd',
      negatable: false,
      help: 'Display dead code report.',
    )
    ..addFlag(
      'monthly-report',
      abbr: 'm',
      negatable: false,
      help: 'Generate monthly summary report.',
    )
    ..addOption(
      'file',
      abbr: 'f',
      help: 'Resume refactoring from a specific file path.',
      valueHelp: 'lib/controllers/notes/notes_provider.dart',
    )
    ..addFlag(
      'report',
      abbr: 'r',
      negatable: false,
      help: 'Print all functions with analysis (no questions).',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information.',
    );

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln('');
    _printUsage(parser);
    exit(1);
  }

  if (results['help'] as bool) {
    _printUsage(parser);
    exit(0);
  }

  // Determine project root (parent of refactoring_tool/)
  final projectRoot = _resolveProjectRoot();

  // Initialize storage
  final storage = StorageManager(projectRoot: projectRoot);
  await storage.initialize();

  if (results['progress'] as bool) {
    await _showProgress(storage);
    return;
  }

  if (results['dead-code'] as bool) {
    await _showDeadCode(storage);
    return;
  }

  if (results['monthly-report'] as bool) {
    await _generateMonthlyReport(storage);
    return;
  }

  if (results['report'] as bool) {
    await _reportMode(
      projectRoot: projectRoot,
      storage: storage,
      resumeFrom: results['file'] as String?,
    );
    return;
  }

  final String? filePath = results['file'] as String?;
  await _startRefactoring(
    projectRoot: projectRoot,
    storage: storage,
    resumeFrom: filePath,
  );
}

/// Resolves the project root directory (parent of refactoring_tool/).
String _resolveProjectRoot() {
  // The script runs from refactoring_tool/bin/main.dart
  // Project root is the parent of refactoring_tool/
  final scriptDir = p.dirname(Platform.script.toFilePath());
  final toolRoot = p.dirname(scriptDir); // refactoring_tool/
  final projectRoot = p.dirname(toolRoot); // project root
  return projectRoot;
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Sinan Note Refactoring Tool');
  stdout.writeln('');
  stdout.writeln('Usage: dart run refactoring_tool [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(parser.usage);
}

/// --progress: Display current refactoring progress
Future<void> _showProgress(StorageManager storage) async {
  final data = await storage.loadProgress();
  if (data == null) {
    stdout.writeln('لا يوجد تقدم محفوظ بعد. ابدأ دورة إعادة الهيكلة أولاً.');
    return;
  }

  final totalFiles = data['totalCoreFiles'] as int? ?? 0;
  final completedFiles = data['completedCoreFiles'] as int? ?? 0;
  final totalFunctions = data['totalFunctionUnits'] as int? ?? 0;
  final reviewedFunctions = data['reviewedFunctionUnits'] as int? ?? 0;
  final percentage = data['completionPercentage'] as num? ?? 0.0;
  final startDate = data['startDate'] as String? ?? '';
  final lastUpdated = data['lastUpdated'] as String? ?? '';

  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('  📊 تقدم إعادة الهيكلة');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('');
  stdout.writeln('  📁 الملفات: $completedFiles / $totalFiles مكتمل');
  stdout.writeln('  📝 الدوال: $reviewedFunctions / $totalFunctions مراجعة');
  stdout.writeln('  📈 النسبة: ${percentage.toStringAsFixed(2)}%');
  stdout.writeln('  📅 تاريخ البدء: $startDate');
  stdout.writeln('  🕐 آخر تحديث: $lastUpdated');
  stdout.writeln('');

  // Display per-file progress
  final files = data['fileProgress'] as List<dynamic>? ?? [];
  if (files.isNotEmpty) {
    stdout.writeln('━━━ تفاصيل الملفات ━━━');
    for (final file in files) {
      final fileMap = file as Map<String, dynamic>;
      final path = fileMap['filePath'] as String? ?? '';
      final status = fileMap['status'] as String? ?? 'notStarted';
      final total = fileMap['totalFunctions'] as int? ?? 0;
      final reviewed = fileMap['reviewedFunctions'] as int? ?? 0;
      final statusIcon = switch (status) {
        'completed' => '✅',
        'inProgress' => '🔄',
        _ => '⬜',
      };
      stdout.writeln('  $statusIcon $path ($reviewed/$total)');
    }
    stdout.writeln('');
  }

  stdout.writeln('═══════════════════════════════════════════════════════');
}

/// --dead-code: Display dead code report
Future<void> _showDeadCode(StorageManager storage) async {
  final data = await storage.loadDeadCode();
  if (data == null) {
    stdout.writeln('لا يوجد تقرير كود ميت بعد. ابدأ دورة إعادة الهيكلة أولاً.');
    return;
  }

  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('  🗑️ تقرير الكود الميت');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('');

  final entries = data['entries'] as List<dynamic>? ?? [];
  final removals = data['removals'] as List<dynamic>? ?? [];

  if (entries.isEmpty && removals.isEmpty) {
    stdout.writeln('  لم يتم اكتشاف كود ميت.');
  } else {
    if (entries.isNotEmpty) {
      stdout.writeln('━━━ دوال بدون استدعاءات (${entries.length}) ━━━');
      for (final entry in entries) {
        final entryMap = entry as Map<String, dynamic>;
        final name = entryMap['functionName'] as String? ?? '';
        final path = entryMap['filePath'] as String? ?? '';
        final line = entryMap['lineNumber'] as int? ?? 0;
        stdout.writeln('  ⚠️ $name');
        stdout.writeln('     📁 $path:$line');
      }
      stdout.writeln('');
    }

    if (removals.isNotEmpty) {
      stdout.writeln('━━━ كود تمت إزالته (${removals.length}) ━━━');
      for (final removal in removals) {
        final removalMap = removal as Map<String, dynamic>;
        final name = removalMap['functionName'] as String? ?? '';
        final path = removalMap['coreFilePath'] as String? ?? '';
        final reason = removalMap['reason'] as String? ?? '';
        stdout.writeln('  🗑️ $name ($path)');
        stdout.writeln('     السبب: $reason');
      }
      stdout.writeln('');
    }
  }

  stdout.writeln('═══════════════════════════════════════════════════════');
}

/// --monthly-report: Generate monthly summary report
Future<void> _generateMonthlyReport(StorageManager storage) async {
  final progressManager = ProgressManager(storage: storage);
  await progressManager.load();

  final report = await progressManager.generateMonthlyReport();

  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('  📋 التقرير الشهري');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('');
  stdout.writeln('  الشهر: ${report['month']}');
  stdout.writeln('  تاريخ التوليد: ${report['generatedAt']}');
  stdout.writeln(
      '  الملفات المكتملة: ${report['completedCoreFiles']} / ${report['totalCoreFiles']}');
  stdout.writeln(
      '  الدوال المراجعة: ${report['reviewedFunctionUnits']} / ${report['totalFunctionUnits']}');
  stdout.writeln(
      '  النسبة: ${(report['completionPercentage'] as num).toStringAsFixed(2)}%');
  stdout.writeln('');

  final filesProcessed = report['filesProcessed'] as List<dynamic>? ?? [];
  if (filesProcessed.isNotEmpty) {
    stdout.writeln('━━━ ملفات مكتملة هذا الشهر ━━━');
    for (final f in filesProcessed) {
      stdout.writeln('  ✅ $f');
    }
    stdout.writeln('');
  }

  final filesInProgress = report['filesInProgress'] as List<dynamic>? ?? [];
  if (filesInProgress.isNotEmpty) {
    stdout.writeln('━━━ ملفات قيد العمل ━━━');
    for (final f in filesInProgress) {
      stdout.writeln('  🔄 $f');
    }
    stdout.writeln('');
  }

  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('  ✅ تم حفظ التقرير الشهري.');
}

/// --report: Print all functions with analysis, no questions
Future<void> _reportMode({
  required String projectRoot,
  required StorageManager storage,
  String? resumeFrom,
}) async {
  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('  📋 تقرير تحليل الكود — Sinan Note');
  stdout.writeln('═══════════════════════════════════════════════════════');

  final fileScanner = FileScanner(projectRoot: projectRoot);
  final functionExtractor = FunctionExtractor();
  final deadCodeDetector = DeadCodeDetector();

  List<CoreFileEntry> coreFiles;
  try {
    coreFiles = fileScanner.scan();
  } on FileScannerException catch (e) {
    stderr.writeln('  ❌ ${e.message}');
    exit(1);
  }

  final importMap = <String, List<String>>{};
  for (final entry in coreFiles) {
    final filePath = p.join(projectRoot, entry.filePath);
    final file = File(filePath);
    if (file.existsSync()) {
      final content = file.readAsStringSync();
      final imports = _extractCoreImports(content, coreFiles);
      importMap[entry.filePath] = imports;
    }
  }

  final sortResult = DependencySorter().sort(coreFiles, importMap);
  final sortedFiles = sortResult.sortedEntries;

  stdout.writeln(
      '  ✅ ${coreFiles.length} ملف أساسي، ${sortResult.circularGroups.length} تبعية دائرية');

  // ── بناء index واحد لكل الاستدعاءات ──────────────────────────────────────
  // بدلاً من مسح كل الملفات لكل دالة (O(n²))، نمسح مرة واحدة ونبني Map
  stdout.writeln('  🔍 جاري بناء index الاستدعاءات (مرة واحدة)...');
  // callIndex: functionName → list of "file:line ← caller"
  final callIndex = <String, List<String>>{};
  final dartFiles = Directory(projectRoot)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) =>
          f.path.endsWith('.dart') &&
          !f.path.contains('.dart_tool') &&
          !f.path.contains('build/') &&
          !f.path.contains('.g.dart') &&
          !f.path.contains('.freezed.dart'))
      .toList();

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    final relPath =
        p.relative(file.path, from: projectRoot).replaceAll('\\', '/');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // استخراج كل identifier يُشبه استدعاء دالة
      final matches =
          RegExp(r'\b([a-zA-Z_][a-zA-Z0-9_]*)\s*[\(\.]').allMatches(line);
      for (final m in matches) {
        final name = m.group(1)!;
        callIndex.putIfAbsent(name, () => []).add('$relPath:${i + 1}');
      }
    }
  }
  stdout.writeln('  ✅ index جاهز — ${callIndex.length} اسم مفهرس');

  // Determine start
  int startIndex = 0;
  if (resumeFrom != null) {
    final norm = resumeFrom.replaceAll(r'\', '/');
    startIndex = sortedFiles.indexWhere((e) => e.filePath == norm);
    if (startIndex < 0) startIndex = 0;
  }

  int totalFunctions = 0;
  int deadCount = 0;
  final deadList = <String>[];

  for (int fileIdx = startIndex; fileIdx < sortedFiles.length; fileIdx++) {
    final coreFile = sortedFiles[fileIdx];
    final filePath = p.join(projectRoot, coreFile.filePath);
    final extraction = functionExtractor.extractFromFile(filePath);
    if (extraction.functions.isEmpty) continue;

    stdout.writeln('');
    stdout.writeln('╔══════════════════════════════════════════════════════');
    stdout.writeln('║ 📁 ${coreFile.filePath}');
    stdout.writeln('║ ${extraction.functions.length} دالة');
    stdout.writeln('╚══════════════════════════════════════════════════════');

    for (final function in extraction.functions) {
      totalFunctions++;

      // استعلام O(1) من الـ index
      final callers = callIndex[function.name] ?? [];

      // تصفية: استبعد الملف نفسه من الاستدعاءات (تعريف الدالة)
      final externalCallers =
          callers.where((c) => !c.startsWith(coreFile.filePath)).toList();

      final isDead = externalCallers.isEmpty &&
          !function.body.contains('@override') &&
          deadCodeDetector.isDeadCode(
            function: function,
            directCallSources: [],
            indirectCallSources: [],
            hasOverrideAnnotation: function.body.contains('@override'),
          );

      // Print function summary
      final deadTag = isDead ? ' 💀 كود ميت' : '';
      stdout.writeln('');
      stdout.writeln('  ┌─ ${function.name}$deadTag');
      stdout.writeln(
          '  │  النوع: ${function.type.name} | ${function.lineCount} سطر (${function.startLine}→${function.endLine}) | إرجاع: ${function.returnType}');

      if (externalCallers.isEmpty) {
        stdout.writeln('  │  الاستدعاءات: لا يوجد');
      } else {
        stdout.writeln('  │  الاستدعاءات (${externalCallers.length}):');
        for (final c in externalCallers.take(5)) {
          stdout.writeln('  │    • $c');
        }
        if (externalCallers.length > 5) {
          stdout.writeln('  │    ... و${externalCallers.length - 5} أخرى');
        }
      }

      stdout.writeln('  └─────');

      if (isDead) {
        deadCount++;
        deadList.add('${coreFile.filePath}::${function.name}');
      }
    }
  }

  // Summary
  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('  📊 ملخص التقرير');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('  الدوال الكلية: $totalFunctions');
  stdout.writeln('  كود ميت محتمل: $deadCount');
  if (deadList.isNotEmpty) {
    stdout.writeln('');
    stdout.writeln('  💀 قائمة الكود الميت المحتمل:');
    stdout.writeln(
        '  ⚠️  تحقق يدوياً — الأداة لا تكتشف: context.select، callbacks، aliases');
    for (final d in deadList) {
      stdout.writeln('     • $d');
    }
  }
  stdout.writeln('═══════════════════════════════════════════════════════');
}

/// Main refactoring loop: scan → sort → extract → analyze → evaluate → modify → test → progress
Future<void> _startRefactoring({
  required String projectRoot,
  required StorageManager storage,
  String? resumeFrom,
}) async {
  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('  🔧 أداة إعادة هيكلة Sinan Note');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('');

  // --- 1. Initialize components ---
  final fileScanner = FileScanner(projectRoot: projectRoot);
  final dependencySorter = DependencySorter();
  final functionExtractor = FunctionExtractor();
  final progressManager = ProgressManager(storage: storage);
  final modificationApplier = ModificationApplier(
    storage: storage,
    projectRoot: projectRoot,
  );
  final callScanner = CallScanner(projectRoot: projectRoot);
  final indirectScanner = IndirectScanner(projectRoot: projectRoot);
  final deadCodeDetector = DeadCodeDetector();
  final eventSheetGenerator = EventSheetGenerator();
  final dependencyGrapher = DependencyGrapher((functionName) {
    final callers = callScanner.scanForDirectCalls(functionName);
    final indirectCallers = indirectScanner.scan(functionName);
    return ResolvedCalls(
      callers: [...callers, ...indirectCallers],
      callees: [], // Downstream requires body analysis - simplified here
    );
  });
  final evaluationPresenter = EvaluationPresenter();
  final answerValidator = AnswerValidator();
  final decisionRecorder = DecisionRecorder(storageManager: storage);
  final testFinder = TestFinder(projectRoot: projectRoot);
  final reverter = Reverter(projectRoot: projectRoot);
  final testExecutor = TestExecutor(
    projectRoot: projectRoot,
    timeoutSeconds: 120,
  );
  final checklistGenerator = ChecklistGenerator();

  // --- 2. Load existing progress or start fresh ---
  await progressManager.load();

  // --- 3. Scan files ---
  stdout.writeln('  📂 جاري مسح الملفات الأساسية...');
  List<CoreFileEntry> coreFiles;
  try {
    coreFiles = fileScanner.scan();
  } on FileScannerException catch (e) {
    stderr.writeln('  ❌ ${e.message}');
    exit(1);
  }
  stdout.writeln('  ✅ تم العثور على ${coreFiles.length} ملف أساسي.');

  // --- 4. Build import map for sorting ---
  final importMap = <String, List<String>>{};
  for (final entry in coreFiles) {
    final filePath = p.join(projectRoot, entry.filePath);
    final file = File(filePath);
    if (file.existsSync()) {
      final content = file.readAsStringSync();
      final imports = _extractCoreImports(content, coreFiles);
      importMap[entry.filePath] = imports;
    }
  }

  // --- 5. Sort by dependency depth ---
  final sortResult = dependencySorter.sort(coreFiles, importMap);
  final sortedFiles = sortResult.sortedEntries;

  if (sortResult.circularGroups.isNotEmpty) {
    stdout.writeln(
        '  ⚠️ تم اكتشاف ${sortResult.circularGroups.length} مجموعة تبعيات دائرية.');
  }

  // --- 6. Count total functions for progress ---
  int totalFunctions = 0;
  final fileFunctionCounts = <String, int>{};
  for (final entry in sortedFiles) {
    final filePath = p.join(projectRoot, entry.filePath);
    final extraction = functionExtractor.extractFromFile(filePath);
    fileFunctionCounts[entry.filePath] = extraction.functions.length;
    totalFunctions += extraction.functions.length;
  }

  // Initialize progress if starting fresh
  if (progressManager.tracker.totalCoreFiles == 0) {
    await progressManager.initializeProgress(
      totalFiles: sortedFiles.length,
      totalFunctions: totalFunctions,
    );
  }

  stdout.writeln(
      '  📊 إجمالي الدوال: $totalFunctions في ${sortedFiles.length} ملف');
  stdout.writeln('');

  // --- 7. Determine starting point ---
  int startIndex = 0;
  if (resumeFrom != null) {
    final normalizedResume = resumeFrom.replaceAll(r'\', '/');
    startIndex = sortedFiles.indexWhere(
      (e) => e.filePath == normalizedResume,
    );
    if (startIndex < 0) {
      stderr.writeln('  ❌ الملف المحدد غير موجود في قائمة Core: $resumeFrom');
      exit(1);
    }
    stdout.writeln('  ▶️ استئناف من: $resumeFrom');
    stdout.writeln('');
  }

  // --- 8. Main refactoring loop: process one file at a time ---
  for (int fileIdx = startIndex; fileIdx < sortedFiles.length; fileIdx++) {
    final coreFile = sortedFiles[fileIdx];
    final filePath = p.join(projectRoot, coreFile.filePath);

    // Extract functions from this file
    final extraction = functionExtractor.extractFromFile(filePath);

    if (extraction.functions.isEmpty) {
      stdout.writeln(
          '  ⏭️ ${coreFile.filePath}: لا توجد دوال قابلة للتحليل. تخطي...');
      continue;
    }

    // Start file in progress manager
    final functionNames = extraction.functions.map((f) => f.name).toList();
    await progressManager.startFile(coreFile.filePath, functionNames);

    // Display file header
    _printFileHeader(coreFile.filePath, progressManager);

    // --- Process each function sequentially ---
    for (int funcIdx = 0; funcIdx < extraction.functions.length; funcIdx++) {
      final function = extraction.functions[funcIdx];

      // Skip already reviewed functions
      final fileProgress = progressManager.tracker.fileProgress
          .where((f) => f.filePath == coreFile.filePath)
          .firstOrNull;
      if (fileProgress != null &&
          fileProgress.reviewedFunctionNames.contains(function.name)) {
        continue;
      }

      // Display function details
      _printFunctionDetails(function);

      // --- Scan call sources ---
      final directCalls = callScanner.scanForDirectCalls(function.name);
      final indirectCalls = indirectScanner.scan(function.name);
      final allCallSources = [...directCalls, ...indirectCalls];

      // Display call sources
      _printCallSources(allCallSources);

      // --- Generate event sheet ---
      final eventSheet = eventSheetGenerator.generate(
        functionUnit: function,
        callSources: allCallSources,
        functionBody: function.body,
      );

      // Save event sheet
      await storage.saveEventSheet(
        coreFilePath: coreFile.filePath,
        functionName: function.name,
        eventSheetData: eventSheet.toJson(),
      );

      // Display event sheet
      _printEventSheet(eventSheet);

      // --- Check for dead code ---
      if (allCallSources.isEmpty) {
        final hasOverride = function.body.contains('@override');
        final isDead = deadCodeDetector.isDeadCode(
          function: function,
          directCallSources: directCalls,
          indirectCallSources: indirectCalls,
          hasOverrideAnnotation: hasOverride,
        );
        if (isDead) {
          stdout.writeln('  ⚠️ كود ميت محتمل: لا توجد استدعاءات لهذه الدالة.');
        }
      }

      // --- Build dependency map ---
      final depMap = dependencyGrapher.buildDependencyMap(
        function.name,
        rootFilePath: coreFile.filePath,
      );
      if (depMap.hasCircularChain) {
        stdout.writeln(
            '  🔄 سلسلة دائرية مكتشفة: ${depMap.circularParticipants.join(", ")}');
      }

      // --- Evaluation Gate ---
      final answers = evaluationPresenter.presentQuestions();

      // Validate answers
      final validation = answerValidator.validate(answers);
      if (!validation.isValid) {
        stdout.writeln('  ❌ إجابات غير صالحة:');
        for (final error in validation.errors) {
          stdout.writeln('     • $error');
        }
        // Mark as reviewed (pending) and continue
        await progressManager.markFunctionReviewed(
            coreFile.filePath, function.name);
        continue;
      }

      // --- Record decision ---
      final record = await decisionRecorder.recordDecision(
        functionName: function.name,
        coreFilePath: coreFile.filePath,
        question1: answers[0],
        question2: answers[1],
        question3: answers[2],
        question4: answers[3],
      );

      // --- Decision logic ---
      if (record.decision == EvaluationDecision.keepUnchanged) {
        stdout.writeln('  ✅ لا تغييرات مطلوبة. الانتقال للدالة التالية.');
        await progressManager.markFunctionReviewed(
            coreFile.filePath, function.name);
        continue;
      }

      if (record.decision == EvaluationDecision.extract) {
        // "pending review" - unsure answers only
        stdout.writeln('  📌 تم تعليم الدالة كـ "مراجعة لاحقة".');
        await progressManager.markFunctionReviewed(
            coreFile.filePath, function.name);
        continue;
      }

      // --- Modification workflow (decision == modify) ---
      stdout.writeln('');
      stdout.writeln('  🔓 تم فتح التعديل. أدخل الكود الجديد للدالة:');
      stdout.writeln('  (أدخل سطراً فارغاً ثم "END" لإنهاء الإدخال)');
      stdout.writeln('');

      final newCode = _readMultilineInput();

      if (newCode.trim().isEmpty) {
        stdout.writeln('  ⏭️ لم يتم إدخال كود. تخطي التعديل.');
        await progressManager.markFunctionReviewed(
            coreFile.filePath, function.name);
        continue;
      }

      // Save state before modification
      await reverter.saveState(coreFile.filePath);

      // Apply modification
      final modResult = await modificationApplier.applyModification(
        original: function,
        newCode: newCode,
        callSources: allCallSources,
        evaluation: record,
      );

      if (modResult.needsApproval) {
        stdout.writeln('  ⚠️ التعديل يغير السلوك الخارجي:');
        for (final diff in modResult.behaviorDifferences) {
          stdout.writeln('     • $diff');
        }
        stdout.write('  هل تريد المتابعة؟ [نعم/لا]: ');
        final approval = stdin.readLineSync()?.trim();
        if (approval != 'نعم') {
          stdout.writeln('  ⏭️ تم إلغاء التعديل.');
          await reverter.revert(coreFile.filePath, functionName: function.name);
          await progressManager.markFunctionReviewed(
              coreFile.filePath, function.name);
          continue;
        }
      } else if (!modResult.isSuccess) {
        stdout.writeln('  ❌ فشل التعديل: ${modResult.message}');
        if (modResult.compilationErrors.isNotEmpty) {
          stdout.writeln('  أخطاء التجميع:');
          for (final err in modResult.compilationErrors) {
            stdout.writeln('     • $err');
          }
        }
        // Revert
        await reverter.revert(coreFile.filePath, functionName: function.name);
        await progressManager.markFunctionReviewed(
            coreFile.filePath, function.name);
        continue;
      }

      // --- Run tests ---
      stdout.writeln('  🧪 جاري تشغيل الاختبارات...');

      final relatedTests = testFinder.findRelatedTests(
        modifiedFilePath: coreFile.filePath,
        callSources: allCallSources,
      );

      if (relatedTests.isEmpty) {
        stdout.writeln('  📋 لا توجد اختبارات آلية. توليد قائمة اختبار يدوية:');
        final checklist = checklistGenerator.generate(
          functionUnit: function,
          callSources: allCallSources,
        );
        stdout.writeln(checklist.toFormattedString());
        // Mark as refactored since modification was applied
        await progressManager.markFunctionRefactored(
            coreFile.filePath, function.name);
        reverter.clearState(coreFile.filePath);
      } else {
        final testResult = await testExecutor.executeTests(
          testFilePaths: relatedTests,
          functionName: function.name,
          filePath: coreFile.filePath,
        );

        if (testResult.isSuccess) {
          stdout.writeln(
              '  ✅ جميع الاختبارات نجحت (${testResult.passedCount} اختبار).');
          await progressManager.markFunctionRefactored(
              coreFile.filePath, function.name);
          reverter.clearState(coreFile.filePath);
        } else if (testResult.isTimeout) {
          stdout.writeln(
              '  ⏱️ تجاوز الوقت المحدد (${testResult.elapsedSeconds.toStringAsFixed(1)} ثانية).');
          stdout.writeln('  ↩️ جاري إرجاع التعديل...');
          await reverter.revert(coreFile.filePath, functionName: function.name);
          await progressManager.markFunctionReviewed(
              coreFile.filePath, function.name);
        } else if (testResult.isFailed) {
          stdout.writeln('  ❌ فشلت ${testResult.failedCount} اختبار(ات).');
          for (final failure in testResult.failures) {
            stdout.writeln('     • ${failure.testName}');
            stdout.writeln(
                '       المتوقع: ${failure.expected} | الفعلي: ${failure.actual}');
          }
          stdout.writeln('  ↩️ جاري إرجاع التعديل...');
          await reverter.revert(coreFile.filePath, functionName: function.name);
          await progressManager.markFunctionReviewed(
              coreFile.filePath, function.name);
        } else {
          // executionError or noTests
          stdout.writeln('  ⚠️ ${testResult.message}');
          await progressManager.markFunctionRefactored(
              coreFile.filePath, function.name);
          reverter.clearState(coreFile.filePath);
        }
      }

      stdout.writeln('');
    }

    // --- Verify static analysis passes before moving to next file ---
    stdout.writeln('  🔍 جاري التحقق من التحليل الثابت...');
    final analysisResult = await _runStaticAnalysis(projectRoot);
    if (analysisResult.isNotEmpty) {
      stdout.writeln('  ⚠️ أخطاء تحليل ثابت:');
      for (final error in analysisResult) {
        stdout.writeln('     • $error');
      }
      stdout.writeln('  ⚠️ يجب إصلاح الأخطاء قبل الانتقال للملف التالي.');
      // Don't exit - let the developer fix and re-run
      break;
    }

    stdout.writeln('  ✅ التحليل الثابت نظيف. الانتقال للملف التالي.');
    stdout.writeln('');
  }

  // --- Final progress display ---
  stdout.writeln('');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('  🏁 انتهت الدورة الحالية');
  stdout.writeln('═══════════════════════════════════════════════════════');
  final tracker = progressManager.tracker;
  stdout.writeln(
      '  📊 التقدم: ${tracker.reviewedFunctionUnits}/${tracker.totalFunctionUnits} '
      '(${tracker.completionPercentage.toStringAsFixed(2)}%)');
  stdout.writeln('');
}

// =============================================================================
// Helper functions
// =============================================================================

/// Extracts Core imports from file content, returning matching file paths.
List<String> _extractCoreImports(
    String content, List<CoreFileEntry> coreFiles) {
  final imports = <String>[];
  final coreFilePaths = coreFiles.map((e) => e.filePath).toSet();
  final lines = content.split('\n');

  for (final line in lines) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('import ')) continue;
    if (trimmed.startsWith('//')) continue;

    // Extract the import path
    final match = RegExp("import\\s+['\"]([^'\"]+)['\"]").firstMatch(trimmed);
    if (match == null) continue;

    final importPath = match.group(1)!;

    // Check if this import matches any core file
    for (final corePath in coreFilePaths) {
      // Match package imports or relative imports
      if (importPath.contains(corePath) ||
          importPath.endsWith(p.basename(corePath))) {
        imports.add(corePath);
        break;
      }
    }
  }

  return imports;
}

/// Prints the file header with progress info.
void _printFileHeader(String filePath, ProgressManager progressManager) {
  final tracker = progressManager.tracker;
  final percentage = tracker.completionPercentage.toStringAsFixed(2);

  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('  📁 الملف: $filePath');
  stdout.writeln(
      '  📊 التقدم: ${tracker.reviewedFunctionUnits}/${tracker.totalFunctionUnits} دالة ($percentage%)');
  stdout.writeln('═══════════════════════════════════════════════════════');
  stdout.writeln('');
}

/// Prints function details.
void _printFunctionDetails(FunctionUnit function) {
  stdout.writeln('━━━ الدالة: ${function.name} ━━━');
  stdout.writeln('  النوع: ${function.type.name}');
  if (function.params.isNotEmpty) {
    final paramStr =
        function.params.map((p) => '${p.type} ${p.name}').join(', ');
    stdout.writeln('  المعاملات: ($paramStr)');
  } else {
    stdout.writeln('  المعاملات: ()');
  }
  stdout.writeln('  الإرجاع: ${function.returnType}');
  stdout.writeln(
      '  الأسطر: ${function.lineCount} سطر (سطر ${function.startLine} → ${function.endLine})');
  stdout.writeln('');
}

/// Prints call sources grouped by file.
void _printCallSources(List<CallSource> callSources) {
  if (callSources.isEmpty) {
    stdout.writeln('━━━ مصادر الاستدعاء (0) ━━━');
    stdout.writeln('  لا توجد استدعاءات معروفة.');
    stdout.writeln('');
    return;
  }

  stdout.writeln('━━━ مصادر الاستدعاء (${callSources.length}) ━━━');

  // Group by file path
  final grouped = <String, List<CallSource>>{};
  for (final source in callSources) {
    grouped.putIfAbsent(source.filePath, () => []).add(source);
  }

  final sortedPaths = grouped.keys.toList()..sort();
  for (final path in sortedPaths) {
    stdout.writeln('  📍 $path');
    for (final source in grouped[path]!) {
      final typeLabel = switch (source.callType) {
        CallType.direct => 'مباشر',
        CallType.providerRead => 'Provider.read',
        CallType.providerWatch => 'Provider.watch',
        CallType.callback => 'callback',
        CallType.streamListen => 'Stream.listen',
        CallType.methodChannel => 'MethodChannel',
      };
      stdout.writeln(
          '     → ${source.callingFunction} [سطر ${source.lineNumber}] ($typeLabel)');
    }
  }
  stdout.writeln('');
}

/// Prints event sheet summary.
void _printEventSheet(EventSheet eventSheet) {
  stdout.writeln('━━━ خريطة الأحداث ━━━');

  if (eventSheet.isEventIsolated) {
    stdout.writeln('  🔇 الدالة معزولة عن الأحداث (لا واردة ولا صادرة)');
  } else {
    if (eventSheet.incomingEvents.isNotEmpty) {
      final incomingNames = eventSheet.incomingEvents
          .map((e) => e.targetOrSource)
          .toSet()
          .join(', ');
      stdout.writeln('  ⬇️ واردة: $incomingNames');
    }
    if (eventSheet.outgoingEvents.isNotEmpty) {
      final outgoingNames = eventSheet.outgoingEvents
          .map((e) => e.targetOrSource)
          .toSet()
          .join(', ');
      stdout.writeln('  ⬆️ صادرة: $outgoingNames');
    }
  }
  stdout.writeln('');
}

/// Reads multiline input from stdin until "END" is entered on its own line.
String _readMultilineInput() {
  final buffer = StringBuffer();
  while (true) {
    final line = stdin.readLineSync();
    if (line == null || line.trim() == 'END') break;
    buffer.writeln(line);
  }
  return buffer.toString();
}

/// Runs `dart analyze` and returns list of errors (empty if clean).
Future<List<String>> _runStaticAnalysis(String projectRoot) async {
  try {
    final result = await Process.run(
      'dart',
      ['analyze', '--no-fatal-warnings'],
      workingDirectory: projectRoot,
    );

    if (result.exitCode == 0) {
      return [];
    }

    final output = '${result.stdout}\n${result.stderr}'.trim();
    final errors = <String>[];

    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty &&
          (trimmed.contains('error') || trimmed.contains('Error'))) {
        errors.add(trimmed);
      }
    }

    if (errors.isEmpty && result.exitCode != 0) {
      errors.add('dart analyze exited with code ${result.exitCode}');
    }

    return errors;
  } catch (e) {
    return ['فشل تشغيل dart analyze: $e'];
  }
}
