import 'package:refactoring_tool/models/core_file_entry.dart';

/// تقدم ملف أساسي واحد
class CoreFileProgress {
  final String filePath;
  final CoreFileStatus status;
  final int totalFunctions;
  final int reviewedFunctions;
  final List<String> reviewedFunctionNames;
  final List<String> pendingFunctionNames;

  const CoreFileProgress({
    required this.filePath,
    required this.status,
    required this.totalFunctions,
    required this.reviewedFunctions,
    this.reviewedFunctionNames = const [],
    this.pendingFunctionNames = const [],
  });

  CoreFileProgress copyWith({
    String? filePath,
    CoreFileStatus? status,
    int? totalFunctions,
    int? reviewedFunctions,
    List<String>? reviewedFunctionNames,
    List<String>? pendingFunctionNames,
  }) {
    return CoreFileProgress(
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      totalFunctions: totalFunctions ?? this.totalFunctions,
      reviewedFunctions: reviewedFunctions ?? this.reviewedFunctions,
      reviewedFunctionNames:
          reviewedFunctionNames ?? this.reviewedFunctionNames,
      pendingFunctionNames: pendingFunctionNames ?? this.pendingFunctionNames,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': filePath,
      'status': status.name,
      'totalFunctions': totalFunctions,
      'reviewedFunctions': reviewedFunctions,
      'reviewed': reviewedFunctionNames,
      'pending': pendingFunctionNames,
    };
  }

  factory CoreFileProgress.fromJson(Map<String, dynamic> json) {
    return CoreFileProgress(
      filePath: json['path'] as String,
      status: CoreFileStatus.values.byName(json['status'] as String),
      totalFunctions: json['totalFunctions'] as int,
      reviewedFunctions: json['reviewedFunctions'] as int,
      reviewedFunctionNames: (json['reviewed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      pendingFunctionNames: (json['pending'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      'CoreFileProgress($filePath: $reviewedFunctions/$totalFunctions, ${status.name})';
}

/// متتبع التقدم العام
class ProgressTracker {
  final int totalCoreFiles;
  final int completedCoreFiles;
  final int totalFunctionUnits;
  final int reviewedFunctionUnits;
  final double completionPercentage;
  final DateTime startDate;
  final DateTime lastUpdated;
  final List<CoreFileProgress> fileProgress;

  const ProgressTracker({
    required this.totalCoreFiles,
    required this.completedCoreFiles,
    required this.totalFunctionUnits,
    required this.reviewedFunctionUnits,
    required this.completionPercentage,
    required this.startDate,
    required this.lastUpdated,
    this.fileProgress = const [],
  });

  ProgressTracker copyWith({
    int? totalCoreFiles,
    int? completedCoreFiles,
    int? totalFunctionUnits,
    int? reviewedFunctionUnits,
    double? completionPercentage,
    DateTime? startDate,
    DateTime? lastUpdated,
    List<CoreFileProgress>? fileProgress,
  }) {
    return ProgressTracker(
      totalCoreFiles: totalCoreFiles ?? this.totalCoreFiles,
      completedCoreFiles: completedCoreFiles ?? this.completedCoreFiles,
      totalFunctionUnits: totalFunctionUnits ?? this.totalFunctionUnits,
      reviewedFunctionUnits:
          reviewedFunctionUnits ?? this.reviewedFunctionUnits,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      startDate: startDate ?? this.startDate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      fileProgress: fileProgress ?? this.fileProgress,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'totalCoreFiles': totalCoreFiles,
      'completedCoreFiles': completedCoreFiles,
      'totalFunctionUnits': totalFunctionUnits,
      'reviewedFunctionUnits': reviewedFunctionUnits,
      'completionPercentage': completionPercentage,
      'files': fileProgress.map((f) => f.toJson()).toList(),
    };
  }

  factory ProgressTracker.fromJson(Map<String, dynamic> json) {
    return ProgressTracker(
      startDate: DateTime.parse(json['startDate'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      totalCoreFiles: json['totalCoreFiles'] as int,
      completedCoreFiles: json['completedCoreFiles'] as int,
      totalFunctionUnits: json['totalFunctionUnits'] as int,
      reviewedFunctionUnits: json['reviewedFunctionUnits'] as int,
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
      fileProgress: (json['files'] as List<dynamic>?)
              ?.map((e) => CoreFileProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      'ProgressTracker($reviewedFunctionUnits/$totalFunctionUnits functions, ${completionPercentage.toStringAsFixed(1)}%)';
}
