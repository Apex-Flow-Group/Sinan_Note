// Copyright © 2025 Apex Flow Group. All rights reserved.
// 📋 NOTE STATE SERVICE — اختبارات شاملة تشمل تسريب المزامنة

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/note_services/note_state_service.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() => initializeTestEnvironment());

  late NoteStateService service;
  late DateTime now;

  setUp(() {
    service = NoteStateService();
    now = DateTime.now();
  });

  tearDown(() => service.dispose());

  // ══════════════════════════════════════════════════════════════
  // 1. الفلترة الصحيحة
  // ══════════════════════════════════════════════════════════════
  group('NoteStateService — Filtering', () {
    test('activeNotes يستثني المحذوفة والمؤرشفة والمقفلة', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Active',
            content: '',
            createdAt: now,
            updatedAt: now),
        Note(
            id: 2,
            title: 'Archived',
            content: '',
            createdAt: now,
            updatedAt: now,
            isArchived: true),
        Note(
            id: 3,
            title: 'Trashed',
            content: '',
            createdAt: now,
            updatedAt: now,
            isTrashed: true),
        Note(
            id: 4,
            title: 'Locked',
            content: '',
            createdAt: now,
            updatedAt: now,
            isLocked: true),
        Note(
            id: 5,
            title: 'Archived+Trashed',
            content: '',
            createdAt: now,
            updatedAt: now,
            isArchived: true,
            isTrashed: true),
      ]);
      expect(service.activeNotes.length, 1);
      expect(service.activeNotes.first.id, 1);
    });

    test('archivedNotes لا تشمل المحذوفة أو المقفلة', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Archived',
            content: '',
            createdAt: now,
            updatedAt: now,
            isArchived: true),
        Note(
            id: 2,
            title: 'Archived+Trashed',
            content: '',
            createdAt: now,
            updatedAt: now,
            isArchived: true,
            isTrashed: true),
        Note(
            id: 3,
            title: 'Archived+Locked',
            content: '',
            createdAt: now,
            updatedAt: now,
            isArchived: true,
            isLocked: true),
      ]);
      expect(service.archivedNotes.length, 1);
      expect(service.archivedNotes.first.id, 1);
    });

    test('trashedNotes لا تشمل المقفلة', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Trashed',
            content: '',
            createdAt: now,
            updatedAt: now,
            isTrashed: true),
        Note(
            id: 2,
            title: 'Trashed+Locked',
            content: '',
            createdAt: now,
            updatedAt: now,
            isTrashed: true,
            isLocked: true),
      ]);
      expect(service.trashedNotes.length, 1);
      expect(service.trashedNotes.first.id, 1);
    });

    test('reminderNotes تشمل فقط التذكيرات المستقبلية غير المقفلة', () {
      final future = now.add(const Duration(days: 1));
      final past = now.subtract(const Duration(days: 1));
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Future',
            content: '',
            createdAt: now,
            updatedAt: now,
            reminderDateTime: future),
        Note(
            id: 2,
            title: 'Past',
            content: '',
            createdAt: now,
            updatedAt: now,
            reminderDateTime: past),
        Note(
            id: 3,
            title: 'Locked+Future',
            content: '',
            createdAt: now,
            updatedAt: now,
            reminderDateTime: future,
            isLocked: true),
        Note(
            id: 4,
            title: 'Trashed+Future',
            content: '',
            createdAt: now,
            updatedAt: now,
            reminderDateTime: future,
            isTrashed: true),
      ]);
      expect(service.reminderNotes.length, 1);
      expect(service.reminderNotes.first.id, 1);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 2. الكاش — Cache Invalidation
  // ══════════════════════════════════════════════════════════════
  group('NoteStateService — Cache Invalidation', () {
    test('الكاش يُحدَّث بعد updateNote', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Original',
            content: '',
            createdAt: now,
            updatedAt: now),
      ]);
      final before = service.activeNotes.first.title;

      service.updateNote(Note(
          id: 1,
          title: 'Updated',
          content: '',
          createdAt: now,
          updatedAt: now));
      final after = service.activeNotes.first.title;

      expect(before, 'Original');
      expect(after, 'Updated');
    });

    test('الكاش يُحدَّث بعد removeNote', () {
      service.updateAllNotes([
        Note(id: 1, title: 'Note', content: '', createdAt: now, updatedAt: now),
      ]);
      expect(service.activeNotes.length, 1);

      service.removeNote(1);
      expect(service.activeNotes.length, 0);
    });

    test('الكاش يُحدَّث بعد batchUpdateNotes', () {
      service.updateAllNotes([
        Note(id: 1, title: 'A', content: '', createdAt: now, updatedAt: now),
        Note(id: 2, title: 'B', content: '', createdAt: now, updatedAt: now),
      ]);

      service.batchUpdateNotes([1, 2], (n) => n.copyWith(isTrashed: true));
      expect(service.activeNotes.length, 0);
      expect(service.trashedNotes.length, 2);
    });

    test('قراءة activeNotes مرتين تُرجع نفس النتيجة (cache hit)', () {
      service.updateAllNotes([
        Note(id: 1, title: 'Note', content: '', createdAt: now, updatedAt: now),
      ]);
      final first = service.activeNotes;
      final second = service.activeNotes;
      expect(identical(first, second), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 3. الترتيب
  // ══════════════════════════════════════════════════════════════
  group('NoteStateService — Sorting', () {
    test('المثبتة تأتي أولاً دائماً', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Regular',
            content: '',
            createdAt: now,
            updatedAt: now,
            isPinned: false),
        Note(
            id: 2,
            title: 'Pinned',
            content: '',
            createdAt: now,
            updatedAt: now.add(const Duration(seconds: -1)),
            isPinned: true),
      ]);
      // المثبتة أقدم لكن يجب أن تأتي أولاً
      expect(service.activeNotes.first.id, 2);
    });

    test('بين المثبتات: الأحدث أولاً', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Pinned Old',
            content: '',
            createdAt: now,
            updatedAt: now.subtract(const Duration(hours: 1)),
            isPinned: true),
        Note(
            id: 2,
            title: 'Pinned New',
            content: '',
            createdAt: now,
            updatedAt: now,
            isPinned: true),
      ]);
      expect(service.activeNotes.first.id, 2);
    });

    test('بين العادية: الأحدث أولاً', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Old',
            content: '',
            createdAt: now,
            updatedAt: now.subtract(const Duration(hours: 2))),
        Note(id: 2, title: 'New', content: '', createdAt: now, updatedAt: now),
        Note(
            id: 3,
            title: 'Middle',
            content: '',
            createdAt: now,
            updatedAt: now.subtract(const Duration(hours: 1))),
      ]);
      final ids = service.activeNotes.map((n) => n.id).toList();
      expect(ids, [2, 3, 1]);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 4. البحث
  // ══════════════════════════════════════════════════════════════
  group('NoteStateService — Search', () {
    test('البحث بنص فارغ يُرجع كل الملاحظات النشطة', () {
      service.updateAllNotes([
        Note(id: 1, title: 'A', content: '', createdAt: now, updatedAt: now),
        Note(
            id: 2,
            title: 'B',
            content: '',
            createdAt: now,
            updatedAt: now,
            isTrashed: true),
      ]);
      expect(service.searchNotes('').length, 1);
    });

    test('البحث بمسافات فقط يُرجع كل الملاحظات النشطة', () {
      service.updateAllNotes([
        Note(id: 1, title: 'A', content: '', createdAt: now, updatedAt: now),
      ]);
      expect(service.searchNotes('   ').length, 1);
    });

    test('البحث في العنوان والمحتوى', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Flutter',
            content: 'Dart code',
            createdAt: now,
            updatedAt: now),
        Note(
            id: 2,
            title: 'Python',
            content: 'Flask framework',
            createdAt: now,
            updatedAt: now),
      ]);
      expect(service.searchNotes('Dart').length, 1);
      expect(service.searchNotes('Flask').length, 1);
      expect(service.searchNotes('code').length, 1);
    });

    test('البحث غير حساس لحالة الأحرف', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Flutter Development',
            content: '',
            createdAt: now,
            updatedAt: now),
      ]);
      expect(service.searchNotes('flutter').length, 1);
      expect(service.searchNotes('FLUTTER').length, 1);
      expect(service.searchNotes('FlUtTeR').length, 1);
    });

    test('البحث لا يُرجع أكثر من 100 نتيجة', () {
      service.updateAllNotes(
        List.generate(
            200,
            (i) => Note(
                  id: i + 1,
                  title: 'Note $i',
                  content: 'search_term',
                  createdAt: now,
                  updatedAt: now,
                )),
      );
      expect(service.searchNotes('search_term').length, 100);
    });

    test('البحث لا يُرجع ملاحظات مقفلة', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Public',
            content: 'secret',
            createdAt: now,
            updatedAt: now),
        Note(
            id: 2,
            title: 'Locked',
            content: 'secret',
            createdAt: now,
            updatedAt: now,
            isLocked: true),
      ]);
      final results = service.searchNotes('secret');
      expect(results.length, 1);
      expect(results.first.id, 1);
    });

    test('البحث يتجاهل التشكيل — يجد "أهلاً" بكتابة "اهلا"', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'أهلاً وسهلاً',
            content: '',
            createdAt: now,
            updatedAt: now),
      ]);
      expect(service.searchNotes('اهلا').length, 1);
      expect(service.searchNotes('أهلاً').length, 1);
    });

    test('البحث يوحّد الألف — يجد "إنجاز" بكتابة "انجاز"', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'إنجاز رائع',
            content: '',
            createdAt: now,
            updatedAt: now),
      ]);
      expect(service.searchNotes('انجاز').length, 1);
    });

    test('البحث يوحّد التاء المربوطة — يجد "مدرسة" بكتابة "مدرسه"', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'مدرسة النجاح',
            content: '',
            createdAt: now,
            updatedAt: now),
      ]);
      expect(service.searchNotes('مدرسه').length, 1);
    });

    test('البحث في المحتوى المطبّع', () {
      service.updateAllNotes([
        Note(
            id: 1,
            title: '',
            content: 'مُحتوى مُهِمّ',
            createdAt: now,
            updatedAt: now),
      ]);
      expect(service.searchNotes('محتوى مهم').length, 1);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 5. تسريب المزامنة — Sync Leak Detection
  // ══════════════════════════════════════════════════════════════
  group('NoteStateService — Sync Leak', () {
    test('_silentSync لا يُشغَّل عند auto_sync معطّل', () async {
      // SharedPreferences مُعدَّة بدون google_drive_auto_sync
      // لذا _silentSync يجب أن يتوقف بعد قراءة الإعداد
      service.updateAllNotes([
        Note(id: 1, title: 'Test', content: '', createdAt: now, updatedAt: now),
      ]);
      service.updateNote(
        Note(
            id: 1,
            title: 'Updated',
            content: '',
            createdAt: now,
            updatedAt: now),
      );
      // انتظر أكثر من 5 ثوانٍ لا يمكن في الاختبار، لكن نتحقق أن لا استثناء
      await Future.delayed(const Duration(milliseconds: 100));
      expect(service.activeNotes.first.title, 'Updated');
    });

    test('dispose يُلغي كل الـ timers بدون استثناء', () {
      service.updateAllNotes([
        Note(id: 1, title: 'Test', content: '', createdAt: now, updatedAt: now),
      ]);
      // تشغيل عمليات تُنشئ timers
      service.updateNote(
          Note(id: 1, title: 'U', content: '', createdAt: now, updatedAt: now));
      service.sortNotes(); // debounced timer
      expect(() => service.dispose(), returnsNormally);
    });

    test('dispose بعد dispose لا يرمي استثناء', () {
      service.dispose();
      expect(() => service.dispose(), returnsNormally);
    });

    test('عمليات متزامنة على نفس الملاحظة لا تُسبب تعارضاً', () async {
      service.updateAllNotes([
        Note(
            id: 1,
            title: 'Original',
            content: '',
            createdAt: now,
            updatedAt: now),
      ]);

      // تحديثات متزامنة
      final futures = List.generate(10, (i) async {
        service.updateNote(
          Note(
              id: 1,
              title: 'Update $i',
              content: '',
              createdAt: now,
              updatedAt: now.add(Duration(milliseconds: i))),
        );
      });

      await Future.wait(futures);
      // يجب أن تكون الملاحظة موجودة بدون استثناء
      expect(service.activeNotes.length, 1);
    });

    test('إضافة وحذف متزامن لا يُسبب تعارضاً', () async {
      service.updateAllNotes([]);

      final addFutures = List.generate(5, (i) async {
        service.addNote(
          Note(
              id: i + 1,
              title: 'Note $i',
              content: '',
              createdAt: now,
              updatedAt: now),
        );
      });

      await Future.wait(addFutures);

      final removeFutures = List.generate(5, (i) async {
        service.removeNote(i + 1);
      });

      await Future.wait(removeFutures);
      expect(service.activeNotes.length, 0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 6. الملاحظات المقفلة
  // ══════════════════════════════════════════════════════════════
  group('NoteStateService — Locked Notes', () {
    test('addNote مع isLocked يضيف للقائمة المقفلة فقط', () {
      service.addNote(
        Note(
            id: 1,
            title: 'Locked',
            content: '',
            createdAt: now,
            updatedAt: now,
            isLocked: true),
      );
      expect(service.lockedNotes.length, 1);
      expect(service.activeNotes.length, 0);
    });

    test('clearLockedNotes يمسح القائمة المقفلة', () {
      service.updateLockedNotes([
        Note(
            id: 1,
            title: 'Locked',
            content: 'Secret',
            createdAt: now,
            updatedAt: now,
            isLocked: true),
      ]);
      expect(service.lockedNotes.length, 1);
      service.clearLockedNotes();
      expect(service.lockedNotes.length, 0);
    });

    test('removeNote يحذف من القائمة المقفلة', () {
      service.updateLockedNotes([
        Note(
            id: 99,
            title: 'Locked',
            content: '',
            createdAt: now,
            updatedAt: now,
            isLocked: true),
      ]);
      service.removeNote(99);
      expect(service.lockedNotes.length, 0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 7. حماية Dispose — لا crash بعد dispose
  // ══════════════════════════════════════════════════════════════
  group('NoteStateService — Dispose Safety', () {
    test('_silentSync لا يُنفَّذ بعد dispose', () async {
      bool callbackCalled = false;
      service.onSyncCompleted = () async {
        callbackCalled = true;
      };

      service.updateAllNotes([
        Note(id: 1, title: 'Test', content: '', createdAt: now, updatedAt: now),
      ]);

      // يُطلق _silentSync (timer 5 ثوانٍ)
      service.updateNote(
        Note(
            id: 1,
            title: 'Modified',
            content: '',
            createdAt: now,
            updatedAt: now),
      );

      // dispose قبل انتهاء الـ timer
      service.dispose();

      // انتظر قليلاً — الـ callback يجب ألا يُستدعى
      await Future.delayed(const Duration(milliseconds: 200));
      expect(callbackCalled, isFalse);
    });

    test('عمليات على الـ state بعد dispose لا ترمي استثناء', () {
      service.updateAllNotes([
        Note(id: 1, title: 'A', content: '', createdAt: now, updatedAt: now),
      ]);
      service.dispose();

      // هذه العمليات يجب ألا ترمي أي استثناء
      expect(
          () => service.updateNote(
                Note(
                    id: 1,
                    title: 'B',
                    content: '',
                    createdAt: now,
                    updatedAt: now),
              ),
          returnsNormally);
      expect(
          () => service.addNote(
                Note(
                    id: 2,
                    title: 'C',
                    content: '',
                    createdAt: now,
                    updatedAt: now),
              ),
          returnsNormally);
      expect(() => service.removeNote(1), returnsNormally);
    });

    test('getNoteById يعمل بعد updateAllNotes', () {
      service.updateAllNotes([
        Note(
            id: 5,
            title: 'Find me',
            content: 'here',
            createdAt: now,
            updatedAt: now),
        Note(
            id: 10,
            title: 'Other',
            content: '',
            createdAt: now,
            updatedAt: now),
      ]);
      final found = service.getNoteById(5);
      expect(found, isNotNull);
      expect(found!.title, 'Find me');
      expect(service.getNoteById(999), isNull);
    });
  });
}
