// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {

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

    var status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await openSettings();
      return false;
    }
    status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Request storage permission (Android 13+ uses scoped storage)
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    // Try photos permission first (Android 13+)
    var status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) return true;
    
    if (!status.isPermanentlyDenied) {
      status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) return true;
    }

    // Fallback to storage permission (Android 12 and below)
    status = await Permission.storage.status;
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      await openSettings();
      return false;
    }
    
    status = await Permission.storage.request();
    return status.isGranted;
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
