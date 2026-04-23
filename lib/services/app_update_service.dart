// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:in_app_update/in_app_update.dart';

/// In-App Update Service — يستخدم Google Play Core API
/// Flexible: يحمّل في الخلفية ويعرض bottom sheet
/// Immediate: يجبر المستخدم على التحديث (للتحديثات الحرجة)
class AppUpdateService {
  static Future<void> checkForUpdate() async {
    // يعمل على Android فقط
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // Flexible — يحمّل في الخلفية ويعرض bottom sheet من Google
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (_) {
      // silent — لا نوقف التطبيق إذا فشل الفحص
    }
  }

  /// للتحديثات الحرجة — يجبر المستخدم على التحديث
  static Future<void> checkForImmediateUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (_) {}
  }
}
