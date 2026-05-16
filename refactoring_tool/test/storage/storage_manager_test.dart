import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../lib/storage/storage_manager.dart';

void main() {
  late Directory tempDir;
  late StorageManager storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('storage_test_');
    storage = StorageManager(projectRoot: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('initialize', () {
    test('creates .refactoring directory structure', () async {
      await storage.initialize();

      final refactoringDir = Directory(p.join(tempDir.path, '.refactoring'));
      expect(await refactoringDir.exists(), isTrue);

      final decisions =
          Directory(p.join(tempDir.path, '.refactoring', 'decisions'));
      expect(await decisions.exists(), isTrue);

      final modifications =
          Directory(p.join(tempDir.path, '.refactoring', 'modifications'));
      expect(await modifications.exists(), isTrue);

      final monthlyReports =
          Directory(p.join(tempDir.path, '.refactoring', 'monthly_reports'));
      expect(await monthlyReports.exists(), isTrue);

      final eventSheets =
          Directory(p.join(tempDir.path, '.refactoring', 'event_sheets'));
      expect(await eventSheets.exists(), isTrue);
    });

    test('is idempotent (can be called multiple times)', () async {
      await storage.initialize();
      await storage.initialize();

      final refactoringDir = Directory(p.join(tempDir.path, '.refactoring'));
      expect(await refactoringDir.exists(), isTrue);
    });
  });

  group('isInitialized', () {
    test('returns false before initialization', () async {
      expect(await storage.isInitialized(), isFalse);
    });

    test('returns true after initialization', () async {
      await storage.initialize();
      expect(await storage.isInitialized(), isTrue);
    });
  });

  group('saveProgress / loadProgress', () {
    setUp(() async {
      await storage.initialize();
    });

    test('saves and loads progress data', () async {
      final progressData = {
        'startDate': '2025-01-15T00:00:00Z',
        'lastUpdated': '2025-01-20T14:30:00Z',
        'totalCoreFiles': 25,
        'completedCoreFiles': 2,
        'totalFunctionUnits': 180,
        'reviewedFunctionUnits': 15,
        'completionPercentage': 8.33,
        'files': [
          {
            'path': 'lib/models/note.dart',
            'status': 'completed',
            'totalFunctions': 5,
            'reviewedFunctions': 5,
            'reviewed': [
              'toMap',
              'fromMap',
              'copyWith',
              'toString',
              'hashCode'
            ],
            'pending': [],
          }
        ],
      };

      await storage.saveProgress(progressData);
      final loaded = await storage.loadProgress();

      expect(loaded, isNotNull);
      expect(loaded!['totalCoreFiles'], equals(25));
      expect(loaded['completionPercentage'], equals(8.33));
      expect((loaded['files'] as List).length, equals(1));
    });

    test('returns null when no progress file exists', () async {
      final loaded = await storage.loadProgress();
      expect(loaded, isNull);
    });

    test('overwrites existing progress data', () async {
      await storage.saveProgress({'totalCoreFiles': 10});
      await storage.saveProgress({'totalCoreFiles': 25});

      final loaded = await storage.loadProgress();
      expect(loaded!['totalCoreFiles'], equals(25));
    });
  });

  group('saveDecision / loadDecisions', () {
    setUp(() async {
      await storage.initialize();
    });

    test('saves and loads a decision entry', () async {
      final decision = {
        'functionName': 'loadNotes',
        'timestamp': '2025-01-20T14:30:00Z',
        'answers': {
          'q1_shouldDo': {'type': 'yes', 'justification': 'needs separation'},
          'q2_canImprove': {'type': 'no'},
          'q3_canMove': {'type': 'no'},
          'q4_canDelegate': {'type': 'yes', 'justification': 'extract filter'},
        },
        'decision': 'modify',
      };

      await storage.saveDecision(
        coreFilePath: 'lib/controllers/notes/notes_provider.dart',
        decisionEntry: decision,
      );

      final loaded = await storage.loadDecisions(
        'lib/controllers/notes/notes_provider.dart',
      );

      expect(loaded, isNotNull);
      expect(loaded!['filePath'],
          equals('lib/controllers/notes/notes_provider.dart'));
      expect((loaded['entries'] as List).length, equals(1));
      expect(
        (loaded['entries'] as List)[0]['functionName'],
        equals('loadNotes'),
      );
    });

    test('appends multiple decisions for same file', () async {
      await storage.saveDecision(
        coreFilePath: 'lib/models/note.dart',
        decisionEntry: {'functionName': 'toMap', 'decision': 'keepUnchanged'},
      );
      await storage.saveDecision(
        coreFilePath: 'lib/models/note.dart',
        decisionEntry: {'functionName': 'fromMap', 'decision': 'modify'},
      );

      final loaded = await storage.loadDecisions('lib/models/note.dart');
      expect((loaded!['entries'] as List).length, equals(2));
    });

    test('returns null for non-existent file decisions', () async {
      final loaded = await storage.loadDecisions('lib/nonexistent.dart');
      expect(loaded, isNull);
    });
  });

  group('loadAllDecisions', () {
    setUp(() async {
      await storage.initialize();
    });

    test('loads all decision files', () async {
      await storage.saveDecision(
        coreFilePath: 'lib/models/note.dart',
        decisionEntry: {'functionName': 'toMap'},
      );
      await storage.saveDecision(
        coreFilePath: 'lib/services/auth_service.dart',
        decisionEntry: {'functionName': 'login'},
      );

      final all = await storage.loadAllDecisions();
      expect(all.length, equals(2));
    });

    test('returns empty list when no decisions exist', () async {
      final all = await storage.loadAllDecisions();
      expect(all, isEmpty);
    });
  });

  group('saveDeadCode / loadDeadCode', () {
    setUp(() async {
      await storage.initialize();
    });

    test('saves and loads dead code report', () async {
      final deadCode = {
        'generatedAt': '2025-01-20T14:30:00Z',
        'entries': [
          {
            'functionName': 'unusedHelper',
            'filePath': 'lib/services/old_service.dart',
            'lineNumber': 42,
            'reason': 'Zero direct and indirect call sources',
          }
        ],
      };

      await storage.saveDeadCode(deadCode);
      final loaded = await storage.loadDeadCode();

      expect(loaded, isNotNull);
      expect((loaded!['entries'] as List).length, equals(1));
      expect(
        (loaded['entries'] as List)[0]['functionName'],
        equals('unusedHelper'),
      );
    });

    test('returns null when no dead code file exists', () async {
      final loaded = await storage.loadDeadCode();
      expect(loaded, isNull);
    });
  });

  group('saveModification / loadModifications', () {
    setUp(() async {
      await storage.initialize();
    });

    test('saves and loads modification entry', () async {
      final timestamp = DateTime(2025, 1, 20);
      final modification = {
        'functionName': 'loadNotes',
        'timestamp': '2025-01-20T14:30:00Z',
        'signatureBefore': 'Future<void> loadNotes({String? category})',
        'signatureAfter': 'Future<void> loadNotes({String? category})',
        'lineCountBefore': 45,
        'lineCountAfter': 28,
        'description': 'Extracted filter logic to helper function',
      };

      await storage.saveModification(
        coreFilePath: 'lib/controllers/notes/notes_provider.dart',
        modificationEntry: modification,
        timestamp: timestamp,
      );

      final loaded = await storage.loadModifications(
        coreFilePath: 'lib/controllers/notes/notes_provider.dart',
        timestamp: timestamp,
      );

      expect(loaded, isNotNull);
      expect(loaded!['month'], equals('2025-01'));
      expect((loaded['entries'] as List).length, equals(1));
    });

    test('appends multiple modifications for same file and month', () async {
      final timestamp = DateTime(2025, 2, 15);

      await storage.saveModification(
        coreFilePath: 'lib/models/note.dart',
        modificationEntry: {'functionName': 'toMap'},
        timestamp: timestamp,
      );
      await storage.saveModification(
        coreFilePath: 'lib/models/note.dart',
        modificationEntry: {'functionName': 'fromMap'},
        timestamp: timestamp,
      );

      final loaded = await storage.loadModifications(
        coreFilePath: 'lib/models/note.dart',
        timestamp: timestamp,
      );
      expect((loaded!['entries'] as List).length, equals(2));
    });
  });

  group('saveEventSheet / loadEventSheet', () {
    setUp(() async {
      await storage.initialize();
    });

    test('saves and loads event sheet for a function', () async {
      final eventSheet = {
        'functionName': 'loadNotes',
        'filePath': 'lib/controllers/notes/notes_provider.dart',
        'incomingEvents': [
          {
            'type': 'directCall',
            'targetOrSource': 'initState',
            'filePath': 'lib/screens/home_screen.dart',
            'lineNumber': 34,
          }
        ],
        'outgoingEvents': [
          {
            'type': 'notifyListeners',
            'targetOrSource': 'notifyListeners()',
            'filePath': 'lib/controllers/notes/notes_provider.dart',
            'lineNumber': 55,
          }
        ],
        'isEventIsolated': false,
      };

      await storage.saveEventSheet(
        coreFilePath: 'lib/controllers/notes/notes_provider.dart',
        functionName: 'loadNotes',
        eventSheetData: eventSheet,
      );

      final loaded = await storage.loadEventSheet(
        coreFilePath: 'lib/controllers/notes/notes_provider.dart',
        functionName: 'loadNotes',
      );

      expect(loaded, isNotNull);
      expect(loaded!['functionName'], equals('loadNotes'));
      expect((loaded['incomingEvents'] as List).length, equals(1));
      expect((loaded['outgoingEvents'] as List).length, equals(1));
    });

    test('returns null for non-existent event sheet', () async {
      final loaded = await storage.loadEventSheet(
        coreFilePath: 'lib/models/note.dart',
        functionName: 'nonexistent',
      );
      expect(loaded, isNull);
    });
  });

  group('saveMonthlyReport / loadMonthlyReport', () {
    setUp(() async {
      await storage.initialize();
    });

    test('saves and loads monthly report', () async {
      final timestamp = DateTime(2025, 1, 15);
      final report = {
        'month': '2025-01',
        'coreFilesProcessed': 3,
        'functionUnitsReviewed': 25,
        'functionUnitsModified': 8,
        'testsAdded': 12,
      };

      await storage.saveMonthlyReport(
        reportData: report,
        timestamp: timestamp,
      );

      final loaded = await storage.loadMonthlyReport(timestamp: timestamp);

      expect(loaded, isNotNull);
      expect(loaded!['month'], equals('2025-01'));
      expect(loaded['coreFilesProcessed'], equals(3));
    });

    test('returns null for non-existent monthly report', () async {
      final loaded =
          await storage.loadMonthlyReport(timestamp: DateTime(2020, 1, 1));
      expect(loaded, isNull);
    });
  });

  group('listMonthlyReports', () {
    setUp(() async {
      await storage.initialize();
    });

    test('lists available monthly reports sorted', () async {
      await storage.saveMonthlyReport(
        reportData: {'month': '2025-03'},
        timestamp: DateTime(2025, 3, 1),
      );
      await storage.saveMonthlyReport(
        reportData: {'month': '2025-01'},
        timestamp: DateTime(2025, 1, 1),
      );
      await storage.saveMonthlyReport(
        reportData: {'month': '2025-02'},
        timestamp: DateTime(2025, 2, 1),
      );

      final reports = await storage.listMonthlyReports();
      expect(reports, equals(['2025-01', '2025-02', '2025-03']));
    });

    test('returns empty list when no reports exist', () async {
      final reports = await storage.listMonthlyReports();
      expect(reports, isEmpty);
    });
  });

  group('retry logic', () {
    test('StorageWriteException contains useful information', () {
      final exception = StorageWriteException(
        filePath: '/some/path.json',
        originalError: 'first error',
        retryError: 'second error',
      );

      expect(exception.toString(), contains('path.json'));
      expect(exception.toString(), contains('first error'));
      expect(exception.toString(), contains('second error'));
      expect(exception.filePath, equals('/some/path.json'));
    });
  });

  group('JSON format', () {
    setUp(() async {
      await storage.initialize();
    });

    test('writes pretty-printed JSON', () async {
      await storage.saveProgress({'totalCoreFiles': 10});

      final file = File(p.join(tempDir.path, '.refactoring', 'progress.json'));
      final content = await file.readAsString();

      // Should be indented (pretty-printed)
      expect(content, contains('  "totalCoreFiles"'));
      // Should be valid JSON
      expect(() => jsonDecode(content), returnsNormally);
    });
  });
}
