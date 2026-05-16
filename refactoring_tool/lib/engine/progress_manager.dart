import 'package:refactoring_tool/models/core_file_entry.dart';
import 'package:refactoring_tool/models/progress_tracker.dart';
import 'package:refactoring_tool/storage/storage_manager.dart';

/// يدير تتبع التقدم العام لعملية إعادة الهيكلة.
///
/// يحافظ على حالة التقدم (عدد الملفات، الدوال المراجعة، النسبة المئوية)
/// ويحفظ التحديثات تلقائياً عبر [StorageManager] بعد كل عملية.
class ProgressManager {
  final StorageManager _storage;

  /// التقدم الحالي - يُحمّل من التخزين أو يُنشأ جديداً
  ProgressTracker _tracker;

  /// آخر شهر تم فيه توليد تقرير شهري (yyyy-MM)
  String? _lastReportMonth;

  ProgressManager({required StorageManager storage})
      : _storage = storage,
        _tracker = ProgressTracker(
          totalCoreFiles: 0,
          completedCoreFiles: 0,
          totalFunctionUnits: 0,
          reviewedFunctionUnits: 0,
          completionPercentage: 0.0,
          startDate: DateTime.now(),
          lastUpdated: DateTime.now(),
          fileProgress: [],
        );

  /// التقدم الحالي (للقراءة فقط)
  ProgressTracker get tracker => _tracker;

  /// تحميل التقدم الموجود من التخزين أو إنشاء جديد.
  Future<void> load() async {
    final data = await _storage.loadProgress();
    if (data != null) {
      _tracker = ProgressTracker.fromJson(data);
      // استخراج آخر شهر تقرير من lastUpdated
      _lastReportMonth = _monthKey(_tracker.lastUpdated);
    }
  }

  /// تهيئة التقدم بعدد الملفات والدوال الإجمالي.
  ///
  /// يُستخدم عند بدء دورة إعادة هيكلة جديدة.
  Future<void> initializeProgress({
    required int totalFiles,
    required int totalFunctions,
  }) async {
    final now = DateTime.now();
    _tracker = ProgressTracker(
      totalCoreFiles: totalFiles,
      completedCoreFiles: 0,
      totalFunctionUnits: totalFunctions,
      reviewedFunctionUnits: 0,
      completionPercentage: 0.0,
      startDate: now,
      lastUpdated: now,
      fileProgress: [],
    );
    _lastReportMonth = _monthKey(now);
    await _persist();
  }

  /// بدء العمل على ملف: تسجيل أسماء الدوال وتعيين الحالة "in_progress".
  ///
  /// يُستدعى عند تقديم أول دالة في الملف للتحليل.
  /// [filePath] مسار الملف النسبي.
  /// [functionNames] أسماء جميع الدوال القابلة للتحليل في الملف.
  Future<void> startFile(String filePath, List<String> functionNames) async {
    final existingIndex =
        _tracker.fileProgress.indexWhere((f) => f.filePath == filePath);

    final fileProgress = CoreFileProgress(
      filePath: filePath,
      status: CoreFileStatus.inProgress,
      totalFunctions: functionNames.length,
      reviewedFunctions: 0,
      reviewedFunctionNames: [],
      pendingFunctionNames: List<String>.from(functionNames),
    );

    final updatedFiles = List<CoreFileProgress>.from(_tracker.fileProgress);
    if (existingIndex >= 0) {
      updatedFiles[existingIndex] = fileProgress;
    } else {
      updatedFiles.add(fileProgress);
    }

    _tracker = _tracker.copyWith(
      fileProgress: updatedFiles,
      lastUpdated: DateTime.now(),
    );

    await _persist();
  }

  /// تعليم دالة كمراجعة (reviewed) - تم تقييمها بدون تعديل.
  ///
  /// يُحدّث التقدم العام وتقدم الملف في نفس العملية (Req 8.2).
  /// يُعيّن حالة الملف "completed" إذا تمت مراجعة جميع الدوال (Req 8.4).
  Future<void> markFunctionReviewed(
      String filePath, String functionName) async {
    await _markFunction(filePath, functionName);
  }

  /// تعليم دالة كمُعاد هيكلتها (refactored) - تم تقييمها وتعديلها.
  ///
  /// يُحدّث التقدم العام وتقدم الملف في نفس العملية (Req 8.2).
  /// يُعيّن حالة الملف "completed" إذا تمت مراجعة جميع الدوال (Req 8.4).
  Future<void> markFunctionRefactored(
      String filePath, String functionName) async {
    await _markFunction(filePath, functionName);
  }

  /// إكمال ملف يدوياً (يُستخدم كبديل عند الحاجة).
  ///
  /// يُعيّن حالة الملف "completed" ويُحدّث عدد الملفات المكتملة.
  Future<void> completeFile(String filePath) async {
    final fileIndex =
        _tracker.fileProgress.indexWhere((f) => f.filePath == filePath);
    if (fileIndex < 0) return;

    final file = _tracker.fileProgress[fileIndex];
    if (file.status == CoreFileStatus.completed) return;

    final updatedFile = file.copyWith(status: CoreFileStatus.completed);
    final updatedFiles = List<CoreFileProgress>.from(_tracker.fileProgress);
    updatedFiles[fileIndex] = updatedFile;

    // حساب عدد الملفات المكتملة
    final completedCount =
        updatedFiles.where((f) => f.status == CoreFileStatus.completed).length;

    _tracker = _tracker.copyWith(
      fileProgress: updatedFiles,
      completedCoreFiles: completedCount,
      lastUpdated: DateTime.now(),
    );

    await _persist();
    await _checkMonthBoundary();
  }

  /// توليد تقرير شهري للشهر الحالي.
  ///
  /// يُولّد تلقائياً عند عبور حدود الشهر (Req 8.5).
  Future<Map<String, dynamic>> generateMonthlyReport({
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final monthKey = _monthKey(now);

    final report = <String, dynamic>{
      'month': monthKey,
      'generatedAt': now.toIso8601String(),
      'totalCoreFiles': _tracker.totalCoreFiles,
      'completedCoreFiles': _tracker.completedCoreFiles,
      'totalFunctionUnits': _tracker.totalFunctionUnits,
      'reviewedFunctionUnits': _tracker.reviewedFunctionUnits,
      'completionPercentage': _tracker.completionPercentage,
      'filesProcessed': _tracker.fileProgress
          .where((f) => f.status == CoreFileStatus.completed)
          .map((f) => f.filePath)
          .toList(),
      'filesInProgress': _tracker.fileProgress
          .where((f) => f.status == CoreFileStatus.inProgress)
          .map((f) => f.filePath)
          .toList(),
    };

    await _storage.saveMonthlyReport(reportData: report, timestamp: now);
    _lastReportMonth = monthKey;

    return report;
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  /// منطق مشترك لتعليم دالة كمراجعة أو مُعاد هيكلتها.
  Future<void> _markFunction(String filePath, String functionName) async {
    final fileIndex =
        _tracker.fileProgress.indexWhere((f) => f.filePath == filePath);
    if (fileIndex < 0) return;

    final file = _tracker.fileProgress[fileIndex];

    // تحقق أن الدالة لم تُراجع مسبقاً
    if (file.reviewedFunctionNames.contains(functionName)) return;

    // تحديث قوائم الدوال
    final updatedReviewed = List<String>.from(file.reviewedFunctionNames)
      ..add(functionName);
    final updatedPending = List<String>.from(file.pendingFunctionNames)
      ..remove(functionName);

    // تحديد حالة الملف
    final allReviewed = updatedPending.isEmpty;
    final newStatus =
        allReviewed ? CoreFileStatus.completed : CoreFileStatus.inProgress;

    final updatedFile = file.copyWith(
      status: newStatus,
      reviewedFunctions: updatedReviewed.length,
      reviewedFunctionNames: updatedReviewed,
      pendingFunctionNames: updatedPending,
    );

    final updatedFiles = List<CoreFileProgress>.from(_tracker.fileProgress);
    updatedFiles[fileIndex] = updatedFile;

    // تحديث العدادات العامة
    final totalReviewed =
        updatedFiles.fold<int>(0, (sum, f) => sum + f.reviewedFunctions);
    final completedCount =
        updatedFiles.where((f) => f.status == CoreFileStatus.completed).length;

    // حساب النسبة المئوية
    final percentage = _tracker.totalFunctionUnits > 0
        ? (totalReviewed / _tracker.totalFunctionUnits) * 100.0
        : 0.0;

    _tracker = _tracker.copyWith(
      fileProgress: updatedFiles,
      reviewedFunctionUnits: totalReviewed,
      completedCoreFiles: completedCount,
      completionPercentage: percentage,
      lastUpdated: DateTime.now(),
    );

    await _persist();
    await _checkMonthBoundary();
  }

  /// حفظ التقدم الحالي في التخزين.
  Future<void> _persist() async {
    await _storage.saveProgress(_tracker.toJson());
  }

  /// التحقق من عبور حدود الشهر وتوليد تقرير إذا لزم الأمر.
  Future<void> _checkMonthBoundary() async {
    final currentMonth = _monthKey(DateTime.now());
    if (_lastReportMonth != null && _lastReportMonth != currentMonth) {
      await generateMonthlyReport();
    }
  }

  /// توليد مفتاح الشهر بصيغة yyyy-MM.
  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
}
