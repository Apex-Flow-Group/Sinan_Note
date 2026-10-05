// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:sinan_note/data/services/notification_service.dart';

/// أذونات التذكيرات للواجهات (الإشعارات والتنبيهات الدقيقة).
class ReminderPermissions {
  ReminderPermissions(this._service);

  final NotificationService _service;

  /// الإشعارات والتنبيه الدقيق كلاهما مسموح؟
  Future<bool> granted() async {
    final status = await _service.checkAllPermissions();
    return status['notifications']! && status['exactAlarm']!;
  }

  /// يطلب الأذونات الناقصة؛ يُرجع إن صارت كلها ممنوحة.
  Future<bool> request() async {
    await _service.requestNotificationPermissions();
    return granted();
  }

  /// هل يُسمح بالتنبيه في الدقيقة نفسها؟
  Future<bool> canScheduleExact() => _service.checkExactAlarmPermission();
}
