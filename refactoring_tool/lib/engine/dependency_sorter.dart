import 'package:refactoring_tool/models/core_file_entry.dart';

/// نتيجة فرز التبعيات تشمل القائمة المرتبة ومجموعات التبعيات الدائرية
class DependencySortResult {
  /// القائمة المرتبة حسب عمق التبعية (الأقل أولاً)
  final List<CoreFileEntry> sortedEntries;

  /// مجموعات التبعيات الدائرية (كل مجموعة تحتوي مسارات الملفات المتبادلة)
  final List<Set<String>> circularGroups;

  const DependencySortResult({
    required this.sortedEntries,
    required this.circularGroups,
  });
}

/// يرتب ملفات Core حسب عمق التبعية ويكتشف التبعيات الدائرية
class DependencySorter {
  /// يرتب قائمة [CoreFileEntry] حسب عمق التبعية.
  ///
  /// - [entries]: قائمة الملفات الأساسية المراد ترتيبها
  /// - [importMap]: خريطة تربط مسار كل ملف بقائمة مسارات ملفات Core التي يستوردها
  ///
  /// يُرجع [DependencySortResult] يحتوي القائمة المرتبة مع تحديث circularDeps
  /// والملفات ذات التبعيات الدائرية مجمّعة معاً.
  DependencySortResult sort(
    List<CoreFileEntry> entries,
    Map<String, List<String>> importMap,
  ) {
    if (entries.isEmpty) {
      return const DependencySortResult(
        sortedEntries: [],
        circularGroups: [],
      );
    }

    // مجموعة مسارات الملفات الأساسية للتحقق السريع
    final coreFilePaths = entries.map((e) => e.filePath).toSet();

    // تصفية importMap لتشمل فقط imports لملفات Core
    final filteredImportMap = <String, List<String>>{};
    for (final entry in entries) {
      final imports = importMap[entry.filePath] ?? [];
      filteredImportMap[entry.filePath] =
          imports.where((imp) => coreFilePaths.contains(imp)).toList();
    }

    // اكتشاف التبعيات الدائرية
    final circularGroups = _detectCircularDependencies(filteredImportMap);

    // بناء خريطة الملفات المتأثرة بتبعيات دائرية
    final circularDepsMap = <String, List<String>>{};
    for (final group in circularGroups) {
      for (final filePath in group) {
        circularDepsMap[filePath] =
            group.where((other) => other != filePath).toList();
      }
    }

    // حساب عمق التبعية لكل ملف (عدد imports لملفات Core أخرى)
    final updatedEntries = entries.map((entry) {
      final coreImports = filteredImportMap[entry.filePath] ?? [];
      final circularDeps = circularDepsMap[entry.filePath] ?? [];

      return entry.copyWith(
        dependencyDepth: coreImports.length,
        circularDeps: circularDeps,
      );
    }).toList();

    // ترتيب حسب عمق التبعية تصاعدياً مع تجميع الملفات الدائرية معاً
    updatedEntries.sort((a, b) {
      final depthComparison = a.dependencyDepth.compareTo(b.dependencyDepth);
      if (depthComparison != 0) return depthComparison;

      // إذا كانا في نفس المجموعة الدائرية، ضعهما متجاورين
      final aGroup = _findCircularGroup(a.filePath, circularGroups);
      final bGroup = _findCircularGroup(b.filePath, circularGroups);

      if (aGroup != null && bGroup != null && aGroup == bGroup) {
        // نفس المجموعة - رتب أبجدياً للثبات
        return a.filePath.compareTo(b.filePath);
      }

      // ملفات ذات تبعيات دائرية تُجمع معاً
      if (a.circularDeps.isNotEmpty && b.circularDeps.isEmpty) return 1;
      if (a.circularDeps.isEmpty && b.circularDeps.isNotEmpty) return -1;

      return a.filePath.compareTo(b.filePath);
    });

    // إعادة ترتيب لضمان تجميع الملفات الدائرية معاً
    final result = _groupCircularEntries(updatedEntries, circularGroups);

    return DependencySortResult(
      sortedEntries: result,
      circularGroups: circularGroups,
    );
  }

  /// يكتشف التبعيات الدائرية بين الملفات.
  /// يُرجع قائمة من المجموعات، كل مجموعة تحتوي ملفات متبادلة التبعية.
  List<Set<String>> _detectCircularDependencies(
    Map<String, List<String>> importMap,
  ) {
    final circularPairs = <Set<String>>{};

    for (final filePath in importMap.keys) {
      final imports = importMap[filePath] ?? [];
      for (final importedFile in imports) {
        // تحقق: هل الملف المستورد يستورد الملف الحالي أيضاً؟
        final reverseImports = importMap[importedFile] ?? [];
        if (reverseImports.contains(filePath)) {
          // تبعية دائرية مكتشفة
          final pair = {filePath, importedFile};
          circularPairs.add(pair);
        }
      }
    }

    // دمج الأزواج المتداخلة في مجموعات أكبر
    final groups = _mergeOverlappingGroups(circularPairs.toList());
    return groups;
  }

  /// يدمج مجموعات متداخلة (تشترك في عنصر واحد على الأقل) في مجموعة واحدة.
  List<Set<String>> _mergeOverlappingGroups(List<Set<String>> pairs) {
    if (pairs.isEmpty) return [];

    final groups = <Set<String>>[];

    for (final pair in pairs) {
      // ابحث عن مجموعة موجودة تتقاطع مع هذا الزوج
      Set<String>? matchingGroup;
      for (final group in groups) {
        if (group.intersection(pair).isNotEmpty) {
          matchingGroup = group;
          break;
        }
      }

      if (matchingGroup != null) {
        matchingGroup.addAll(pair);
      } else {
        groups.add(Set<String>.from(pair));
      }
    }

    // مرور ثانٍ لدمج أي مجموعات أصبحت متداخلة بعد الإضافة
    bool merged = true;
    while (merged) {
      merged = false;
      for (int i = 0; i < groups.length; i++) {
        for (int j = i + 1; j < groups.length; j++) {
          if (groups[i].intersection(groups[j]).isNotEmpty) {
            groups[i].addAll(groups[j]);
            groups.removeAt(j);
            merged = true;
            break;
          }
        }
        if (merged) break;
      }
    }

    return groups;
  }

  /// يبحث عن المجموعة الدائرية التي ينتمي إليها ملف معين.
  Set<String>? _findCircularGroup(
    String filePath,
    List<Set<String>> circularGroups,
  ) {
    for (final group in circularGroups) {
      if (group.contains(filePath)) return group;
    }
    return null;
  }

  /// يعيد ترتيب القائمة لضمان أن الملفات في نفس المجموعة الدائرية متجاورة.
  List<CoreFileEntry> _groupCircularEntries(
    List<CoreFileEntry> entries,
    List<Set<String>> circularGroups,
  ) {
    if (circularGroups.isEmpty) return entries;

    final result = <CoreFileEntry>[];
    final processed = <String>{};

    for (final entry in entries) {
      if (processed.contains(entry.filePath)) continue;

      final group = _findCircularGroup(entry.filePath, circularGroups);
      if (group != null) {
        // أضف جميع أعضاء المجموعة الدائرية معاً
        final groupEntries = entries
            .where((e) => group.contains(e.filePath))
            .toList()
          ..sort((a, b) => a.filePath.compareTo(b.filePath));

        for (final groupEntry in groupEntries) {
          if (!processed.contains(groupEntry.filePath)) {
            result.add(groupEntry);
            processed.add(groupEntry.filePath);
          }
        }
      } else {
        result.add(entry);
        processed.add(entry.filePath);
      }
    }

    return result;
  }
}
