import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:refactoring_tool/models/core_file_entry.dart';

/// يمسح مجلدات Core ويُرجع قائمة بالملفات الأساسية مع عدد imports المباشرة
class FileScanner {
  /// المجلدات الأساسية التي يتم مسحها
  static const List<String> coreDirectories = [
    'lib/controllers',
    'lib/services',
    'lib/models',
    'lib/providers',
    'lib/core',
  ];

  /// أنماط الملفات المستبعدة
  static const List<String> excludedPatterns = [
    '.g.dart',
    '.freezed.dart',
  ];

  /// أسماء المجلدات المستبعدة
  static const List<String> excludedDirectories = [
    'generated',
    'build',
    '.dart_tool',
  ];

  final String projectRoot;

  FileScanner({required this.projectRoot});

  /// يمسح جميع مجلدات Core ويُرجع قائمة CoreFileEntry
  ///
  /// يرمي [FileScannerException] إذا لم يتم العثور على أي ملفات
  List<CoreFileEntry> scan() {
    final List<CoreFileEntry> entries = [];

    for (final dir in coreDirectories) {
      final dirPath = p.join(projectRoot, dir);
      final directory = Directory(dirPath);

      if (!directory.existsSync()) {
        continue;
      }

      final files = _scanDirectory(directory);
      entries.addAll(files);
    }

    if (entries.isEmpty) {
      throw FileScannerException(
        'لم يتم العثور على أي ملفات Core في المجلدات المحددة. '
        'تم مسح: ${coreDirectories.join(", ")}',
      );
    }

    return entries;
  }

  /// يمسح مجلد واحد بشكل متكرر ويُرجع الملفات المؤهلة
  List<CoreFileEntry> _scanDirectory(Directory directory) {
    final List<CoreFileEntry> entries = [];

    final entities = directory.listSync(recursive: true);

    for (final entity in entities) {
      if (entity is! File) continue;

      final filePath = entity.path;

      // تحقق أن الملف هو .dart
      if (!filePath.endsWith('.dart')) continue;

      // استبعاد الملفات المولدة
      if (_isExcludedFile(filePath)) continue;

      // استبعاد الملفات في مجلدات مستبعدة
      if (_isInExcludedDirectory(filePath)) continue;

      // حساب عدد imports المباشرة لملفات Core أخرى
      final importCount = _countCoreImports(entity);

      // المسار النسبي من جذر المشروع
      final relativePath = p.relative(filePath, from: projectRoot);
      // توحيد الفواصل لتكون forward slashes
      final normalizedPath = relativePath.replaceAll(r'\', '/');

      entries.add(CoreFileEntry(
        filePath: normalizedPath,
        directImportCount: importCount,
        dependencyDepth:
            importCount, // سيتم تحسينه لاحقاً بواسطة dependency_sorter
      ));
    }

    return entries;
  }

  /// يتحقق إذا كان الملف مستبعداً بناءً على اسمه
  bool _isExcludedFile(String filePath) {
    final fileName = p.basename(filePath);
    return excludedPatterns.any((pattern) => fileName.endsWith(pattern));
  }

  /// يتحقق إذا كان الملف في مجلد مستبعد
  bool _isInExcludedDirectory(String filePath) {
    final parts = p.split(filePath);
    return parts.any((part) => excludedDirectories.contains(part));
  }

  /// يحسب عدد import statements التي تشير إلى مجلدات Core أخرى
  int _countCoreImports(File file) {
    final content = file.readAsStringSync();
    final lines = content.split('\n');
    int count = 0;

    // أنماط import التي تشير إلى مجلدات Core
    final coreImportPatterns = [
      RegExp(r'''import\s+['"].*[/\\]controllers[/\\]'''),
      RegExp(r'''import\s+['"].*[/\\]services[/\\]'''),
      RegExp(r'''import\s+['"].*[/\\]models[/\\]'''),
      RegExp(r'''import\s+['"].*[/\\]providers[/\\]'''),
      RegExp(r'''import\s+['"].*[/\\]core[/\\]'''),
      // أنماط package imports
      RegExp(r'''import\s+['"]package:[^'"]+/controllers/'''),
      RegExp(r'''import\s+['"]package:[^'"]+/services/'''),
      RegExp(r'''import\s+['"]package:[^'"]+/models/'''),
      RegExp(r'''import\s+['"]package:[^'"]+/providers/'''),
      RegExp(r'''import\s+['"]package:[^'"]+/core/'''),
    ];

    for (final line in lines) {
      final trimmed = line.trim();

      // تخطي التعليقات
      if (trimmed.startsWith('//') || trimmed.startsWith('/*')) continue;

      // تحقق إذا كان السطر import statement يشير إلى Core
      if (trimmed.startsWith('import ')) {
        for (final pattern in coreImportPatterns) {
          if (pattern.hasMatch(trimmed)) {
            count++;
            break; // لا نحسب نفس السطر مرتين
          }
        }
      }
    }

    return count;
  }
}

/// استثناء يُرمى عند فشل عملية المسح
class FileScannerException implements Exception {
  final String message;

  FileScannerException(this.message);

  @override
  String toString() => 'FileScannerException: $message';
}
