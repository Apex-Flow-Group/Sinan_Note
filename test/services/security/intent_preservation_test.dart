// Copyright © 2025 Apex Flow Group. All rights reserved.

// النوايا الخارجية (ويدجت، مشاركة، ملف .sinan، إشعار) لا تُنفَّذ قبل
// المصادقة: تنتظر حتى تجهز الشاشة الرئيسية، ثم تُنفَّذ مرة واحدة فقط.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/data/services/intent_handler_service.dart';
import 'package:sinan_note/ui/core/navigation/app_navigation.dart';

const _view = 'com.apexflow.app.sinan.ACTION_VIEW_NOTE';

void main() {
  late IntentInbox inbox;
  late List<Map> executed;

  setUp(() {
    inbox = IntentInbox();
    executed = [];
    inbox.execute = executed.add;
  });

  group('before authentication', () {
    test('a widget intent waits and is not executed', () {
      inbox.deliver({'action': _view, 'note_id': 42});

      expect(executed, isEmpty);
      expect(inbox.pending?['note_id'], 42);
    });

    test('a shared text and a .sinan file wait too', () {
      inbox.deliver({'shared_text': 'hello'});
      expect(executed, isEmpty);
      inbox.deliver({'file_path': '/tmp/a.sinan'});
      expect(executed, isEmpty);
      expect(inbox.pending?['file_path'], '/tmp/a.sinan');
    });

    test('without an executor nothing runs even when ready', () {
      inbox
        ..execute = null
        ..ready = true
        ..deliver({'action': _view, 'note_id': 1});
      expect(inbox.pending, isNotNull);
    });
  });

  group('after authentication', () {
    test('the waiting intent runs once the main screen is ready', () {
      inbox.deliver({'action': _view, 'note_id': 7});
      inbox.ready = true;

      expect(executed.single['note_id'], 7);
      expect(inbox.pending, isNull);
    });

    test('a warm intent runs immediately', () {
      inbox.ready = true;
      inbox.deliver({'action': _view, 'note_id': 9});
      expect(executed.single['note_id'], 9);
    });

    test('an intent never runs twice', () {
      inbox.deliver({'action': _view, 'note_id': 3});
      inbox.ready = true;
      inbox.ready = true;
      inbox.ready = false;
      inbox.ready = true;
      expect(executed, hasLength(1));
    });

    test('locking again makes new intents wait', () {
      inbox.ready = true;
      inbox.ready = false;
      inbox.deliver({'action': _view, 'note_id': 77});
      expect(executed, isEmpty);
      expect(inbox.pending?['note_id'], 77);
    });

    test('the latest waiting intent wins', () {
      inbox.deliver({'action': _view, 'note_id': 1});
      inbox.deliver({'action': _view, 'note_id': 2});
      inbox.ready = true;
      expect(executed.single['note_id'], 2);
    });

    test('the delivered map is copied', () {
      final data = {'action': _view, 'note_id': 5};
      inbox.deliver(data);
      data['note_id'] = 6;
      inbox.ready = true;
      expect(executed.single['note_id'], 5);
    });
  });

  group('only intents with content are accepted', () {
    const service = IntentHandlerService();

    test('empty intents are rejected', () {
      expect(
          service.hasValidContent({
            'action': null,
            'note_id': 0,
            'shared_text': null,
            'file_path': null,
          }),
          isFalse);
      expect(service.hasValidContent({'action': _view, 'note_id': 0}), isFalse);
      expect(service.hasValidContent({'shared_text': ''}), isFalse);
    });

    test('notes, shared text, files and widget actions are accepted', () {
      expect(service.hasValidContent({'action': _view, 'note_id': 4}), isTrue);
      expect(service.hasValidContent({'shared_text': 'x'}), isTrue);
      expect(service.hasValidContent({'file_path': '/a.sinan'}), isTrue);
      expect(
          service.hasValidContent({
            'action': 'com.apexflow.app.sinan.ACTION_SELECT_NOTE_FOR_WIDGET'
          }),
          isTrue);
    });
  });
}
