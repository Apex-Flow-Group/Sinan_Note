// Copyright © 2025 Apex Flow Group. All rights reserved.
//
// اختبار شامل لسيناريو إرسال واستقبال ملف .sinan عبر Apex Share
// يحاكي: إنشاء ملف → إرسال → استقبال → فتح الملاحظة

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/intent_handler_service.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() => initializeTestEnvironment());

  group('Apex Share — Send & Receive Flow', () {
    late IntentHandlerService intentService;
    late Directory tempDir;

    setUp(() {
      intentService = const IntentHandlerService();
      tempDir = Directory.systemTemp.createTempSync('apex_share_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    // ══════════════════════════════════════════════════════════════════════
    // السيناريو 1: إرسال ملاحظة بسيطة (simple) واستقبالها
    // ══════════════════════════════════════════════════════════════════════

    test('Simple note: send → receive → identical content & type', () async {
      // الملاحظة الأصلية كما هي في الداتابيز (content = Delta JSON)
      final originalNote = Note(
        id: 42,
        title: 'ملاحظة تجريبية',
        content: '[{"insert":"مرحبا بالعالم\\nسطر ثاني\\n"}]',
        createdAt: DateTime(2026, 7, 20, 10, 0),
        updatedAt: DateTime(2026, 7, 20, 10, 5),
        colorIndex: 3,
        noteType: 'simple',
        isPinned: true,
        categoryIds: [1, 5],
      );

      // ═══ جهة الإرسال: _sendViaApex يستخدم note.toMap() ═══
      final sinanFileContent = jsonEncode(originalNote.toMap());

      // تحقق أن الملف يحتوي كل الحقول
      final sentJson = jsonDecode(sinanFileContent) as Map<String, dynamic>;
      expect(sentJson['title'], equals('ملاحظة تجريبية'));
      expect(sentJson['content'],
          equals('[{"insert":"مرحبا بالعالم\\nسطر ثاني\\n"}]'));
      expect(sentJson['noteType'], equals('simple'));
      expect(sentJson['colorIndex'], equals(3));
      expect(sentJson['isPinned'], equals(1));
      expect(sentJson['categoryIds'], equals('1,5'));
      expect(sentJson['updatedAt'], isNotNull);

      // ═══ جهة الاستقبال: parseSinanFile ═══
      final filePath = '${tempDir.path}/test_note.sinan';
      await File(filePath).writeAsString(sinanFileContent);

      final receivedNote = await intentService.parseSinanFile(filePath);

      expect(receivedNote, isNotNull);
      expect(receivedNote!.title, equals('ملاحظة تجريبية'));
      expect(receivedNote.content,
          equals('[{"insert":"مرحبا بالعالم\\nسطر ثاني\\n"}]'));
      expect(receivedNote.noteType, equals('simple'));
      expect(receivedNote.colorIndex, equals(3));
      expect(receivedNote.isPinned, isTrue);
      expect(receivedNote.categoryIds, equals([1, 5]));
      // id يجب أن يكون null (ملاحظة جديدة)
      expect(receivedNote.id, isNull);
    });

    // ══════════════════════════════════════════════════════════════════════
    // السيناريو 2: إرسال Checklist واستقبالها
    // ══════════════════════════════════════════════════════════════════════

    test('Checklist note: send → receive → preserves checklist format',
        () async {
      final checklistNote = Note(
        id: 100,
        title: 'قائمة مهام',
        content:
            '{"items":[{"text":"مهمة 1","checked":true},{"text":"مهمة 2","checked":false}]}',
        createdAt: DateTime(2026, 7, 20),
        updatedAt: DateTime(2026, 7, 20),
        colorIndex: 5,
        noteType: 'checklist',
        isChecklist: true,
      );

      final sinanFileContent = jsonEncode(checklistNote.toMap());
      final filePath = '${tempDir.path}/checklist.sinan';
      await File(filePath).writeAsString(sinanFileContent);

      final received = await intentService.parseSinanFile(filePath);

      expect(received, isNotNull);
      expect(received!.noteType, equals('checklist'));
      expect(received.isChecklist, isTrue);
      expect(received.content, contains('"items"'));
      expect(received.content, contains('"مهمة 1"'));
      expect(received.content, contains('"checked":true'));
    });

    // ══════════════════════════════════════════════════════════════════════
    // السيناريو 3: إرسال Code note واستقبالها
    // ══════════════════════════════════════════════════════════════════════

    test('Code note: send → receive → preserves code content & type', () async {
      final codeNote = Note(
        id: 200,
        title: 'main.dart',
        content: 'void main() {\n  print("Hello");\n}',
        createdAt: DateTime(2026, 7, 20),
        updatedAt: DateTime(2026, 7, 20),
        colorIndex: 0,
        noteType: 'code',
        isProfessional: true,
      );

      final sinanFileContent = jsonEncode(codeNote.toMap());
      final filePath = '${tempDir.path}/code.sinan';
      await File(filePath).writeAsString(sinanFileContent);

      final received = await intentService.parseSinanFile(filePath);

      expect(received, isNotNull);
      expect(received!.noteType, equals('code'));
      expect(received.isProfessional, isTrue);
      expect(received.content, contains('void main()'));
      expect(received.content, contains('print("Hello")'));
    });

    // ══════════════════════════════════════════════════════════════════════
    // السيناريو 4: استقبال ملف .sinan بصيغة قديمة (بدون updatedAt)
    // ══════════════════════════════════════════════════════════════════════

    test('Legacy format (no updatedAt): still works', () async {
      final legacyJson = jsonEncode({
        'title': 'ملاحظة قديمة',
        'content': 'نص عادي بدون Delta',
        'noteType': 'simple',
        'colorIndex': 2,
        'createdAt': '2026-07-01T10:00:00.000Z',
      });

      final filePath = '${tempDir.path}/legacy.sinan';
      await File(filePath).writeAsString(legacyJson);

      final received = await intentService.parseSinanFile(filePath);

      expect(received, isNotNull);
      expect(received!.title, equals('ملاحظة قديمة'));
      expect(received.content, equals('نص عادي بدون Delta'));
      expect(received.noteType, equals('simple'));
      expect(received.colorIndex, equals(2));
    });

    // ══════════════════════════════════════════════════════════════════════
    // السيناريو 5: استقبال عبر shared_text (JSON يحتوي title+content)
    // محاكاة: الملف يُمرر كـ shared_text بدل file_path
    // ══════════════════════════════════════════════════════════════════════

    test('Shared text that is actually .sinan JSON → detected correctly', () {
      final sinanJson = jsonEncode({
        'title': 'نص مشارك',
        'content': '[{"insert":"محتوى\\n"}]',
        'noteType': 'simple',
        'colorIndex': 8,
        'updatedAt': '2026-07-20T14:15:08.164Z',
        'createdAt': '2026-07-20T14:15:08.164Z',
      });

      // كشف: هل هذا JSON يحتوي title + content؟
      final isSinanFile = _isSinanJson(sinanJson);
      expect(isSinanFile, isTrue);

      // التحقق أنه لو مرّ على cleanSharedText سابقاً (الخطأ القديم)
      // كان سيُحفظ ملوث
      final oldBehavior = intentService.cleanSharedText(sinanJson);
      // cleanSharedText يجب أن لا يُستخدم لهذا — لكن نتأكد أنه ما يكسر
      expect(oldBehavior['text'], isNotEmpty);
    });

    // ══════════════════════════════════════════════════════════════════════
    // السيناريو 6: نص مشارك عادي (ليس .sinan) — لا يُعامل كملف
    // ══════════════════════════════════════════════════════════════════════

    test('Regular shared text is NOT mistaken for .sinan file', () {
      const regularText = 'مرحبا هذا نص عادي من تطبيق آخر';
      expect(_isSinanJson(regularText), isFalse);

      const jsonButNotSinan = '{"key": "value", "data": 123}';
      expect(_isSinanJson(jsonButNotSinan), isFalse);

      const urlText = 'Check this https://example.com/page';
      expect(_isSinanJson(urlText), isFalse);
    });

    // ══════════════════════════════════════════════════════════════════════
    // السيناريو 7: cleanSharedText مع Delta JSON من تطبيق خارجي
    // ══════════════════════════════════════════════════════════════════════

    test('cleanSharedText extracts plain text from Delta JSON', () {
      const deltaJson = '[{"insert":"نص من تطبيق\\nسطر ثاني\\n"}]';
      final result = intentService.cleanSharedText(deltaJson);
      expect(result['text'], equals('نص من تطبيق\nسطر ثاني'));
      expect(result['text'], isNot(contains('insert')));
      expect(result['text'], isNot(contains('{')));
    });

    // ══════════════════════════════════════════════════════════════════════
    // السيناريو 8: cleanSharedText ينظف أحرف غير مرئية
    // ══════════════════════════════════════════════════════════════════════

    test('cleanSharedText removes invisible Unicode characters', () {
      const dirtyText = 'مرحبا\u200Bعالم\u200D \uFEFFنص\u00AD';
      final result = intentService.cleanSharedText(dirtyText);
      // بعد إزالة الأحرف غير المرئية: "مرحباعالم نص" (مسافة واحدة)
      expect(result['text'], equals('مرحباعالم نص'));
      expect(result['text'], isNot(contains('\u200B')));
      expect(result['text'], isNot(contains('\uFEFF')));
    });

    // ══════════════════════════════════════════════════════════════════════
    // السيناريو 9: Round-trip — نسخة طبق الأصل
    // ══════════════════════════════════════════════════════════════════════

    test('Full round-trip: toMap → file → parseSinanFile → identical Note',
        () async {
      final original = Note(
        id: 999,
        title: 'Round Trip Test',
        content: '[{"insert":"Hello World\\n","attributes":{"bold":true}}]',
        createdAt: DateTime(2026, 1, 15, 8, 30),
        updatedAt: DateTime(2026, 7, 20, 14, 0),
        colorIndex: 7,
        noteType: 'simple',
        isPinned: true,
        isArchived: false,
        isLocked: true,
        categoryIds: [2, 3, 9],
        isHiddenFromHome: true,
      );

      // Send
      final fileContent = jsonEncode(original.toMap());
      final filePath = '${tempDir.path}/roundtrip.sinan';
      await File(filePath).writeAsString(fileContent);

      // Receive
      final received = await intentService.parseSinanFile(filePath);

      expect(received, isNotNull);
      // كل الحقول مطابقة (ما عدا id والتواريخ)
      expect(received!.title, equals(original.title));
      expect(received.content, equals(original.content));
      expect(received.colorIndex, equals(original.colorIndex));
      expect(received.noteType, equals(original.noteType));
      expect(received.isPinned, equals(original.isPinned));
      expect(received.isLocked, equals(original.isLocked));
      expect(received.categoryIds, equals(original.categoryIds));
      expect(received.isHiddenFromHome, equals(original.isHiddenFromHome));
      expect(received.isArchived, equals(original.isArchived));
      // id يكون null (ملاحظة جديدة)
      expect(received.id, isNull);
    });
  });
}

/// محاكاة الكشف اللي يحصل في main.dart → _openEditorWithSharedText
bool _isSinanJson(String text) {
  if (!text.trimLeft().startsWith('{')) return false;
  try {
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    return decoded.containsKey('content') && decoded.containsKey('title');
  } catch (_) {
    return false;
  }
}
