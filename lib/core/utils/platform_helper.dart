// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper class للتحقق من نوع الجهاز والتخطيط المناسب
class PlatformHelper {
  /// التحقق من أن الجهاز هو Desktop حقيقي (Linux/Windows/macOS)
  static bool get isDesktopPlatform {
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }

  /// التحقق من أن الجهاز هو Mobile (Android/iOS)
  static bool get isMobilePlatform {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// التحقق من أن الجهاز هو موبايل صغير (ليس تابلت)
  /// يستخدم أقصر ضلع للتفريق بين الموبايل والتابلت
  static bool isMobilePhone(BuildContext context) {
    if (!isMobilePlatform) return false;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide < 600; // أقل من 600 = موبايل، أكبر = تابلت
  }

  /// التحقق من أن الجهاز هو تابلت
  static bool isTablet(BuildContext context) {
    if (!isMobilePlatform) return false;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }

  /// التحقق من أن الشاشة يجب أن تستخدم Desktop Layout
  /// الهاتف: موبايل دائماً — التابلت أفقي: ديسكتوب — التابلت عمودي: موبايل
  static bool shouldUseDesktopLayout(BuildContext context,
      {double breakpoint = 600}) {
    if (isDesktopPlatform) return true;
    final size = MediaQuery.of(context).size;
    final isTabletDevice = size.shortestSide >= breakpoint;
    return isTabletDevice && size.width >= 800;
  }

  /// قفل اتجاه الشاشة للموبايل فقط (Portrait)
  /// يسمح بالتدوير للتابلت والديسكتوب
  static Future<void> lockOrientationForMobile(BuildContext context) async {
    if (isMobilePhone(context)) {
      // قفل على Portrait للموبايل فقط
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      // السماح بجميع الاتجاهات للتابلت والديسكتوب
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// إلغاء قفل الاتجاه (السماح بجميع الاتجاهات)
  static Future<void> unlockOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}
