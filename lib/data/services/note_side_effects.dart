// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/data/services/app_strings.dart';
import 'package:sinan_note/data/services/notification_service.dart';
import 'package:sinan_note/data/services/widget_service.dart';
import 'package:sinan_note/domain/logger.dart';
import 'package:sinan_note/domain/models/note.dart';
import 'package:sinan_note/domain/text/checklist.dart';
import 'package:sinan_note/domain/text/note_text.dart';

/// ما يحدث خارج القاعدة عند تغيّر ملاحظة: التذكيرات وويدجت الشاشة الرئيسية.
/// يستقبل الملاحظة كما خُزّنت؛ المقفلة تُعرض بنص عام لا بمحتواها.
abstract interface class NoteSideEffects {
  Future<void> noteChanged(Note note);
  Future<void> noteRemoved(int id);
}

class PlatformNoteSideEffects implements NoteSideEffects {
  PlatformNoteSideEffects({
    required NotificationService notifications,
    required WidgetService widgets,
  })  : _notifications = notifications,
        _widgets = widgets;

  final NotificationService _notifications;
  final WidgetService _widgets;

  static const _bodyChars = 100;

  @override
  Future<void> noteChanged(Note note) async {
    final id = note.id;
    if (id == null) return;
    await _cancel(id);
    final at = note.reminderDateTime;
    if (at != null &&
        at.isAfter(DateTime.now()) &&
        !note.isTrashed &&
        !note.isArchived) {
      await _schedule(note, at);
    }
    await _widgets.refreshIfPinned(note);
  }

  @override
  Future<void> noteRemoved(int id) async {
    await _cancel(id);
    await _widgets.resetIfPinned(id);
  }

  Future<void> _schedule(Note note, DateTime at) async {
    try {
      // Android 12+: بلا إذن التنبيه الدقيق لا يُجدول شيء
      if (!await _notifications.checkExactAlarmPermission()) return;
      await _notifications.scheduleNotification(
        id: note.id!,
        title: reminderTitle(note),
        body: reminderBody(note),
        scheduledTime: at,
        recurrenceRule: note.recurrenceRule,
        payload: note.id.toString(),
      );
    } on Object catch (e) {
      AppLogger.warning('Reminder not scheduled: $e', 'SideEffects');
    }
  }

  Future<void> _cancel(int id) async {
    try {
      await _notifications.cancelNotification(id);
    } on Object catch (_) {}
  }

  /// عنوان التذكير: المقفلة لا يظهر عنوانها على شاشة القفل.
  static String reminderTitle(Note note) => note.isLocked || note.title.isEmpty
      ? AppStrings.current.reminder
      : note.title;

  /// نص التذكير: فارغ للمقفلة، والقائمة كبنود، وغيرها نصاً عادياً.
  static String reminderBody(Note note) {
    if (note.isLocked) return '';
    if (note.isChecklist) {
      final text =
          ChecklistFormatter.formatForSharing(note.title, note.content);
      return text.length > _bodyChars
          ? '${text.substring(0, _bodyChars)}...'
          : text;
    }
    return NoteText.toDisplayText(note.content, maxChars: _bodyChars);
  }
}
