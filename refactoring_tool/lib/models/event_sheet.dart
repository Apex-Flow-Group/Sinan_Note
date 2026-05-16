/// نوع الحدث
enum EventType {
  directCall,
  providerRebuild,
  streamSubscription,
  methodChannelIncoming,
  navigatorCallback,
  lifecycleCallback,
  notifyListeners,
  streamEmission,
  navigatorCall,
  methodChannelOutgoing,
}

/// يمثل إدخال حدث واحد
class EventEntry {
  final EventType type;
  final String targetOrSource;
  final String filePath;
  final int lineNumber;

  const EventEntry({
    required this.type,
    required this.targetOrSource,
    required this.filePath,
    required this.lineNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'targetOrSource': targetOrSource,
      'filePath': filePath,
      'lineNumber': lineNumber,
    };
  }

  factory EventEntry.fromJson(Map<String, dynamic> json) {
    return EventEntry(
      type: EventType.values.byName(json['type'] as String),
      targetOrSource: json['targetOrSource'] as String,
      filePath: json['filePath'] as String,
      lineNumber: json['lineNumber'] as int,
    );
  }

  @override
  String toString() =>
      'EventEntry(${type.name}: $targetOrSource at $filePath:$lineNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventEntry &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          targetOrSource == other.targetOrSource &&
          filePath == other.filePath &&
          lineNumber == other.lineNumber;

  @override
  int get hashCode => Object.hash(type, targetOrSource, filePath, lineNumber);
}

/// خريطة الأحداث لدالة
class EventSheet {
  final String functionName;
  final String filePath;
  final List<EventEntry> incomingEvents;
  final List<EventEntry> outgoingEvents;
  final bool isEventIsolated;

  const EventSheet({
    required this.functionName,
    required this.filePath,
    this.incomingEvents = const [],
    this.outgoingEvents = const [],
    required this.isEventIsolated,
  });

  Map<String, dynamic> toJson() {
    return {
      'functionName': functionName,
      'filePath': filePath,
      'incomingEvents': incomingEvents.map((e) => e.toJson()).toList(),
      'outgoingEvents': outgoingEvents.map((e) => e.toJson()).toList(),
      'isEventIsolated': isEventIsolated,
    };
  }

  factory EventSheet.fromJson(Map<String, dynamic> json) {
    return EventSheet(
      functionName: json['functionName'] as String,
      filePath: json['filePath'] as String,
      incomingEvents: (json['incomingEvents'] as List<dynamic>?)
              ?.map((e) => EventEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      outgoingEvents: (json['outgoingEvents'] as List<dynamic>?)
              ?.map((e) => EventEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isEventIsolated: json['isEventIsolated'] as bool,
    );
  }

  @override
  String toString() =>
      'EventSheet($functionName: ${incomingEvents.length} incoming, ${outgoingEvents.length} outgoing, isolated: $isEventIsolated)';
}
