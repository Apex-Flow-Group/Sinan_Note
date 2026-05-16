import 'dart:io';

import 'package:refactoring_tool/gate/decision_recorder.dart';
import 'package:refactoring_tool/models/evaluation_record.dart';
import 'package:refactoring_tool/storage/storage_manager.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late StorageManager storageManager;
  late DecisionRecorder recorder;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('decision_recorder_test_');
    storageManager = StorageManager(projectRoot: tempDir.path);
    await storageManager.initialize();
    recorder = DecisionRecorder(storageManager: storageManager);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DecisionRecorder.determineDecision', () {
    test('all "لا" answers → keepUnchanged', () {
      final answers = List.generate(
        4,
        (_) => const EvaluationAnswer(type: AnswerType.no),
      );
      final decision = recorder.determineDecision(answers);
      expect(decision, EvaluationDecision.keepUnchanged);
    });

    test('any "نعم" answer → modify', () {
      final answers = [
        const EvaluationAnswer(
            type: AnswerType.yes, justification: 'تحسين الأداء'),
        const EvaluationAnswer(type: AnswerType.no),
        const EvaluationAnswer(type: AnswerType.no),
        const EvaluationAnswer(type: AnswerType.no),
      ];
      final decision = recorder.determineDecision(answers);
      expect(decision, EvaluationDecision.modify);
    });

    test('multiple "نعم" answers → modify', () {
      final answers = [
        const EvaluationAnswer(type: AnswerType.yes, justification: 'تحسين'),
        const EvaluationAnswer(
            type: AnswerType.yes, justification: 'فصل المنطق'),
        const EvaluationAnswer(type: AnswerType.no),
        const EvaluationAnswer(type: AnswerType.unsure),
      ];
      final decision = recorder.determineDecision(answers);
      expect(decision, EvaluationDecision.modify);
    });

    test('"نعم" with "غير متأكد" → modify (yes takes priority)', () {
      final answers = [
        const EvaluationAnswer(type: AnswerType.unsure),
        const EvaluationAnswer(
            type: AnswerType.yes, justification: 'يمكن تحسينها'),
        const EvaluationAnswer(type: AnswerType.unsure),
        const EvaluationAnswer(type: AnswerType.no),
      ];
      final decision = recorder.determineDecision(answers);
      expect(decision, EvaluationDecision.modify);
    });

    test('only "غير متأكد" answers → extract (pending review)', () {
      final answers = List.generate(
        4,
        (_) => const EvaluationAnswer(type: AnswerType.unsure),
      );
      final decision = recorder.determineDecision(answers);
      expect(decision, EvaluationDecision.extract);
    });

    test('"غير متأكد" mixed with "لا" (no "نعم") → extract (pending review)',
        () {
      final answers = [
        const EvaluationAnswer(type: AnswerType.no),
        const EvaluationAnswer(type: AnswerType.unsure),
        const EvaluationAnswer(type: AnswerType.no),
        const EvaluationAnswer(type: AnswerType.unsure),
      ];
      final decision = recorder.determineDecision(answers);
      expect(decision, EvaluationDecision.extract);
    });
  });

  group('DecisionRecorder.recordDecision', () {
    test('creates EvaluationRecord and persists via StorageManager', () async {
      final timestamp = DateTime(2025, 1, 20, 14, 30);

      final record = await recorder.recordDecision(
        functionName: 'loadNotes',
        coreFilePath: 'lib/controllers/notes/notes_provider.dart',
        question1: const EvaluationAnswer(type: AnswerType.no),
        question2: const EvaluationAnswer(type: AnswerType.no),
        question3: const EvaluationAnswer(type: AnswerType.no),
        question4: const EvaluationAnswer(type: AnswerType.no),
        timestamp: timestamp,
      );

      expect(record.functionName, 'loadNotes');
      expect(record.coreFilePath, 'lib/controllers/notes/notes_provider.dart');
      expect(record.timestamp, timestamp);
      expect(record.decision, EvaluationDecision.keepUnchanged);

      // Verify persisted
      final loaded = await storageManager
          .loadDecisions('lib/controllers/notes/notes_provider.dart');
      expect(loaded, isNotNull);
      expect((loaded!['entries'] as List).length, 1);
    });

    test('records modify decision when any answer is yes', () async {
      final record = await recorder.recordDecision(
        functionName: 'addNote',
        coreFilePath: 'lib/controllers/notes/notes_provider.dart',
        question1: const EvaluationAnswer(type: AnswerType.no),
        question2: const EvaluationAnswer(
            type: AnswerType.yes, justification: 'يمكن تقليل التعقيد'),
        question3: const EvaluationAnswer(type: AnswerType.no),
        question4: const EvaluationAnswer(type: AnswerType.unsure),
      );

      expect(record.decision, EvaluationDecision.modify);
    });

    test('records extract (pending review) when only unsure', () async {
      final record = await recorder.recordDecision(
        functionName: 'deleteNote',
        coreFilePath: 'lib/services/note_service.dart',
        question1: const EvaluationAnswer(type: AnswerType.unsure),
        question2: const EvaluationAnswer(type: AnswerType.unsure),
        question3: const EvaluationAnswer(type: AnswerType.no),
        question4: const EvaluationAnswer(type: AnswerType.unsure),
      );

      expect(record.decision, EvaluationDecision.extract);
    });

    test('stores JSON with correct structure per Function_Unit', () async {
      final timestamp = DateTime(2025, 2, 10, 9, 0);

      await recorder.recordDecision(
        functionName: 'saveNote',
        coreFilePath: 'lib/services/note_service.dart',
        question1: const EvaluationAnswer(
            type: AnswerType.yes, justification: 'فصل التخزين'),
        question2: const EvaluationAnswer(type: AnswerType.no),
        question3: const EvaluationAnswer(type: AnswerType.no),
        question4: const EvaluationAnswer(type: AnswerType.no),
        timestamp: timestamp,
      );

      final loaded =
          await storageManager.loadDecisions('lib/services/note_service.dart');
      final entry = (loaded!['entries'] as List).first as Map<String, dynamic>;

      expect(entry['functionName'], 'saveNote');
      expect(entry['coreFilePath'], 'lib/services/note_service.dart');
      expect(entry['timestamp'], timestamp.toIso8601String());
      expect(entry['decision'], 'modify');
      expect(entry['question1']['type'], 'yes');
      expect(entry['question1']['justification'], 'فصل التخزين');
    });
  });

  group('DecisionRecorder.recordModification', () {
    test('persists before-and-after summary', () async {
      final timestamp = DateTime(2025, 1, 20, 15, 0);

      await recorder.recordModification(
        functionName: 'loadNotes',
        coreFilePath: 'lib/controllers/notes/notes_provider.dart',
        signatureBefore: 'Future<void> loadNotes({String? category})',
        signatureAfter: 'Future<void> loadNotes({String? category})',
        lineCountBefore: 45,
        lineCountAfter: 28,
        changeDescription: 'فصل منطق التصفية إلى _filterNotesByCategory',
        justifyingAnswers: [AnswerType.yes, AnswerType.yes],
        timestamp: timestamp,
      );

      final loaded = await storageManager.loadModifications(
        coreFilePath: 'lib/controllers/notes/notes_provider.dart',
        timestamp: timestamp,
      );

      expect(loaded, isNotNull);
      final entry = (loaded!['entries'] as List).first as Map<String, dynamic>;
      expect(entry['functionName'], 'loadNotes');
      expect(entry['signatureBefore'],
          'Future<void> loadNotes({String? category})');
      expect(entry['signatureAfter'],
          'Future<void> loadNotes({String? category})');
      expect(entry['lineCountBefore'], 45);
      expect(entry['lineCountAfter'], 28);
      expect(entry['changeDescription'],
          'فصل منطق التصفية إلى _filterNotesByCategory');
      expect(entry['justifyingAnswers'], ['yes', 'yes']);
    });

    test('truncates description to 500 characters', () async {
      final longDescription = 'أ' * 600;

      await recorder.recordModification(
        functionName: 'processData',
        coreFilePath: 'lib/services/data_service.dart',
        signatureBefore: 'void processData()',
        signatureAfter: 'void processData()',
        lineCountBefore: 100,
        lineCountAfter: 80,
        changeDescription: longDescription,
        justifyingAnswers: [AnswerType.yes],
      );

      final loaded = await storageManager.loadModifications(
        coreFilePath: 'lib/services/data_service.dart',
      );

      final entry = (loaded!['entries'] as List).first as Map<String, dynamic>;
      expect((entry['changeDescription'] as String).length, 500);
    });
  });

  group('DecisionRecorder.recordDeadCodeRemoval', () {
    test('documents dead code removal with all required fields', () async {
      final removalDate = DateTime(2025, 3, 1, 10, 0);

      await recorder.recordDeadCodeRemoval(
        functionName: 'unusedHelper',
        coreFilePath: 'lib/models/note.dart',
        reason: 'لا يوجد أي استدعاء لهذه الدالة',
        lastCallSourceCount: 0,
        dateOfRemoval: removalDate,
      );

      final deadCodeData = await storageManager.loadDeadCode();
      expect(deadCodeData, isNotNull);

      final removals = deadCodeData!['removals'] as List;
      expect(removals, hasLength(1));

      final removal = removals.first as Map<String, dynamic>;
      expect(removal['functionName'], 'unusedHelper');
      expect(removal['coreFilePath'], 'lib/models/note.dart');
      expect(removal['reason'], 'لا يوجد أي استدعاء لهذه الدالة');
      expect(removal['lastCallSourceCount'], 0);
      expect(removal['dateOfRemoval'], removalDate.toIso8601String());
    });

    test('appends to existing dead code report', () async {
      await recorder.recordDeadCodeRemoval(
        functionName: 'oldFunction',
        coreFilePath: 'lib/services/old_service.dart',
        reason: 'كود ميت',
      );

      await recorder.recordDeadCodeRemoval(
        functionName: 'anotherOldFunction',
        coreFilePath: 'lib/services/old_service.dart',
        reason: 'لم يعد مستخدماً',
      );

      final deadCodeData = await storageManager.loadDeadCode();
      final removals = deadCodeData!['removals'] as List;
      expect(removals, hasLength(2));
      expect(
          (removals[0] as Map<String, dynamic>)['functionName'], 'oldFunction');
      expect((removals[1] as Map<String, dynamic>)['functionName'],
          'anotherOldFunction');
    });

    test('defaults lastCallSourceCount to 0', () async {
      await recorder.recordDeadCodeRemoval(
        functionName: 'deadFunc',
        coreFilePath: 'lib/core/utils.dart',
        reason: 'غير مستخدم',
      );

      final deadCodeData = await storageManager.loadDeadCode();
      final removal =
          (deadCodeData!['removals'] as List).first as Map<String, dynamic>;
      expect(removal['lastCallSourceCount'], 0);
    });
  });
}
