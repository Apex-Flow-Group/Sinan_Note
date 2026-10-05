// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/data/services/code_export_service.dart';

/// أدوات ملاحظات الكود: حفظ الكود كملف في التنزيلات.
class CodeTools {
  /// يُرجع مسار الملف.
  Future<String> saveToDownloads({
    required String code,
    required String? language,
    required String fileName,
  }) =>
      CodeExportService.saveToDownloads(
          code: code, language: language, fileName: fileName);
}
