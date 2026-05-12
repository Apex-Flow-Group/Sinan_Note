// Copyright © 2025 Apex Flow Group. All rights reserved.
// 🔁 اختبار مشكلة التكرار في المزامنة — يثبت أن الإصلاح يعمل

import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/storage/sqlite_database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    initializeTestEnvironment();
  });

  setUp(() {
    SqliteDatabaseService.resetInstance();
    // قاعدة بيانات في الذاكرة لكل اختبار — عزل تام
    SqliteDatabaseService.overrideDbPath(':memory:');
  });

  tearDown(() async {
    await SqliteDatabaseService().closeDB();
    SqliteDatabaseService.resetInstance();
  });

  // ══════════════════════════════════════════════════════════════
  // المشكلة الأصلية: insertNote تحذف الـ id → تكرار عند كل مزامنة
  // ══════════════════════════════════════════════════════════════
  group('Sync Duplication Bug — التكرار عند المزامنة', () {
    test('insertNote تُعطي id جديد (السلوك الصحيح للإنشاء)', () async {
      final db = SqliteDatabaseService();
      final note = Note(
        id: 99,
        title: 'ملاحظة',
        content: 'محتوى',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final newId = await db.insertNote(note);
      // insertNote تتجاهل الـ id وتُعطي id جديد من AUTOINCREMENT
      expect(newId, isNot(equals(99)));
    });

    test('upsertNote تحافظ على الـ id الأصلي', () async {
      final db = SqliteDatabaseService();
      final note = Note(
        id: 42,
        title: 'ملاحظة مزامنة',
        content: 'محتوى',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.upsertNote(note);
      final retrieved = await db.getNoteById(42);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 42);
      expect(retrieved.title, 'ملاحظة مزامنة');
    });

    test('دورة مزامنة واحدة — لا تكرار', () async {
      final db = SqliteDatabaseService();
      final now = DateTime.now();

      // الحالة الابتدائية: 3 ملاحظات محلية
      for (int i = 1; i <= 3; i++) {
        await db.upsertNote(Note(
          id: i,
          title: 'ملاحظة $i',
          content: 'محتوى $i',
          createdAt: now,
          updatedAt: now,
        ));
      }

      // محاكاة _silentMerge: نوتات Drive (نفس الـ ids)
      final driveNotes = [
        Note(id: 1, title: 'ملاحظة 1', content: 'محتوى 1', createdAt: now, updatedAt: now),
        Note(id: 2, title: 'ملاحظة 2 محدثة', content: 'محتوى جديد', createdAt: now, updatedAt: now.add(const Duration(minutes: 5))),
        Note(id: 3, title: 'ملاحظة 3', content: 'محتوى 3', createdAt: now, updatedAt: now),
      ];

      // تطبيق الدمج بالطريقة الجديدة (upsertNote)
      final localNotes = await db.getAllNotes();
      final Map<int, Note> merged = {};
      for (final n in localNotes) {
        if (n.id != null) merged[n.id!] = n;
      }
      for (final n in driveNotes) {
        if (n.id == null) continue;
        final local = merged[n.id!];
        if (local == null || n.updatedAt.isAfter(local.updatedAt)) {
          merged[n.id!] = n;
        }
      }

      // upsert بدل حذف + insert
      final allLocal = await db.getAllNotes();
      final mergedIds = merged.keys.toSet();
      for (final n in allLocal) {
        if (n.id != null && !mergedIds.contains(n.id)) await db.deleteNote(n.id!);
      }
      for (final n in merged.values) {
        await db.upsertNote(n);
      }

      final result = await db.getAllNotes();
      expect(result.length, 3, reason: 'يجب أن تبقى 3 ملاحظات بدون تكرار');
    });

    test('3 دورات مزامنة متتالية — لا تكرار تراكمي', () async {
      final db = SqliteDatabaseService();
      final now = DateTime.now();

      // إدراج أولي
      for (int i = 1; i <= 3; i++) {
        await db.upsertNote(Note(
          id: i,
          title: 'ملاحظة $i',
          content: 'محتوى',
          createdAt: now,
          updatedAt: now,
        ));
      }

      // 3 دورات مزامنة
      for (int cycle = 0; cycle < 3; cycle++) {
        final driveNotes = List.generate(3, (i) => Note(
          id: i + 1,
          title: 'ملاحظة ${i + 1}',
          content: 'محتوى دورة $cycle',
          createdAt: now,
          updatedAt: now.add(Duration(minutes: cycle)),
        ));

        final localNotes = await db.getAllNotes();
        final Map<int, Note> merged = {};
        for (final n in localNotes) {
          if (n.id != null) merged[n.id!] = n;
        }
        for (final n in driveNotes) {
          if (n.id == null) continue;
          final local = merged[n.id!];
          if (local == null || n.updatedAt.isAfter(local.updatedAt)) {
            merged[n.id!] = n;
          }
        }

        final allLocal = await db.getAllNotes();
        final mergedIds = merged.keys.toSet();
        for (final n in allLocal) {
          if (n.id != null && !mergedIds.contains(n.id)) await db.deleteNote(n.id!);
        }
        for (final n in merged.values) {
          await db.upsertNote(n);
        }
      }

      final result = await db.getAllNotes();
      expect(result.length, 3,
          reason: 'بعد 3 دورات مزامنة يجب أن تبقى 3 ملاحظات فقط');
    });

    test('المشكلة القديمة — insertNote تُسبب تكراراً (توثيق السلوك الخاطئ)', () async {
      final db = SqliteDatabaseService();
      final now = DateTime.now();

      // إدراج أولي بـ upsert
      for (int i = 1; i <= 3; i++) {
        await db.upsertNote(Note(
          id: i,
          title: 'ملاحظة $i',
          content: 'محتوى',
          createdAt: now,
          updatedAt: now,
        ));
      }

      // محاكاة السلوك القديم: حذف الكل ثم insertNote (تُعطي ids جديدة)
      final allLocal = await db.getAllNotes();
      for (final n in allLocal) {
        if (n.id != null) await db.deleteNote(n.id!);
      }

      final driveNotes = List.generate(3, (i) => Note(
        id: i + 1,
        title: 'ملاحظة ${i + 1}',
        content: 'محتوى',
        createdAt: now,
        updatedAt: now,
      ));

      for (final n in driveNotes) {
        await db.insertNote(n); // السلوك القديم — يُعطي id جديد
      }

      final result = await db.getAllNotes();
      // النوتات موجودة لكن بـ ids مختلفة (4,5,6 بدل 1,2,3)
      expect(result.length, 3);
      // في الدورة التالية ستُضاف كنوتات جديدة → تكرار
      final ids = result.map((n) => n.id).toList();
      expect(ids.contains(1), isFalse, reason: 'السلوك القديم يُضيع الـ id الأصلي');
    });

    test('upsertNote تُحدّث ملاحظة موجودة بدل إضافة نسخة جديدة', () async {
      final db = SqliteDatabaseService();
      final now = DateTime.now();

      await db.upsertNote(Note(
        id: 1,
        title: 'النسخة الأولى',
        content: 'محتوى',
        createdAt: now,
        updatedAt: now,
      ));

      // upsert مرة ثانية بنفس الـ id
      await db.upsertNote(Note(
        id: 1,
        title: 'النسخة المحدثة',
        content: 'محتوى جديد',
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 1)),
      ));

      final all = await db.getAllNotes();
      expect(all.length, 1, reason: 'يجب أن تكون ملاحظة واحدة فقط');
      expect(all.first.title, 'النسخة المحدثة');
    });
  });

  // ══════════════════════════════════════════════════════════════
  // downloadDatabase — نفس المشكلة كانت موجودة هنا أيضاً
  // ══════════════════════════════════════════════════════════════
  group('downloadDatabase — لا تكرار بعد الإصلاح', () {
    /// محاكاة منطق downloadDatabase بعد الإصلاح (upsertNote)
    Future<void> simulateDownload(SqliteDatabaseService db, List<Note> driveNotes) async {
      final allLocal = await db.getAllNotes();
      for (final n in allLocal) {
        if (n.id != null && !n.isLocked) await db.deleteNote(n.id!);
      }
      for (final n in driveNotes) {
        await db.upsertNote(n); // الإصلاح
      }
    }

    /// محاكاة المنطق القديم (insertNote)
    Future<void> simulateDownloadOld(SqliteDatabaseService db, List<Note> driveNotes) async {
      final allLocal = await db.getAllNotes();
      for (final n in allLocal) {
        if (n.id != null && !n.isLocked) await db.deleteNote(n.id!);
      }
      for (final n in driveNotes) {
        await db.insertNote(n); // السلوك القديم
      }
    }

    test('download ثم silentMerge — لا تكرار مع upsertNote', () async {
      final db = SqliteDatabaseService();
      final now = DateTime.now();

      final driveNotes = List.generate(3, (i) => Note(
        id: i + 1, title: 'ملاحظة ${i + 1}', content: 'محتوى',
        createdAt: now, updatedAt: now,
      ));

      // دورة 1: download
      await simulateDownload(db, driveNotes);
      expect((await db.getAllNotes()).length, 3);

      // دورة 2: silentMerge (upsert نفس النوتات)
      final localNotes = await db.getAllNotes();
      final Map<int, Note> merged = {};
      for (final n in localNotes) { if (n.id != null) merged[n.id!] = n; }
      for (final n in driveNotes) {
        if (n.id == null) continue;
        final local = merged[n.id!];
        if (local == null || n.updatedAt.isAfter(local.updatedAt)) merged[n.id!] = n;
      }
      final allLocal = await db.getAllNotes();
      final mergedIds = merged.keys.toSet();
      for (final n in allLocal) {
        if (n.id != null && !mergedIds.contains(n.id)) await db.deleteNote(n.id!);
      }
      for (final n in merged.values) { await db.upsertNote(n); }

      expect((await db.getAllNotes()).length, 3,
          reason: 'download + silentMerge يجب أن تبقى 3 ملاحظات');
    });

    test('السلوك القديم لـ download يُسبب تكراراً في الدورة التالية', () async {
      final db = SqliteDatabaseService();
      final now = DateTime.now();

      // إدراج أولي — الـ ids تبدأ من 1
      final driveNotes = List.generate(3, (i) => Note(
        id: i + 1, title: 'ملاحظة ${i + 1}', content: 'محتوى',
        createdAt: now, updatedAt: now,
      ));
      await simulateDownloadOld(db, driveNotes); // ids: 1,2,3

      // دورة ثانية: download قديم — يحذف 1,2,3 ثم يُدرج بـ ids جديدة 4,5,6
      await simulateDownloadOld(db, driveNotes);
      final afterSecondDownload = await db.getAllNotes();
      // الـ ids الجديدة هي 4,5,6 — ليست 1,2,3
      expect(afterSecondDownload.map((n) => n.id).contains(1), isFalse,
          reason: 'السلوك القديم يُضيع الـ ids الأصلية بعد كل دورة');

      // الآن silentMerge: Drive يحتوي ids 1,2,3 لكن المحلي 4,5,6 → تكرار
      final localNotes = await db.getAllNotes();
      final Map<int, Note> merged = {};
      for (final n in localNotes) { if (n.id != null) merged[n.id!] = n; }
      for (final n in driveNotes) {
        if (n.id == null) continue;
        final local = merged[n.id!];
        if (local == null || n.updatedAt.isAfter(local.updatedAt)) merged[n.id!] = n;
      }
      final allLocal = await db.getAllNotes();
      final mergedIds = merged.keys.toSet();
      for (final n in allLocal) {
        if (n.id != null && !mergedIds.contains(n.id)) await db.deleteNote(n.id!);
      }
      for (final n in merged.values) { await db.upsertNote(n); }

      // النتيجة: 6 ملاحظات بدل 3 — التكرار الذي أبلغ عنه المستخدمون
      expect((await db.getAllNotes()).length, greaterThan(3),
          reason: 'السلوك القديم يُسبب تكراراً في الدورة التالية');
    });

    test('5 دورات download + merge متتالية — لا تكرار', () async {
      final db = SqliteDatabaseService();
      final now = DateTime.now();

      final driveNotes = List.generate(5, (i) => Note(
        id: i + 1, title: 'ملاحظة ${i + 1}', content: 'محتوى',
        createdAt: now, updatedAt: now,
      ));

      for (int cycle = 0; cycle < 5; cycle++) {
        // download
        await simulateDownload(db, driveNotes);
        // merge
        final localNotes = await db.getAllNotes();
        final Map<int, Note> merged = {};
        for (final n in localNotes) { if (n.id != null) merged[n.id!] = n; }
        for (final n in driveNotes) {
          if (n.id == null) continue;
          final local = merged[n.id!];
          if (local == null || n.updatedAt.isAfter(local.updatedAt)) merged[n.id!] = n;
        }
        final allLocal = await db.getAllNotes();
        final mergedIds = merged.keys.toSet();
        for (final n in allLocal) {
          if (n.id != null && !mergedIds.contains(n.id)) await db.deleteNote(n.id!);
        }
        for (final n in merged.values) { await db.upsertNote(n); }
      }

      expect((await db.getAllNotes()).length, 5,
          reason: 'بعد 5 دورات يجب أن تبقى 5 ملاحظات فقط');
    });
  });

  // ══════════════════════════════════════════════════════════════
  // منطق الحذف — الأحدث يتغلب
  // ══════════════════════════════════════════════════════════════
  group('منطق الحذف — الأحدث يتغلب', () {
    Map<int, Note> _applyMerge({
      required List<Note> local,
      required List<Note> drive,
      required Map<int, DateTime> deleted,
    }) {
      final Map<int, Note> merged = {};
      for (final n in local) {
        if (n.id != null) merged[n.id!] = n;
      }
      for (final n in drive) {
        if (n.id == null) continue;
        final loc = merged[n.id!];
        if (loc == null || n.updatedAt.isAfter(loc.updatedAt)) merged[n.id!] = n;
      }
      deleted.forEach((id, deletedAt) {
        final note = merged[id];
        if (note != null && deletedAt.isAfter(note.updatedAt)) merged.remove(id);
      });
      return merged;
    }

    test('حذف في A ثم تعديل في B — التعديل يتغلب (النوتة تبقى)', () {
      final t1 = DateTime(2025, 1, 1, 10, 0); // وقت الحذف
      final t2 = DateTime(2025, 1, 1, 10, 5); // وقت التعديل — أحدث

      final driveNotes = [
        Note(id: 1, title: 'نسخة محدثة', content: '', createdAt: t1, updatedAt: t2),
      ];
      final deleted = {1: t1}; // حذف قبل التعديل

      final result = _applyMerge(local: [], drive: driveNotes, deleted: deleted);
      expect(result.containsKey(1), isTrue,
          reason: 'التعديل أحدث → النوتة تبقى');
    });

    test('تعديل في A ثم حذف في B — الحذف يتغلب (النوتة تُحذف)', () {
      final t1 = DateTime(2025, 1, 1, 10, 0); // وقت التعديل
      final t2 = DateTime(2025, 1, 1, 10, 5); // وقت الحذف — أحدث

      final localNotes = [
        Note(id: 1, title: 'نسخة محدثة', content: '', createdAt: t1, updatedAt: t1),
      ];
      final deleted = {1: t2}; // حذف بعد التعديل

      final result = _applyMerge(local: localNotes, drive: [], deleted: deleted);
      expect(result.containsKey(1), isFalse,
          reason: 'الحذف أحدث → النوتة تُحذف');
    });

    test('نوتة غير محذوفة لا تتأثر', () {
      final now = DateTime.now();
      final localNotes = [
        Note(id: 1, title: 'نوتة 1', content: '', createdAt: now, updatedAt: now),
        Note(id: 2, title: 'نوتة 2', content: '', createdAt: now, updatedAt: now),
      ];
      final deleted = {1: now.subtract(const Duration(minutes: 1))}; // الحذف قبل التعديل

      final result = _applyMerge(local: localNotes, drive: [], deleted: deleted);
      expect(result.containsKey(1), isTrue, reason: 'التعديل أحدث → النوتة تبقى');
      expect(result.containsKey(2), isTrue, reason: 'النوتة غير المحذوفة تبقى');
    });
  });
}
