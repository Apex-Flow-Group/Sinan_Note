// Copyright © 2025 Apex Flow Group. All rights reserved.



import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/core/utils/logger.dart';
import 'package:sinan_note/models/category.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import 'package:sinan_note/services/sync/sync_transport.dart';

/// محرك المزامنة — يحتوي على كل منطق الدمج والقرارات.
/// لا يعرف شيئاً عن Google Drive مباشرة — يتحدث مع [SyncTransport] فقط.
class SyncEngine {
  SyncEngine._();

  // ── Upload ────────────────────────────────────────────────────────────────

  /// رفع النوتات العادية (غير المشفرة) + الكتالوجات + deleted_ids
  static Future<bool> upload() async {
    try {
      final dbService = SqliteDatabaseService();
      final allNotes = await dbService.getAllNotes();

      // الخزنة محلية دائماً — لا نرفع المشفر
      final notes = allNotes.where((n) => !n.isLocked).toList();
      final categories = await dbService.getAllCategories();
      final deletedIds = await SqliteDatabaseService.getDeletedNoteIds();
      await SqliteDatabaseService.cleanOldDeletions();

      final backupData = <String, dynamic>{
        'version': '2.0',
        'created_at': DateTime.now().toIso8601String(),
        'notes': notes.map((n) => n.toMap()).toList(),
        'categories': categories
            .map((c) => {'id': c.id, 'name': c.name, 'sortOrder': c.sortOrder})
            .toList(),
        'deleted_ids': deletedIds
            .map((id, dt) => MapEntry('$id', dt.millisecondsSinceEpoch)),
      };

      final success = await SyncTransport.uploadCompressed(backupData);
      if (success) {
        // مسح deleted_ids بعد الرفع — تم تطبيقها
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('deleted_note_ids');
        AppLogger.success('Uploaded ${notes.length} notes', 'SyncEngine');
      }
      return success;
    } catch (e) {
      AppLogger.error('Upload failed', 'SyncEngine', e);
      return false;
    }
  }

  // ── Download (استبدال كامل) ───────────────────────────────────────────────

  /// تنزيل من السحابة واستبدال النوتات العادية بالكامل
  static Future<bool> download() async {
    try {
      final data = await SyncTransport.downloadAndDecompress();
      if (data == null) throw Exception('No backup found in Drive');

      final List<dynamic> notesList = data['notes'] ?? [];
      final List<dynamic> categoriesList = data['categories'] ?? [];

      // فقط النوتات غير المشفرة
      final regularNotes =
          notesList.where((m) => (m['isLocked'] ?? 0) == 0).toList();

      final dbService = SqliteDatabaseService();
      final lockedLocal = await dbService.getLockedNotes();

      // حذف العادية وإدراج نوتات Drive
      final allLocal = await dbService.getAllNotes();
      for (final n in allLocal) {
        if (n.id != null && !n.isLocked) await dbService.deleteNote(n.id!);
      }
      for (final m in regularNotes) {
        await dbService.upsertNote(Note.fromMap(m));
      }
      for (final n in lockedLocal) {
        await dbService.updateNote(n);
      }

      // استعادة الكتالوجات
      if (categoriesList.isNotEmpty) {
        final existingCats = await dbService.getAllCategories();
        for (final c in existingCats) {
          await dbService.deleteCategory(c.id);
        }
        for (final c in categoriesList) {
          await dbService.insertCategory(NoteCategory(
            id: c['id'] as int,
            name: c['name'] as String,
            sortOrder: c['sortOrder'] as int? ?? 0,
          ));
        }
      }

      // مسح deleted_ids المحلية — بعد Download لا تعد موثوقة
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('deleted_note_ids');
      await prefs.setInt(
          'last_upload_timestamp', DateTime.now().millisecondsSinceEpoch);

      AppLogger.success(
          'Downloaded ${regularNotes.length} notes', 'SyncEngine');
      return true;
    } catch (e) {
      AppLogger.error('Download failed', 'SyncEngine', e);
      return false;
    }
  }

  // ── Silent Merge (الأحدث يفوز) ───────────────────────────────────────────

  /// دمج صامت — يقارن النوتات المحلية مع Drive والأحدث يفوز
  static Future<void> silentMerge() async {
    try {
      final data = await SyncTransport.downloadAndDecompress();
      if (data == null) return;

      // Fast Path check: MD5 لم يتغير = لا حاجة لدمج ثقيل
      final currentMd5 = await SyncTransport.getDriveMd5();
      final prefs = await SharedPreferences.getInstance();
      final lastKnownMd5 = prefs.getString('last_known_drive_md5');
      final isFastPath = currentMd5 != null &&
          lastKnownMd5 != null &&
          currentMd5 == lastKnownMd5;

      AppLogger.info(
        isFastPath ? 'Fast path: MD5 match' : 'Merge path: MD5 changed',
        'SyncEngine',
      );

      // Parse Drive data
      final driveNotes = _parseNotes(data);
      final driveCats = _parseCategories(data);
      final driveDeleted = _parseDeletedIds(data);
      final localDeleted = await SqliteDatabaseService.getDeletedNoteIds();

      // بناء allDeleted
      final allDeleted = <int, DateTime>{};
      if (isFastPath) {
        allDeleted.addAll(localDeleted);
        driveDeleted.forEach((id, dt) {
          if (!allDeleted.containsKey(id) || dt.isAfter(allDeleted[id]!)) {
            allDeleted[id] = dt;
          }
        });
      } else {
        allDeleted.addAll(driveDeleted);
      }

      // Merge notes — الأحدث يفوز
      final dbService = SqliteDatabaseService();
      final localNotes = await dbService.getAllNotes();

      final Map<int, Note> merged = {};
      for (final n in localNotes) {
        if (n.id != null && !n.isLocked) merged[n.id!] = n;
      }
      for (final n in driveNotes) {
        if (n.id == null) continue;
        final local = merged[n.id!];
        if (local == null || n.updatedAt.isAfter(local.updatedAt)) {
          merged[n.id!] = n;
        }
      }

      // تطبيق الحذف
      if (isFastPath) {
        allDeleted.forEach((id, deletedAt) {
          final note = merged[id];
          if (note != null && deletedAt.isAfter(note.updatedAt)) {
            merged.remove(id);
          }
        });
      } else {
        // Merge Path: تحكيم بمقارنة التواريخ
        for (final n in driveNotes) {
          if (n.id == null) continue;
          if (localDeleted.containsKey(n.id)) {
            final deletedAt = localDeleted[n.id]!;
            if (deletedAt.isAfter(n.updatedAt)) {
              merged.remove(n.id);
            } else {
              merged[n.id!] = n;
            }
          }
        }
        driveDeleted.forEach((id, deletedAt) {
          final note = merged[id];
          if (note != null && deletedAt.isAfter(note.updatedAt)) {
            merged.remove(id);
          }
        });
      }

      // حفظ النتيجة
      final allLocal = await dbService.getAllNotes();
      final mergedIds = merged.keys.toSet();
      for (final n in allLocal) {
        if (n.id != null && !n.isLocked && !mergedIds.contains(n.id)) {
          await dbService.deleteNote(n.id!);
        }
      }
      for (final n in merged.values) {
        await dbService.upsertNote(n);
      }

      // دمج الكتالوجات
      await _mergeCategories(dbService, driveCats);

      AppLogger.success(
        '${isFastPath ? "Fast" : "Merge"} path done: ${merged.length} notes',
        'SyncEngine',
      );

      // رفع بعد الدمج
      await upload();
    } catch (e) {
      AppLogger.error('Silent merge failed', 'SyncEngine', e);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static List<Note> _parseNotes(Map<String, dynamic> data) {
    final List<dynamic> list = data['notes'] ?? [];
    return list
        .where((m) => (m['isLocked'] ?? 0) == 0)
        .map((m) => Note.fromMap(m))
        .toList();
  }

  static List<Map<String, dynamic>> _parseCategories(
      Map<String, dynamic> data) {
    final List<dynamic> list = data['categories'] ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  static Map<int, DateTime> _parseDeletedIds(Map<String, dynamic> data) {
    final raw = data['deleted_ids'] as Map? ?? {};
    final result = <int, DateTime>{};
    raw.forEach((k, v) {
      final id = int.tryParse(k.toString());
      final ms = v is int ? v : int.tryParse(v.toString());
      if (id != null && ms != null) {
        result[id] = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    });
    return result;
  }

  static Future<void> _mergeCategories(
    SqliteDatabaseService dbService,
    List<Map<String, dynamic>> driveCats,
  ) async {
    if (driveCats.isEmpty) return;

    final existingCats = await dbService.getAllCategories();
    final existingIds = existingCats.map((c) => c.id).toSet();
    final driveCatIds = driveCats.map((c) => c['id'] as int).toSet();

    for (final c in driveCats) {
      final catId = c['id'] as int;
      final cat = NoteCategory(
        id: catId,
        name: c['name'] as String,
        sortOrder: c['sortOrder'] as int? ?? 0,
      );
      if (existingIds.contains(catId)) {
        await dbService.updateCategory(cat);
      } else {
        await dbService.insertCategory(cat);
      }
    }
    for (final c in existingCats) {
      if (!driveCatIds.contains(c.id)) {
        await dbService.deleteCategory(c.id);
      }
    }
  }
}

