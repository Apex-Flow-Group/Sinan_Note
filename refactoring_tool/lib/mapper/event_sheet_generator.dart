import 'package:refactoring_tool/models/call_source.dart';
import 'package:refactoring_tool/models/event_sheet.dart';
import 'package:refactoring_tool/models/function_unit.dart';

/// يولّد خريطة الأحداث (Event_Sheet) لدالة معينة
///
/// يحلل مصادر الاستدعاء الواردة ويصنفها حسب النوع،
/// ويحلل جسم الدالة لاكتشاف الأحداث الصادرة.
class EventSheetGenerator {
  /// يولّد [EventSheet] لدالة معينة
  ///
  /// [functionUnit] - الدالة المراد تحليلها
  /// [callSources] - مصادر الاستدعاء الواردة للدالة
  /// [functionBody] - جسم الدالة لتحليل الأحداث الصادرة
  EventSheet generate({
    required FunctionUnit functionUnit,
    required List<CallSource> callSources,
    required String functionBody,
  }) {
    final incomingEvents = _buildIncomingEvents(callSources);
    final outgoingEvents = _buildOutgoingEvents(functionBody, functionUnit);
    final isEventIsolated = incomingEvents.isEmpty && outgoingEvents.isEmpty;

    return EventSheet(
      functionName: functionUnit.name,
      filePath: functionUnit.filePath,
      incomingEvents: incomingEvents,
      outgoingEvents: outgoingEvents,
      isEventIsolated: isEventIsolated,
    );
  }

  /// يبني قائمة الأحداث الواردة من مصادر الاستدعاء
  List<EventEntry> _buildIncomingEvents(List<CallSource> callSources) {
    return callSources.map((source) {
      final eventType = _mapCallTypeToEventType(source.callType);
      return EventEntry(
        type: eventType,
        targetOrSource: source.callingFunction,
        filePath: source.filePath,
        lineNumber: source.lineNumber,
      );
    }).toList();
  }

  /// يحوّل نوع الاستدعاء إلى نوع حدث وارد
  EventType _mapCallTypeToEventType(CallType callType) {
    switch (callType) {
      case CallType.direct:
        return EventType.directCall;
      case CallType.providerRead:
      case CallType.providerWatch:
        return EventType.providerRebuild;
      case CallType.streamListen:
        return EventType.streamSubscription;
      case CallType.methodChannel:
        return EventType.methodChannelIncoming;
      case CallType.callback:
        return EventType.navigatorCallback;
    }
  }

  /// يبني قائمة الأحداث الصادرة بتحليل جسم الدالة
  List<EventEntry> _buildOutgoingEvents(
    String functionBody,
    FunctionUnit functionUnit,
  ) {
    final outgoing = <EventEntry>[];
    final lines = functionBody.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = functionUnit.startLine + i;

      // notifyListeners()
      _checkNotifyListeners(line, lineNumber, functionUnit, outgoing);

      // StreamController.add() / .sink.add()
      _checkStreamEmission(line, lineNumber, functionUnit, outgoing);

      // Navigator calls
      _checkNavigatorCalls(line, lineNumber, functionUnit, outgoing);

      // MethodChannel outgoing (invokeMethod)
      _checkMethodChannelOutgoing(line, lineNumber, functionUnit, outgoing);
    }

    return outgoing;
  }

  /// يكتشف استدعاءات notifyListeners()
  void _checkNotifyListeners(
    String line,
    int lineNumber,
    FunctionUnit functionUnit,
    List<EventEntry> outgoing,
  ) {
    final pattern = RegExp(r'notifyListeners\s*\(');
    if (pattern.hasMatch(line)) {
      outgoing.add(EventEntry(
        type: EventType.notifyListeners,
        targetOrSource: 'notifyListeners()',
        filePath: functionUnit.filePath,
        lineNumber: lineNumber,
      ));
    }
  }

  /// يكتشف إرسال أحداث عبر Stream
  void _checkStreamEmission(
    String line,
    int lineNumber,
    FunctionUnit functionUnit,
    List<EventEntry> outgoing,
  ) {
    // StreamController.add(), .sink.add(), StreamController.addError()
    final addPattern = RegExp(r'(\w+)\s*\.\s*add\s*\(');
    final sinkAddPattern = RegExp(r'(\w+)\s*\.\s*sink\s*\.\s*add\s*\(');
    final addErrorPattern = RegExp(r'(\w+)\s*\.\s*addError\s*\(');

    RegExpMatch? match;

    match = sinkAddPattern.firstMatch(line);
    if (match != null) {
      outgoing.add(EventEntry(
        type: EventType.streamEmission,
        targetOrSource: '${match.group(1)}.sink.add()',
        filePath: functionUnit.filePath,
        lineNumber: lineNumber,
      ));
      return;
    }

    match = addErrorPattern.firstMatch(line);
    if (match != null) {
      outgoing.add(EventEntry(
        type: EventType.streamEmission,
        targetOrSource: '${match.group(1)}.addError()',
        filePath: functionUnit.filePath,
        lineNumber: lineNumber,
      ));
      return;
    }

    match = addPattern.firstMatch(line);
    if (match != null) {
      // تجنب الإيجابيات الكاذبة: تحقق أن الاسم يحتوي على controller/stream
      final identifier = match.group(1)!.toLowerCase();
      if (identifier.contains('controller') ||
          identifier.contains('stream') ||
          identifier.contains('sink') ||
          identifier.startsWith('_') && line.contains('Controller')) {
        outgoing.add(EventEntry(
          type: EventType.streamEmission,
          targetOrSource: '${match.group(1)}.add()',
          filePath: functionUnit.filePath,
          lineNumber: lineNumber,
        ));
      }
    }
  }

  /// يكتشف استدعاءات Navigator
  void _checkNavigatorCalls(
    String line,
    int lineNumber,
    FunctionUnit functionUnit,
    List<EventEntry> outgoing,
  ) {
    final navigatorPatterns = [
      RegExp(r'Navigator\s*\.\s*of\s*\(\s*\w*\s*\)\s*\.\s*(\w+)'),
      RegExp(
          r'Navigator\s*\.\s*(push|pop|pushReplacement|pushNamed|pushAndRemoveUntil|popUntil|popAndPushNamed|replace|pushNamedAndRemoveUntil)\s*[(<]'),
      RegExp(
          r'navigator\s*\.\s*(push|pop|pushReplacement|pushNamed|pushAndRemoveUntil|popUntil|popAndPushNamed|replace|pushNamedAndRemoveUntil)\s*[(<]'),
    ];

    for (final pattern in navigatorPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final method = match.group(1) ?? 'navigate';
        outgoing.add(EventEntry(
          type: EventType.navigatorCall,
          targetOrSource: 'Navigator.$method',
          filePath: functionUnit.filePath,
          lineNumber: lineNumber,
        ));
        return; // واحد فقط لكل سطر
      }
    }

    // GoRouter patterns
    final goRouterPatterns = [
      RegExp(r'context\s*\.\s*(go|push|pop|pushReplacement|pushNamed)\s*[(<]'),
      RegExp(r'GoRouter\s*\.\s*of\s*\(\s*\w*\s*\)\s*\.\s*(\w+)'),
    ];

    for (final pattern in goRouterPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final method = match.group(1) ?? 'navigate';
        outgoing.add(EventEntry(
          type: EventType.navigatorCall,
          targetOrSource: 'GoRouter.$method',
          filePath: functionUnit.filePath,
          lineNumber: lineNumber,
        ));
        return;
      }
    }
  }

  /// يكتشف استدعاءات MethodChannel الصادرة (invokeMethod)
  void _checkMethodChannelOutgoing(
    String line,
    int lineNumber,
    FunctionUnit functionUnit,
    List<EventEntry> outgoing,
  ) {
    final pattern = RegExp(r'(\w+)\s*\.\s*invokeMethod\s*[(<]');
    final match = pattern.firstMatch(line);
    if (match != null) {
      outgoing.add(EventEntry(
        type: EventType.methodChannelOutgoing,
        targetOrSource: '${match.group(1)}.invokeMethod()',
        filePath: functionUnit.filePath,
        lineNumber: lineNumber,
      ));
    }
  }
}
