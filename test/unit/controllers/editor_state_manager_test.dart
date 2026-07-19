// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/screens/shared/note_editor/state/editor_state_manager.dart';

void main() {
  group('EditorStateManager', () {
    late EditorStateManager manager;
    late DateTime now;

    setUp(() {
      manager = EditorStateManager();
      now = DateTime.now();
    });

    group('Initialization', () {
      test('initializes with default values', () {
        expect(manager.content, '');
        expect(manager.customTitle, null);
        expect(manager.checklistTitle, null);
        expect(manager.colorIndex, 0);
        expect(manager.isAuthenticated, false);
        expect(manager.isSaving, false);
        expect(manager.isDirty, false);
        expect(manager.hasContent, false);
        expect(manager.canUndo, false);
        expect(manager.canRedo, false);
        expect(manager.reminderDateTime, null);
        expect(manager.recurrenceRule, null);
      });
    });

    group('loadFromNote', () {
      test('loads simple note correctly', () {
        final note = Note(
          id: 1,
          title: 'Test Title',
          content: 'Test Content',
          createdAt: now,
          updatedAt: now,
          colorIndex: 2,
          noteType: 'simple',
        );

        manager.loadFromNote(
          noteContent: note.content,
          noteTitle: note.title,
          noteColorIndex: note.colorIndex,
        );

        expect(manager.content, 'Test Content');
        expect(manager.customTitle, 'Test Title');
        expect(manager.colorIndex, 2);
        expect(manager.hasContent, true);
      });

      test('loads checklist note correctly', () {
        final note = Note(
          id: 1,
          title: 'Checklist Title',
          content: '[]Item 1\n[x]Item 2',
          createdAt: now,
          updatedAt: now,
          noteType: 'checklist',
          isChecklist: true,
        );

        manager.loadFromNote(
          noteContent: note.content,
          noteTitle: note.title,
          isChecklist: true,
        );

        expect(manager.content, '[]Item 1\n[x]Item 2');
        expect(manager.checklistTitle, 'Checklist Title');
        expect(manager.hasContent, true);
      });

      test('loads note with reminder correctly', () {
        final reminderDate = now.add(const Duration(days: 1));
        final note = Note(
          id: 1,
          title: 'Reminder Note',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
          reminderDateTime: reminderDate,
          recurrenceRule: 'FREQ=DAILY',
        );

        manager.loadFromNote(
          noteContent: note.content,
          noteTitle: note.title,
          noteReminderDateTime: note.reminderDateTime,
          noteRecurrenceRule: note.recurrenceRule,
        );

        expect(manager.reminderDateTime, reminderDate);
        expect(manager.recurrenceRule, 'FREQ=DAILY');
      });

      test('updates snapshot after loading', () {
        final note = Note(
          id: 1,
          title: 'Test',
          content: 'Content',
          createdAt: now,
          updatedAt: now,
        );

        manager.loadFromNote(
          noteContent: note.content,
          noteTitle: note.title,
        );

        expect(manager.hasChanges(), false);
      });
    });

    group('hasChanges', () {
      test('returns false when no changes', () {
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
        );

        expect(manager.hasChanges(), false);
      });

      test('detects content changes', () {
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
        );

        manager.updateContent('Modified');

        expect(manager.hasChanges(), true);
      });

      test('detects title changes', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteTitle: 'Original Title',
        );

        manager.customTitle = 'Modified Title';

        expect(manager.hasChanges(), true);
      });

      test('detects color changes', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteColorIndex: 0,
        );

        manager.colorIndex = 1;

        expect(manager.hasChanges(), true);
      });

      test('detects reminder changes', () {
        final originalDate = now.add(const Duration(days: 1));
        manager.loadFromNote(
          noteContent: 'Content',
          noteReminderDateTime: originalDate,
        );

        manager.reminderDateTime = now.add(const Duration(days: 2));

        expect(manager.hasChanges(), true);
      });

      test('detects recurrence rule changes', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteRecurrenceRule: 'FREQ=DAILY',
        );

        manager.recurrenceRule = 'FREQ=WEEKLY';

        expect(manager.hasChanges(), true);
      });

      test('detects reminder removal', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteReminderDateTime: now.add(const Duration(days: 1)),
        );

        manager.reminderDateTime = null;

        expect(manager.hasChanges(), true);
      });

      test('handles null title correctly', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteTitle: null,
        );

        expect(manager.hasChanges(), false);

        manager.customTitle = 'New Title';
        expect(manager.hasChanges(), true);
      });
    });

    group('updateSnapshot', () {
      test('updates snapshot to current state', () {
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
        );

        manager.updateContent('Modified');
        expect(manager.hasChanges(), true);

        manager.updateSnapshot();
        expect(manager.hasChanges(), false);
      });

      test('updates all snapshot fields', () {
        manager.updateContent('New Content');
        manager.updateTitle('New Title');
        manager.colorIndex = 3;
        manager.reminderDateTime = now.add(const Duration(days: 1));
        manager.recurrenceRule = 'FREQ=DAILY';

        manager.updateSnapshot();
        expect(manager.hasChanges(), false);

        manager.updateContent('Different');
        expect(manager.hasChanges(), true);
      });
    });

    group('State Management', () {
      test('tracks content state correctly', () {
        expect(manager.hasContent, false);

        manager.content = 'Some content';
        manager.hasContent = true;

        expect(manager.hasContent, true);
      });

      test('tracks UI state correctly', () {
        expect(manager.isAuthenticated, false);
        expect(manager.isSaving, false);
        expect(manager.isDirty, false);

        manager.isAuthenticated = true;
        manager.isSaving = true;
        manager.isDirty = true;

        expect(manager.isAuthenticated, true);
        expect(manager.isSaving, true);
        expect(manager.isDirty, true);
      });

      test('tracks undo/redo state correctly', () {
        expect(manager.canUndo, false);
        expect(manager.canRedo, false);

        manager.canUndo = true;
        manager.canRedo = true;

        expect(manager.canUndo, true);
        expect(manager.canRedo, true);
      });
    });

    group('Edge Cases', () {
      test('handles empty content', () {
        manager.loadFromNote(
          noteContent: '',
          noteTitle: '',
        );

        expect(manager.hasChanges(), false);

        manager.updateContent('New');
        expect(manager.hasChanges(), true);
      });

      test('handles very long content', () {
        final longContent = 'A' * 10000;
        manager.loadFromNote(
          noteContent: longContent,
        );

        expect(manager.content, longContent);
        expect(manager.hasChanges(), false);
      });

      test('handles special characters in content', () {
        const specialContent = 'مرحبا\n\t\r\n😀🎉';
        manager.loadFromNote(
          noteContent: specialContent,
        );

        expect(manager.content, specialContent);
        expect(manager.hasChanges(), false);
      });

      test('handles null values correctly', () {
        manager.loadFromNote(
          noteContent: 'Content',
          noteTitle: null,
          noteReminderDateTime: null,
          noteRecurrenceRule: null,
        );

        expect(manager.customTitle, null);
        expect(manager.reminderDateTime, null);
        expect(manager.recurrenceRule, null);
        expect(manager.hasChanges(), false);
      });

      test('handles DateTime comparison correctly', () {
        final date1 = DateTime(2025, 1, 1, 12, 0, 0);
        final date2 = DateTime(2025, 1, 1, 12, 0, 0);

        manager.loadFromNote(
          noteContent: 'Content',
          noteReminderDateTime: date1,
        );

        manager.reminderDateTime = date2;

        // Same date/time should not trigger changes
        expect(manager.hasChanges(), false);
      });
    });

    group('Complex Scenarios', () {
      test('handles multiple changes and snapshot updates', () {
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
          noteColorIndex: 0,
        );
        expect(manager.hasChanges(), false);

        manager.updateContent('Modified 1');
        expect(manager.hasChanges(), true);

        manager.updateSnapshot();
        expect(manager.hasChanges(), false);

        manager.updateTitle('New Title');
        expect(manager.hasChanges(), true);

        manager.updateSnapshot();
        expect(manager.hasChanges(), false);
      });

      test('handles reverting changes', () {
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
        );

        // Make changes
        manager.content = 'Modified';
        manager.customTitle = 'New Title';
        expect(manager.hasChanges(), true);

        // Revert by reloading
        manager.loadFromNote(
          noteContent: 'Original',
          noteTitle: 'Title',
        );
        expect(manager.hasChanges(), false);
      });

      test('handles switching between note types', () {
        // Load as simple note
        manager.loadFromNote(
          noteContent: 'Simple content',
          noteTitle: 'Simple Title',
        );

        // Switch to checklist
        manager.content = '[]Item 1';
        manager.checklistTitle = 'Checklist Title';
        manager.customTitle = null;

        expect(manager.hasChanges(), true);
      });
    });

    group('autosave guard — isSaving', () {
      test('isSaving يمنع hasChanges من التأثير على منطق الحفظ الخارجي', () {
        manager.loadFromNote(noteContent: 'محتوى', noteTitle: 'عنوان');
        manager.markDirty();
        expect(manager.hasChanges(), true);

        manager.isSaving = true;
        // hasChanges لا تزال true — الـ guard في EditorSaveOperations وليس هنا
        expect(manager.hasChanges(), true);
        expect(manager.isSaving, true);
      });

      test('isSaving يُعاد تعيينه بعد الحفظ', () {
        manager.isSaving = true;
        manager.isSaving = false;
        expect(manager.isSaving, false);
      });

      test('isSaving لا يؤثر على isDirty', () {
        manager.markDirty();
        manager.isSaving = true;
        expect(manager.isDirty, true);
        manager.isSaving = false;
        expect(manager.isDirty, true); // isDirty يبقى حتى updateSnapshot
      });
    });

    group('isDirty مقابل snapshot', () {
      test('markDirty يُعيّن isDirty بدون تغيير snapshot', () {
        manager.loadFromNote(noteContent: 'أصلي', noteTitle: 'عنوان');
        expect(manager.isDirty, false);

        manager.markDirty();
        expect(manager.isDirty, true);
        // snapshot لم يتغير — originalContent لا يزال 'أصلي'
        expect(manager.originalContent, 'أصلي');
      });

      test('markClean يُصفّر isDirty بدون تحديث snapshot', () {
        manager.loadFromNote(noteContent: 'أصلي', noteTitle: 'عنوان');
        manager.markDirty();
        manager.content = 'جديد';

        manager.markClean();
        expect(manager.isDirty, false);
        // لكن hasChanges قد تظل true إذا تغير العنوان
        manager.customTitle = 'عنوان مختلف';
        expect(manager.hasChanges(), true); // title تغير
      });

      test('updateSnapshot يُصفّر isDirty ويحدث كل الحقول', () {
        manager.loadFromNote(
          noteContent: 'أصلي',
          noteTitle: 'عنوان',
          noteColorIndex: 0,
          noteReminderDateTime: null,
          noteRecurrenceRule: null,
        );

        manager.content = 'جديد';
        manager.customTitle = 'عنوان جديد';
        manager.colorIndex = 5;
        manager.reminderDateTime = DateTime(2025, 6, 1);
        manager.recurrenceRule = 'FREQ=WEEKLY';
        manager.markDirty();

        manager.updateSnapshot();

        expect(manager.isDirty, false);
        expect(manager.originalContent, 'جديد');
        expect(manager.originalTitle, 'عنوان جديد');
        expect(manager.originalColorIndex, 5);
        expect(manager.originalReminderDateTime, DateTime(2025, 6, 1));
        expect(manager.originalRecurrenceRule, 'FREQ=WEEKLY');
        expect(manager.hasChanges(), false);
      });

      test('autosave لا يستدعي updateSnapshot — isDirty يبقى true', () {
        // هذا يحاكي سلوك EditorSaveOperations.saveToDatabase مع isManualSave=false
        manager.loadFromNote(noteContent: 'أصلي', noteTitle: 'عنوان');
        manager.markDirty();

        // autosave: isManualSave=false → لا يستدعي updateSnapshot
        // نحاكي ذلك مباشرة
        void savedWithoutSnapshot() {
          // حفظ بدون updateSnapshot
          manager.isSaving = false;
        }

        savedWithoutSnapshot();

        // isDirty لا يزال true — الـ snapshot لم يتحدث
        expect(manager.isDirty, true);
        expect(manager.hasChanges(), true);
      });

      test('manual save يستدعي updateSnapshot — isDirty يصبح false', () {
        manager.loadFromNote(noteContent: 'أصلي', noteTitle: 'عنوان');
        manager.markDirty();
        manager.content = 'محتوى جديد';

        // manual save: isManualSave=true → يستدعي updateSnapshot
        manager.updateSnapshot();

        expect(manager.isDirty, false);
        expect(manager.hasChanges(), false);
      });
    });

    group('categoryIds و isHiddenFromHome', () {
      test('loadFromNote يحمّل categoryIds بشكل صحيح', () {
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteCategoryIds: [1, 2, 3],
        );
        expect(manager.categoryIds, [1, 2, 3]);
      });

      test('categoryIds فارغة بالافتراضي', () {
        manager.loadFromNote(noteContent: 'محتوى');
        expect(manager.categoryIds, isEmpty);
      });

      test('isHiddenFromHome يُحمَّل بشكل صحيح', () {
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteIsHiddenFromHome: true,
        );
        expect(manager.isHiddenFromHome, true);
      });

      test('تغيير categoryIds يُعيّن isDirty', () {
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteCategoryIds: [1],
        );
        manager.categoryIds = [1, 2];
        manager.markDirty();
        expect(manager.hasChanges(), true);
      });

      test('loadFromNote ينسخ categoryIds بدون reference مشترك', () {
        final original = [1, 2, 3];
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteCategoryIds: original,
        );
        original.add(4); // تعديل القائمة الأصلية
        expect(manager.categoryIds, [1, 2, 3]); // لا يتأثر
      });
    });

    group('checklist title مقابل customTitle', () {
      test('checklist: checklistTitle يُعيَّن و customTitle يبقى null', () {
        manager.loadFromNote(
          noteContent: '{"title":"مهام","items":[]}',
          noteTitle: 'مهام',
          isChecklist: true,
        );
        expect(manager.checklistTitle, 'مهام');
        expect(manager.customTitle, null);
      });

      test('simple: customTitle يُعيَّن و checklistTitle يبقى null', () {
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteTitle: 'عنوان',
          isChecklist: false,
        );
        expect(manager.customTitle, 'عنوان');
        expect(manager.checklistTitle, null);
      });

      test('hasChanges تقرأ checklistTitle عند isChecklist', () {
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteTitle: 'مهام',
          isChecklist: true,
        );
        expect(manager.hasChanges(), false);

        manager.checklistTitle = 'مهام محدثة';
        expect(manager.hasChanges(), true);
      });

      test('originalTitle يُحدَّث من checklistTitle عند updateSnapshot', () {
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteTitle: 'مهام',
          isChecklist: true,
        );
        manager.checklistTitle = 'مهام جديدة';
        manager.updateSnapshot();
        expect(manager.originalTitle, 'مهام جديدة');
        expect(manager.hasChanges(), false);
      });
    });

    group('clear', () {
      test('clear يُعيد كل الحقول للقيم الافتراضية', () {
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteTitle: 'عنوان',
          noteColorIndex: 5,
          noteReminderDateTime: DateTime(2025, 1, 1),
          noteRecurrenceRule: 'FREQ=DAILY',
          noteCategoryIds: [1, 2],
          noteIsHiddenFromHome: true,
        );
        manager.markDirty();
        manager.isSaving = true;
        manager.canUndo = true;
        manager.canRedo = true;

        manager.clear();

        expect(manager.content, '');
        expect(manager.customTitle, null);
        expect(manager.checklistTitle, null);
        expect(manager.colorIndex, 0);
        expect(manager.isDirty, false);
        expect(manager.isSaving, false);
        expect(manager.hasContent, false);
        expect(manager.canUndo, false);
        expect(manager.canRedo, false);
        expect(manager.reminderDateTime, null);
        expect(manager.recurrenceRule, null);
        expect(manager.originalContent, '');
        expect(manager.originalTitle, '');
        expect(manager.originalColorIndex, 0);
        expect(manager.hasChanges(), false);
      });

      test('clear ثم loadFromNote يعمل بشكل صحيح', () {
        manager.loadFromNote(noteContent: 'قديم', noteTitle: 'قديم');
        manager.markDirty();
        manager.clear();

        manager.loadFromNote(noteContent: 'جديد', noteTitle: 'جديد');
        expect(manager.content, 'جديد');
        expect(manager.hasChanges(), false);
        expect(manager.isDirty, false);
      });
    });

    group('تسلسل autosave الحقيقي', () {
      test('كتابة → dirty → autosave بدون snapshot → كتابة → dirty لا يزال',
          () {
        // يحاكي: المستخدم يكتب → autosave يحفظ → يكتب مجدداً
        manager.loadFromNote(noteContent: 'نص أولي', noteTitle: '');

        // كتابة أولى
        manager.updateContent('نص أولي + إضافة');
        expect(manager.isDirty, true);

        // autosave يحفظ بدون updateSnapshot
        manager.isSaving = true;
        manager.isSaving = false;
        // isDirty لا يزال true
        expect(manager.isDirty, true);

        // كتابة ثانية
        manager.updateContent('نص أولي + إضافة + المزيد');
        expect(manager.isDirty, true);
        expect(manager.hasChanges(), true);
      });

      test('manual save → updateSnapshot → لا تغييرات', () {
        manager.loadFromNote(noteContent: 'نص', noteTitle: 'عنوان');
        manager.updateContent('نص محدث');
        manager.customTitle = 'عنوان محدث';
        manager.colorIndex = 3;

        // manual save
        manager.updateSnapshot();

        expect(manager.hasChanges(), false);
        expect(manager.isDirty, false);
        expect(manager.originalContent, 'نص محدث');
        expect(manager.originalTitle, 'عنوان محدث');
        expect(manager.originalColorIndex, 3);
      });

      test('تغيير اللون فقط يُكتشف كتغيير', () {
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteTitle: 'عنوان',
          noteColorIndex: 2,
        );
        expect(manager.hasChanges(), false);

        manager.colorIndex = 7;
        // isDirty لا يزال false لكن colorIndex تغير
        expect(manager.isDirty, false);
        expect(manager.hasChanges(),
            true); // يكتشف عبر colorIndex != originalColorIndex
      });

      test('إزالة reminder تُكتشف كتغيير حتى بدون isDirty', () {
        final reminder = DateTime(2025, 12, 31);
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteReminderDateTime: reminder,
        );
        expect(manager.hasChanges(), false);

        manager.reminderDateTime = null;
        expect(manager.isDirty, false); // لم نستدعِ markDirty
        expect(manager.hasChanges(),
            true); // يكتشف عبر reminderDateTime != original
      });
    });

    group('Performance', () {
      test('hasChanges is fast for large content', () {
        final largeContent = 'A' * 100000;
        manager.loadFromNote(
          noteContent: largeContent,
        );

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          manager.hasChanges();
        }
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('updateSnapshot is fast', () {
        manager.content = 'Content' * 1000;
        manager.customTitle = 'Title';
        manager.colorIndex = 5;

        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          manager.updateSnapshot();
        }
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
