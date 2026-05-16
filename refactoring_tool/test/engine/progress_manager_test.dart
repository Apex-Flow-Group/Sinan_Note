import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:refactoring_tool/engine/progress_manager.dart';
import 'package:refactoring_tool/models/core_file_entry.dart';
import 'package:refactoring_tool/storage/storage_manager.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late StorageManager storage;
  late ProgressManager manager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('progress_manager_test_');
    storage = StorageManager(projectRoot: tempDir.path);
    await storage.initialize();
    manager = ProgressManager(storage: storage);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('ProgressManager', () {
    group('initializeProgress', () {
      test('sets total files and functions correctly', () async {
        await manager.initializeProgress(totalFiles: 10, totalFunctions: 50);

        expect(manager.tracker.totalCoreFiles, 10);
        expect(manager.tracker.totalFunctionUnits, 50);
        expect(manager.tracker.completedCoreFiles, 0);
        expect(manager.tracker.reviewedFunctionUnits, 0);
        expect(manager.tracker.completionPercentage, 0.0);
      });

      test('persists progress to storage', () async {
        await manager.initializeProgress(totalFiles: 5, totalFunctions: 20);

        final data = await storage.loadProgress();
        expect(data, isNotNull);
        expect(data!['totalCoreFiles'], 5);
        expect(data['totalFunctionUnits'], 20);
      });
    });

    group('startFile', () {
      test('sets file status to inProgress', () async {
        await manager.initializeProgress(totalFiles: 2, totalFunctions: 5);

        await manager.startFile(
            'lib/models/note.dart', ['toMap', 'fromMap', 'copyWith']);

        final fileProgress = manager.tracker.fileProgress;
        expect(fileProgress.length, 1);
        expect(fileProgress[0].filePath, 'lib/models/note.dart');
        expect(fileProgress[0].status, CoreFileStatus.inProgress);
        expect(fileProgress[0].totalFunctions, 3);
        expect(fileProgress[0].reviewedFunctions, 0);
        expect(fileProgress[0].pendingFunctionNames,
            ['toMap', 'fromMap', 'copyWith']);
      });

      test('replaces existing file entry if called again', () async {
        await manager.initializeProgress(totalFiles: 2, totalFunctions: 5);

        await manager.startFile('lib/models/note.dart', ['toMap', 'fromMap']);
        await manager.startFile(
            'lib/models/note.dart', ['toMap', 'fromMap', 'copyWith']);

        expect(manager.tracker.fileProgress.length, 1);
        expect(manager.tracker.fileProgress[0].totalFunctions, 3);
      });
    });

    group('markFunctionReviewed', () {
      test('increments reviewed count and updates percentage', () async {
        await manager.initializeProgress(totalFiles: 1, totalFunctions: 3);
        await manager.startFile(
            'lib/models/note.dart', ['toMap', 'fromMap', 'copyWith']);

        await manager.markFunctionReviewed('lib/models/note.dart', 'toMap');

        expect(manager.tracker.reviewedFunctionUnits, 1);
        expect(manager.tracker.fileProgress[0].reviewedFunctions, 1);
        expect(manager.tracker.fileProgress[0].reviewedFunctionNames,
            contains('toMap'));
        expect(manager.tracker.fileProgress[0].pendingFunctionNames,
            isNot(contains('toMap')));
        // 1/3 * 100 ≈ 33.33
        expect(manager.tracker.completionPercentage, closeTo(33.33, 0.01));
      });

      test('does not double-count already reviewed function', () async {
        await manager.initializeProgress(totalFiles: 1, totalFunctions: 2);
        await manager.startFile('lib/models/note.dart', ['toMap', 'fromMap']);

        await manager.markFunctionReviewed('lib/models/note.dart', 'toMap');
        await manager.markFunctionReviewed('lib/models/note.dart', 'toMap');

        expect(manager.tracker.reviewedFunctionUnits, 1);
        expect(manager.tracker.fileProgress[0].reviewedFunctions, 1);
      });

      test('sets file to completed when all functions reviewed', () async {
        await manager.initializeProgress(totalFiles: 1, totalFunctions: 2);
        await manager.startFile('lib/models/note.dart', ['toMap', 'fromMap']);

        await manager.markFunctionReviewed('lib/models/note.dart', 'toMap');
        await manager.markFunctionReviewed('lib/models/note.dart', 'fromMap');

        expect(
            manager.tracker.fileProgress[0].status, CoreFileStatus.completed);
        expect(manager.tracker.completedCoreFiles, 1);
        expect(manager.tracker.completionPercentage, 100.0);
      });

      test('ignores unknown file path', () async {
        await manager.initializeProgress(totalFiles: 1, totalFunctions: 2);
        await manager.startFile('lib/models/note.dart', ['toMap', 'fromMap']);

        await manager.markFunctionReviewed('lib/unknown.dart', 'toMap');

        expect(manager.tracker.reviewedFunctionUnits, 0);
      });
    });

    group('markFunctionRefactored', () {
      test('works the same as markFunctionReviewed for progress', () async {
        await manager.initializeProgress(totalFiles: 1, totalFunctions: 2);
        await manager.startFile('lib/models/note.dart', ['toMap', 'fromMap']);

        await manager.markFunctionRefactored('lib/models/note.dart', 'toMap');

        expect(manager.tracker.reviewedFunctionUnits, 1);
        expect(manager.tracker.fileProgress[0].reviewedFunctions, 1);
        expect(manager.tracker.completionPercentage, 50.0);
      });
    });

    group('completeFile', () {
      test('sets file status to completed', () async {
        await manager.initializeProgress(totalFiles: 2, totalFunctions: 4);
        await manager.startFile('lib/models/note.dart', ['toMap', 'fromMap']);

        await manager.completeFile('lib/models/note.dart');

        expect(
            manager.tracker.fileProgress[0].status, CoreFileStatus.completed);
        expect(manager.tracker.completedCoreFiles, 1);
      });

      test('ignores already completed file', () async {
        await manager.initializeProgress(totalFiles: 1, totalFunctions: 2);
        await manager.startFile('lib/models/note.dart', ['toMap', 'fromMap']);

        await manager.completeFile('lib/models/note.dart');
        await manager.completeFile('lib/models/note.dart');

        expect(manager.tracker.completedCoreFiles, 1);
      });

      test('ignores unknown file path', () async {
        await manager.initializeProgress(totalFiles: 1, totalFunctions: 2);

        await manager.completeFile('lib/unknown.dart');

        expect(manager.tracker.completedCoreFiles, 0);
      });
    });

    group('load', () {
      test('loads existing progress from storage', () async {
        // Save progress first
        await manager.initializeProgress(totalFiles: 5, totalFunctions: 25);
        await manager.startFile('lib/models/note.dart', ['toMap', 'fromMap']);
        await manager.markFunctionReviewed('lib/models/note.dart', 'toMap');

        // Create a new manager and load
        final newManager = ProgressManager(storage: storage);
        await newManager.load();

        expect(newManager.tracker.totalCoreFiles, 5);
        expect(newManager.tracker.totalFunctionUnits, 25);
        expect(newManager.tracker.reviewedFunctionUnits, 1);
        expect(newManager.tracker.fileProgress.length, 1);
        expect(newManager.tracker.fileProgress[0].reviewedFunctionNames,
            contains('toMap'));
      });

      test('handles missing progress file gracefully', () async {
        final newManager = ProgressManager(storage: storage);
        await newManager.load();

        // Should keep default empty tracker
        expect(newManager.tracker.totalCoreFiles, 0);
        expect(newManager.tracker.totalFunctionUnits, 0);
      });
    });

    group('generateMonthlyReport', () {
      test('generates report with current progress data', () async {
        await manager.initializeProgress(totalFiles: 3, totalFunctions: 10);
        await manager.startFile('lib/models/note.dart', ['toMap', 'fromMap']);
        await manager.markFunctionReviewed('lib/models/note.dart', 'toMap');

        final report = await manager.generateMonthlyReport();

        expect(report['totalCoreFiles'], 3);
        expect(report['totalFunctionUnits'], 10);
        expect(report['reviewedFunctionUnits'], 1);
        expect(report['month'], isNotEmpty);
      });

      test('saves report to storage', () async {
        await manager.initializeProgress(totalFiles: 2, totalFunctions: 5);

        await manager.generateMonthlyReport();

        final reports = await storage.listMonthlyReports();
        expect(reports, isNotEmpty);
      });
    });

    group('persistence', () {
      test('persists after every update operation', () async {
        await manager.initializeProgress(totalFiles: 1, totalFunctions: 2);
        await manager.startFile('lib/models/note.dart', ['toMap', 'fromMap']);

        // Verify progress.json exists and is up to date
        final progressFile =
            File(p.join(tempDir.path, '.refactoring', 'progress.json'));
        expect(await progressFile.exists(), isTrue);

        final content = await progressFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        expect(data['totalCoreFiles'], 1);
        expect((data['files'] as List).length, 1);
      });
    });

    group('multi-file tracking', () {
      test('tracks progress across multiple files correctly', () async {
        await manager.initializeProgress(totalFiles: 2, totalFunctions: 4);

        await manager.startFile('lib/models/note.dart', ['toMap', 'fromMap']);
        await manager
            .startFile('lib/services/note_service.dart', ['save', 'delete']);

        await manager.markFunctionReviewed('lib/models/note.dart', 'toMap');
        await manager.markFunctionRefactored(
            'lib/services/note_service.dart', 'save');

        expect(manager.tracker.reviewedFunctionUnits, 2);
        expect(manager.tracker.completionPercentage, 50.0);
        expect(manager.tracker.completedCoreFiles, 0);

        // Complete both files
        await manager.markFunctionReviewed('lib/models/note.dart', 'fromMap');
        await manager.markFunctionRefactored(
            'lib/services/note_service.dart', 'delete');

        expect(manager.tracker.reviewedFunctionUnits, 4);
        expect(manager.tracker.completionPercentage, 100.0);
        expect(manager.tracker.completedCoreFiles, 2);
      });
    });
  });
}
