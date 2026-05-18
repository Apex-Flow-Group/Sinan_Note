// Copyright © 2025 Apex Flow Group. All rights reserved.



import 'package:shared_preferences/shared_preferences.dart';

class RateLimiterService {
  static const String _keyAttempts = 'pin_attempts';
  static const String _keyLockUntil = 'pin_lock_until';
  static const String _keyLastAttempt = 'pin_last_attempt';

  static const int _maxAttempts = 5;
  static const int _lockDuration1 = 5 * 60; // 5 دقائق بالثواني
  static const int _lockDuration2 = 15 * 60; // 15 دقيقة
  static const int _lockDuration3 = 60 * 60; // ساعة

  /// التحقق من حالة القفل الحالية
  /// يرجع null إذا لم يكن مقفلاً، أو الوقت المتبقي بالثواني
  static Future<int?> getRemainingLockTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntil = prefs.getInt(_keyLockUntil);
    
    if (lockUntil == null) return null;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = lockUntil - now;
    
    if (remaining <= 0) {
      // انتهى وقت القفل - إعادة تعيين
      await _reset();
      return null;
    }
    
    return remaining;
  }

  /// تسجيل محاولة فاشلة
  /// يرجع الوقت المتبقي للقفل (بالثواني) أو null إذا لم يتم القفل
  static Future<int?> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    
    // التحقق من القفل الحالي
    final lockTime = await getRemainingLockTime();
    if (lockTime != null) return lockTime;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final attempts = (prefs.getInt(_keyAttempts) ?? 0) + 1;
    
    await prefs.setInt(_keyAttempts, attempts);
    await prefs.setInt(_keyLastAttempt, now);
    
    if (attempts >= _maxAttempts) {
      // تحديد مدة القفل بناءً على عدد مرات القفل السابقة
      final lockDuration = _calculateLockDuration(attempts);
      final lockUntil = now + lockDuration;
      
      await prefs.setInt(_keyLockUntil, lockUntil);
      return lockDuration;
    }
    
    return null;
  }

  /// حساب مدة القفل بناءً على عدد المحاولات
  static int _calculateLockDuration(int attempts) {
    if (attempts >= _maxAttempts * 3) {
      return _lockDuration3; // ساعة
    } else if (attempts >= _maxAttempts * 2) {
      return _lockDuration2; // 15 دقيقة
    } else {
      return _lockDuration1; // 5 دقائق
    }
  }

  /// إعادة تعيين العداد بعد محاولة ناجحة
  static Future<void> reset() async {
    await _reset();
  }

  static Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAttempts);
    await prefs.remove(_keyLockUntil);
    await prefs.remove(_keyLastAttempt);
  }

  /// الحصول على عدد المحاولات المتبقية
  static Future<int> getRemainingAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_keyAttempts) ?? 0;
    return (_maxAttempts - attempts).clamp(0, _maxAttempts);
  }

  /// تنسيق الوقت المتبقي للعرض
  static String formatRemainingTime(int seconds) {
    if (seconds >= 3600) {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return secs > 0 ? '${minutes}m ${secs}s' : '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }
}

