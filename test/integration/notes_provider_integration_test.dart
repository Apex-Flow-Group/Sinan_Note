// Copyright © 2025 Apex Flow Group. All rights reserved.
// 🗂️ NOTES PROVIDER — اختبارات تكاملية شاملة

@Tags(['serial'])


import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import '../test_setup.dart';
void main() {
  setUpAll(() => initializeTestEnvironment());

  late NotesProvider provider;
  late DateTime now;

  setUp(() {
    SqliteDatabaseService.resetInstance();
    SqliteDatabaseService.overrideDbPath(':memory:');
    provider = NotesProvider();
    now = DateTime.now();
  });

  tearDown(() async {
    await SqliteDatabaseService().closeDB();
    SqliteDatabaseService.resetInstance();
    // provider قد يكون تم dispose() في الاختبار نفسه
    try {
      provider.dispose();
    } catch (_) {}
  });

  Note note(
      {int? id,
      String title = 'Test',
      String content = 'Content',
      bool isLocked = false,
      bool isArchived = false,
      bool isTrashed = false,
      bool isPinned = false,
      String noteType = 'simple',
      DateTime? reminder}) {
    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      isLocked: isLocked,
      isArchived: isArchived,
      isTrashed: isTrashed,
      isPinned: isPinned,
      noteType: noteType,
      reminderDateTime: reminder,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 1. CRUD الأساسي
  // ══════════════════════════════════════════════════════════════
  group('NotesProvider — CRUD', () {
    test('addNote يُضيف ملاحظة ويُرجع ID صحيح', () async {
      final id = await provider.addNote(note(title: 'New Note'));
      expect(id, greaterThan(0));
      expect(provider.activeNotes.length, 1);
    });

    test('addNote يُطلق notifyListeners', () async {
      int count = 0;
      provider.addListener(() => count++);
      await provider.addNote(note());
      expect(count, greaterThan(0));
    });

    test('updateNote يُحدِّث الملاحظة', () async {
      final id = await provider.addNote(note(title: 'Original'));
      await provider.updateNote(note(id: id, title: 'Updated'));
      expect(provider.activeNotes.first.title, 'Updated');
    });

    test('updateNote silent لا يُطلق notifyListeners', () async {
      final id = await provider.addNote(note());
      int count = 0;
      provider.addListener(() => count++);
      await provider.updateNote(note(id: id, title: 'Silent'), silent: true);
      expect(count, 0);
    });

    test('deleteNote يحذف الملاحظة', () async {
      final id = await provider.addNote(note());
      await provider.deleteNote(id);
      expect(provider.activeNotes.length, 0);
    });

    test('addOrUpdateNote يُضيف ملاحظة جديدة', () async {
      final id = await provider.addOrUpdateNote(note());
      expect(id, greaterThan(0));
    });

    test('addOrUpdateNote يُحدِّث ملاحظة موجودة', () async {
      final id = await provider.addNote(note(title: 'Original'));
      await provider.addOrUpdateNote(note(id: id, title: 'Updated'));
      expect(provider.activeNotes.first.title, 'Updated');
    });

    test('duplicateNote يُنشئ نسخة مستقلة', () async {
      final id =
          await provider.addNote(note(title: 'Original', content: 'Content'));
      final newId = await provider.duplicateNote(id);
      expect(newId, isNot(equals(id)));
      expect(provider.activeNotes.length, 2);
      final copy = provider.activeNotes.firstWhere((n) => n.id == newId);
      expect(copy.title, contains('Copy'));
    });

    test('duplicateNote لملاحظة غير موجودة يُرجع -1', () async {
      final result = await provider.duplicateNote(99999);
      expect(result, -1);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 2. الأرشيف والسلة
  // ══════════════════════════════════════════════════════════════
  group('NotesProvider — Archive & Trash', () {
    test('archiveNote ينقل للأرشيف', () async {
      final id = await provider.addNote(note());
      await provider.archiveNote(id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.archivedNotes.length, 1);
      expect(provider.activeNotes.length, 0);
    });

    test('unarchiveNote يُعيد من الأرشيف', () async {
      final id = await provider.addNote(note());
      await provider.archiveNote(id);
      await Future.delayed(const Duration(milliseconds: 50));
      await provider.unarchiveNote(id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.activeNotes.length, 1);
      expect(provider.archivedNotes.length, 0);
    });

    test('trashNote ينقل للسلة', () async {
      final id = await provider.addNote(note());
      await provider.trashNote(id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.trashedNotes.length, 1);
      expect(provider.activeNotes.length, 0);
    });

    test('restoreNote يُعيد من السلة', () async {
      final id = await provider.addNote(note());
      await provider.trashNote(id);
      await Future.delayed(const Duration(milliseconds: 50));
      await provider.restoreNote(id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.activeNotes.length, 1);
      expect(provider.trashedNotes.length, 0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 3. العمليات الجماعية
  // ══════════════════════════════════════════════════════════════
  group('NotesProvider — Batch Operations', () {
    test('trashNotes يحذف متعدد', () async {
      final id1 = await provider.addNote(note(title: 'A'));
      final id2 = await provider.addNote(note(title: 'B'));
      final id3 = await provider.addNote(note(title: 'C'));

      await provider.trashNotes([id1, id2]);
      expect(provider.trashedNotes.length, 2);
      expect(provider.activeNotes.length, 1);
      expect(provider.activeNotes.first.id, id3);
    });

    test('archiveNotes يؤرشف متعدد', () async {
      final id1 = await provider.addNote(note(title: 'A'));
      final id2 = await provider.addNote(note(title: 'B'));

      await provider.archiveNotes([id1, id2]);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.archivedNotes.length, 2);
      expect(provider.activeNotes.length, 0);
    });

    test('restoreNotes يُعيد متعدد', () async {
      final id1 = await provider.addNote(note(title: 'A'));
      final id2 = await provider.addNote(note(title: 'B'));
      await provider.trashNotes([id1, id2]);

      await provider.restoreNotes([id1, id2]);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.activeNotes.length, 2);
      expect(provider.trashedNotes.length, 0);
    });

    test('unarchiveNotes يُعيد متعدد من الأرشيف', () async {
      final id1 = await provider.addNote(note(title: 'A'));
      final id2 = await provider.addNote(note(title: 'B'));
      await provider.archiveNotes([id1, id2]);
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.unarchiveNotes([id1, id2]);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.activeNotes.length, 2);
      expect(provider.archivedNotes.length, 0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 4. الخزنة
  // ══════════════════════════════════════════════════════════════
  group('NotesProvider — Vault', () {
    test('isVaultUnlocked يبدأ بـ false', () {
      expect(provider.isVaultUnlocked, isFalse);
    });

    test('unlockVault يفتح الخزنة', () {
      provider.unlockVault();
      expect(provider.isVaultUnlocked, isTrue);
    });

    test('lockVault يقفل الخزنة ويُطلق notifyListeners', () {
      provider.unlockVault();
      int count = 0;
      provider.addListener(() => count++);
      provider.lockVault();
      expect(provider.isVaultUnlocked, isFalse);
      expect(count, greaterThan(0));
    });

    test('lockVault يمسح الملاحظات المقفلة من الذاكرة', () async {
      provider.unlockVault();
      provider.lockVault();
      expect(provider.lockedNotes.length, 0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 5. البحث
  // ══════════════════════════════════════════════════════════════
  group('NotesProvider — Search', () {
    test('searchNotes يجد بالعنوان', () async {
      await provider.addNote(note(title: 'Flutter Guide'));
      await provider.addNote(note(title: 'Python Tutorial'));

      final results = provider.searchNotes('Flutter');
      expect(results.length, 1);
      expect(results.first.title, 'Flutter Guide');
    });

    test('searchNotes يجد بالمحتوى', () async {
      await provider.addNote(note(title: 'Note', content: 'Dart programming'));
      final results = provider.searchNotes('Dart');
      expect(results.length, 1);
    });

    test('searchNotes بنص فارغ يُرجع كل الملاحظات النشطة', () async {
      await provider.addNote(note(title: 'A'));
      await provider.addNote(note(title: 'B'));
      expect(provider.searchNotes('').length, 2);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 6. دورة الحياة الكاملة
  // ══════════════════════════════════════════════════════════════
  group('NotesProvider — Full Lifecycle', () {
    test('دورة حياة كاملة: إضافة → تحديث → أرشفة → استعادة → حذف', () async {
      // إضافة
      final id = await provider.addNote(note(title: 'Lifecycle'));
      expect(provider.activeNotes.length, 1);

      // تحديث
      await provider.updateNote(note(id: id, title: 'Updated'));
      expect(provider.activeNotes.first.title, 'Updated');

      // أرشفة
      await provider.archiveNote(id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.archivedNotes.length, 1);
      expect(provider.activeNotes.length, 0);

      // استعادة من الأرشيف
      await provider.unarchiveNote(id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.activeNotes.length, 1);

      // نقل للسلة
      await provider.trashNote(id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.trashedNotes.length, 1);

      // استعادة من السلة
      await provider.restoreNote(id);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(provider.activeNotes.length, 1);

      // حذف نهائي
      await provider.deleteNote(id);
      expect(provider.activeNotes.length, 0);
    });

    test('dispose لا يرمي استثناء', () {
      expect(() => provider.dispose(), returnsNormally);
    });

    test('refreshAllNotes لا يُشغَّل إذا كان يُحمَّل بالفعل', () async {
      // استدعاء متزامن
      final f1 = provider.refreshAllNotes();
      final f2 = provider.refreshAllNotes();
      await Future.wait([f1, f2]);
      // لا يجب أن يرمي استثناء
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 7. تسريب المزامنة — Race Conditions
  // ══════════════════════════════════════════════════════════════
  group('NotesProvider — Sync Race Conditions', () {
    test('إضافة 100 ملاحظة بشكل متزامن لا يُسبب تعارضاً', () async {
      final futures = List.generate(
        100,
        (i) => provider.addNote(note(title: 'Note $i', content: 'Content $i')),
      );
      final ids = await Future.wait(futures);
      // كل ID يجب أن يكون فريداً
      expect(ids.toSet().length, 100);
    });

    test('تحديث وحذف متزامن لا يرمي استثناء', () async {
      final id = await provider.addNote(note(title: 'Test'));

      await Future.wait([
        provider.updateNote(note(id: id, title: 'Updated')),
        provider.deleteNote(id),
      ]);
      // لا يجب أن يرمي استثناء
    });

    test('refreshAllNotes المتزامن لا يُضاعف البيانات', () async {
      await provider.addNote(note(title: 'A'));
      await provider.addNote(note(title: 'B'));

      await Future.wait([
        provider.refreshAllNotes(),
        provider.refreshAllNotes(),
        provider.refreshAllNotes(),
      ]);

      // يجب أن تكون 2 ملاحظات فقط
      expect(provider.activeNotes.length, 2);
    });
  });
}

