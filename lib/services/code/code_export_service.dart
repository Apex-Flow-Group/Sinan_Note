// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sinan_note/services/code/language_detector.dart';

/// يحفظ ملف الكود مباشرة في مجلد التحميلات بالامتداد الصحيح
class CodeExportService {
  /// يحفظ الكود في Downloads ويُرجع مسار الملف المحفوظ
  static Future<String> saveToDownloads({
    required String code,
    required String? language,
    required String fileName,
  }) async {
    final ext = _resolveExtension(language, fileName);
    final safeName = _buildFileName(fileName, ext);
    final dir = await _getDownloadsDir();
    final file = File('${dir.path}/$safeName');
    await file.writeAsString(code, flush: true);
    return file.path;
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static String _resolveExtension(String? language, String fileName) {
    // إذا كان الاسم يحتوي على امتداد بالفعل نستخدمه
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex > 0 && dotIndex < fileName.length - 1) {
      return fileName.substring(dotIndex); // e.g. ".py"
    }
    if (language == null) return '.txt';
    // custom:ext
    if (language.startsWith('custom:')) {
      return '.${language.substring(7)}';
    }
    return LanguageDetector.getFileExtension(language); // e.g. ".svg"
  }

  static String _buildFileName(String title, String ext) {
    // نظّف الاسم من الأحرف غير المسموح بها
    final clean = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final base = clean.isEmpty ? 'code' : clean;
    // إذا كان الاسم ينتهي بالامتداد بالفعل لا نضيفه مرة ثانية
    if (base.toLowerCase().endsWith(ext.toLowerCase())) return base;
    return '$base$ext';
  }

  static Future<Directory> _getDownloadsDir() async {
    if (Platform.isAndroid) {
      const path = '/storage/emulated/0/Download';
      final dir = Directory(path);
      if (await dir.exists()) return dir;
    }
    if (Platform.isIOS) {
      // iOS: نحفظ في Documents (يمكن الوصول إليه من Files app)
      return getApplicationDocumentsDirectory();
    }
    // Linux / macOS / Windows: مجلد Downloads الافتراضي
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    if (home.isNotEmpty) {
      final dir = Directory('$home/Downloads');
      if (await dir.exists()) return dir;
    }
    return getApplicationDocumentsDirectory();
  }
}
