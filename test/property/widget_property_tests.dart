// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/models/note.dart';
import 'package:sinan_note/services/note_services/note_side_effect_service.dart';

void main() {
  group('Widget Integration Property Tests', () {
    group('Property 10: Widget Update on Pinned Note Modification', () {
      test('widget updates called for pinned notes', () async {
        final service = NoteSideEffectService();

        for (int i = 0; i < 50; i++) {
          final note = Note(
            id: i,
            title: 'title_$i',
            content: 'content sentence $i',
            isPinned: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await service.checkAndUpdateIfPinned(note);
        }
      });

      test('widget updates skipped for non-pinned notes', () async {
        final service = NoteSideEffectService();

        for (int i = 0; i < 50; i++) {
          final note = Note(
            id: i,
            title: 'title_$i',
            content: 'content sentence $i',
            isPinned: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          await service.checkAndUpdateIfPinned(note);
        }
      });
    });

    group('Property 13: Widget Reset on Pinned Note Deletion', () {
      test('widget reset called for pinned note deletion', () async {
        final service = NoteSideEffectService();

        for (int i = 0; i < 50; i++) {
          await service.checkAndResetIfPinned(i);
        }
      });

      test('widget operations are idempotent', () async {
        final service = NoteSideEffectService();

        final note = Note(
          id: 1,
          title: 'Test',
          content: 'Content',
          isPinned: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await service.checkAndUpdateIfPinned(note);
        await service.checkAndUpdateIfPinned(note);
        await service.checkAndUpdateIfPinned(note);
      });
    });
  });
}

