import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Manages all JSON read/write operations for the `.refactoring/` directory.
///
/// The storage layer persists progress, decisions, dead code reports,
/// modifications, event sheets, and monthly reports as structured JSON files.
/// It implements retry logic: one retry on write failure, then throws.
class StorageManager {
  /// The root path of the target project being refactored.
  final String projectRoot;

  /// The path to the `.refactoring/` directory.
  late final String _refactoringDir;

  StorageManager({required this.projectRoot}) {
    _refactoringDir = p.join(projectRoot, '.refactoring');
  }

  // ---------------------------------------------------------------------------
  // Directory Structure
  // ---------------------------------------------------------------------------

  /// Subdirectory names within `.refactoring/`.
  static const String _decisionsDir = 'decisions';
  static const String _modificationsDir = 'modifications';
  static const String _monthlyReportsDir = 'monthly_reports';
  static const String _eventSheetsDir = 'event_sheets';

  /// Creates the `.refactoring/` directory structure on first run.
  ///
  /// Structure:
  /// ```
  /// .refactoring/
  /// ├── decisions/
  /// ├── modifications/
  /// ├── monthly_reports/
  /// └── event_sheets/
  /// ```
  Future<void> initialize() async {
    final dirs = [
      _refactoringDir,
      p.join(_refactoringDir, _decisionsDir),
      p.join(_refactoringDir, _modificationsDir),
      p.join(_refactoringDir, _monthlyReportsDir),
      p.join(_refactoringDir, _eventSheetsDir),
    ];

    for (final dir in dirs) {
      await Directory(dir).create(recursive: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Progress Tracking
  // ---------------------------------------------------------------------------

  /// Saves the progress tracker data to `.refactoring/progress.json`.
  Future<void> saveProgress(Map<String, dynamic> progressData) async {
    final filePath = p.join(_refactoringDir, 'progress.json');
    await _writeJsonFile(filePath, progressData);
  }

  /// Loads the progress tracker data from `.refactoring/progress.json`.
  ///
  /// Returns `null` if the file does not exist.
  Future<Map<String, dynamic>?> loadProgress() async {
    final filePath = p.join(_refactoringDir, 'progress.json');
    return await _readJsonFile(filePath);
  }

  // ---------------------------------------------------------------------------
  // Decisions
  // ---------------------------------------------------------------------------

  /// Saves an evaluation decision for a function within a core file.
  ///
  /// Decisions are stored per-file in `decisions/{fileName}.json`.
  /// Each file contains a list of decision entries.
  Future<void> saveDecision({
    required String coreFilePath,
    required Map<String, dynamic> decisionEntry,
  }) async {
    final fileName = _fileNameFromPath(coreFilePath);
    final filePath = p.join(_refactoringDir, _decisionsDir, '$fileName.json');

    // Load existing decisions for this file, or start fresh
    Map<String, dynamic> fileData;
    final existing = await _readJsonFile(filePath);
    if (existing != null) {
      fileData = existing;
    } else {
      fileData = {
        'filePath': coreFilePath,
        'entries': <dynamic>[],
      };
    }

    (fileData['entries'] as List<dynamic>).add(decisionEntry);
    await _writeJsonFile(filePath, fileData);
  }

  /// Loads all decisions for a specific core file.
  ///
  /// Returns `null` if no decisions exist for the file.
  Future<Map<String, dynamic>?> loadDecisions(String coreFilePath) async {
    final fileName = _fileNameFromPath(coreFilePath);
    final filePath = p.join(_refactoringDir, _decisionsDir, '$fileName.json');
    return await _readJsonFile(filePath);
  }

  /// Loads all decision files from the decisions directory.
  Future<List<Map<String, dynamic>>> loadAllDecisions() async {
    final dir = Directory(p.join(_refactoringDir, _decisionsDir));
    if (!await dir.exists()) return [];

    final results = <Map<String, dynamic>>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final data = await _readJsonFile(entity.path);
        if (data != null) {
          results.add(data);
        }
      }
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // Dead Code
  // ---------------------------------------------------------------------------

  /// Saves the dead code report to `.refactoring/dead_code.json`.
  Future<void> saveDeadCode(Map<String, dynamic> deadCodeData) async {
    final filePath = p.join(_refactoringDir, 'dead_code.json');
    await _writeJsonFile(filePath, deadCodeData);
  }

  /// Loads the dead code report from `.refactoring/dead_code.json`.
  ///
  /// Returns `null` if the file does not exist.
  Future<Map<String, dynamic>?> loadDeadCode() async {
    final filePath = p.join(_refactoringDir, 'dead_code.json');
    return await _readJsonFile(filePath);
  }

  // ---------------------------------------------------------------------------
  // Modifications
  // ---------------------------------------------------------------------------

  /// Saves a modification log entry.
  ///
  /// Modifications are stored in `modifications/{yyyy-MM-fileName}.json`.
  Future<void> saveModification({
    required String coreFilePath,
    required Map<String, dynamic> modificationEntry,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final fileName = _fileNameFromPath(coreFilePath);
    final filePath = p.join(
      _refactoringDir,
      _modificationsDir,
      '$monthPrefix-$fileName.json',
    );

    // Load existing modifications or start fresh
    Map<String, dynamic> fileData;
    final existing = await _readJsonFile(filePath);
    if (existing != null) {
      fileData = existing;
    } else {
      fileData = {
        'filePath': coreFilePath,
        'month': monthPrefix,
        'entries': <dynamic>[],
      };
    }

    (fileData['entries'] as List<dynamic>).add(modificationEntry);
    await _writeJsonFile(filePath, fileData);
  }

  /// Loads modification logs for a specific core file and month.
  Future<Map<String, dynamic>?> loadModifications({
    required String coreFilePath,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final monthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final fileName = _fileNameFromPath(coreFilePath);
    final filePath = p.join(
      _refactoringDir,
      _modificationsDir,
      '$monthPrefix-$fileName.json',
    );
    return await _readJsonFile(filePath);
  }

  // ---------------------------------------------------------------------------
  // Event Sheets
  // ---------------------------------------------------------------------------

  /// Saves an event sheet for a specific function.
  ///
  /// Event sheets are stored in `event_sheets/{fileName}/{functionName}.json`.
  Future<void> saveEventSheet({
    required String coreFilePath,
    required String functionName,
    required Map<String, dynamic> eventSheetData,
  }) async {
    final fileName = _fileNameFromPath(coreFilePath);
    final dirPath = p.join(_refactoringDir, _eventSheetsDir, fileName);
    await Directory(dirPath).create(recursive: true);

    final filePath = p.join(dirPath, '$functionName.json');
    await _writeJsonFile(filePath, eventSheetData);
  }

  /// Loads an event sheet for a specific function.
  ///
  /// Returns `null` if the event sheet does not exist.
  Future<Map<String, dynamic>?> loadEventSheet({
    required String coreFilePath,
    required String functionName,
  }) async {
    final fileName = _fileNameFromPath(coreFilePath);
    final filePath = p.join(
      _refactoringDir,
      _eventSheetsDir,
      fileName,
      '$functionName.json',
    );
    return await _readJsonFile(filePath);
  }

  // ---------------------------------------------------------------------------
  // Monthly Reports
  // ---------------------------------------------------------------------------

  /// Saves a monthly report.
  ///
  /// Monthly reports are stored in `monthly_reports/{yyyy-MM}.json`.
  Future<void> saveMonthlyReport({
    required Map<String, dynamic> reportData,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final filePath = p.join(
      _refactoringDir,
      _monthlyReportsDir,
      '$monthKey.json',
    );
    await _writeJsonFile(filePath, reportData);
  }

  /// Loads a monthly report for a specific month.
  ///
  /// Returns `null` if the report does not exist.
  Future<Map<String, dynamic>?> loadMonthlyReport({DateTime? timestamp}) async {
    final now = timestamp ?? DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final filePath = p.join(
      _refactoringDir,
      _monthlyReportsDir,
      '$monthKey.json',
    );
    return await _readJsonFile(filePath);
  }

  /// Lists all available monthly reports.
  Future<List<String>> listMonthlyReports() async {
    final dir = Directory(p.join(_refactoringDir, _monthlyReportsDir));
    if (!await dir.exists()) return [];

    final reports = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        reports.add(p.basenameWithoutExtension(entity.path));
      }
    }
    reports.sort();
    return reports;
  }

  // ---------------------------------------------------------------------------
  // Utility: Check if initialized
  // ---------------------------------------------------------------------------

  /// Returns `true` if the `.refactoring/` directory exists.
  Future<bool> isInitialized() async {
    return await Directory(_refactoringDir).exists();
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  /// Writes JSON data to a file with retry logic.
  ///
  /// Retries once on failure, then throws a [StorageWriteException].
  Future<void> _writeJsonFile(
    String filePath,
    Map<String, dynamic> data,
  ) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    try {
      await File(filePath).writeAsString(jsonString, flush: true);
    } catch (e) {
      // Retry once
      try {
        await File(filePath).writeAsString(jsonString, flush: true);
      } catch (retryError) {
        throw StorageWriteException(
          filePath: filePath,
          originalError: e,
          retryError: retryError,
        );
      }
    }
  }

  /// Reads and decodes a JSON file.
  ///
  /// Returns `null` if the file does not exist.
  /// Throws [FormatException] if the file contains invalid JSON.
  Future<Map<String, dynamic>?> _readJsonFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    if (content.trim().isEmpty) return null;

    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Extracts a safe file name from a Dart file path.
  ///
  /// Example: `lib/controllers/notes/notes_provider.dart` → `notes_provider`
  String _fileNameFromPath(String filePath) {
    return p.basenameWithoutExtension(filePath);
  }
}

/// Exception thrown when a file write fails after retry.
class StorageWriteException implements Exception {
  final String filePath;
  final Object originalError;
  final Object retryError;

  StorageWriteException({
    required this.filePath,
    required this.originalError,
    required this.retryError,
  });

  @override
  String toString() =>
      'StorageWriteException: Failed to write to "$filePath" after retry. '
      'Original error: $originalError, Retry error: $retryError';
}
