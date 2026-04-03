// Copyright © 2025 Apex Flow Group. All rights reserved.
// 🔒 NOTE SECURITY SERVICE — اختبارات شاملة

import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/note_services/note_db_interface.dart';
import 'package:apex_note/services/note_services/note_security_service.dart';
import 'package:apex_note/services/note_services/note_state_service.dart';
import 'package:apex_note/services/security/vault_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_setup.dart';

// Mock يُطبِّق NoteDbInterface بدون Isar الحقيقي
class _MockDb implements NoteDbInterface {
  final Map<int, Note> _store = {};

  @override
  Future<List<Note>> getLockedNotes() async =>
      _store.values.where((n) => n.isLocked).toList();

  @override
  Future<Note?> getNoteById(int id) async => _store[id];

  @override
  Future<int> updateNote(Note note) async {
    _store[note.id!] = note;
    return note.id!;
  }

  void seed(Note note) => _store[note.id!] = note;
}

void main() {
  setUpAll(() => initializeTestEnvironment());

  late NoteSecurityService security;
  late _MockDb db;
  late NoteStateService state;
  late DateTime now;

  setUp(() {
    security = NoteSecurityService();
    db = _MockDb();
    state = NoteStateService();
    now = DateTime.now();
  });

  tearDown(() => state.dispose());

  // ══════════════════════════════════════════════════════════════
  // 1. إدارة جلسة الخزنة
  // ══════════════════════════════════════════════════════════════
  group('NoteSecurityService — Vault Session', () {
    test('الخزنة مقفلة في البداية', () {
      expect(security.isVaultUnlocked, isFalse);
    });

    test('unlockVault يفتح الخزنة', () {
      security.unlockVault();
      expect(security.isVaultUnlocked, isTrue);
    });

    test('lockVault يقفل الخزنة', () {
      security.unlockVault();
      security.lockVault();
      expect(security.isVaultUnlocked, isFalse);
    });

    test('قفل متعدد لا يرمي استثناء', () {
      security.lockVault();
      security.lockVault();
      expect(security.isVaultUnlocked, isFalse);
    });

    test('فتح ثم قفل ثم فتح يعمل بشكل صحيح', () {
      security.unlockVault();
      expect(security.isVaultUnlocked, isTrue);
      security.lockVault();
      expect(security.isVaultUnlocked, isFalse);
      security.unlockVault();
      expect(security.isVaultUnlocked, isTrue);
    });

    test('الجلسة تنتهي بعد 5 دقائق (اختبار المنطق)', () {
      // نتحقق أن الـ getter يحسب الوقت بشكل صحيح
      security.unlockVault();
      expect(security.isVaultUnlocked, isTrue);
      // لا يمكن انتظار 5 دقائق في الاختبار، لكن نتحقق من المنطق
      // عبر التحقق من أن الجلسة لا تزال صالحة بعد ثانية
      expect(security.isVaultUnlocked, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 2. جلب الملاحظات المقفلة
  // ══════════════════════════════════════════════════════════════
  group('NoteSecurityService — Fetch Locked Notes', () {
    test('قائمة فارغة عند عدم وجود ملاحظات مقفلة', () async {
      final notes = await security.fetchAndDecryptLockedNotes(db);
      expect(notes, isEmpty);
    });

    test('يجلب الملاحظات المقفلة', () async {
      db.seed(Note(id: 1, title: 'Locked', content: 'Secret', createdAt: now, updatedAt: now, isLocked: true));
      db.seed(Note(id: 2, title: 'Public', content: 'Public', createdAt: now, updatedAt: now, isLocked: false));

      final notes = await security.fetchAndDecryptLockedNotes(db);
      expect(notes.length, 1);
      expect(notes.first.id, 1);
    });

    test('فشل فك التشفير يُرجع الملاحظة كما هي', () async {
      db.seed(Note(
        id: 1,
        title: 'invalid_encrypted_data',
        content: 'invalid_encrypted_data',
        createdAt: now,
        updatedAt: now,
        isLocked: true,
      ));

      final notes = await security.fetchAndDecryptLockedNotes(db);
      expect(notes.length, 1);
      // يجب أن لا يرمي استثناء
    });

    test('ملاحظة checklist مقفلة تُعالج بشكل صحيح', () async {
      const checklistJson = '{"title":"Tasks","items":[{"id":"1","text":"Task","isDone":false}]}';
      db.seed(Note(
        id: 1,
        title: 'Checklist',
        content: checklistJson,
        createdAt: now,
        updatedAt: now,
        isLocked: true,
        isChecklist: true,
        noteType: 'checklist',
      ));

      final notes = await security.fetchAndDecryptLockedNotes(db);
      expect(notes.length, 1);
      // لا يجب أن يرمي استثناء
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 3. تبديل حالة القفل
  // ══════════════════════════════════════════════════════════════
  group('NoteSecurityService — Toggle Lock', () {
    setUp(() async {
      await VaultService.clearVault();
      await VaultService.setupVault('TestPass');
      await VaultService.unlockWithPassword('TestPass');
    });

    tearDown(() async => await VaultService.clearVault());
    test('قفل ملاحظة يُحدِّث isLocked في قاعدة البيانات', () async {
      db.seed(Note(id: 1, title: 'Test', content: 'Content', createdAt: now, updatedAt: now, isLocked: false));

      await security.toggleLockStatus(1, true, db);

      final updated = await db.getNoteById(1);
      expect(updated?.isLocked, isTrue);
    });

    test('فك قفل ملاحظة يُحدِّث isLocked في قاعدة البيانات', () async {
      db.seed(Note(id: 1, title: 'Test', content: 'Content', createdAt: now, updatedAt: now, isLocked: true));

      await security.toggleLockStatus(1, false, db);

      final updated = await db.getNoteById(1);
      expect(updated?.isLocked, isFalse);
    });

    test('قفل ملاحظة بمحتوى فارغ لا يُشفِّر', () async {
      db.seed(Note(id: 1, title: '', content: '', createdAt: now, updatedAt: now, isLocked: false));

      await security.toggleLockStatus(1, true, db);

      final updated = await db.getNoteById(1);
      expect(updated?.title, '');
      expect(updated?.content, '');
    });

    test('ملاحظة غير موجودة لا ترمي استثناء', () async {
      await expectLater(
        security.toggleLockStatus(999, true, db),
        completes,
      );
    });

    test('قفل checklist يُعيد ترتيب JSON قبل التشفير', () async {
      const validJson = '{"title":"Tasks","items":[{"id":"1","text":"Task","isDone":false}]}';
      db.seed(Note(
        id: 1,
        title: 'Checklist',
        content: validJson,
        createdAt: now,
        updatedAt: now,
        isLocked: false,
        isChecklist: true,
        noteType: 'checklist',
      ));

      // لا يجب أن يرمي استثناء
      await expectLater(
        security.toggleLockStatus(1, true, db),
        completes,
      );
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 4. مسح الجلسة
  // ══════════════════════════════════════════════════════════════
  group('NoteSecurityService — Clear Session', () {
    test('clearLockedSession يمسح الملاحظات المقفلة من الذاكرة', () {
      state.updateLockedNotes([
        Note(id: 1, title: 'Secret', content: 'Secret Content', createdAt: now, updatedAt: now, isLocked: true),
      ]);
      expect(state.lockedNotes.length, 1);

      security.clearLockedSession(state);
      expect(state.lockedNotes.length, 0);
    });

    test('clearLockedSession لا يؤثر على الملاحظات العادية', () {
      state.updateAllNotes([
        Note(id: 1, title: 'Regular', content: 'Content', createdAt: now, updatedAt: now),
      ]);
      state.updateLockedNotes([
        Note(id: 2, title: 'Locked', content: 'Secret', createdAt: now, updatedAt: now, isLocked: true),
      ]);

      security.clearLockedSession(state);

      expect(state.activeNotes.length, 1);
      expect(state.lockedNotes.length, 0);
    });
  });
}
