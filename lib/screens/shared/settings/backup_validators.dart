// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';

class BackupValidators {
  /// Check if backup file contains vault_data
  static Future<bool> checkForVaultData(String backupPath) async {
    try {
      final file = File(backupPath);
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
    return fileName.endsWith('.isar') || fileName.contains('backup');
  }
}
