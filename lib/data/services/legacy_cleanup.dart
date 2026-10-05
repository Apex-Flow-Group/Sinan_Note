// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يحذف ما تركته الإصدارات السابقة ولم يعد له استخدام.
abstract final class LegacyCleanup {
  static Future<void> run() async {
    try {
      // نسخ القاعدة قبل "إعادة تعيين الخزنة": مشفّرة بمفتاح لم يعد موجوداً
      final dir = await getApplicationDocumentsDirectory();
      for (final entity in dir.listSync()) {
        if (entity is File &&
            p.basename(entity.path).startsWith('vault_reset_backup_')) {
          await entity.delete();
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('vault_reset_backup_path');
      await prefs.remove('vault_reset_backup_date');
      // سجل الحذف بالأرقام المحلية ومؤشر Drive القديم: حلّ محلهما
      // sync_tombstones (بالـ uuid)
      await prefs.remove('deleted_note_ids');
      await prefs.remove('last_known_drive_md5');
    } on Object {
      // تنظيف اختياري — يُعاد في التشغيل التالي
    }
  }
}
