// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sinan_note/data/services/app_update_service.dart';
import 'package:sinan_note/data/services/diagnostics/apex_diagnostics_engine.dart';
import 'package:sinan_note/data/services/notification_service.dart';
import 'package:sinan_note/data/services/widget_service.dart';
import 'package:sinan_note/domain/logger.dart';

/// تهيئة خدمات المنصة عند بدء التطبيق.
class AppStartup {
  /// التشخيص، الإشعارات، وويدجت الشاشة الرئيسية. لا يرمي.
  Future<void> initServices() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      ApexDiagnosticsEngine().init(appDir.path);
      if (Platform.isAndroid || Platform.isIOS) {
        await NotificationService().initialize();
        if (Platform.isAndroid) await WidgetService().initialize();
      }
    } on Object catch (e) {
      AppLogger.error('Background services init error', 'AppStartup', e);
    }
  }

  Future<void> checkForUpdate() => AppUpdateService.checkForUpdate();
}
