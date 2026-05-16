/// يمثل حالة ملف أساسي في قائمة الانتظار
enum CoreFileStatus { notStarted, inProgress, completed }

/// يمثل ملف أساسي في قائمة الانتظار
class CoreFileEntry {
  final String filePath;
  final int directImportCount;
  final int dependencyDepth;
  final List<String> circularDeps;
  final CoreFileStatus status;

  const CoreFileEntry({
    required this.filePath,
    required this.directImportCount,
    required this.dependencyDepth,
    this.circularDeps = const [],
    this.status = CoreFileStatus.notStarted,
  });

  CoreFileEntry copyWith({
    String? filePath,
    int? directImportCount,
    int? dependencyDepth,
    List<String>? circularDeps,
    CoreFileStatus? status,
  }) {
    return CoreFileEntry(
      filePath: filePath ?? this.filePath,
      directImportCount: directImportCount ?? this.directImportCount,
      dependencyDepth: dependencyDepth ?? this.dependencyDepth,
      circularDeps: circularDeps ?? this.circularDeps,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'directImportCount': directImportCount,
      'dependencyDepth': dependencyDepth,
      'circularDeps': circularDeps,
      'status': status.name,
    };
  }

  factory CoreFileEntry.fromJson(Map<String, dynamic> json) {
    return CoreFileEntry(
      filePath: json['filePath'] as String,
      directImportCount: json['directImportCount'] as int,
      dependencyDepth: json['dependencyDepth'] as int,
      circularDeps: (json['circularDeps'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: CoreFileStatus.values.byName(json['status'] as String),
    );
  }

  @override
  String toString() =>
      'CoreFileEntry(filePath: $filePath, depth: $dependencyDepth, status: ${status.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreFileEntry &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath;

  @override
  int get hashCode => filePath.hashCode;
}
