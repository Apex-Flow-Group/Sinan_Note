// Copyright © 2025 Apex Flow Group. All rights reserved.

/// كم محاولة خاطئة تُحتمل قبل القفل، وكم يدوم — يتصاعد ولا يُصفَّر إلا
/// بنجاح.
abstract final class AttemptPolicy {
  static const maxAttempts = 5;

  /// مدة القفل بعد [failures] محاولة فاشلة متتالية، أو null.
  static Duration? lockAfter(int failures) {
    if (failures < maxAttempts) return null;
    if (failures >= maxAttempts * 3) return const Duration(hours: 1);
    if (failures >= maxAttempts * 2) return const Duration(minutes: 15);
    return const Duration(minutes: 5);
  }
}
