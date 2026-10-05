// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/domain/models/note_mode.dart';
import 'package:sinan_note/screens/shared/note_editor/controllers/editor_smart_controller.dart';
import 'package:sinan_note/screens/shared/note_editor/state/editor_save_manager.dart';

void main() {
  group('isContentEmpty', () {
    test('فارغ لنص عادي', () {
      expect(EditorSaveManager.isContentEmpty('', NoteMode.simple), true);
      expect(EditorSaveManager.isContentEmpty('   ', NoteMode.simple), true);
    });

    test('غير فارغ لنص عادي', () {
      expect(EditorSaveManager.isContentEmpty('hello', NoteMode.simple), false);
    });

    test('checklist فارغ — title وitems فارغة', () {
      const empty = '{"title":"","items":[]}';
      expect(EditorSaveManager.isContentEmpty(empty, NoteMode.checklist), true);
    });

    test('checklist غير فارغ — title موجود', () {
      const withTitle = '{"title":"مهام","items":[]}';
      expect(EditorSaveManager.isContentEmpty(withTitle, NoteMode.checklist),
          false);
    });

    test('checklist غير فارغ — item موجود', () {
      const withItem =
          '{"title":"","items":[{"id":"1","text":"اشتري خبز","isDone":false}]}';
      expect(EditorSaveManager.isContentEmpty(withItem, NoteMode.checklist),
          false);
    });

    test('checklist — JSON تالف يُعامَل كفارغ', () {
      expect(EditorSaveManager.isContentEmpty('not-json', NoteMode.checklist),
          true);
    });

    test('checklist — items كلها نصوص فارغة', () {
      const allEmpty =
          '{"title":"","items":[{"id":"1","text":"","isDone":false},{"id":"2","text":"  ","isDone":false}]}';
      expect(
          EditorSaveManager.isContentEmpty(allEmpty, NoteMode.checklist), true);
    });
  });

  group('determineNoteType', () {
    final smart = EditorSmartController();

    test('checklist دائماً يُرجع checklist', () {
      expect(
        EditorSaveManager.determineNoteType(
          mode: NoteMode.checklist,
          detectedLanguage: 'Python',
          isLanguageManuallySelected: true,
          existingNoteType: 'simple',
          smartController: smart,
        ),
        'checklist',
      );
    });

    test('لغة مكتشفة تُحدد النوع', () {
      final type = EditorSaveManager.determineNoteType(
        mode: NoteMode.code,
        detectedLanguage: 'Python',
        isLanguageManuallySelected: false,
        existingNoteType: null,
        smartController: smart,
      );
      expect(type, 'python');
    });

    test('نوع موجود غير generic يُحفظ في وضع code', () {
      final type = EditorSaveManager.determineNoteType(
        mode: NoteMode.code,
        detectedLanguage: null,
        isLanguageManuallySelected: false,
        existingNoteType: 'dart',
        smartController: smart,
      );
      expect(type, 'dart');
    });

    test('نوع generic يُستبدل بـ mode.name', () {
      for (final generic in ['code', 'pro', 'professional']) {
        final type = EditorSaveManager.determineNoteType(
          mode: NoteMode.code,
          detectedLanguage: null,
          isLanguageManuallySelected: false,
          existingNoteType: generic,
          smartController: smart,
        );
        expect(type, NoteMode.code.name,
            reason: 'generic "$generic" يجب أن يُرجع mode.name');
      }
    });

    test('بدون لغة ونوع — يُرجع mode.name', () {
      final type = EditorSaveManager.determineNoteType(
        mode: NoteMode.simple,
        detectedLanguage: null,
        isLanguageManuallySelected: false,
        existingNoteType: null,
        smartController: smart,
      );
      expect(type, 'simple');
    });
  });
}
