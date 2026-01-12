// Copyright © 2025 Apex Flow Group. All rights reserved.
// Notification Test Utility - For debugging reminders

import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationTest {
  static Future<void> testNotificationIn1Minute() async {
    final service = NotificationService();
    
    // Check permissions
    final hasNotif = await service.checkNotificationPermission();
    final hasAlarm = await service.checkExactAlarmPermission();
    
    if (kDebugMode) {
      print('=== NOTIFICATION TEST ===');
      print('Notification Permission: $hasNotif');
      print('Exact Alarm Permission: $hasAlarm');
    }
    
    if (!hasNotif || !hasAlarm) {
      if (kDebugMode) {
        print('Requesting permissions...');
      }
      final granted = await service.requestNotificationPermissions();
      if (kDebugMode) {
        print('Permissions granted: $granted');
      }
    }
    
    // Schedule test notification for 1 minute from now
    final testTime = DateTime.now().add(const Duration(minutes: 1));
    
    try {
      await service.scheduleNotification(
        id: 99999,
        title: 'Test Reminder',
        body: 'This is a test notification scheduled 1 minute ago',
        scheduledTime: testTime,
      );
      
      if (kDebugMode) {
        print('Test notification scheduled for: $testTime');
        print('Current time: ${DateTime.now()}');
        print('=== TEST COMPLETE ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ERROR scheduling test notification: $e');
      }
    }
  }
}
