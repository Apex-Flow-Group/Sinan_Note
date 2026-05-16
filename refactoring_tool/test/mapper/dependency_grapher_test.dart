import 'package:refactoring_tool/mapper/dependency_grapher.dart';
import 'package:refactoring_tool/models/call_source.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyGrapher', () {
    test('builds empty map when function has no callers or callees', () {
      final grapher = DependencyGrapher((functionName) {
        return const ResolvedCalls();
      });

      final result = grapher.buildDependencyMap('isolatedFunc');

      expect(result.rootFunction, 'isolatedFunc');
      expect(result.upstreamCallers, isEmpty);
      expect(result.downstreamCallees, isEmpty);
      expect(result.hasCircularChain, isFalse);
      expect(result.circularParticipants, isEmpty);
    });

    test('builds upstream callers up to 3 levels', () {
      final grapher = DependencyGrapher((functionName) {
        switch (functionName) {
          case 'target':
            return const ResolvedCalls(callers: [
              CallSource(
                callingFunction: 'callerA',
                filePath: 'a.dart',
                lineNumber: 10,
                callType: CallType.direct,
              ),
            ]);
          case 'callerA':
            return const ResolvedCalls(callers: [
              CallSource(
                callingFunction: 'callerB',
                filePath: 'b.dart',
                lineNumber: 20,
                callType: CallType.direct,
              ),
            ]);
          case 'callerB':
            return const ResolvedCalls(callers: [
              CallSource(
                callingFunction: 'callerC',
                filePath: 'c.dart',
                lineNumber: 30,
                callType: CallType.direct,
              ),
            ]);
          case 'callerC':
            // Level 4 - should NOT be included
            return const ResolvedCalls(callers: [
              CallSource(
                callingFunction: 'callerD',
                filePath: 'd.dart',
                lineNumber: 40,
                callType: CallType.direct,
              ),
            ]);
          default:
            return const ResolvedCalls();
        }
      });

      final result = grapher.buildDependencyMap('target');

      expect(result.upstreamCallers.length, 1);
      expect(result.upstreamCallers[0].functionName, 'callerA');
      expect(result.upstreamCallers[0].depth, 1);

      // Level 2
      expect(result.upstreamCallers[0].children.length, 1);
      expect(result.upstreamCallers[0].children[0].functionName, 'callerB');
      expect(result.upstreamCallers[0].children[0].depth, 2);

      // Level 3
      expect(result.upstreamCallers[0].children[0].children.length, 1);
      expect(result.upstreamCallers[0].children[0].children[0].functionName,
          'callerC');
      expect(result.upstreamCallers[0].children[0].children[0].depth, 3);

      // Level 4 should NOT exist
      expect(
          result.upstreamCallers[0].children[0].children[0].children, isEmpty);
    });

    test('builds downstream callees up to 3 levels', () {
      final grapher = DependencyGrapher((functionName) {
        switch (functionName) {
          case 'target':
            return const ResolvedCalls(callees: [
              CallSource(
                callingFunction: 'calleeX',
                filePath: 'x.dart',
                lineNumber: 5,
                callType: CallType.direct,
              ),
            ]);
          case 'calleeX':
            return const ResolvedCalls(callees: [
              CallSource(
                callingFunction: 'calleeY',
                filePath: 'y.dart',
                lineNumber: 15,
                callType: CallType.providerRead,
              ),
            ]);
          case 'calleeY':
            return const ResolvedCalls(callees: [
              CallSource(
                callingFunction: 'calleeZ',
                filePath: 'z.dart',
                lineNumber: 25,
                callType: CallType.streamListen,
              ),
            ]);
          default:
            return const ResolvedCalls();
        }
      });

      final result = grapher.buildDependencyMap('target');

      expect(result.downstreamCallees.length, 1);
      expect(result.downstreamCallees[0].functionName, 'calleeX');
      expect(result.downstreamCallees[0].depth, 1);

      expect(result.downstreamCallees[0].children.length, 1);
      expect(result.downstreamCallees[0].children[0].functionName, 'calleeY');
      expect(result.downstreamCallees[0].children[0].depth, 2);

      expect(result.downstreamCallees[0].children[0].children.length, 1);
      expect(result.downstreamCallees[0].children[0].children[0].functionName,
          'calleeZ');
      expect(result.downstreamCallees[0].children[0].children[0].depth, 3);
    });

    test('detects circular chain when node appears in both directions', () {
      final grapher = DependencyGrapher((functionName) {
        switch (functionName) {
          case 'funcA':
            return const ResolvedCalls(
              callers: [
                CallSource(
                  callingFunction: 'funcB',
                  filePath: 'b.dart',
                  lineNumber: 10,
                  callType: CallType.direct,
                ),
              ],
              callees: [
                CallSource(
                  callingFunction: 'funcB',
                  filePath: 'b.dart',
                  lineNumber: 20,
                  callType: CallType.direct,
                ),
              ],
            );
          case 'funcB':
            return const ResolvedCalls(
              callers: [
                CallSource(
                  callingFunction: 'funcC',
                  filePath: 'c.dart',
                  lineNumber: 30,
                  callType: CallType.direct,
                ),
              ],
              callees: [
                CallSource(
                  callingFunction: 'funcA',
                  filePath: 'a.dart',
                  lineNumber: 40,
                  callType: CallType.direct,
                ),
              ],
            );
          default:
            return const ResolvedCalls();
        }
      });

      final result = grapher.buildDependencyMap('funcA');

      expect(result.hasCircularChain, isTrue);
      expect(result.circularParticipants, contains('funcB'));
    });

    test('lists all participating functions in circular chains sorted', () {
      final grapher = DependencyGrapher((functionName) {
        switch (functionName) {
          case 'root':
            return const ResolvedCalls(
              callers: [
                CallSource(
                  callingFunction: 'alpha',
                  filePath: 'alpha.dart',
                  lineNumber: 1,
                  callType: CallType.direct,
                ),
                CallSource(
                  callingFunction: 'beta',
                  filePath: 'beta.dart',
                  lineNumber: 2,
                  callType: CallType.direct,
                ),
              ],
              callees: [
                CallSource(
                  callingFunction: 'alpha',
                  filePath: 'alpha.dart',
                  lineNumber: 3,
                  callType: CallType.direct,
                ),
                CallSource(
                  callingFunction: 'beta',
                  filePath: 'beta.dart',
                  lineNumber: 4,
                  callType: CallType.direct,
                ),
              ],
            );
          default:
            return const ResolvedCalls();
        }
      });

      final result = grapher.buildDependencyMap('root');

      expect(result.hasCircularChain, isTrue);
      expect(result.circularParticipants, ['alpha', 'beta']);
    });

    test('handles multiple callers at same level', () {
      final grapher = DependencyGrapher((functionName) {
        if (functionName == 'target') {
          return const ResolvedCalls(callers: [
            CallSource(
              callingFunction: 'caller1',
              filePath: 'file1.dart',
              lineNumber: 10,
              callType: CallType.direct,
            ),
            CallSource(
              callingFunction: 'caller2',
              filePath: 'file2.dart',
              lineNumber: 20,
              callType: CallType.providerWatch,
            ),
          ]);
        }
        return const ResolvedCalls();
      });

      final result = grapher.buildDependencyMap('target');

      expect(result.upstreamCallers.length, 2);
      expect(result.upstreamCallers[0].functionName, 'caller1');
      expect(result.upstreamCallers[1].functionName, 'caller2');
    });

    test('avoids infinite loop on self-referencing function', () {
      final grapher = DependencyGrapher((functionName) {
        return ResolvedCalls(callers: [
          CallSource(
            callingFunction: functionName,
            filePath: 'self.dart',
            lineNumber: 1,
            callType: CallType.direct,
          ),
        ]);
      });

      final result = grapher.buildDependencyMap('recursive');

      // Should not hang or overflow - self-references are skipped
      expect(result.upstreamCallers, isEmpty);
    });

    test('avoids infinite loop on mutual recursion in upstream', () {
      final grapher = DependencyGrapher((functionName) {
        switch (functionName) {
          case 'a':
            return const ResolvedCalls(callers: [
              CallSource(
                callingFunction: 'b',
                filePath: 'b.dart',
                lineNumber: 1,
                callType: CallType.direct,
              ),
            ]);
          case 'b':
            return const ResolvedCalls(callers: [
              CallSource(
                callingFunction: 'a',
                filePath: 'a.dart',
                lineNumber: 1,
                callType: CallType.direct,
              ),
            ]);
          default:
            return const ResolvedCalls();
        }
      });

      // Should not hang - visited set prevents infinite recursion
      final result = grapher.buildDependencyMap('a');
      expect(result.upstreamCallers.length, 1);
      expect(result.upstreamCallers[0].functionName, 'b');
    });

    test('maxDepth constant is 3', () {
      expect(DependencyGrapher.maxDepth, 3);
    });
  });
}
