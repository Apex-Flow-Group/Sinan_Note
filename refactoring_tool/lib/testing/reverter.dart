import 'dart:io';

import 'package:path/path.dart' as p;

/// استثناء يُطلق عند فشل عملية الإرجاع (revert).
///
/// يشير إلى حالة طوارئ تتطلب إيقاف المعالجة فوراً
/// والحفاظ على الحالة الحالية وإبلاغ المطور.
class RevertFailureException implements Exception {
  /// رسالة الخطأ التوضيحية
  final String message;

  /// مسار الملف الذي فشل إرجاعه
  final String filePath;

  /// اسم الدالة المتأثرة
  final String? functionName;

  /// الخطأ الأصلي الذي سبب فشل الإرجاع
  final Object? originalError;

  const RevertFailureException({
    required this.message,
    required this.filePath,
    this.functionName,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer('RevertFailureException: $message');
    buffer.writeln();
    buffer.writeln('  الملف: $filePath');
    if (functionName != null) {
      buffer.writeln('  الدالة: $functionName');
    }
    if (originalError != null) {
      buffer.writeln('  الخطأ الأصلي: $originalError');
    }
    return buffer.toString();
  }
}

/// حالة ملف محفوظة في الذاكرة قبل التعديل.
class _SavedFileState {
  /// المحتوى الأصلي للملف
  final String content;

  /// المسار الكامل للملف
  final String filePath;

  /// وقت الحفظ
  final DateTime savedAt;

  const _SavedFileState({
    required this.content,
    required this.filePath,
    required this.savedAt,
  });
}

/// يدير حفظ واستعادة حالة الملفات قبل وبعد التعديل.
///
/// المسؤوليات:
/// - حفظ محتوى الملف في الذاكرة قبل التعديل
/// - استعادة المحتوى المحفوظ عند فشل الاختبارات
/// - إطلاق [RevertFailureException] إذا فشلت عملية الاستعادة
///
/// يستخدم تخزين في الذاكرة (in-memory) لسرعة الأداء وبساطة التنفيذ.
class Reverter {
  /// مسار جذر المشروع
  final String projectRoot;

  /// الحالات المحفوظة للملفات (مسار → حالة)
  final Map<String, _SavedFileState> _savedStates = {};

  Reverter({required this.projectRoot});

  /// يحفظ حالة ملف قبل التعديل.
  ///
  /// [filePath] — المسار النسبي أو المطلق للملف المراد حفظ حالته.
  ///
  /// يقرأ محتوى الملف ويخزنه في الذاكرة.
  /// إذا كان الملف محفوظاً مسبقاً، يتم تحديث الحالة المحفوظة.
  ///
  /// يُطلق [FileSystemException] إذا لم يمكن قراءة الملف.
  Future<void> saveState(String filePath) async {
    final resolvedPath = _resolvePath(filePath);
    final file = File(resolvedPath);

    if (!await file.exists()) {
      throw FileSystemException(
        'الملف غير موجود ولا يمكن حفظ حالته',
        resolvedPath,
      );
    }

    final content = await file.readAsString();

    _savedStates[resolvedPath] = _SavedFileState(
      content: content,
      filePath: resolvedPath,
      savedAt: DateTime.now(),
    );
  }

  /// يحفظ حالة عدة ملفات قبل التعديل.
  ///
  /// [filePaths] — قائمة المسارات المراد حفظ حالتها.
  ///
  /// يحفظ كل ملف على حدة. إذا فشل حفظ أي ملف، يستمر مع الباقي.
  /// يُرجع قائمة المسارات التي فشل حفظها.
  Future<List<String>> saveStates(List<String> filePaths) async {
    final failedPaths = <String>[];

    for (final filePath in filePaths) {
      try {
        await saveState(filePath);
      } catch (_) {
        failedPaths.add(filePath);
      }
    }

    return failedPaths;
  }

  /// يستعيد حالة ملف محفوظة مسبقاً.
  ///
  /// [filePath] — المسار النسبي أو المطلق للملف المراد استعادته.
  ///
  /// يكتب المحتوى المحفوظ إلى الملف ويزيل الحالة من الذاكرة.
  ///
  /// يُطلق [RevertFailureException] إذا:
  /// - لم تكن هناك حالة محفوظة للملف
  /// - فشلت عملية الكتابة إلى الملف
  ///
  /// عند فشل الاستعادة، يجب إيقاف المعالجة فوراً والحفاظ على الحالة الحالية.
  Future<void> revert(String filePath, {String? functionName}) async {
    final resolvedPath = _resolvePath(filePath);

    final savedState = _savedStates[resolvedPath];
    if (savedState == null) {
      throw RevertFailureException(
        message: 'لا توجد حالة محفوظة للملف. لا يمكن الإرجاع.',
        filePath: resolvedPath,
        functionName: functionName,
      );
    }

    try {
      final file = File(resolvedPath);
      await file.writeAsString(savedState.content);
    } catch (e) {
      // فشل الإرجاع — حالة طوارئ
      throw RevertFailureException(
        message: 'فشل إرجاع الملف إلى حالته السابقة. '
            'يجب إيقاف المعالجة والحفاظ على الحالة الحالية.',
        filePath: resolvedPath,
        functionName: functionName,
        originalError: e,
      );
    }

    // إزالة الحالة المحفوظة بعد الاستعادة الناجحة
    _savedStates.remove(resolvedPath);
  }

  /// يستعيد حالة جميع الملفات المحفوظة.
  ///
  /// يحاول استعادة كل ملف على حدة. إذا فشل أي ملف،
  /// يُطلق [RevertFailureException] مع معلومات عن الملف الفاشل.
  ///
  /// يُستخدم عند الحاجة لإرجاع تعديل يشمل عدة ملفات.
  Future<void> revertAll({String? functionName}) async {
    final paths = _savedStates.keys.toList();

    for (final path in paths) {
      await revert(path, functionName: functionName);
    }
  }

  /// يتحقق إذا كان هناك حالة محفوظة لملف معين.
  bool hasState(String filePath) {
    final resolvedPath = _resolvePath(filePath);
    return _savedStates.containsKey(resolvedPath);
  }

  /// يُرجع عدد الملفات المحفوظة حالياً.
  int get savedCount => _savedStates.length;

  /// يُرجع قائمة مسارات الملفات المحفوظة.
  List<String> get savedFilePaths => _savedStates.keys.toList();

  /// يمسح جميع الحالات المحفوظة بدون استعادة.
  ///
  /// يُستخدم بعد نجاح الاختبارات لتنظيف الذاكرة.
  void clearSavedStates() {
    _savedStates.clear();
  }

  /// يمسح حالة ملف محدد بدون استعادة.
  void clearState(String filePath) {
    final resolvedPath = _resolvePath(filePath);
    _savedStates.remove(resolvedPath);
  }

  /// يحول المسار النسبي إلى مسار مطلق.
  String _resolvePath(String filePath) {
    if (p.isAbsolute(filePath)) return p.normalize(filePath);
    return p.normalize(p.join(projectRoot, filePath));
  }
}
