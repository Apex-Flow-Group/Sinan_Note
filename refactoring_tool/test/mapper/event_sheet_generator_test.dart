import 'package:refactoring_tool/mapper/event_sheet_generator.dart';
import 'package:refactoring_tool/models/call_source.dart';
import 'package:refactoring_tool/models/event_sheet.dart';
import 'package:refactoring_tool/models/function_unit.dart';
import 'package:test/test.dart';

void main() {
  late EventSheetGenerator generator;

  setUp(() {
    generator = EventSheetGenerator();
  });

  FunctionUnit createFunction({
    String name = 'testFunction',
    String filePath = 'lib/test.dart',
    int startLine = 10,
    String body = '',
  }) {
    final lines = body.split('\n').length;
    return FunctionUnit(
      name: name,
      filePath: filePath,
      startLine: startLine,
      endLine: startLine + lines - 1,
      lineCount: lines,
      signature: 'void $name()',
      returnType: 'void',
      body: body,
      type: FunctionType.method,
    );
  }

  group('EventSheetGenerator', () {
    group('incoming events', () {
      test('maps direct call sources to directCall event type', () {
        final fn = createFunction();
        final callSources = [
          const CallSource(
            callingFunction: 'initState',
            filePath: 'lib/screens/home.dart',
            lineNumber: 34,
            callType: CallType.direct,
          ),
        ];

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: callSources,
          functionBody: '',
        );

        expect(sheet.incomingEvents.length, 1);
        expect(sheet.incomingEvents[0].type, EventType.directCall);
        expect(sheet.incomingEvents[0].targetOrSource, 'initState');
        expect(sheet.incomingEvents[0].filePath, 'lib/screens/home.dart');
        expect(sheet.incomingEvents[0].lineNumber, 34);
      });

      test('maps providerRead to providerRebuild event type', () {
        final fn = createFunction();
        final callSources = [
          const CallSource(
            callingFunction: 'build',
            filePath: 'lib/widgets/note_list.dart',
            lineNumber: 12,
            callType: CallType.providerRead,
          ),
        ];

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: callSources,
          functionBody: '',
        );

        expect(sheet.incomingEvents[0].type, EventType.providerRebuild);
      });

      test('maps providerWatch to providerRebuild event type', () {
        final fn = createFunction();
        final callSources = [
          const CallSource(
            callingFunction: 'build',
            filePath: 'lib/widgets/note_list.dart',
            lineNumber: 15,
            callType: CallType.providerWatch,
          ),
        ];

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: callSources,
          functionBody: '',
        );

        expect(sheet.incomingEvents[0].type, EventType.providerRebuild);
      });

      test('maps streamListen to streamSubscription event type', () {
        final fn = createFunction();
        final callSources = [
          const CallSource(
            callingFunction: 'setupListeners',
            filePath: 'lib/services/sync.dart',
            lineNumber: 45,
            callType: CallType.streamListen,
          ),
        ];

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: callSources,
          functionBody: '',
        );

        expect(sheet.incomingEvents[0].type, EventType.streamSubscription);
      });

      test('maps methodChannel to methodChannelIncoming event type', () {
        final fn = createFunction();
        final callSources = [
          const CallSource(
            callingFunction: 'handlePlatformCall',
            filePath: 'lib/services/platform.dart',
            lineNumber: 20,
            callType: CallType.methodChannel,
          ),
        ];

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: callSources,
          functionBody: '',
        );

        expect(sheet.incomingEvents[0].type, EventType.methodChannelIncoming);
      });

      test('maps callback to navigatorCallback event type', () {
        final fn = createFunction();
        final callSources = [
          const CallSource(
            callingFunction: 'onRouteComplete',
            filePath: 'lib/routes/router.dart',
            lineNumber: 88,
            callType: CallType.callback,
          ),
        ];

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: callSources,
          functionBody: '',
        );

        expect(sheet.incomingEvents[0].type, EventType.navigatorCallback);
      });

      test('handles multiple call sources', () {
        final fn = createFunction();
        final callSources = [
          const CallSource(
            callingFunction: 'initState',
            filePath: 'lib/screens/home.dart',
            lineNumber: 34,
            callType: CallType.direct,
          ),
          const CallSource(
            callingFunction: 'build',
            filePath: 'lib/widgets/note_list.dart',
            lineNumber: 12,
            callType: CallType.providerWatch,
          ),
          const CallSource(
            callingFunction: 'onData',
            filePath: 'lib/services/sync.dart',
            lineNumber: 50,
            callType: CallType.streamListen,
          ),
        ];

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: callSources,
          functionBody: '',
        );

        expect(sheet.incomingEvents.length, 3);
        expect(sheet.incomingEvents[0].type, EventType.directCall);
        expect(sheet.incomingEvents[1].type, EventType.providerRebuild);
        expect(sheet.incomingEvents[2].type, EventType.streamSubscription);
      });
    });

    group('outgoing events', () {
      test('detects notifyListeners() calls', () {
        const body = '''
    _notes = fetchedNotes;
    notifyListeners();
''';
        final fn = createFunction(body: body);

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: [],
          functionBody: body,
        );

        expect(sheet.outgoingEvents.length, 1);
        expect(sheet.outgoingEvents[0].type, EventType.notifyListeners);
        expect(sheet.outgoingEvents[0].targetOrSource, 'notifyListeners()');
      });

      test('detects StreamController.add() calls', () {
        const body = '''
    _streamController.add(newData);
''';
        final fn = createFunction(body: body);

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: [],
          functionBody: body,
        );

        expect(sheet.outgoingEvents.length, 1);
        expect(sheet.outgoingEvents[0].type, EventType.streamEmission);
        expect(
            sheet.outgoingEvents[0].targetOrSource, '_streamController.add()');
      });

      test('detects sink.add() calls', () {
        const body = '''
    _controller.sink.add(event);
''';
        final fn = createFunction(body: body);

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: [],
          functionBody: body,
        );

        expect(sheet.outgoingEvents.length, 1);
        expect(sheet.outgoingEvents[0].type, EventType.streamEmission);
        expect(
            sheet.outgoingEvents[0].targetOrSource, '_controller.sink.add()');
      });

      test('detects Navigator.push calls', () {
        const body = '''
    Navigator.push(context, route);
''';
        final fn = createFunction(body: body);

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: [],
          functionBody: body,
        );

        expect(sheet.outgoingEvents.length, 1);
        expect(sheet.outgoingEvents[0].type, EventType.navigatorCall);
        expect(sheet.outgoingEvents[0].targetOrSource, 'Navigator.push');
      });

      test('detects Navigator.of(context).pop calls', () {
        const body = '''
    Navigator.of(context).pop();
''';
        final fn = createFunction(body: body);

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: [],
          functionBody: body,
        );

        expect(sheet.outgoingEvents.length, 1);
        expect(sheet.outgoingEvents[0].type, EventType.navigatorCall);
        expect(sheet.outgoingEvents[0].targetOrSource, 'Navigator.pop');
      });

      test('detects MethodChannel invokeMethod calls', () {
        const body = '''
    await _channel.invokeMethod('getData');
''';
        final fn = createFunction(body: body);

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: [],
          functionBody: body,
        );

        expect(sheet.outgoingEvents.length, 1);
        expect(sheet.outgoingEvents[0].type, EventType.methodChannelOutgoing);
        expect(
            sheet.outgoingEvents[0].targetOrSource, '_channel.invokeMethod()');
      });

      test('detects multiple outgoing events in same body', () {
        const body = '''
    _notes = fetchedNotes;
    notifyListeners();
    _streamController.add(fetchedNotes);
    Navigator.pop(context);
''';
        final fn = createFunction(body: body);

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: [],
          functionBody: body,
        );

        expect(sheet.outgoingEvents.length, 3);
        expect(sheet.outgoingEvents[0].type, EventType.notifyListeners);
        expect(sheet.outgoingEvents[1].type, EventType.streamEmission);
        expect(sheet.outgoingEvents[2].type, EventType.navigatorCall);
      });
    });

    group('event isolation', () {
      test('flags function as event-isolated when no events', () {
        final fn = createFunction(body: 'return 42;');

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: [],
          functionBody: 'return 42;',
        );

        expect(sheet.isEventIsolated, isTrue);
        expect(sheet.incomingEvents, isEmpty);
        expect(sheet.outgoingEvents, isEmpty);
      });

      test('not event-isolated when has incoming events', () {
        final fn = createFunction(body: 'return 42;');
        final callSources = [
          const CallSource(
            callingFunction: 'caller',
            filePath: 'lib/a.dart',
            lineNumber: 5,
            callType: CallType.direct,
          ),
        ];

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: callSources,
          functionBody: 'return 42;',
        );

        expect(sheet.isEventIsolated, isFalse);
      });

      test('not event-isolated when has outgoing events', () {
        const body = 'notifyListeners();';
        final fn = createFunction(body: body);

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: [],
          functionBody: body,
        );

        expect(sheet.isEventIsolated, isFalse);
      });
    });

    group('EventSheet metadata', () {
      test('includes correct function name and file path', () {
        final fn = createFunction(
          name: 'loadNotes',
          filePath: 'lib/controllers/notes_provider.dart',
        );

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: [],
          functionBody: '',
        );

        expect(sheet.functionName, 'loadNotes');
        expect(sheet.filePath, 'lib/controllers/notes_provider.dart');
      });

      test('line numbers are correct for outgoing events', () {
        const body = '''line1
line2
notifyListeners();
line4''';
        final fn = createFunction(body: body, startLine: 20);

        final sheet = generator.generate(
          functionUnit: fn,
          callSources: [],
          functionBody: body,
        );

        // notifyListeners is on line index 2, so lineNumber = 20 + 2 = 22
        expect(sheet.outgoingEvents[0].lineNumber, 22);
      });
    });
  });
}
