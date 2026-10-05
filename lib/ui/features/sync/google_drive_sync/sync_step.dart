// Copyright © 2025 Apex Flow Group. All rights reserved.

/// حالات صفحة المزامنة
enum SyncStep {
  /// تسجيل الدخول
  signIn,
  
  /// فحص الحالة
  checking,
  
  /// حل التعارض (conditional - يظهر فقط عند وجود تعارض)
  conflict,
  
  /// جاري المزامنة
  syncing,
  
  /// نجحت المزامنة
  success,
  
  /// خطأ
  error,
}




