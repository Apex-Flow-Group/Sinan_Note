// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static Future<int> _getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> requestCameraPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> isCameraPermissionPermanentlyDenied() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    var status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Request notification permission (required for Android 13+ and reminders)
  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    final sdkVersion = await _getAndroidSdkVersion();

    // Android 13+ (API 33+) requires explicit notification permission
    if (Platform.isAndroid && sdkVersion >= 33) {
      var status = await Permission.notification.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        await openSettings();
        return false;
      }
      status = await Permission.notification.request();
      return status.isGranted;
    }

    // iOS always requires notification permission
    if (Platform.isIOS) {
      var status = await Permission.notification.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        await openSettings();
        return false;
      }
      status = await Permission.notification.request();
      return status.isGranted;
    }

    return true;
  }

  /// Request storage permission (Android 13+ uses scoped storage)
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final sdkVersion = await _getAndroidSdkVersion();

    // Android 13+ (API 33+) uses granular media permissions
    if (sdkVersion >= 33) {
      // For media files, request photos/videos/audio instead of storage
      var status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied) {
        await openSettings();
        return false;
      }
      status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    } else {
      // Android 12 and below use storage permission
      var status = await Permission.storage.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        await openSettings();
        return false;
      }
      status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  /// Check if any permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(
      Permission permission) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    var status = await permission.status;
    return status.isPermanentlyDenied;
  }

  static Future<bool> requestNetworkPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    var status = await Permission.nearbyWifiDevices.status;
    if (status.isGranted || status.isLimited) return true;
    if (status.isPermanentlyDenied) return false;
    status = await Permission.nearbyWifiDevices.request();
    return status.isGranted || status.isLimited;
  }
}
