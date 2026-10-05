// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:sinan_note/generated/l10n/app_localizations.dart';

/// نصوص الواجهة بلغة التطبيق لما يعمل خارج شجرة الويدجت: ويدجت الشاشة
/// الرئيسية ونافذة البصمة. تُربط في نقطة التركيب بلغة التطبيق الفعلية؛
/// قبل ذلك (أو في الخلفية) تتبع لغة الجهاز.
abstract final class AppStrings {
  static AppLocalizations Function() _resolve = deviceLanguage;

  static void configure(AppLocalizations Function() resolve) =>
      _resolve = resolve;

  static AppLocalizations get current => _resolve();

  static AppLocalizations deviceLanguage() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return lookupAppLocalizations(Locale(code == 'ar' ? 'ar' : 'en'));
  }
}
