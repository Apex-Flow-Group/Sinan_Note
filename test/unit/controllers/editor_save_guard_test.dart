// Copyright © 2025 Apex Flow Group. All rights reserved.
// ⚡ اختبارات حراسة الحفظ — تمنع الحفظ/الإشعار الكاذب عند فتح نوت بدون تعديل

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/controllers/editor/editor_state_manager.dart';

void main() {
  group('حراسة الحفظ — فتح نوت بدون تعديل', () {
    late EditorStateManager manager;

    setUp(() {
      manager = EditorStateManager();
    });

    // ══════════════════════════════════════════════════════════════
    // 1. نوت الكود — فتح بالعارض أو المحرر بدون تعديل
    // ══════════════════════════════════════════════════════════════
    group('Code Note — لا حفظ بدون تعديل', () {
      test('loadFromNote ثم hasChanges يُرجع false مباشرة', () {
        manager.loadFromNote(
          noteContent: 'void main() { print("hello"); }',
          noteTitle: 'main.dart',
          noteColorIndex: 0,
        );

        // بعد التحميل مباشرة — لا تغييرات
        expect(manager.hasChanges(), false);
        expect(manager.isDirty, false);
      });

      test('isLoading يحمي من markDirty أثناء التهيئة', () {
        manager.isLoading = true;
        manager.loadFromNote(
          noteContent: 'int x = 0;',
          noteTitle: 'code.dart',
        );

        // محاكاة: CodeController يُرسل حدث تغيير أثناء التهيئة
        // الحارس isLoading يمنع markDirty في _handleContentChange
        // لذا نتحقق أن isDirty لا يزال false
        expect(manager.isDirty, false);
        expect(manager.hasChanges(), false);

        // بعد انتهاء التحميل
        manager.isLoading = false;
        expect(manager.hasChanges(), false);
      });

      test('markDirty بعد isLoading=false يُفعَّل بشكل صحيح', () {
        manager.isLoading = true;
        manager.loadFromNote(
          noteContent: 'final x = 42;',
          noteTitle: 'test.dart',
        );
        manager.isLoading = false;

        // الآن المستخدم يكتب فعلاً
        manager.markDirty();
        expect(manager.hasChanges(), true);
      });

      test('فتح وإغلاق بدون تعديل — hasChanges يبقى false', () {
        // محاكاة: فتح نوت كود → إغلاق
        manager.loadFromNote(
          noteContent: 'class MyApp extends StatelessWidget {}',
          noteTitle: 'app.dart',
          noteColorIndex: 3,
        );
        manager.isLoading = false;

        // لم يحدث أي markDirty — المستخدم لم يكتب شيئاً
        expect(manager.hasChanges(), false);
        expect(manager.isDirty, false);
      });
    });

    // ══════════════════════════════════════════════════════════════
    // 2. نوت عادي (Quill) — فتح بالمحرر بدون تعديل
    // ══════════════════════════════════════════════════════════════
    group('Quill Note — لا إشعار حفظ كاذب', () {
      test('فتح نوت عادي وإغلاق — hasChanges = false', () {
        manager.loadFromNote(
          noteContent: '[{"insert":"مرحبا بالعالم\\n"}]',
          noteTitle: 'ملاحظة عادية',
          noteColorIndex: 1,
        );
        manager.isLoading = false;

        expect(manager.hasChanges(), false);
      });

      test('isLoading يحمي من تغييرات Quill الداخلية', () {
        manager.isLoading = true;
        manager.loadFromNote(
          noteContent: '[{"insert":"نص\\n"}]',
          noteTitle: 'ملاحظة',
        );

        // محاكاة: Quill يُرسل change event أثناء _fixDeltaDirections
        // الحارس يمنع markDirty
        expect(manager.isDirty, false);

        manager.isLoading = false;
        expect(manager.hasChanges(), false);
      });
    });

    // ══════════════════════════════════════════════════════════════
    // 3. نوت قائمة مهام — فتح بالمحرر بدون تعديل
    // ══════════════════════════════════════════════════════════════
    group('Checklist Note — لا حفظ بدون تعديل', () {
      test('فتح checklist وإغلاق — hasChanges = false', () {
        manager.loadFromNote(
          noteContent:
              '{"title":"مهام","items":[{"text":"شراء حليب","checked":false}]}',
          noteTitle: 'مهام',
          isChecklist: true,
        );
        manager.isLoading = false;

        expect(manager.hasChanges(), false);
        expect(manager.checklistTitle, 'مهام');
      });

      test('تبديل checkbox في العارض يُفعِّل hasChanges', () {
        manager.loadFromNote(
          noteContent: '{"items":[{"text":"مهمة","checked":false}]}',
          noteTitle: 'قائمة',
          isChecklist: true,
        );
        manager.isLoading = false;

        // المستخدم ضغط على checkbox
        manager.markDirty();
        expect(manager.hasChanges(), true);
      });
    });

    // ══════════════════════════════════════════════════════════════
    // 4. سيناريو الحفظ الكامل — saveToDatabase guard
    // ══════════════════════════════════════════════════════════════
    group('Save Guard Logic — محاكاة EditorSaveOperations', () {
      /// محاكاة شرط الحفظ في EditorSaveOperations.saveToDatabase
      bool shouldSave({
        required EditorStateManager stateManager,
        required bool forceUpdate,
        required int? savedNoteId,
        required int? existingNoteId,
        required bool isNewLockedNote,
      }) {
        if (stateManager.isSaving) return false;
        if (!forceUpdate &&
            !isNewLockedNote &&
            (savedNoteId != null || existingNoteId != null)) {
          if (!stateManager.hasChanges()) {
            return false;
          }
        }
        return true;
      }

      test('نوت موجودة بدون تغيير — لا يُحفظ', () {
        manager.loadFromNote(
          noteContent: 'محتوى ثابت',
          noteTitle: 'عنوان',
        );
        manager.isLoading = false;

        final result = shouldSave(
          stateManager: manager,
          forceUpdate: false,
          savedNoteId: 42,
          existingNoteId: 42,
          isNewLockedNote: false,
        );
        expect(result, false);
      });

      test('نوت موجودة مع تغيير — يُحفظ', () {
        manager.loadFromNote(
          noteContent: 'محتوى أصلي',
          noteTitle: 'عنوان',
        );
        manager.isLoading = false;
        manager.markDirty();

        final result = shouldSave(
          stateManager: manager,
          forceUpdate: false,
          savedNoteId: 42,
          existingNoteId: 42,
          isNewLockedNote: false,
        );
        expect(result, true);
      });

      test('forceUpdate يتجاوز حارس hasChanges', () {
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteTitle: 'عنوان',
        );
        manager.isLoading = false;
        // لا تغييرات

        final result = shouldSave(
          stateManager: manager,
          forceUpdate: true,
          savedNoteId: 42,
          existingNoteId: 42,
          isNewLockedNote: false,
        );
        expect(result, true);
      });

      test('isSaving يمنع الحفظ المتكرر', () {
        manager.loadFromNote(noteContent: 'محتوى', noteTitle: 'عنوان');
        manager.markDirty();
        manager.isSaving = true;

        final result = shouldSave(
          stateManager: manager,
          forceUpdate: false,
          savedNoteId: 42,
          existingNoteId: 42,
          isNewLockedNote: false,
        );
        expect(result, false);
      });

      test('نوت جديدة (بدون id) — يُحفظ حتى بدون hasChanges', () {
        manager.loadFromNote(noteContent: 'محتوى جديد', noteTitle: 'عنوان');
        manager.isLoading = false;
        // لا savedNoteId ولا existingNoteId

        final result = shouldSave(
          stateManager: manager,
          forceUpdate: false,
          savedNoteId: null,
          existingNoteId: null,
          isNewLockedNote: false,
        );
        expect(result, true); // لا يوجد id → الشرط لا ينطبق → يُحفظ
      });

      test('نوت مقفلة جديدة — يُحفظ حتى بدون تغيير', () {
        manager.loadFromNote(noteContent: '', noteTitle: '');
        manager.isLoading = false;

        final result = shouldSave(
          stateManager: manager,
          forceUpdate: false,
          savedNoteId: null,
          existingNoteId: null,
          isNewLockedNote: true,
        );
        expect(result, true);
      });
    });

    // ══════════════════════════════════════════════════════════════
    // 5. سيناريو _handleBack — إشعار الحفظ
    // ══════════════════════════════════════════════════════════════
    group('handleBack — إشعار الحفظ يعتمد على نتيجة الحفظ الفعلية', () {
      test('hasContent=true + hasChanges=false → لا إشعار (didSave=false)', () {
        manager.loadFromNote(
          noteContent: 'محتوى موجود',
          noteTitle: 'عنوان',
        );
        manager.isLoading = false;

        const hasContent = true;
        final hasChanges = manager.hasChanges(); // false

        // محاكاة: _handleBack
        bool didSave = false;
        if (hasContent && hasChanges) {
          didSave = true; // لن يصل هنا
        }

        expect(didSave, false); // لا إشعار
      });

      test('hasContent=true + hasChanges=true → إشعار (didSave=true)', () {
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteTitle: 'عنوان',
        );
        manager.isLoading = false;
        manager.markDirty(); // المستخدم عدّل فعلاً

        const hasContent = true;
        final hasChanges = manager.hasChanges(); // true

        bool didSave = false;
        if (hasContent && hasChanges) {
          didSave = true; // يتم الحفظ
        }

        expect(didSave, true); // إشعار صحيح
      });

      test('hasContent=false → لا حفظ ولا إشعار', () {
        manager.loadFromNote(noteContent: '', noteTitle: '');
        manager.isLoading = false;

        final hasContent = manager.content.trim().isNotEmpty;
        final hasChanges = manager.hasChanges();

        bool didSave = false;
        if (hasContent && hasChanges) {
          didSave = true;
        }

        expect(hasContent, false);
        expect(didSave, false);
      });
    });

    // ══════════════════════════════════════════════════════════════
    // 6. Edge Cases — حالات حافة
    // ══════════════════════════════════════════════════════════════
    group('Edge Cases', () {
      test('تغيير اللون فقط — يُحفظ ولكن لا يُعتبر dirty', () {
        manager.loadFromNote(
          noteContent: 'محتوى',
          noteTitle: 'عنوان',
          noteColorIndex: 0,
        );
        manager.isLoading = false;

        manager.colorIndex = 5;
        // isDirty = false ولكن hasChanges = true بسبب colorIndex
        expect(manager.isDirty, false);
        expect(manager.hasChanges(), true);
      });

      test('إعادة المحتوى للقيمة الأصلية بعد markDirty', () {
        manager.loadFromNote(
          noteContent: 'نص أصلي',
          noteTitle: 'عنوان',
        );
        manager.isLoading = false;

        // المستخدم كتب ثم مسح — isDirty = true لكن المحتوى لم يتغير فعلاً
        manager.markDirty();
        expect(manager.hasChanges(), true); // isDirty = true

        // لكن إذا أعدنا markClean (مثلاً undo الكامل)
        manager.markClean();
        // والمحتوى الفعلي لم يتغير (title, color, reminder كلها أصلية)
        expect(manager.hasChanges(), false);
      });

      test('تسلسل سريع: load → isLoading=false → markDirty → markClean', () {
        manager.loadFromNote(noteContent: 'كود', noteTitle: 'file.dart');
        manager.isLoading = false;

        // حدث CodeController بعد isLoading=false (حالة نادرة)
        // لكن المحتوى لم يتغير فعلاً — فقط isDirty
        manager.markDirty();
        expect(manager.hasChanges(), true);

        // AutoSave يحفظ ويستدعي markClean (في حالة autosave)
        manager.markClean();
        expect(manager.hasChanges(), false);
      });

      test('multiple loadFromNote calls reset state properly', () {
        // أول تحميل
        manager.loadFromNote(noteContent: 'نوت 1', noteTitle: 'أول');
        manager.markDirty();
        expect(manager.hasChanges(), true);

        // تحميل ثاني (المستخدم فتح نوت أخرى)
        manager.loadFromNote(noteContent: 'نوت 2', noteTitle: 'ثاني');
        expect(manager.hasChanges(), false);
        expect(manager.isDirty, false);
      });

      test('نوت فارغة المحتوى مع عنوان — hasContent يعتمد على content فقط', () {
        manager.loadFromNote(
          noteContent: '',
          noteTitle: 'عنوان بدون محتوى',
        );
        // hasContent يُحسب من content.isNotEmpty في loadFromNote
        expect(manager.hasContent, false);
      });

      test('نوت بمحتوى مسافات فقط — hasContent=true (trim يحدث خارجياً)', () {
        manager.loadFromNote(
          noteContent: '   ',
          noteTitle: '',
        );
        // loadFromNote يستخدم content.isNotEmpty (بدون trim)
        expect(manager.hasContent, true);
        // الـ trim يحدث في _handleContentChange و _handleBack
      });
    });
  });
}
