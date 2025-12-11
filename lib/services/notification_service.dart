// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // تهيئة المناطق الزمنية
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    // طلب الأذونات للإشعارات والتنبيهات الدقيقة
    if (Platform.isAndroid) {
      await requestNotificationPermissions();
    }

    // إنشاء قناة الإشعارات بأعلى أولوية
    const androidChannel = AndroidNotificationChannel(
      'sinan_note_reminders',
      'تذكيرات',
      description: 'تذكيرات وتنبيهات الملاحظات',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// طلب أذونات الإشعارات لـ Android 13+
  Future<bool> requestNotificationPermissions() async {
    if (!Platform.isAndroid) return true;

    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return false;

    // طلب إذن الإشعارات (Android 13+)
    final notificationPermission =
        await androidImpl.requestNotificationsPermission();

    // طلب إذن التنبيهات الدقيقة (Android 12+)
    final exactAlarmPermission =
        await androidImpl.requestExactAlarmsPermission();

    return (notificationPermission ?? false) && (exactAlarmPermission ?? false);
  }

  /// فحص إذن الإشعارات
  Future<bool> checkNotificationPermission() async {
    if (!Platform.isAndroid) return true;

    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return false;

    final permission = await androidImpl.areNotificationsEnabled();
    return permission ?? false;
  }

  /// فحص إذن التنبيهات الدقيقة (Exact Alarms)
  Future<bool> checkExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;

    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return false;

    final permission = await androidImpl.canScheduleExactNotifications();
    return permission ?? false;
  }

  /// طلب إذن التنبيهات الدقيقة فقط
  Future<bool> requestExactAlarmsPermission() async {
    if (!Platform.isAndroid) return true;

    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl == null) return false;

    final permission = await androidImpl.requestExactAlarmsPermission();
    return permission ?? false;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? recurrenceRule,
  }) async {
    // Verify permissions before scheduling
    if (Platform.isAndroid) {
      final hasNotificationPerm = await checkNotificationPermission();
      final hasExactAlarmPerm = await checkExactAlarmPermission();

      if (!hasNotificationPerm || !hasExactAlarmPerm) {
        if (kDebugMode) {
          print('Missing permissions: Notification=$hasNotificationPerm, ExactAlarm=$hasExactAlarmPerm');
        }
        // Request permissions if missing
        await requestNotificationPermissions();
        
        // Verify again
        final recheckNotif = await checkNotificationPermission();
        final recheckAlarm = await checkExactAlarmPermission();
        
        if (!recheckNotif || !recheckAlarm) {
          throw Exception('Notification permissions denied');
        }
      }
    }

    // Cancel existing notification
    await cancelNotification(id);

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'sinan_note_reminders',
        'تذكيرات',
        channelDescription: 'تذكيرات وتنبيهات الملاحظات',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      ),
    );

    try {
      if (recurrenceRule == null || recurrenceRule == 'none') {
        // One-time notification
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tzScheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        // Recurring notification
        DateTimeComponents? matchDateTimeComponents;

        switch (recurrenceRule) {
          case 'DAILY':
            matchDateTimeComponents = DateTimeComponents.time;
            break;
          case 'WEEKLY':
            matchDateTimeComponents = DateTimeComponents.dayOfWeekAndTime;
            break;
          case 'MONTHLY':
            matchDateTimeComponents = DateTimeComponents.dayOfMonthAndTime;
            break;
          default:
            matchDateTimeComponents = null;
        }

        if (matchDateTimeComponents != null) {
          await _notifications.zonedSchedule(
            id,
            title,
            body,
            tzScheduledTime,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: matchDateTimeComponents,
          );
        }
      }
      
      if (kDebugMode) {
        print('Notification scheduled: ID=$id, Time=$scheduledTime');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to schedule notification: $e');
      }
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      // Ignore errors when canceling non-existent notifications
      if (kDebugMode) {
        print('Warning: Could not cancel notification $id: $e');
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
