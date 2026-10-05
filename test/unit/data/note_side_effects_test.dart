// Copyright © 2025 Apex Flow Group. All rights reserved.

// ما يحدث خارج القاعدة عند تغيّر ملاحظة: يُلغى التذكير القديم دائماً،
// ويُجدول الجديد فقط إن كان مستقبلياً لملاحظة نشطة، والمقفلة لا يظهر
// عنوانها ولا محتواها في الإشعار.

import 'package:flutter_test/flutter_test.dart';
import 'package:sinan_note/data/services/app_strings.dart';
import 'package:sinan_note/data/services/note_side_effects.dart';
import 'package:sinan_note/data/services/notification_service.dart';
import 'package:sinan_note/data/services/widget_service.dart';
import 'package:sinan_note/domain/models/note.dart';

class _Scheduled {
  _Scheduled(this.id, this.title, this.body, this.at, this.rule);
  final int id;
  final String title;
  final String body;
  final DateTime at;
  final String? rule;
}

class _FakeNotifications implements NotificationService {
  bool exactAllowed = true;
  final cancelled = <int>[];
  final scheduled = <_Scheduled>[];

  @override
  Future<bool> checkExactAlarmPermission() async => exactAllowed;

  @override
  Future<void> cancelNotification(int id) async => cancelled.add(id);

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? recurrenceRule,
    String? payload,
  }) async =>
      scheduled.add(_Scheduled(id, title, body, scheduledTime, recurrenceRule));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWidgets implements WidgetService {
  final refreshed = <int>[];
  final reset = <int>[];

  @override
  Future<void> refreshIfPinned(Note note) async => refreshed.add(note.id!);

  @override
  Future<void> resetIfPinned(int id) async => reset.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeNotifications notifications;
  late _FakeWidgets widgets;
  late PlatformNoteSideEffects effects;
  final now = DateTime.now();
  final tomorrow = now.add(const Duration(days: 1));

  Note note({
    int? id = 1,
    String title = 'Title',
    String content = 'Body',
    DateTime? reminder,
    bool locked = false,
    bool trashed = false,
    bool archived = false,
    bool checklist = false,
    String? rule,
  }) =>
      Note(
        id: id,
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
        reminderDateTime: reminder,
        isLocked: locked,
        isTrashed: trashed,
        isArchived: archived,
        isChecklist: checklist,
        recurrenceRule: rule,
      );

  setUp(() {
    notifications = _FakeNotifications();
    widgets = _FakeWidgets();
    effects =
        PlatformNoteSideEffects(notifications: notifications, widgets: widgets);
  });

  test('a future reminder replaces the old one', () async {
    await effects.noteChanged(note(reminder: tomorrow, rule: 'DAILY'));

    expect(notifications.cancelled, [1]);
    final s = notifications.scheduled.single;
    expect((s.id, s.title, s.body, s.at, s.rule),
        (1, 'Title', 'Body', tomorrow, 'DAILY'));
    expect(widgets.refreshed, [1]);
  });

  test('no reminder, a past one, trashed or archived: cancel only', () async {
    for (final n in [
      note(),
      note(reminder: now.subtract(const Duration(minutes: 1))),
      note(reminder: tomorrow, trashed: true),
      note(reminder: tomorrow, archived: true),
    ]) {
      await effects.noteChanged(n);
    }
    expect(notifications.cancelled, [1, 1, 1, 1]);
    expect(notifications.scheduled, isEmpty);
  });

  test('without the exact-alarm permission nothing is scheduled', () async {
    notifications.exactAllowed = false;
    await effects.noteChanged(note(reminder: tomorrow));
    expect(notifications.scheduled, isEmpty);
  });

  test('a locked note shows neither its title nor its content', () async {
    await effects.noteChanged(note(
        title: 'Secret plan',
        content: 'secret body',
        locked: true,
        reminder: tomorrow));
    final s = notifications.scheduled.single;
    expect(s.title, AppStrings.current.reminder);
    expect(s.body, isEmpty);
  });

  test('an untitled note uses the generic title', () async {
    await effects.noteChanged(note(title: '', reminder: tomorrow));
    expect(notifications.scheduled.single.title, AppStrings.current.reminder);
  });

  test('long bodies are cut to 100 characters', () {
    final body = PlatformNoteSideEffects.reminderBody(note(content: 'A' * 300));
    expect(body.length, lessThanOrEqualTo(103));
  });

  test('a note without an id is ignored', () async {
    await effects.noteChanged(note(id: null, reminder: tomorrow));
    expect(notifications.cancelled, isEmpty);
    expect(widgets.refreshed, isEmpty);
  });

  test('a removed note cancels its reminder and frees the widget', () async {
    await effects.noteRemoved(7);
    expect(notifications.cancelled, [7]);
    expect(widgets.reset, [7]);
  });
}
