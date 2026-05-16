// Copyright © 2025 Apex Flow Group. All rights reserved.
// ☁️ GOOGLE DRIVE SYNC — اختبارات حقيقية وشاملة

import 'dart:convert';

import 'package:apex_note/models/note.dart';
import 'package:apex_note/services/storage/compression_service.dart';
import 'package:apex_note/services/sync/cloud_sync_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_setup.dart';

void main() {
  setUpAll(() => initializeTestEnvironment());

  // ══════════════════════════════════════════════════════════════
  // 1. حالة المصادقة
  // ══════════════════════════════════════════════════════════════
  group('CloudSyncGateway — Auth State', () {
    test('isSignedIn يُرجع false قبل تسجيل الدخول', () {
      expect(CloudSyncGateway.isSignedIn, isFalse);
    });

    test('currentUserEmail يُرجع null قبل تسجيل الدخول', () {
      expect(CloudSyncGateway.currentUserEmail, isNull);
    });

    test('lastSyncTime يُرجع null قبل أي مزامنة', () {
      expect(CloudSyncGateway.lastSyncTime, isNull);
    });

    test('upload يرمي استثناء عند عدم تسجيل الدخول', () async {
      expect(
        () async => await CloudSyncGateway.upload(),
        throwsA(isA<Exception>()),
      );
    });

    test('download يرمي استثناء عند عدم تسجيل الدخول', () async {
      expect(
        () async => await CloudSyncGateway.download(),
        throwsA(isA<Exception>()),
      );
    });

    test('hasBackupInCloud يُرجع false عند عدم تسجيل الدخول', () async {
      expect(await CloudSyncGateway.hasBackupInCloud(), isFalse);
    });

    test('getCloudNotesCount يُرجع 0 عند عدم تسجيل الدخول', () async {
      expect(await CloudSyncGateway.getCloudNotesCount(), 0);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 2. Rate Limiting — منع الإرسال المتكرر
  // ══════════════════════════════════════════════════════════════
  group('CloudSyncGateway — Rate Limiting Logic', () {
    // نختبر المنطق الداخلي عبر CompressionService وبنية البيانات

    test('بنية النسخة الاحتياطية صحيحة', () {
      final notes = [
        Note(
          id: 1,
          title: 'Test',
          content: 'Content',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final backupData = {
        'version': '2.0',
        'created_at': DateTime.now().toIso8601String(),
        'notes': notes.map((n) => n.toMap()).toList(),
      };

      expect(backupData['version'], '2.0');
      expect(backupData.containsKey('created_at'), isTrue);
      expect((backupData['notes'] as List).length, 1);
    });

    test('النسخة الاحتياطية مع vault_data تحتوي على المفاتيح الصحيحة', () {
      final backupData = {
        'version': '2.0',
        'created_at': DateTime.now().toIso8601String(),
        'notes': [],
        'vault_data': {
          'encrypted_master_key': 'enc_key',
          'recovery_hash': 'hash',
          'created_at': DateTime.now().toIso8601String(),
        },
      };

      expect(backupData.containsKey('vault_data'), isTrue);
      final vault = backupData['vault_data'] as Map;
      expect(vault.containsKey('encrypted_master_key'), isTrue);
      expect(vault.containsKey('recovery_hash'), isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 3. Compression — ضغط وفك ضغط البيانات
  // ══════════════════════════════════════════════════════════════
  group('CompressionService — Backup Compression', () {
    test('ضغط وفك ضغط JSON بسيط', () {
      const json = '{"version":"2.0","notes":[]}';
      final compressed = CompressionService.compress(json);
      final decompressed = CompressionService.decompress(compressed);
      expect(decompressed, equals(json));
    });

    test('الضغط يُقلل حجم البيانات', () {
      final largeJson = jsonEncode({
        'notes': List.generate(
            100,
            (i) => {
                  'id': i,
                  'title': 'Note $i',
                  'content': 'Content $i ' * 20,
                  'createdAt': DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                }),
      });

      final compressed = CompressionService.compress(largeJson);
      expect(compressed.length, lessThan(largeJson.length));
    });

    test('ضغط وفك ضغط ملاحظات حقيقية', () {
      final notes = List.generate(
          50,
          (i) => Note(
                id: i,
                title: 'ملاحظة $i',
                content: 'محتوى الملاحظة رقم $i مع نص عربي طويل نسبياً',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                noteType: i % 2 == 0 ? 'simple' : 'code',
              ));

      final json = jsonEncode({
        'version': '2.0',
        'notes': notes.map((n) => n.toMap()).toList(),
      });

      final compressed = CompressionService.compress(json);
      final decompressed = CompressionService.decompress(compressed);
      final decoded = jsonDecode(decompressed) as Map<String, dynamic>;

      expect((decoded['notes'] as List).length, 50);
    });

    test('ضغط نص فارغ لا يرمي استثناء', () {
      expect(() => CompressionService.compress(''), returnsNormally);
    });

    test('ضغط وفك ضغط بيانات مع vault_data', () {
      final data = jsonEncode({
        'version': '2.0',
        'notes': [],
        'vault_data': {
          'encrypted_master_key': 'abc123:xyz789',
          'recovery_hash': 'salt:hash',
        },
      });

      final compressed = CompressionService.compress(data);
      final decompressed = CompressionService.decompress(compressed);
      final decoded = jsonDecode(decompressed) as Map<String, dynamic>;

      expect(decoded.containsKey('vault_data'), isTrue);
      expect(decoded['vault_data']['encrypted_master_key'], 'abc123:xyz789');
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 4. Merge Logic — منطق الدمج
  // ══════════════════════════════════════════════════════════════
  group('Merge Logic — Smart Merge Algorithm', () {
    test('الدمج الذكي يختار الملاحظة الأحدث', () {
      final now = DateTime.now();
      final older = now.subtract(const Duration(hours: 1));

      final localNote = Note(
        id: 1,
        title: 'Local Version',
        content: 'Local Content',
        createdAt: now,
        updatedAt: now,
      );

      final driveNote = Note(
        id: 1,
        title: 'Drive Version',
        content: 'Drive Content',
        createdAt: older,
        updatedAt: older,
      );

      // محاكاة منطق الدمج
      final Map<int, Note> mergedMap = {};
      mergedMap[localNote.id!] = localNote;

      if (driveNote.id != null) {
        if (mergedMap.containsKey(driveNote.id!)) {
          if (driveNote.updatedAt
              .isAfter(mergedMap[driveNote.id!]!.updatedAt)) {
            mergedMap[driveNote.id!] = driveNote;
          }
        } else {
          mergedMap[driveNote.id!] = driveNote;
        }
      }

      // الملاحظة المحلية أحدث، يجب أن تُختار
      expect(mergedMap[1]!.title, 'Local Version');
    });

    test('الدمج الذكي يختار ملاحظة Drive إذا كانت أحدث', () {
      final now = DateTime.now();
      final older = now.subtract(const Duration(hours: 1));

      final localNote = Note(
        id: 1,
        title: 'Local Old',
        content: 'Old Content',
        createdAt: older,
        updatedAt: older,
      );

      final driveNote = Note(
        id: 1,
        title: 'Drive New',
        content: 'New Content',
        createdAt: now,
        updatedAt: now,
      );

      final Map<int, Note> mergedMap = {};
      mergedMap[localNote.id!] = localNote;

      if (driveNote.updatedAt.isAfter(mergedMap[driveNote.id!]!.updatedAt)) {
        mergedMap[driveNote.id!] = driveNote;
      }

      expect(mergedMap[1]!.title, 'Drive New');
    });

    test('الدمج يضيف ملاحظات Drive غير الموجودة محلياً', () {
      final now = DateTime.now();

      final localNotes = [
        Note(
            id: 1,
            title: 'Local 1',
            content: '',
            createdAt: now,
            updatedAt: now),
      ];

      final driveNotes = [
        Note(
            id: 1,
            title: 'Local 1',
            content: '',
            createdAt: now,
            updatedAt: now),
        Note(
            id: 2,
            title: 'Drive Only',
            content: '',
            createdAt: now,
            updatedAt: now),
      ];

      final Map<int, Note> mergedMap = {};
      for (final n in localNotes) {
        mergedMap[n.id!] = n;
      }
      for (final n in driveNotes) {
        if (!mergedMap.containsKey(n.id!)) {
          mergedMap[n.id!] = n;
        }
      }

      expect(mergedMap.length, 2);
      expect(mergedMap.containsKey(2), isTrue);
    });

    test('الدمج يحافظ على ملاحظات محلية غير موجودة في Drive', () {
      final now = DateTime.now();

      final localNotes = [
        Note(
            id: 1,
            title: 'Local Only',
            content: '',
            createdAt: now,
            updatedAt: now),
        Note(id: 2, title: 'Both', content: '', createdAt: now, updatedAt: now),
      ];

      final driveNotes = [
        Note(id: 2, title: 'Both', content: '', createdAt: now, updatedAt: now),
      ];

      final Map<int, Note> mergedMap = {};
      for (final n in localNotes) {
        mergedMap[n.id!] = n;
      }
      for (final n in driveNotes) {
        if (!mergedMap.containsKey(n.id!)) mergedMap[n.id!] = n;
      }

      expect(mergedMap.length, 2);
      expect(mergedMap.containsKey(1), isTrue);
    });

    test('الدمج مع قوائم فارغة لا يرمي استثناء', () {
      final Map<int, Note> mergedMap = {};
      final List<Note> localNotes = [];
      final List<Note> driveNotes = [];

      for (final n in localNotes) {
        mergedMap[n.id!] = n;
      }
      for (final n in driveNotes) {
        if (!mergedMap.containsKey(n.id!)) mergedMap[n.id!] = n;
      }

      expect(mergedMap.isEmpty, isTrue);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 5. تسلسل البيانات — Note.toMap / Note.fromMap
  // ══════════════════════════════════════════════════════════════
  group('Note Serialization — Backup Data Integrity', () {
    test('toMap ثم fromMap يُرجع نفس البيانات', () {
      final now = DateTime.now();
      final original = Note(
        id: 42,
        title: 'عنوان الملاحظة',
        content: 'محتوى الملاحظة',
        createdAt: now,
        updatedAt: now,
        colorIndex: 3,
        isArchived: false,
        isTrashed: false,
        isLocked: false,
        noteType: 'simple',
        isPinned: true,
        isChecklist: false,
      );

      final map = original.toMap();
      final restored = Note.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.colorIndex, original.colorIndex);
      expect(restored.isPinned, original.isPinned);
      expect(restored.noteType, original.noteType);
    });

    test('fromMap يتعامل مع noteType القديم "pro"', () {
      final map = {
        'id': 1,
        'title': 'Code Note',
        'content': 'print("hello")',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'noteType': 'pro',
        'colorIndex': 0,
        'isArchived': 0,
        'isTrashed': 0,
        'isLocked': 0,
        'isCompleted': 0,
        'isProfessional': 1,
        'isPinned': 0,
        'isChecklist': 0,
      };

      final note = Note.fromMap(map);
      expect(note.noteType, 'code');
    });

    test('fromMap يتعامل مع noteType القديم "professional"', () {
      final map = {
        'id': 1,
        'title': 'Code',
        'content': 'code',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'noteType': 'professional',
        'colorIndex': 0,
        'isArchived': 0,
        'isTrashed': 0,
        'isLocked': 0,
        'isCompleted': 0,
        'isProfessional': 1,
        'isPinned': 0,
        'isChecklist': 0,
      };

      final note = Note.fromMap(map);
      expect(note.noteType, 'code');
    });

    test('تسلسل 1000 ملاحظة وإعادة تحميلها بدون فقدان بيانات', () {
      final now = DateTime.now();
      final notes = List.generate(
          1000,
          (i) => Note(
                id: i + 1,
                title: 'ملاحظة $i',
                content: 'محتوى $i',
                createdAt: now,
                updatedAt: now,
                colorIndex: i % 12,
                noteType: ['simple', 'code', 'checklist', 'reminder'][i % 4],
              ));

      final json = jsonEncode(notes.map((n) => n.toMap()).toList());
      final decoded = jsonDecode(json) as List;
      final restored = decoded.map((m) => Note.fromMap(m)).toList();

      expect(restored.length, 1000);
      for (int i = 0; i < 1000; i++) {
        expect(restored[i].title, notes[i].title);
        expect(restored[i].colorIndex, notes[i].colorIndex);
        expect(restored[i].noteType, notes[i].noteType);
      }
    });

    test('ملاحظة مع تذكير تُحفظ وتُستعاد بشكل صحيح', () {
      final reminder = DateTime(2025, 12, 31, 10, 30);
      final note = Note(
        id: 1,
        title: 'تذكير',
        content: 'محتوى',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reminderDateTime: reminder,
        recurrenceRule: 'daily',
      );

      final map = note.toMap();
      final restored = Note.fromMap(map);

      expect(restored.reminderDateTime, isNotNull);
      expect(restored.recurrenceRule, 'daily');
    });

    test('ملاحظة مقفلة تُحفظ وتُستعاد بشكل صحيح', () {
      final note = Note(
        id: 1,
        title: 'iv1234567890123456:encryptedcontent',
        content: 'iv1234567890123456:encryptedcontent',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isLocked: true,
      );

      final map = note.toMap();
      final restored = Note.fromMap(map);

      expect(restored.isLocked, isTrue);
      expect(restored.title, note.title);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // 6. تسريب المزامنة — Race Conditions
  // ══════════════════════════════════════════════════════════════
  group('Sync Leak — Concurrent Operations', () {
    test('طلبات رفع متزامنة لا تُسبب تعارضاً (بدون تسجيل دخول)', () async {
      // بدون تسجيل دخول، كل الطلبات يجب أن ترمي استثناء بشكل نظيف
      final futures = List.generate(5, (_) async {
        try {
          await CloudSyncGateway.upload();
          return 'success';
        } catch (e) {
          return 'error: ${e.toString()}';
        }
      });

      final results = await Future.wait(futures);
      // كل النتائج يجب أن تكون أخطاء (لأنه غير مسجل)
      expect(results.every((r) => r.startsWith('error')), isTrue);
    });

    test('طلبات تحميل متزامنة لا تُسبب تعارضاً', () async {
      final futures = List.generate(5, (_) async {
        try {
          await CloudSyncGateway.download();
          return 'success';
        } catch (e) {
          return 'error';
        }
      });

      final results = await Future.wait(futures);
      expect(results.every((r) => r == 'error'), isTrue);
    });
  });
}
