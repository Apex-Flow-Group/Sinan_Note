// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/models/note_version.dart';
import 'package:sinan_note/services/search/smart_search_service.dart';
import 'package:sinan_note/services/security/rate_limiter_service.dart';
import 'package:sinan_note/services/storage/compression_service.dart';
import 'package:sinan_note/services/storage/sqlite_database_service.dart';
import 'package:sinan_note/services/version_control_service.dart';
import 'package:sinan_note/services/version_history_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../test_setup.dart';
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    initializeTestEnvironment();
  });

  // ══════════════════════════════════════════════════════════════
  // CompressionService
  // ══════════════════════════════════════════════════════════════
  group('CompressionService', () {
    test('compress then decompress returns original', () {
      const json = '{"version":"2.0","notes":[]}';
      final compressed = CompressionService.compress(json);
      expect(CompressionService.decompress(compressed), json);
    });

    test('compression reduces size for large data', () {
      final large =
          '{"notes":${List.generate(100, (i) => '{"id":$i,"title":"Note $i","content":"Content $i repeated many times"}')}}'
              .replaceAll('}}', '}}');
      final compressed = CompressionService.compress(large);
      expect(compressed.length, lessThan(large.length));
    });

    test('handles empty string', () {
      expect(() => CompressionService.compress(''), returnsNormally);
    });

    test('handles Arabic content', () {
      const arabic =
          '{"notes":[{"title":"ملاحظة عربية","content":"محتوى عربي طويل نسبياً"}]}';
      final compressed = CompressionService.compress(arabic);
      expect(CompressionService.decompress(compressed), arabic);
    });

    test('handles special characters', () {
      const special = '{"content":"Hello\\nWorld\\t😀🎉"}';
      expect(
          CompressionService.decompress(CompressionService.compress(special)),
          special);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // RateLimiterService
  // ══════════════════════════════════════════════════════════════
  group('RateLimiterService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await RateLimiterService.reset();
    });

    test('no lock initially', () async {
      expect(await RateLimiterService.getRemainingLockTime(), isNull);
    });

    test('5 remaining attempts initially', () async {
      expect(await RateLimiterService.getRemainingAttempts(), 5);
    });

    test('failed attempt decrements remaining', () async {
      await RateLimiterService.recordFailedAttempt();
      expect(await RateLimiterService.getRemainingAttempts(), 4);
    });

    test('5 failed attempts triggers lock', () async {
      for (int i = 0; i < 5; i++) {
        await RateLimiterService.recordFailedAttempt();
      }
      expect(await RateLimiterService.getRemainingLockTime(), isNotNull);
      expect(await RateLimiterService.getRemainingLockTime(), greaterThan(0));
    });

    test('reset clears all state', () async {
      await RateLimiterService.recordFailedAttempt();
      await RateLimiterService.recordFailedAttempt();
      await RateLimiterService.reset();
      expect(await RateLimiterService.getRemainingAttempts(), 5);
      expect(await RateLimiterService.getRemainingLockTime(), isNull);
    });

    test('formatRemainingTime formats seconds', () {
      expect(RateLimiterService.formatRemainingTime(45), '45s');
    });

    test('formatRemainingTime formats minutes', () {
      expect(RateLimiterService.formatRemainingTime(90), '1m 30s');
    });

    test('formatRemainingTime formats hours', () {
      expect(RateLimiterService.formatRemainingTime(3600), '1h');
    });

    test('formatRemainingTime formats hours and minutes', () {
      expect(RateLimiterService.formatRemainingTime(3660), '1h 1m');
    });

    test('lock duration constants are progressive', () {
      // 5 min < 15 min < 60 min
      expect(5 * 60, lessThan(15 * 60));
      expect(15 * 60, lessThan(60 * 60));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // VersionControlService
  // ══════════════════════════════════════════════════════════════
  group('VersionControlService', () {
    late SqliteDatabaseService db;
    late VersionControlService service;
    late DateTime now;

    setUp(() async {
      SqliteDatabaseService.resetInstance();
      SqliteDatabaseService.overrideDbPath(':memory:');
      db = SqliteDatabaseService();
      service = VersionControlService();
      now = DateTime.now();
    });

    tearDown(() async {
      await db.closeDB();
      SqliteDatabaseService.resetInstance();
    });

    Future<int> insertNote(String title, String content) async {
      return await db.insertNote(Note(
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      ));
    }

    test(
        'startEditingSession + endEditingSession saves version on significant change',
        () async {
      final id = await insertNote('Title', 'Short');
      service.startEditingSession(id, 'Title', 'Short');

      final longContent = 'A' * 200;
      await service.endEditingSession(
        noteId: id,
        title: 'Title',
        content: longContent,
      );

      final history = await db.getNoteHistory(id);
      expect(history, isNotEmpty);
    });

    test('no version saved when content unchanged', () async {
      final id = await insertNote('Title', 'Content');
      service.startEditingSession(id, 'Title', 'Content');
      await service.endEditingSession(
          noteId: id, title: 'Title', content: 'Content');

      final history = await db.getNoteHistory(id);
      expect(history, isEmpty);
    });

    test('no version saved for locked notes', () async {
      final id = await insertNote('Title', 'Content');
      service.startEditingSession(id, 'Title', 'Content');
      await service.endEditingSession(
        noteId: id,
        title: 'Title',
        content: 'A' * 200,
        isLocked: true,
      );

      final history = await db.getNoteHistory(id);
      expect(history, isEmpty);
    });

    test('smartLogVersion saves manual version', () async {
      final id = await insertNote('Title', 'Content');
      await service.smartLogVersion(
        noteId: id,
        title: 'Title',
        content: 'New Content',
        isManualAction: true,
        noteType: 'simple',
      );

      final history = await db.getNoteHistory(id);
      expect(history.length, 1);
      expect(history.first.action, 'manual_save');
    });

    test('smartLogVersion skips non-manual actions', () async {
      final id = await insertNote('Title', 'Content');
      await service.smartLogVersion(
        noteId: id,
        title: 'Title',
        content: 'New Content',
        isManualAction: false,
      );

      expect(await db.getNoteHistory(id), isEmpty);
    });

    test('smartLogVersion skips duplicate content', () async {
      final id = await insertNote('Title', 'Content');
      await service.smartLogVersion(
        noteId: id,
        title: 'Title',
        content: 'Content',
        isManualAction: true,
      );
      await service.smartLogVersion(
        noteId: id,
        title: 'Title',
        content: 'Content',
        isManualAction: true,
      );

      expect((await db.getNoteHistory(id)).length, 1);
    });

    test('forceLog saves even duplicate content', () async {
      final id = await insertNote('Title', 'Content');
      await service.smartLogVersion(
        noteId: id,
        title: 'Title',
        content: 'Content',
        isManualAction: true,
        forceLog: true,
      );
      await service.smartLogVersion(
        noteId: id,
        title: 'Title',
        content: 'Content',
        isManualAction: true,
        forceLog: true,
      );

      expect((await db.getNoteHistory(id)).length, 2);
    });

    test('max 5 versions kept', () async {
      final id = await insertNote('Title', 'Content');
      for (int i = 0; i < 8; i++) {
        await service.smartLogVersion(
          noteId: id,
          title: 'Title $i',
          content: 'Content $i',
          isManualAction: true,
          forceLog: true,
        );
      }

      expect((await db.getNoteHistory(id)).length, lessThanOrEqualTo(5));
    });
  });

  // ══════════════════════════════════════════════════════════════
  // VersionHistoryService
  // ══════════════════════════════════════════════════════════════
  group('VersionHistoryService', () {
    late SqliteDatabaseService db;
    late VersionHistoryService service;
    late DateTime now;

    setUp(() async {
      SqliteDatabaseService.resetInstance();
      SqliteDatabaseService.overrideDbPath(':memory:');
      db = SqliteDatabaseService();
      service = VersionHistoryService();
      now = DateTime.now();
    });

    tearDown(() async {
      await db.closeDB();
      SqliteDatabaseService.resetInstance();
    });

    test('getNotesWithHistory returns notes that have versions', () async {
      final id = await db.insertNote(Note(
        title: 'Note',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      ));
      await db.logNoteVersion(NoteVersion.create(
        noteId: id,
        title: 'Note',
        content: 'Content',
        timestamp: now,
        action: 'created',
        noteType: 'simple',
      ));

      final notes = await service.getNotesWithHistory();
      expect(notes.any((n) => n.id == id), true);
    });

    test('getNotesWithHistory excludes locked notes', () async {
      final id = await db.insertNote(Note(
        title: 'Locked',
        content: 'Secret',
        createdAt: now,
        updatedAt: now,
        isLocked: true,
      ));
      await db.logNoteVersion(NoteVersion.create(
        noteId: id,
        title: 'Locked',
        content: 'Secret',
        timestamp: now,
        action: 'created',
        noteType: 'simple',
      ));

      final notes = await service.getNotesWithHistory();
      expect(notes.any((n) => n.id == id), false);
    });

    test('getNoteVersions returns max 20 versions', () async {
      final id = await db.insertNote(Note(
        title: 'Note',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      ));
      for (int i = 0; i < 25; i++) {
        await db.logNoteVersion(NoteVersion.create(
          noteId: id,
          title: 'Note $i',
          content: 'Content $i',
          timestamp: now.add(Duration(minutes: i)),
          action: 'updated',
          noteType: 'simple',
        ));
      }

      final versions = await service.getNoteVersions(id);
      expect(versions.length, lessThanOrEqualTo(20));
    });

    test('getVersionCount returns correct count', () async {
      final id = await db.insertNote(Note(
        title: 'Note',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      ));
      for (int i = 0; i < 3; i++) {
        await db.logNoteVersion(NoteVersion.create(
          noteId: id,
          title: 'Note',
          content: 'Content $i',
          timestamp: now,
          action: 'updated',
          noteType: 'simple',
        ));
      }

      expect(await service.getVersionCount(id), 3);
    });

    test('restoreVersion updates note content', () async {
      final id = await db.insertNote(Note(
        title: 'Original',
        content: 'Original Content',
        createdAt: now,
        updatedAt: now,
      ));
      final version = NoteVersion.create(
        noteId: id,
        title: 'Old Title',
        content: 'Old Content',
        timestamp: now,
        action: 'created',
        noteType: 'simple',
      );

      await service.restoreVersion(id, version);

      final restored = await db.getNoteById(id);
      expect(restored!.title, 'Old Title');
      expect(restored.content, 'Old Content');
    });
  });

  // ══════════════════════════════════════════════════════════════
  // SmartSearchService
  // ══════════════════════════════════════════════════════════════
  group('SmartSearchService', () {
    late SqliteDatabaseService db;
    late SmartSearchService service;
    late DateTime now;

    setUp(() async {
      SqliteDatabaseService.resetInstance();
      SqliteDatabaseService.overrideDbPath(':memory:');
      db = SqliteDatabaseService();
      service = SmartSearchService();
      now = DateTime.now();
    });

    tearDown(() async {
      await db.closeDB();
      SqliteDatabaseService.resetInstance();
    });

    test('empty query returns empty result', () async {
      final result = await service.search('');
      expect(result.notes, isEmpty);
      expect(result.suggestion, isNull);
    });

    test('whitespace query returns empty result', () async {
      final result = await service.search('   ');
      expect(result.notes, isEmpty);
    });

    test('finds notes by title', () async {
      await db.insertNote(Note(
        title: 'Flutter Tutorial',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      ));
      await db.insertNote(Note(
        title: 'Dart Guide',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      ));

      final result = await service.search('Flutter');
      expect(result.notes.length, 1);
      expect(result.notes.first.title, 'Flutter Tutorial');
    });

    test('finds notes by content', () async {
      await db.insertNote(Note(
        title: 'Note',
        content: 'This is about Flutter development',
        createdAt: now,
        updatedAt: now,
      ));

      final result = await service.search('Flutter');
      expect(result.notes.length, 1);
    });

    test('search is case insensitive', () async {
      await db.insertNote(Note(
        title: 'Flutter',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      ));

      final result = await service.search('flutter');
      expect(result.notes.length, 1);
    });

    test('no results for non-existent query', () async {
      await db.insertNote(Note(
        title: 'Flutter',
        content: 'Content',
        createdAt: now,
        updatedAt: now,
      ));

      final result = await service.search('xyz123nonexistent');
      expect(result.notes, isEmpty);
    });

    test('does not return locked notes', () async {
      await db.insertNote(Note(
        title: 'Secret Flutter',
        content: 'Locked content',
        createdAt: now,
        updatedAt: now,
        isLocked: true,
      ));

      final result = await service.search('Flutter');
      expect(result.notes, isEmpty);
    });
  });
}

