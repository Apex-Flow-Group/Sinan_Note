/// نوع الدالة
enum FunctionType { method, constructor, topLevel, buildMethod, getter, setter }

/// حالة المراجعة
enum ReviewStatus { pending, reviewed, refactored, pendingReview }

/// يمثل معامل دالة
class Parameter {
  final String name;
  final String type;
  final bool isRequired;
  final bool isNamed;
  final String? defaultValue;

  const Parameter({
    required this.name,
    required this.type,
    this.isRequired = true,
    this.isNamed = false,
    this.defaultValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'isRequired': isRequired,
      'isNamed': isNamed,
      if (defaultValue != null) 'defaultValue': defaultValue,
    };
  }

  factory Parameter.fromJson(Map<String, dynamic> json) {
    return Parameter(
      name: json['name'] as String,
      type: json['type'] as String,
      isRequired: json['isRequired'] as bool? ?? true,
      isNamed: json['isNamed'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String?,
    );
  }

  @override
  String toString() => '$type $name';
}

/// يمثل دالة واحدة قابلة للتحليل
class FunctionUnit {
  final String name;
  final String filePath;
  final int startLine;
  final int endLine;
  final int lineCount;
  final String signature;
  final String returnType;
  final List<Parameter> params;
  final String body;
  final FunctionType type;
  final ReviewStatus reviewStatus;

  const FunctionUnit({
    required this.name,
    required this.filePath,
    required this.startLine,
    required this.endLine,
    required this.lineCount,
    required this.signature,
    required this.returnType,
    this.params = const [],
    required this.body,
    required this.type,
    this.reviewStatus = ReviewStatus.pending,
  });

  FunctionUnit copyWith({
    String? name,
    String? filePath,
    int? startLine,
    int? endLine,
    int? lineCount,
    String? signature,
    String? returnType,
    List<Parameter>? params,
    String? body,
    FunctionType? type,
    ReviewStatus? reviewStatus,
  }) {
    return FunctionUnit(
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      lineCount: lineCount ?? this.lineCount,
      signature: signature ?? this.signature,
      returnType: returnType ?? this.returnType,
      params: params ?? this.params,
      body: body ?? this.body,
      type: type ?? this.type,
      reviewStatus: reviewStatus ?? this.reviewStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'filePath': filePath,
      'startLine': startLine,
      'endLine': endLine,
      'lineCount': lineCount,
      'signature': signature,
      'returnType': returnType,
      'params': params.map((p) => p.toJson()).toList(),
      'body': body,
      'type': type.name,
      'reviewStatus': reviewStatus.name,
    };
  }

  factory FunctionUnit.fromJson(Map<String, dynamic> json) {
    return FunctionUnit(
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      startLine: json['startLine'] as int,
      endLine: json['endLine'] as int,
      lineCount: json['lineCount'] as int,
      signature: json['signature'] as String,
      returnType: json['returnType'] as String,
      params: (json['params'] as List<dynamic>?)
              ?.map((e) => Parameter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      body: json['body'] as String,
      type: FunctionType.values.byName(json['type'] as String),
      reviewStatus: ReviewStatus.values.byName(json['reviewStatus'] as String),
    );
  }

  @override
  String toString() =>
      'FunctionUnit(name: $name, type: ${type.name}, lines: $lineCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunctionUnit &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          filePath == other.filePath &&
          startLine == other.startLine;

  @override
  int get hashCode => Object.hash(name, filePath, startLine);
}
