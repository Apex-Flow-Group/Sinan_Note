// Copyright © 2025 Apex Flow Group. All rights reserved.

// لمس تذكير يفتح ملاحظته: حتى لو فتح التطبيق وهو مغلق (اللمسة تصل قبل أن
// يعيّن التطبيق من يستقبلها)، ولا تُسلَّم مرتين.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/data/services/notification_service.dart';

void main() {
  late NotificationService service;
  late List<int> opened;

  setUp(() {
    service = NotificationService();
    opened = [];
  });

  test('a tap is delivered to the app', () {
    service.onNoteTapped = opened.add;
    service.receivePayload('42');
    expect(opened, [42]);
  });

  test('a tap that launched the app waits for the app, then opens once', () {
    service.receivePayload('7');
    expect(opened, isEmpty);
    service.onNoteTapped = opened.add;
    expect(opened, [7]);
    // يُستهلك: إعادة التعيين لا تعيده
    service.onNoteTapped = opened.add;
    expect(opened, [7]);
  });

  test('the latest waiting tap wins', () {
    service.receivePayload('1');
    service.receivePayload('2');
    service.onNoteTapped = opened.add;
    expect(opened, [2]);
  });

  test('payloads that are not a note id are ignored', () {
    service.onNoteTapped = opened.add;
    service.receivePayload(null);
    service.receivePayload('');
    service.receivePayload('note');
    expect(opened, isEmpty);
  });
}
