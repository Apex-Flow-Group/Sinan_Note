// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../core/utils/logger.dart';
import 'storage/isar_database_service.dart';
import '../screens/note_view_screen.dart';
import '../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // تهيئة المناطق الزمنية
    tz.initializeTimeZones();
    
    // كشف توقيت جهاز المستخدم الحالي
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      AppLogger.success('Timezone set to: $timeZoneName', 'Notification');
    } catch (e) {
      AppLogger.warning('Failed to set local timezone, using UTC fallback', 'Notification');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

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

  /// فحص شامل لجميع الأذونات المطلوبة للتذكيرات
  Future<Map<String, bool>> checkAllPermissions() async {
    if (!Platform.isAndroid) {
      return {'notifications': true, 'exactAlarm': true};
    }

    final hasNotifications = await checkNotificationPermission();
    final hasExactAlarm = await checkExactAlarmPermission();

    return {
      'notifications': hasNotifications,
      'exactAlarm': hasExactAlarm,
    };
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? recurrenceRule,
    String? payload,
  }) async {
    // Verify permissions before scheduling
    if (Platform.isAndroid) {
      final hasNotificationPerm = await checkNotificationPermission();
      final hasExactAlarmPerm = await checkExactAlarmPermission();

      if (!hasNotificationPerm || !hasExactAlarmPerm) {
        AppLogger.warning('Missing permissions: Notification=$hasNotificationPerm, ExactAlarm=$hasExactAlarmPerm', 'Notification');
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
          payload: payload,
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
            payload: payload,
          );
        }
      }
      
      AppLogger.success('Notification scheduled: ID=$id, Time=$scheduledTime', 'Notification');
    } catch (e) {
      AppLogger.error('Failed to schedule notification', 'Notification', e);
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      // Ignore errors when canceling non-existent notifications
      AppLogger.debug('Could not cancel notification $id', 'Notification');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static void _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null) {
      final noteId = int.tryParse(payload);
      if (noteId != null) {
        await _openNoteById(noteId);
      }
    }
  }

  static Future<void> _openNoteById(int noteId) async {
    try {
      final dbService = IsarDatabaseService();
      final note = await dbService.getNoteById(noteId);
      if (note != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => NoteViewScreen(note: note, showRestore: false),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error opening note', 'Notification', e);
    }
  }
}
