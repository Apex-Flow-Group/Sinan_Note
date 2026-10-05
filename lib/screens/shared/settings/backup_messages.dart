// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/widgets.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';

class BackupMessages {
  /// رسالة إلغاء الاستيراد/الاستعادة بلغة [lang] (الإنجليزية إن لم تُدعم).
  static String getCancelMessage(String lang, String operation) {
    final locale = Locale(lang);
    final l10n = lookupAppLocalizations(
      AppLocalizations.delegate.isSupported(locale)
          ? locale
          : const Locale('en'),
    );
    return operation == 'import' ? l10n.importCancelled : l10n.restoreCancelled;
  }
}
