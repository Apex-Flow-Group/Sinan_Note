// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

class BackupValidators {
  static const int _maxFileSizeBytes = 100 * 1024 * 1024; // 100 MB
  /// Validates file exists, size, and basic integrity. Returns error message or null.
  static Future<String?> validate(String path, {required bool isDatabase}) async {
    final file = File(path);
    if (!await file.exists()) return 'الملف غير موجود';

    final size = await file.length();
    if (size == 0) return 'الملف فارغ';
    if (size > _maxFileSizeBytes) return 'حجم الملف كبير جداً (الحد الأقصى 100 MB)';

    if (!isDatabase) {
      try {
        final content = await file.readAsString();
        jsonDecode(content);
      } catch (_) {
        return 'الملف تالف أو ليس JSON صالحاً';
      }
    }
    return null;
  }

  /// Check if backup file contains vault_data (JSON only)
  static Future<bool> checkForVaultData(String backupPath) async {
    try {
      final file = File(backupPath);
      final size = await file.length();
      if (size == 0 || size > _maxFileSizeBytes) return false;
      final json = await file.readAsString();
      final dynamic jsonData = jsonDecode(json);
      if (jsonData is Map<String, dynamic>) {
        return jsonData.containsKey('vault_data');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Auto-detect if file is database or JSON
  static bool isDatabaseFile(String fileName) {
    return fileName.endsWith('.isar') || fileName.endsWith('.sinannote');
  }

}
