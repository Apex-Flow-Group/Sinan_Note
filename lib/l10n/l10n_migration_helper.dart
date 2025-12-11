// Copyright © 2025 Apex Flow Group. All rights reserved.
// Migration Helper: للانتقال التدريجي من النظام القديم إلى ARB

import 'package:flutter/widgets.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';

/// Helper class للحصول على AppLocalizations بسهولة
class L10nHelper {
  /// الحصول على AppLocalizations من BuildContext
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context)!;
  }

  /// التحقق من اللغة الحالية
  static bool isArabic(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  /// التحقق من اللغة الحالية
  static bool isEnglish(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en';
  }

  /// الحصول على كود اللغة الحالية
  static String currentLanguage(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }
}

/// Extension على BuildContext لسهولة الوصول
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  String get languageCode => Localizations.localeOf(this).languageCode;
  bool get isArabic => languageCode == 'ar';
  bool get isEnglish => languageCode == 'en';
}
