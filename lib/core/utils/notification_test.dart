// Copyright © 2025 Apex Flow Group. All rights reserved.
// Notification Test Utility - For debugging reminders

import 'logger.dart';
import '../../services/notification_service.dart';

class NotificationTest {
  static Future<void> testNotificationIn1Minute() async {
    final service = NotificationService();
    
    // Check permissions
    final hasNotif = await service.checkNotificationPermission();
    final hasAlarm = await service.checkExactAlarmPermission();
    
    AppLogger.info('=== NOTIFICATION TEST ===', 'NotificationTest');
    AppLogger.info('Notification Permission: $hasNotif', 'NotificationTest');
    AppLogger.info('Exact Alarm Permission: $hasAlarm', 'NotificationTest');
    
    if (!hasNotif || !hasAlarm) {
      AppLogger.info('Requesting permissions...', 'NotificationTest');
      final granted = await service.requestNotificationPermissions();
      AppLogger.info('Permissions granted: $granted', 'NotificationTest');
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
      
      AppLogger.success('Test notification scheduled for: $testTime', 'NotificationTest');
      AppLogger.info('Current time: ${DateTime.now()}', 'NotificationTest');
      AppLogger.info('=== TEST COMPLETE ===', 'NotificationTest');
    } catch (e) {
      AppLogger.error('ERROR scheduling test notification', 'NotificationTest', e);
    }
  }
}
