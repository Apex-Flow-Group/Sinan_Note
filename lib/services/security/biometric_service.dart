// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/logger.dart';
import 'package:apex_note/services/diagnostics/apex_error_manager.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

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
      AppLogger.debug("Biometric check error: $e");
      return false;
    }
  }

  /// المصادقة باستخدام البصمة أو كلمة مرور الجهاز
  static Future<bool> authenticate() async {
    return await ApexErrorManager.monitorCritical(() async {
      if (Platform.isLinux || Platform.isWindows) return true;

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
        AppLogger.debug("Authentication error: $e");
        return false;
      }
    }, 'BiometricAuth');
  }

  static Future<String> _getAuthenticationMessage() async {
    final settings = SettingsProvider();
    await settings.ensureInitialized();
    return settings.locale?.languageCode == 'ar'
        ? 'يرجى المصادقة لفتح الملاحظة'
        : 'Please authenticate to open the note';
  }
}
