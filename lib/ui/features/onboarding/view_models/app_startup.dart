// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:sinan_note/data/services/app_update_service.dart';
import 'package:sinan_note/data/services/notification_service.dart';
import 'package:sinan_note/data/services/widget_service.dart';
import 'package:sinan_note/domain/logger.dart';

/// تهيئة خدمات المنصة عند بدء التطبيق.
class AppStartup {
  AppStartup({
    required NotificationService notifications,
    required WidgetService widgets,
  })  : _notifications = notifications,
        _widgets = widgets;

  final NotificationService _notifications;
  final WidgetService _widgets;

  /// الإشعارات وويدجت الشاشة الرئيسية. لا يرمي.
  Future<void> initServices() async {
    try {
      if (NotificationService.isSupported) await _notifications.initialize();
      if (Platform.isAndroid) await _widgets.initialize();
    } on Object catch (e) {
      AppLogger.error('Background services init error', 'AppStartup', e);
    }
  }

  Future<void> checkForUpdate() => AppUpdateService.checkForUpdate();
}
