// Copyright © 2025 Apex Flow Group. All rights reserved.
//
// مصدر واحد لكل أحجام الخطوط في التطبيق.
// لا يُسمح باستخدام fontSize ثابت في أي مكان آخر.

class AppFontSize {
  AppFontSize._();

  // ── أحجام أساسية ──────────────────────────────────────────────────────────
  static const double xs   = 11.0; // تواريخ، labels صغيرة
  static const double sm   = 13.0; // subtitle، hints
  static const double md   = 15.0; // نص عادي، قوائم
  static const double lg   = 17.0; // نص المحرر والعارض
  static const double xl   = 20.0; // عناوين كبيرة
  static const double xxl  = 24.0; // عناوين رئيسية

  // ── مختصرات دلالية ────────────────────────────────────────────────────────
  static const double noteBody    = lg;   // نص الملاحظة في المحرر والعارض
  static const double noteTitle   = xl;   // عنوان الملاحظة (checklist)
  static const double cardBody    = md;   // نص الكارد في الرئيسية
  static const double cardTitle   = md;   // عنوان الكارد
  static const double label       = sm;   // labels وsubtitles
  static const double timestamp   = xs;   // التواريخ والأوقات
}
