// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:flutter/services.dart';

/// خدمة فحص وجود Apex Transfer والمشاركة عبره
///
/// تعتمد على MethodChannel الموجود في MainActivity.kt
/// (isPackageInstalled + openApexWithFile)
class ApexShareService {
  static const _channel = MethodChannel('com.apexflow.app.sinan/widget');
  static const apexPackage = 'com.apexflow.tools.transfer';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$apexPackage';

  /// Cache — نفحص مرة واحدة فقط لكل جلسة
  static bool? _cachedInstalled;

  /// هل Apex Transfer مثبت على الجهاز؟
  ///
  /// يعمل على Android فقط. على Desktop يرجع false دائماً.
  static Future<bool> isInstalled() async {
    if (!Platform.isAndroid) return false;

    // استخدم الـ cache إذا سبق الفحص
    if (_cachedInstalled != null) return _cachedInstalled!;

    try {
      final result = await _channel.invokeMethod<bool>(
        'isPackageInstalled',
        {'package': apexPackage},
      );
      _cachedInstalled = result ?? false;
      return _cachedInstalled!;
    } catch (_) {
      _cachedInstalled = false;
      return false;
    }
  }

  /// أعد فحص الوجود (بعد عودة المستخدم من Play Store مثلاً)
  static void invalidateCache() {
    _cachedInstalled = null;
  }

  /// فتح ملف .sinan في Apex Transfer
  ///
  /// يُرجع true إذا نجح، أو يرمي استثناء إذا لم يكن Apex مثبتاً.
  static Future<bool> openFileInApex(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openApexWithFile',
        {'path': filePath},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      if (e.code == 'NOT_INSTALLED') {
        _cachedInstalled = false;
        rethrow;
      }
      rethrow;
    }
  }
}
