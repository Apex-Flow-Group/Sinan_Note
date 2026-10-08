// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:sinan_note/data/services/app_update_service.dart';
import 'package:sinan_note/data/services/notification_service.dart';
import 'package:sinan_note/data/services/widget_service.dart';
import 'package:sinan_note/domain/logger.dart';
import 'package:sinan_note/domain/startup_trace.dart';

/// بدء التشغيل للشاشات: توقيت الخطوات، وخدمات المنصة التي تُهيَّأ في الخلفية.
class AppStartup {
  AppStartup({
    required NotificationService notifications,
    required WidgetService widgets,
    required this.trace,
  })  : _notifications = notifications,
        _widgets = widgets;

  final NotificationService _notifications;
  final WidgetService _widgets;
  final StartupTrace trace;

  /// الإشعارات وويدجت الشاشة الرئيسية، في الخلفية بعد ظهور الرئيسية. لا
  /// يرمي. جدولة تذكير قبل اكتمالها تنتظرها داخل الخدمة.
  Future<void> initServices() =>
      trace.background('notifications, widget', () async {
        try {
          if (NotificationService.isSupported) {
            await _notifications.initialize();
          }
          if (Platform.isAndroid) await _widgets.initialize();
        } on Object catch (e) {
          AppLogger.error('Background services init error', 'AppStartup', e);
        }
      });

  Future<void> checkForUpdate() => AppUpdateService.checkForUpdate();
}
