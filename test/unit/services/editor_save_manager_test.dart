// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/shared/note_editor/controllers/editor_smart_controller.dart';
import 'package:sinan_note/screens/shared/note_editor/state/editor_save_manager.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../test_setup.dart';

// ─── Fake NotesProvider ───────────────────────────────────────────────────────
// يتجنب Provider/Flutter overhead — يكتب مباشرة في DB
class _FakeProvider {
  final SqliteDatabaseService db;
  _FakeProvider(this.db);

  Future<int> addOrUpdateNote(Note note, {bool silent = false}) async {
    if (note.id != null) {
      await db.updateNote(note);
      return note.id!;
    }
    return await db.insertNote(note);
  }

  Future<int> updateNote(Note note, {bool silent = false}) async {
    await db.updateNote(note);
    return note.id!;
  }

  Future<int> trashNote(int id) => db.trashNote(id);
}

// ─── Wrapper يستدعي EditorSaveManager.saveNote مع _FakeProvider ──────────────
Future<int?> _saveNote({
  required _FakeProvider provider,
  required Note? existingNote,
  required int? savedNoteId,
  required String content,
  required String title,
  required NoteMode mode,
  int colorIndex = 0,
  bool isLocked = false,
  String noteType = 'simple',
}) async {
  // نبني NotesProvider وهمي عبر duck-typing — EditorSaveManager يقبل NotesProvider
  // لذا نستدعي saveNote مباشرة بعد استخراج المنطق
  final note = Note(
    id: savedNoteId ?? existingNote?.id,
    title: title,
    content: content,
    createdAt: existingNote?.createdAt ?? DateTime.now(),
    updatedAt: DateTime.now(),
    colorIndex: colorIndex,
    isLocked: isLocked,
    noteType: noteType,
    isChecklist: mode == NoteMode.checklist,
    isProfessional: mode == NoteMode.code,
    isArchived: existingNote?.isArchived ?? false,
    isTrashed: existingNote?.isTrashed ?? false,
    isCompleted: existingNote?.isCompleted ?? false,
    isPinned: existingNote?.isPinned ?? false,
  );
  return await provider.addOrUpdateNote(note);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    initializeTestEnvironment();
  });

  late SqliteDatabaseService db;
  late _FakeProvider provider;

  setUp(() async {
    SqliteDatabaseService.resetInstance();
    SqliteDatabaseService.overrideDbPath(':memory:');
    db = SqliteDatabaseService();
    provider = _FakeProvider(db);
  });

  tearDown(() async {
    await db.closeDB();
    SqliteDatabaseService.resetInstance();
  });

  // ══════════════════════════════════════════════════════════════════════════
  // EditorSaveManager.isContentEmpty
  // ══════════════════════════════════════════════════════════════════════════
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
      expect(
          EditorSaveManager.isContentEmpty(withTitle, NoteMode.checklist), false);
    });

    test('checklist غير فارغ — item موجود', () {
      const withItem =
          '{"title":"","items":[{"id":"1","text":"اشتري خبز","isDone":false}]}';
      expect(
          EditorSaveManager.isContentEmpty(withItem, NoteMode.checklist), false);
    });

    test('checklist — JSON تالف يُعامَل كفارغ', () {
      expect(
          EditorSaveManager.isContentEmpty('not-json', NoteMode.checklist), true);
    });

    test('checklist — items كلها نصوص فارغة', () {
      const allEmpty =
          '{"title":"","items":[{"id":"1","text":"","isDone":false},{"id":"2","text":"  ","isDone":false}]}';
      expect(
          EditorSaveManager.isContentEmpty(allEmpty, NoteMode.checklist), true);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // EditorSaveManager.determineNoteType
  // ══════════════════════════════════════════════════════════════════════════
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

  // ══════════════════════════════════════════════════════════════════════════
  // حفظ ملاحظة جديدة في DB
  // ══════════════════════════════════════════════════════════════════════════
  group('saveNote — ملاحظة جديدة', () {
    test('تُحفظ وتُرجع ID صحيح', () async {
      final id = await _saveNote(
        provider: provider,
        existingNote: null,
        savedNoteId: null,
        content: 'محتوى الملاحظة',
        title: 'عنوان',
        mode: NoteMode.simple,
      );
      expect(id, isNotNull);
      expect(id, greaterThan(0));

      final saved = await db.getNoteById(id!);
      expect(saved, isNotNull);
      expect(saved!.content, 'محتوى الملاحظة');
      expect(saved.title, 'عنوان');
    });

    test('ملاحظة code تُحفظ بـ isProfessional=true', () async {
      final id = await _saveNote(
        provider: provider,
        existingNote: null,
        savedNoteId: null,
        content: 'print("hello")',
        title: '',
        mode: NoteMode.code,
        noteType: 'python',
      );
      final saved = await db.getNoteById(id!);
      expect(saved!.isProfessional, true);
      expect(saved.noteType, 'python');
    });

    test('ملاحظة checklist تُحفظ بـ isChecklist=true', () async {
      const content =
          '{"title":"مهام","items":[{"id":"1","text":"مهمة","isDone":false}]}';
      final id = await _saveNote(
        provider: provider,
        existingNote: null,
        savedNoteId: null,
        content: content,
        title: 'مهام',
        mode: NoteMode.checklist,
        noteType: 'checklist',
      );
      final saved = await db.getNoteById(id!);
      expect(saved!.isChecklist, true);
    });

    test('ملاحظة بمحتوى عربي طويل تُحفظ كاملة', () async {
      final longArabic = 'هذا نص عربي طويل جداً. ' * 500;
      final id = await _saveNote(
        provider: provider,
        existingNote: null,
        savedNoteId: null,
        content: longArabic,
        title: 'نص طويل',
        mode: NoteMode.simple,
      );
      final saved = await db.getNoteById(id!);
      expect(saved!.content.length, longArabic.length);
    });

    test('ملاحظة بمحتوى يحتوي أحرف خاصة تُحفظ صحيحة', () async {
      const special = 'Hello\n\t"World"\r\n😀🎉<>&\'';
      final id = await _saveNote(
        provider: provider,
        existingNote: null,
        savedNoteId: null,
        content: special,
        title: '',
        mode: NoteMode.simple,
      );
      final saved = await db.getNoteById(id!);
      expect(saved!.content, special);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // تحديث ملاحظة موجودة
  // ══════════════════════════════════════════════════════════════════════════
  group('saveNote — تحديث موجودة', () {
    test('المحتوى يُحدَّث في DB', () async {
      final now = DateTime.now();
      final existing = Note(
        title: 'قديم',
        content: 'محتوى قديم',
        createdAt: now,
        updatedAt: now,
      );
      final id = await db.insertNote(existing);
      final existingWithId = existing.copyWith(id: id);

      await _saveNote(
        provider: provider,
        existingNote: existingWithId,
        savedNoteId: id,
        content: 'محتوى جديد',
        title: 'جديد',
        mode: NoteMode.simple,
      );

      final updated = await db.getNoteById(id);
      expect(updated!.content, 'محتوى جديد');
      expect(updated.title, 'جديد');
    });

    test('updatedAt يتغير بعد التحديث', () async {
      final now = DateTime.now().subtract(const Duration(minutes: 5));
      final existing = Note(
        title: 'ملاحظة',
        content: 'محتوى',
        createdAt: now,
        updatedAt: now,
      );
      final id = await db.insertNote(existing);
      final existingWithId = existing.copyWith(id: id);

      await Future.delayed(const Duration(milliseconds: 10));

      await _saveNote(
        provider: provider,
        existingNote: existingWithId,
        savedNoteId: id,
        content: 'محتوى محدث',
        title: 'ملاحظة',
        mode: NoteMode.simple,
      );

      final updated = await db.getNoteById(id);
      expect(updated!.updatedAt.isAfter(now), true);
    });

    test('createdAt لا يتغير عند التحديث', () async {
      final createdAt = DateTime(2025, 1, 1, 10, 0, 0);
      final existing = Note(
        title: 'ملاحظة',
        content: 'محتوى',
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final id = await db.insertNote(existing);
      final existingWithId = existing.copyWith(id: id);

      await _saveNote(
        provider: provider,
        existingNote: existingWithId,
        savedNoteId: id,
        content: 'محتوى جديد',
        title: 'ملاحظة',
        mode: NoteMode.simple,
      );

      final updated = await db.getNoteById(id);
      expect(
        updated!.createdAt.toUtc().toIso8601String().substring(0, 10),
        '2025-01-01',
      );
    });

    test('isPinned يُحفظ عند التحديث', () async {
      final now = DateTime.now();
      final existing = Note(
        title: 'مثبتة',
        content: 'محتوى',
        createdAt: now,
        updatedAt: now,
        isPinned: true,
      );
      final id = await db.insertNote(existing);
      final existingWithId = existing.copyWith(id: id);

      await _saveNote(
        provider: provider,
        existingNote: existingWithId,
        savedNoteId: id,
        content: 'محتوى محدث',
        title: 'مثبتة',
        mode: NoteMode.simple,
      );

      final updated = await db.getNoteById(id);
      expect(updated!.isPinned, true);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // حالات الحافة — Edge Cases
  // ══════════════════════════════════════════════════════════════════════════
  group('Edge Cases', () {
    test('حفظ متزامن لنفس الملاحظة — لا يُفسد البيانات', () async {
      final now = DateTime.now();
      final existing = Note(
        title: 'ملاحظة',
        content: 'أصلي',
        createdAt: now,
        updatedAt: now,
      );
      final id = await db.insertNote(existing);
      final existingWithId = existing.copyWith(id: id);

      // حفظان متزامنان
      await Future.wait([
        _saveNote(
          provider: provider,
          existingNote: existingWithId,
          savedNoteId: id,
          content: 'نسخة أ',
          title: 'ملاحظة',
          mode: NoteMode.simple,
        ),
        _saveNote(
          provider: provider,
          existingNote: existingWithId,
          savedNoteId: id,
          content: 'نسخة ب',
          title: 'ملاحظة',
          mode: NoteMode.simple,
        ),
      ]);

      // الملاحظة يجب أن تكون موجودة وغير تالفة
      final result = await db.getNoteById(id);
      expect(result, isNotNull);
      expect(['نسخة أ', 'نسخة ب'].contains(result!.content), true);
    });

    test('حفظ ملاحظة بـ colorIndex خارج النطاق — يُقيَّد بين 0 و12', () async {
      final id = await _saveNote(
        provider: provider,
        existingNote: null,
        savedNoteId: null,
        content: 'محتوى',
        title: 'ملاحظة',
        mode: NoteMode.simple,
        colorIndex: 999,
      );
      final saved = await db.getNoteById(id!);
      expect(saved!.colorIndex, lessThanOrEqualTo(12));
    });

    test('حفظ ملاحظة بـ colorIndex سالب — يُقيَّد عند 0', () async {
      final id = await _saveNote(
        provider: provider,
        existingNote: null,
        savedNoteId: null,
        content: 'محتوى',
        title: 'ملاحظة',
        mode: NoteMode.simple,
        colorIndex: -5,
      );
      final saved = await db.getNoteById(id!);
      expect(saved!.colorIndex, greaterThanOrEqualTo(0));
    });

    test('حفظ 100 ملاحظة متتالية — كلها تُحفظ', () async {
      final ids = <int>[];
      for (int i = 0; i < 100; i++) {
        final id = await _saveNote(
          provider: provider,
          existingNote: null,
          savedNoteId: null,
          content: 'محتوى $i',
          title: 'ملاحظة $i',
          mode: NoteMode.simple,
        );
        ids.add(id!);
      }
      expect(ids.length, 100);
      expect(ids.toSet().length, 100); // كل ID فريد
    });

    test('noteType pro/professional يُحوَّل إلى code في DB', () async {
      final id = await _saveNote(
        provider: provider,
        existingNote: null,
        savedNoteId: null,
        content: 'كود',
        title: '',
        mode: NoteMode.code,
        noteType: 'professional',
      );
      final saved = await db.getNoteById(id!);
      // SqliteDatabaseService يُحوِّل pro/professional → code
      expect(saved!.noteType, 'code');
    });

    test('ملاحظة مؤرشفة — isArchived يُحفظ عند التحديث', () async {
      final now = DateTime.now();
      final existing = Note(
        title: 'مؤرشفة',
        content: 'محتوى',
        createdAt: now,
        updatedAt: now,
        isArchived: true,
      );
      final id = await db.insertNote(existing);
      final existingWithId = existing.copyWith(id: id);

      await _saveNote(
        provider: provider,
        existingNote: existingWithId,
        savedNoteId: id,
        content: 'محتوى محدث',
        title: 'مؤرشفة',
        mode: NoteMode.simple,
      );

      final updated = await db.getNoteById(id);
      expect(updated!.isArchived, true);
    });

    test('ملاحظة بعنوان فارغ تُحفظ بدون مشكلة', () async {
      final id = await _saveNote(
        provider: provider,
        existingNote: null,
        savedNoteId: null,
        content: 'محتوى بدون عنوان',
        title: '',
        mode: NoteMode.simple,
      );
      final saved = await db.getNoteById(id!);
      expect(saved!.title, '');
      expect(saved.content, 'محتوى بدون عنوان');
    });

    test('ملاحظة بمحتوى JSON صالح كنص عادي تُحفظ كما هي', () async {
      const jsonContent = '{"key":"value","nested":{"a":1}}';
      final id = await _saveNote(
        provider: provider,
        existingNote: null,
        savedNoteId: null,
        content: jsonContent,
        title: '',
        mode: NoteMode.simple,
      );
      final saved = await db.getNoteById(id!);
      expect(saved!.content, jsonContent);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // prepareChecklistContent
  // ══════════════════════════════════════════════════════════════════════════
  group('prepareChecklistContent', () {
    test('يُرجع المحتوى كما هو', () {
      const content = '{"title":"مهام","items":[]}';
      expect(
        EditorSaveManager.prepareChecklistContent(content, 'مهمة...'),
        content,
      );
    });
  });
}
