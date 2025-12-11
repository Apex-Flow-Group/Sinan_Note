// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'settings_provider.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// التحقق من دعم الجهاز للمصادقة البيومترية
  static Future<bool> hasBiometrics() async {
    if (Platform.isLinux || Platform.isWindows) return false;
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint("Biometric check error: $e");
      return false;
    }
  }

  /// المصادقة باستخدام البصمة أو كلمة مرور الجهاز
  static Future<bool> authenticate() async {
    if (Platform.isLinux || Platform.isWindows) return true;
    final isAvailable = await hasBiometrics();
    if (!isAvailable) return false;

    try {
      return await _auth.authenticate(
        localizedReason: await _getAuthenticationMessage(),
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint("Authentication error: $e");
      return false;
    }
  }

  static Future<String> _getAuthenticationMessage() async {
    final settings = SettingsProvider();
    await settings.ensureInitialized();
    return settings.locale?.languageCode == 'ar'
        ? 'يرجى المصادقة لفتح الملاحظة'
        : 'Please authenticate to open the note';
  }
}
