// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sinan_note/data/services/app_strings.dart';
import 'package:sinan_note/domain/logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// إشعارات التذكير. يُنشأ مرة في نقطة التركيب؛ على سطح المكتب لا يفعل شيئاً.
class NotificationService {
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void>? _ready;

  /// مرة واحدة: المناطق الزمنية، والمكتبة، والقناة، والتذكير الذي فتح التطبيق.
  /// لا ينتظرها بدء التشغيل؛ الجدولة والإلغاء ينتظرانها. الأذونات لا تُطلب
  /// هنا بل عند ضبط تذكير.
  Future<void> initialize() =>
      _ready ??= _initialize().onError<Object>((error, stack) {
        _ready = null; // فشل عابر: يُعاد في الطلب التالي
        Error.throwWithStackTrace(error, stack);
      });

  Future<void> _initialize() async {
    // تهيئة المناطق الزمنية
    tz.initializeTimeZones();

    // كشف توقيت جهاز المستخدم الحالي
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      AppLogger.success('Timezone set to: $timeZoneName', 'Notification');
    } catch (e) {
      AppLogger.warning(
          'Failed to set local timezone, using UTC fallback', 'Notification');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // التطبيق كان مغلقاً وفُتح من تذكير: الاستجابة لا تمر بالـ callback
    final launch = await _notifications.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      receivePayload(launch!.notificationResponse?.payload);
    }

    // إنشاء قناة الإشعارات بأعلى أولوية
    // اسم القناة ووصفها يظهران في إعدادات النظام: بلغة التطبيق
    final androidChannel = AndroidNotificationChannel(
      'sinan_note_reminders',
      AppStrings.current.reminders,
      description: AppStrings.current.reminderChannelDescription,
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
    if (!isSupported) return;
    await initialize();
    // Verify permissions before scheduling
    if (Platform.isAndroid) {
      final hasNotificationPerm = await checkNotificationPermission();
      final hasExactAlarmPerm = await checkExactAlarmPermission();

      if (!hasNotificationPerm || !hasExactAlarmPerm) {
        AppLogger.warning(
            'Missing permissions: Notification=$hasNotificationPerm, ExactAlarm=$hasExactAlarmPerm',
            'Notification');
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

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'sinan_note_reminders',
        AppStrings.current.reminders,
        channelDescription: AppStrings.current.reminderChannelDescription,
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
          id: id,
          title: title,
          body: body,
          scheduledDate: tzScheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
            id: id,
            title: title,
            body: body,
            scheduledDate: tzScheduledTime,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: matchDateTimeComponents,
            payload: payload,
          );
        }
      }

      AppLogger.success('Notification scheduled: ID=$id, Time=$scheduledTime',
          'Notification');
    } catch (e) {
      AppLogger.error('Failed to schedule notification', 'Notification', e);
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!isSupported) return;
    await initialize();
    try {
      await _notifications.cancel(id: id);
    } catch (e) {
      // Ignore errors when canceling non-existent notifications
      AppLogger.debug('Could not cancel notification $id', 'Notification');
    }
  }

  void Function(int noteId)? _onNoteTapped;
  int? _pendingTap;

  /// ما يحدث عند لمس تذكير ملاحظة (يعيّنه التطبيق؛ يمر بقفل التطبيق، ولا
  /// يفتح ملاحظة مقفلة). لمسة وصلت قبل تعيينه تُسلَّم عند تعيينه.
  void Function(int noteId)? get onNoteTapped => _onNoteTapped;
  set onNoteTapped(void Function(int noteId)? callback) {
    _onNoteTapped = callback;
    final pending = _pendingTap;
    if (callback != null && pending != null) {
      _pendingTap = null;
      callback(pending);
    }
  }

  /// حمولة تذكير لُمس (رقم الملاحظة).
  void receivePayload(String? payload) {
    final noteId = int.tryParse(payload ?? '');
    if (noteId == null) return;
    final callback = _onNoteTapped;
    if (callback == null) {
      _pendingTap = noteId;
    } else {
      callback(noteId);
    }
  }

  void _onNotificationTapped(NotificationResponse response) =>
      receivePayload(response.payload);
}
