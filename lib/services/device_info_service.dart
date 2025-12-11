// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();

  factory DeviceInfoService() {
    return _instance;
  }

  DeviceInfoService._internal();

  Future<Map<String, String>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final packageInfo = await PackageInfo.fromPlatform();

      return {
        'device': androidInfo.model,
        'os': 'Android ${androidInfo.version.release}',
        'version': packageInfo.version,
        'build': packageInfo.buildNumber,
      };
    } catch (e) {
      return {
        'device': 'Unknown',
        'os': 'Unknown',
        'version': 'Unknown',
        'build': 'Unknown',
      };
    }
  }
}
