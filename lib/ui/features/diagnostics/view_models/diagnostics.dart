// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:share_plus/share_plus.dart';
import 'package:sinan_note/data/services/diagnostics/apex_diagnostics_engine.dart';
import 'package:sinan_note/data/services/diagnostics/database_report.dart';

/// أدوات التشخيص للواجهات: سجل الأخطاء وتقرير القاعدة.
class Diagnostics {
  Diagnostics([ApexDiagnosticsEngine? engine])
      : _engine = engine ?? ApexDiagnosticsEngine();

  static const developerEmail = 'contact.apex.flow@gmail.com';

  final ApexDiagnosticsEngine _engine;

  /// السجل، أو null إن لم يُسجَّل شيء.
  Future<String?> errorLog() => _engine.getErrorLog();

  Future<void> clearLog() => _engine.clearLog();

  /// يشارك السجل مع المطوّر (نص تقني بالإنجليزية عمداً).
  Future<void> shareErrorLog() async {
    final log = await _engine.getErrorLog() ?? '-';
    await Share.share(
      'Error Report for Apex Flow Group\n\n$log\n\nSend to: $developerEmail',
      subject: 'Sinan Note - Error Report',
    );
  }

  Future<Map<String, dynamic>> databaseReport() => DatabaseReport.build();
}
