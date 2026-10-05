// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:sinan_note/data/services/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// تقرير تشخيص عن قاعدة البيانات (للمطوّر): الحجم، عدد الصفوف، عيّنة.
/// يفتح نسخة للقراءة فقط؛ عناوين الملاحظات المقفلة لا تُعرض.
abstract final class DatabaseReport {
  static Future<Map<String, dynamic>> build() async {
    final result = <String, dynamic>{};

    // ── SQLite ─────────────────────────────────────────────────────────────
    try {
      final dbPath = await _getSqlitePath();
      final exists = await File(dbPath).exists();
      if (!exists) {
        result['sqlite'] = {'error': 'File not found: $dbPath'};
      } else {
        final fileSize = await File(dbPath).length();
        final db = await openDatabase(dbPath, readOnly: true);
        final tables = await db
            .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final counts = <String, int>{};
        for (final t in tables) {
          final name = t['name'] as String;
          if (name.startsWith('sqlite_')) continue;
          final r = await db.rawQuery('SELECT COUNT(*) as c FROM "$name"');
          counts[name] = (r.first['c'] as int?) ?? 0;
        }
        Future<int> notesWhere(String flag) async =>
            Sqflite.firstIntValue(await db
                .rawQuery('SELECT COUNT(*) FROM notes WHERE $flag = 1')) ??
            0;
        result['notes_summary'] = {
          'notes': counts['notes'] ?? 0,
          'locked': await notesWhere('isLocked'),
          'archived': await notesWhere('isArchived'),
          'trashed': await notesWhere('isTrashed'),
          'categories': counts['categories'] ?? 0,
          'versions': counts['note_versions'] ?? 0,
        };
        // عناوين الملاحظات المقفلة مشفّرة؛ لا تُعرض
        final sample = await db.rawQuery(
            "SELECT id, CASE WHEN isLocked = 1 THEN '🔒' ELSE title END "
            'AS title, noteType, isLocked FROM notes LIMIT 5');
        await db.close();
        result['sqlite'] = {
          'path': dbPath,
          'size_kb': (fileSize / 1024).toStringAsFixed(1),
          'tables': counts,
          'sample': sample,
        };
      }
    } catch (e) {
      result['sqlite'] = {'error': e.toString()};
    }

    return result;
  }

  static Future<String> _getSqlitePath() => AppDatabase.defaultPath();
}
