import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:refactoring_tool/models/call_source.dart';

/// يبحث عن ملفات الاختبار المرتبطة بملف معدّل أو بمصادر استدعاء دالة معدّلة.
///
/// يمسح مجلد `test/` للعثور على ملفات `.dart` التي:
/// 1. تستورد الملف المعدّل مباشرة
/// 2. تستورد ملفات تحتوي على مصادر استدعاء (Call_Sources) للدالة المعدّلة
///
/// يُرجع قائمة بمسارات ملفات الاختبار المرتبطة.
class TestFinder {
  final String projectRoot;

  TestFinder({required this.projectRoot});

  /// يبحث عن ملفات الاختبار المرتبطة بالملف المعدّل ومصادر الاستدعاء.
  ///
  /// [modifiedFilePath] — المسار النسبي للملف المعدّل (مثل `lib/services/note_service.dart`)
  /// [callSources] — قائمة مصادر الاستدعاء للدالة المعدّلة
  ///
  /// يُرجع قائمة مسارات ملفات الاختبار (نسبية من جذر المشروع).
  List<String> findRelatedTests({
    required String modifiedFilePath,
    required List<CallSource> callSources,
  }) {
    final testDir = Directory(p.join(projectRoot, 'test'));
    if (!testDir.existsSync()) {
      return [];
    }

    final testFiles = _collectTestFiles(testDir);
    if (testFiles.isEmpty) {
      return [];
    }

    // جمع المسارات التي نبحث عنها في imports
    final targetPaths = _buildTargetPaths(modifiedFilePath, callSources);

    final Set<String> relatedTests = {};

    for (final testFile in testFiles) {
      if (_testFileImportsAny(testFile, targetPaths)) {
        final relativePath = p.relative(testFile.path, from: projectRoot);
        final normalizedPath = relativePath.replaceAll(r'\', '/');
        relatedTests.add(normalizedPath);
      }
    }

    // ترتيب أبجدي
    final result = relatedTests.toList()..sort();
    return result;
  }

  /// يجمع جميع ملفات .dart في مجلد test/
  List<File> _collectTestFiles(Directory testDir) {
    final List<File> testFiles = [];

    try {
      final entities = testDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;
        testFiles.add(entity);
      }
    } catch (_) {
      // تخطي إذا لم يمكن قراءة المجلد
      return [];
    }

    return testFiles;
  }

  /// يبني قائمة المسارات المستهدفة للبحث عنها في imports
  ///
  /// تشمل:
  /// - الملف المعدّل نفسه
  /// - ملفات تحتوي على مصادر استدعاء (Call_Sources)
  Set<String> _buildTargetPaths(
    String modifiedFilePath,
    List<CallSource> callSources,
  ) {
    final Set<String> targets = {};

    // إضافة الملف المعدّل
    targets.add(_normalizeForImportMatch(modifiedFilePath));

    // إضافة ملفات مصادر الاستدعاء
    for (final source in callSources) {
      targets.add(_normalizeForImportMatch(source.filePath));
    }

    return targets;
  }

  /// يُطبّع المسار ليكون قابلاً للمطابقة مع import statements
  ///
  /// يحوّل المسار إلى شكل يمكن مطابقته سواء كان import نسبي أو package import.
  /// مثال: `lib/services/note_service.dart` → `services/note_service.dart`
  String _normalizeForImportMatch(String filePath) {
    // توحيد الفواصل
    final normalized = filePath.replaceAll(r'\', '/');

    // إزالة بادئة lib/ إذا وجدت (لمطابقة package imports)
    if (normalized.startsWith('lib/')) {
      return normalized.substring(4); // إزالة 'lib/'
    }

    return normalized;
  }

  /// يتحقق إذا كان ملف اختبار يستورد أي من المسارات المستهدفة
  bool _testFileImportsAny(File testFile, Set<String> targetPaths) {
    final String content;
    try {
      content = testFile.readAsStringSync();
    } catch (_) {
      return false;
    }

    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();

      // تخطي غير import statements
      if (!trimmed.startsWith('import ')) continue;

      // تخطي التعليقات
      if (trimmed.startsWith('//')) continue;

      // استخراج مسار الـ import
      final importPath = _extractImportPath(trimmed);
      if (importPath == null) continue;

      // مطابقة مع المسارات المستهدفة
      if (_importMatchesAnyTarget(importPath, targetPaths)) {
        return true;
      }
    }

    return false;
  }

  /// يستخرج مسار الـ import من سطر import statement
  ///
  /// مثال: `import 'package:app/services/note_service.dart';` → `package:app/services/note_service.dart`
  /// مثال: `import '../services/note_service.dart';` → `../services/note_service.dart`
  String? _extractImportPath(String importLine) {
    // مطابقة import 'path' أو import "path"
    final singleQuoteMatch =
        RegExp(r"import\s+'([^']+)'").firstMatch(importLine);
    if (singleQuoteMatch != null) {
      return singleQuoteMatch.group(1);
    }

    final doubleQuoteMatch =
        RegExp(r'import\s+"([^"]+)"').firstMatch(importLine);
    if (doubleQuoteMatch != null) {
      return doubleQuoteMatch.group(1);
    }

    return null;
  }

  /// يتحقق إذا كان مسار import يطابق أي من المسارات المستهدفة
  bool _importMatchesAnyTarget(String importPath, Set<String> targetPaths) {
    for (final target in targetPaths) {
      // مطابقة package import: package:app_name/services/note_service.dart
      // نبحث عن الجزء بعد package:name/ ونقارنه مع target
      if (importPath.startsWith('package:')) {
        final packagePath = _extractPackagePath(importPath);
        if (packagePath != null && packagePath == target) {
          return true;
        }
        // مطابقة جزئية: إذا انتهى بنفس المسار
        if (packagePath != null && packagePath.endsWith(target)) {
          return true;
        }
        if (target.endsWith(packagePath ?? '')) {
          return true;
        }
      }

      // مطابقة relative import: يحتوي على اسم الملف
      // مثال: '../services/note_service.dart' يطابق 'services/note_service.dart'
      final normalizedImport = importPath.replaceAll(r'\', '/');

      if (normalizedImport.endsWith(target)) {
        return true;
      }

      // مطابقة عكسية: target ينتهي بنفس الملف
      if (target.endsWith(p.basename(normalizedImport)) &&
          _pathSegmentsMatch(normalizedImport, target)) {
        return true;
      }
    }

    return false;
  }

  /// يستخرج المسار بعد package:name/ من package import
  ///
  /// مثال: `package:sinan_note/services/note_service.dart` → `services/note_service.dart`
  String? _extractPackagePath(String packageImport) {
    final match = RegExp(r'package:[^/]+/(.+)').firstMatch(packageImport);
    return match?.group(1);
  }

  /// يتحقق من تطابق أجزاء المسار (للتعامل مع relative imports)
  ///
  /// يزيل `../` و `./` ويقارن الأجزاء المتبقية
  bool _pathSegmentsMatch(String importPath, String targetPath) {
    // إزالة relative prefixes
    final cleanImport = importPath
        .replaceAll(RegExp(r'^(\.\./)+'), '')
        .replaceAll(RegExp(r'^\./'), '');

    final cleanTarget = targetPath
        .replaceAll(RegExp(r'^(\.\./)+'), '')
        .replaceAll(RegExp(r'^\./'), '');

    // مقارنة: أحدهما ينتهي بالآخر
    return cleanImport.endsWith(cleanTarget) ||
        cleanTarget.endsWith(cleanImport);
  }
}
