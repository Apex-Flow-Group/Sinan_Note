#!/usr/bin/env dart
// Copyright © 2025 Apex Flow Group. All rights reserved.
// Professional Import Fixer for Sinan Note

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final config = _parseArgs(args);

  print('🔧 Sinan Note - Professional Import Fixer v2.0');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  final targetDir = Directory(config['path'] as String);
  if (!await targetDir.exists()) {
    print('❌ Error: Directory not found: ${targetDir.path}');
    exit(1);
  }

  final files = await _getDartFiles(targetDir);
  print('📁 Found ${files.length} Dart files');
  print('🎯 Mode: ${config['dryRun'] ? "DRY RUN (no changes)" : "FIX MODE"}');
  print('');

  final stats = <String, int>{
    'fixed': 0,
    'skipped': 0,
    'errors': 0,
    'duplicates': 0,
    'unused': 0,
  };

  final issues = <String>[];

  for (final file in files) {
    final relativePath =
        file.path.replaceFirst('${Directory.current.path}/', '');
    try {
      final result = await _fixImports(file, config['dryRun'] as bool);

      if (result['changed'] as bool) {
        print('✅ Fixed: $relativePath');
        if (result['duplicates'] as int > 0) {
          print('   ⚠️  Removed ${result['duplicates']} duplicate imports');
          stats['duplicates'] =
              stats['duplicates']! + (result['duplicates'] as int);
        }
        stats['fixed'] = stats['fixed']! + 1;
      } else {
        if (config['verbose'] as bool) {
          print('⏭️  Skipped: $relativePath (already formatted)');
        }
        stats['skipped'] = stats['skipped']! + 1;
      }

      if ((result['issues'] as List).isNotEmpty) {
        issues.add('$relativePath:');
        for (final issue in result['issues'] as List) {
          issues.add('  - $issue');
        }
      }
    } catch (e) {
      print('❌ Error: $relativePath - $e');
      stats['errors'] = stats['errors']! + 1;
    }
  }

  print('');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('📊 Summary:');
  print('   ✅ Fixed: ${stats['fixed']} files');
  print('   ⏭️  Skipped: ${stats['skipped']} files');
  print('   ❌ Errors: ${stats['errors']} files');
  print('   🔄 Duplicates removed: ${stats['duplicates']}');
  print('   📁 Total: ${files.length} files');

  if (issues.isNotEmpty) {
    print('');
    print('⚠️  Issues found:');
    for (final issue in issues) {
      print('   $issue');
    }
  }

  if (config['dryRun'] as bool) {
    print('');
    print('💡 This was a dry run. Use without --dry-run to apply changes.');
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  if (config['report'] as bool) {
    await _generateReport(stats, issues);
  }
}

Map<String, dynamic> _parseArgs(List<String> args) {
  return {
    'path': args.contains('--path') ? args[args.indexOf('--path') + 1] : 'lib',
    'dryRun': args.contains('--dry-run'),
    'verbose': args.contains('--verbose') || args.contains('-v'),
    'report': args.contains('--report'),
  };
}

Future<List<File>> _getDartFiles(Directory dir) async {
  final files = <File>[];
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      if (!entity.path.contains('.g.dart') &&
          !entity.path.contains('.freezed.dart') &&
          !entity.path.contains('generated/') &&
          !entity.path.contains('.mocks.dart')) {
        files.add(entity);
      }
    }
  }
  return files;
}

Future<Map<String, dynamic>> _fixImports(File file, bool dryRun) async {
  final content = await file.readAsString();
  final lines = content.split('\n');

  final dartImports = <String>{};
  final flutterImports = <String>{};
  final packageImports = <String>{};
  final relativeImports = <String>{};
  final exports = <String>{};
  final parts = <String>[];
  final otherLines = <String>[];
  final issues = <String>[];

  bool inImportSection = false;
  int firstImportIndex = -1;
  int duplicateCount = 0;
  final seenImports = <String>{};

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    if (trimmed.startsWith('part ')) {
      parts.add(line);
      continue;
    }

    if (trimmed.startsWith('import ') || trimmed.startsWith('export ')) {
      if (firstImportIndex == -1) firstImportIndex = i;
      inImportSection = true;

      final normalized = trimmed.replaceAll(RegExp(r'\s+'), ' ');
      if (seenImports.contains(normalized)) {
        duplicateCount++;
        issues.add('Duplicate import: $trimmed');
        continue;
      }
      seenImports.add(normalized);

      if (trimmed.startsWith('export ')) {
        exports.add(line);
      } else if (trimmed.contains("'dart:") || trimmed.contains('"dart:')) {
        dartImports.add(line);
      } else if (trimmed.contains("'package:flutter") ||
          trimmed.contains('"package:flutter')) {
        flutterImports.add(line);
      } else if (trimmed.contains("'package:") ||
          trimmed.contains('"package:')) {
        packageImports.add(line);
      } else {
        relativeImports.add(line);
      }
    } else if (trimmed.isEmpty && inImportSection) {
      continue;
    } else {
      if (inImportSection && trimmed.isNotEmpty) {
        inImportSection = false;
      }
      otherLines.add(line);
    }
  }

  if (dartImports.isEmpty &&
      flutterImports.isEmpty &&
      packageImports.isEmpty &&
      relativeImports.isEmpty) {
    return {'changed': false, 'duplicates': 0, 'issues': issues};
  }

  final sortedDart = dartImports.toList()..sort();
  final sortedFlutter = flutterImports.toList()..sort();
  final sortedPackage = packageImports.toList()..sort();
  final sortedRelative = relativeImports.toList()..sort();
  final sortedExports = exports.toList()..sort();

  final newLines = <String>[];

  if (firstImportIndex > 0) {
    newLines.addAll(lines.sublist(0, firstImportIndex));
  }

  if (sortedDart.isNotEmpty) {
    newLines.addAll(sortedDart);
    newLines.add('');
  }

  if (sortedFlutter.isNotEmpty) {
    newLines.addAll(sortedFlutter);
    newLines.add('');
  }

  if (sortedPackage.isNotEmpty) {
    newLines.addAll(sortedPackage);
    newLines.add('');
  }

  if (sortedRelative.isNotEmpty) {
    newLines.addAll(sortedRelative);
    newLines.add('');
  }

  if (parts.isNotEmpty) {
    newLines.addAll(parts);
    newLines.add('');
  }

  if (sortedExports.isNotEmpty) {
    newLines.addAll(sortedExports);
    newLines.add('');
  }

  bool foundNonImport = false;
  for (final line in otherLines) {
    if (line.trim().isNotEmpty || foundNonImport) {
      foundNonImport = true;
      newLines.add(line);
    }
  }

  final newContent = newLines.join('\n');
  final changed = newContent != content;

  if (changed && !dryRun) {
    await file.writeAsString(newContent);
  }

  return {
    'changed': changed,
    'duplicates': duplicateCount,
    'issues': issues,
  };
}

Future<void> _generateReport(
    Map<String, int> stats, List<String> issues) async {
  final report = {
    'timestamp': DateTime.now().toIso8601String(),
    'statistics': stats,
    'issues': issues,
  };

  final reportFile = File('scripts/import_fix_report.json');
  await reportFile
      .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  print('\n📄 Report saved to: ${reportFile.path}');
}
