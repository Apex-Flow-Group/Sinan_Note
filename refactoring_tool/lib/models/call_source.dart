/// نوع الاستدعاء
enum CallType {
  direct,
  providerRead,
  providerWatch,
  callback,
  streamListen,
  methodChannel,
}

/// يمثل مصدر استدعاء لدالة
class CallSource {
  final String callingFunction;
  final String filePath;
  final int lineNumber;
  final CallType callType;

  const CallSource({
    required this.callingFunction,
    required this.filePath,
    required this.lineNumber,
    required this.callType,
  });

  Map<String, dynamic> toJson() {
    return {
      'callingFunction': callingFunction,
      'filePath': filePath,
      'lineNumber': lineNumber,
      'callType': callType.name,
    };
  }

  factory CallSource.fromJson(Map<String, dynamic> json) {
    return CallSource(
      callingFunction: json['callingFunction'] as String,
      filePath: json['filePath'] as String,
      lineNumber: json['lineNumber'] as int,
      callType: CallType.values.byName(json['callType'] as String),
    );
  }

  @override
  String toString() =>
      'CallSource($callingFunction in $filePath:$lineNumber [${callType.name}])';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallSource &&
          runtimeType == other.runtimeType &&
          callingFunction == other.callingFunction &&
          filePath == other.filePath &&
          lineNumber == other.lineNumber &&
          callType == other.callType;

  @override
  int get hashCode =>
      Object.hash(callingFunction, filePath, lineNumber, callType);
}
