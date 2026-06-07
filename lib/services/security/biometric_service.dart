// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';import 'package:flutter/services.dart';import 'package:local_auth/local_auth.dart'; import 'package:sinan_note/controllers/settings/settings_provider.dart'; import 'package:sinan_note/core/utils/logger.dart'; import 'package:sinan_note/services/diagnostics/apex_error_manager.dart';
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// التحقق من دعم الجهاز للمصادقة البيومترية
  /// يُرجع true فقط إذا كان الجهاز يدعم البصمة ولديه credentials مسجّلة فعلاً
  static Future<bool> hasBiometrics() async {
    if (Platform.isLinux || Platform.isWindows) return false;
    try {
      // الجهاز يدعم البصمة hardware
      final bool canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      // توجد بصمة مسجّلة فعلاً على الجهاز
      final List<BiometricType> available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (e) {
      AppLogger.debug("Biometric check error: $e");
      return false;
    }
  }

  /// المصادقة باستخدام البصمة أو كلمة مرور الجهاز
  /// يرجع null لو الجهاز لا يدعم أو لا توجد credentials مسجّلة
  static Future<bool?> authenticateOrNull() async {
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
      // NotAvailable = لا توجد credentials مسجّلة (الجهاز بلا حماية)
      if (e.code == 'NotAvailable') return null;
      return false;
    }
  }

  /// المصادقة باستخدام البصمة أو كلمة مرور الجهاز
  static Future<bool> authenticate() async {
    return await ApexErrorManager.monitorCritical(() async {
      final result = await authenticateOrNull();
      return result ?? false;
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

