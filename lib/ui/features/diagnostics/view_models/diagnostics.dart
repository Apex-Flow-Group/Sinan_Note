// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:share_plus/share_plus.dart';
import 'package:sinan_note/data/services/diagnostics/database_report.dart';
import 'package:sinan_note/data/services/diagnostics/error_log.dart';

/// أدوات التشخيص للواجهات: سجل الأخطاء وتقرير القاعدة.
class Diagnostics {
  Diagnostics(this._log);

  static const developerEmail = 'contact.apex.flow@gmail.com';

  final ErrorLog _log;

  /// السجل، أو null إن لم يُسجَّل شيء.
  Future<String?> errorLog() => _log.read();

  Future<void> clearLog() => _log.clear();

  /// يشارك السجل مع المطوّر (نص تقني بالإنجليزية عمداً).
  Future<void> shareErrorLog() async {
    final log = await _log.read() ?? '-';
    await Share.share(
      'Error Report for Apex Flow Group\n\n$log\n\nSend to: $developerEmail',
      subject: 'Sinan Note - Error Report',
    );
  }

  Future<Map<String, dynamic>> databaseReport() => DatabaseReport.build();
}
