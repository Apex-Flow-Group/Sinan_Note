import 'package:refactoring_tool/testing/test_executor.dart';
import 'package:test/test.dart';

/// Mock RevertHandler for testing
class MockRevertHandler implements RevertHandler {
  bool revertCalled = false;
  String? revertedFilePath;
  bool shouldSucceed;

  MockRevertHandler({this.shouldSucceed = true});

  @override
  Future<bool> revert(String filePath) async {
    revertCalled = true;
    revertedFilePath = filePath;
    return shouldSucceed;
  }
}

/// Mock RefactorMarker for testing
class MockRefactorMarker implements RefactorMarker {
  bool markCalled = false;
  String? markedFilePath;
  String? markedFunctionName;

  @override
  Future<void> markAsRefactored(String filePath, String functionName) async {
    markCalled = true;
    markedFilePath = filePath;
    markedFunctionName = functionName;
  }
}

void main() {
  group('TestExecutor', () {
    group('executeTests - empty/missing test files', () {
      test('returns noTests when testFilePaths is empty', () async {
        const executor = TestExecutor(projectRoot: '.');

        final result = await executor.executeTests(
          testFilePaths: [],
          functionName: 'myFunction',
        );

        expect(result.status, equals(TestExecutionStatus.noTests));
        expect(result.functionName, equals('myFunction'));
        expect(result.message, contains('myFunction'));
      });

      test('returns noTests when test files do not exist', () async {
        const executor = TestExecutor(projectRoot: '.');

        final result = await executor.executeTests(
          testFilePaths: ['non_existent_test.dart'],
          functionName: 'myFunction',
        );

        expect(result.status, equals(TestExecutionStatus.noTests));
        expect(result.functionName, equals('myFunction'));
      });
    });

    group('TestExecutionResult', () {
      test('isSuccess returns true for passed status', () {
        const result = TestExecutionResult(
          status: TestExecutionStatus.passed,
          message: 'All tests passed',
          passedCount: 5,
        );

        expect(result.isSuccess, isTrue);
        expect(result.isFailed, isFalse);
        expect(result.isTimeout, isFalse);
      });

      test('isFailed returns true for failed status', () {
        const result = TestExecutionResult(
          status: TestExecutionStatus.failed,
          message: 'Tests failed',
          failedCount: 2,
        );

        expect(result.isFailed, isTrue);
        expect(result.isSuccess, isFalse);
      });

      test('isTimeout returns true for timeout status', () {
        const result = TestExecutionResult(
          status: TestExecutionStatus.timeout,
          message: 'Timeout',
          elapsedSeconds: 120.0,
          functionName: 'slowFunction',
        );

        expect(result.isTimeout, isTrue);
        expect(result.isSuccess, isFalse);
        expect(result.functionName, equals('slowFunction'));
        expect(result.elapsedSeconds, equals(120.0));
      });

      test('toJson serializes all fields correctly', () {
        const result = TestExecutionResult(
          status: TestExecutionStatus.failed,
          message: 'Test failed',
          failures: [
            TestFailureDetail(
              testName: 'test addition',
              assertion: 'equals',
              expected: '4',
              actual: '5',
            ),
          ],
          functionName: 'add',
          elapsedSeconds: 2.5,
          passedCount: 3,
          failedCount: 1,
          revertTriggered: true,
          markedAsRefactored: false,
        );

        final json = result.toJson();

        expect(json['status'], equals('failed'));
        expect(json['message'], equals('Test failed'));
        expect(json['functionName'], equals('add'));
        expect(json['elapsedSeconds'], equals(2.5));
        expect(json['passedCount'], equals(3));
        expect(json['failedCount'], equals(1));
        expect(json['revertTriggered'], isTrue);
        expect(json['markedAsRefactored'], isFalse);
        expect(json['failures'], hasLength(1));
      });

      test('fromJson deserializes correctly', () {
        final json = {
          'status': 'passed',
          'message': 'All passed',
          'failures': <dynamic>[],
          'functionName': 'myFunc',
          'elapsedSeconds': 1.2,
          'passedCount': 5,
          'failedCount': 0,
          'revertTriggered': false,
          'markedAsRefactored': true,
        };

        final result = TestExecutionResult.fromJson(json);

        expect(result.status, equals(TestExecutionStatus.passed));
        expect(result.message, equals('All passed'));
        expect(result.functionName, equals('myFunc'));
        expect(result.elapsedSeconds, equals(1.2));
        expect(result.passedCount, equals(5));
        expect(result.failedCount, equals(0));
        expect(result.revertTriggered, isFalse);
        expect(result.markedAsRefactored, isTrue);
      });

      test('copyWith creates new instance with updated fields', () {
        const original = TestExecutionResult(
          status: TestExecutionStatus.passed,
          message: 'Passed',
          passedCount: 5,
        );

        final updated = original.copyWith(
          revertTriggered: true,
          elapsedSeconds: 3.0,
        );

        expect(updated.status, equals(TestExecutionStatus.passed));
        expect(updated.revertTriggered, isTrue);
        expect(updated.elapsedSeconds, equals(3.0));
        expect(updated.passedCount, equals(5));
      });
    });

    group('TestFailureDetail', () {
      test('toJson serializes correctly', () {
        const detail = TestFailureDetail(
          testName: 'should add numbers',
          assertion: 'Expected: 4, Actual: 5',
          expected: '4',
          actual: '5',
        );

        final json = detail.toJson();

        expect(json['testName'], equals('should add numbers'));
        expect(json['assertion'], equals('Expected: 4, Actual: 5'));
        expect(json['expected'], equals('4'));
        expect(json['actual'], equals('5'));
      });

      test('fromJson deserializes correctly', () {
        final json = {
          'testName': 'test subtraction',
          'assertion': 'equals',
          'expected': '0',
          'actual': '-1',
        };

        final detail = TestFailureDetail.fromJson(json);

        expect(detail.testName, equals('test subtraction'));
        expect(detail.assertion, equals('equals'));
        expect(detail.expected, equals('0'));
        expect(detail.actual, equals('-1'));
      });
    });

    group('RevertHandler integration', () {
      test('revert is not called when no handler provided', () async {
        const executor = TestExecutor(projectRoot: '.');

        final result = await executor.executeTests(
          testFilePaths: [],
          functionName: 'myFunc',
          filePath: 'lib/my_file.dart',
        );

        // No tests = no revert needed
        expect(result.revertTriggered, isFalse);
      });
    });

    group('RefactorMarker integration', () {
      test('marker is not called when no handler provided', () async {
        const executor = TestExecutor(projectRoot: '.');

        final result = await executor.executeTests(
          testFilePaths: [],
          functionName: 'myFunc',
          filePath: 'lib/my_file.dart',
        );

        expect(result.markedAsRefactored, isFalse);
      });
    });

    group('TestExecutor constructor', () {
      test('default timeout is 120 seconds', () {
        const executor = TestExecutor(projectRoot: '/project');
        expect(executor.timeoutSeconds, equals(120));
      });

      test('custom timeout is accepted', () {
        const executor =
            TestExecutor(projectRoot: '/project', timeoutSeconds: 60);
        expect(executor.timeoutSeconds, equals(60));
      });

      test('accepts revertHandler and refactorMarker', () {
        final revertHandler = MockRevertHandler();
        final refactorMarker = MockRefactorMarker();

        final executor = TestExecutor(
          projectRoot: '/project',
          revertHandler: revertHandler,
          refactorMarker: refactorMarker,
        );

        expect(executor.revertHandler, isNotNull);
        expect(executor.refactorMarker, isNotNull);
      });
    });
  });
}
