// Copyright © 2025 Apex Flow Group. All rights reserved.
//
// مصدر واحد لكل أحجام الخطوط في التطبيق.
// لا يُسمح باستخدام fontSize ثابت في أي مكان آخر.

class AppFontSize {
  AppFontSize._();

  // ── أحجام أساسية ──────────────────────────────────────────────────────────
  static const double xs = 11.0; // تواريخ، labels صغيرة
  static const double sm = 13.0; // subtitle، hints
  static const double md = 15.0; // نص عادي، قوائم
  static const double lg = 17.0; // نص المحرر والعارض
  static const double xl = 20.0; // عناوين كبيرة
  static const double xxl = 24.0; // عناوين رئيسية

  // ── مختصرات دلالية ────────────────────────────────────────────────────────
  static const double noteBody = lg; // نص الملاحظة في المحرر والعارض
  static const double noteTitle = xl; // عنوان الملاحظة (checklist)
  static const double cardBody = md; // نص الكارد في الرئيسية
  static const double cardTitle = md; // عنوان الكارد
  static const double label = sm; // labels وsubtitles
  static const double timestamp = xs; // التواريخ والأوقات
}

/// حساب ارتفاع السطر الديناميكي بناءً على حجم الخط ونوعه
class AppLineHeight {
  AppLineHeight._();

  /// ارتفاع السطر للنص العادي (paragraph)
  /// يزداد تلقائياً مع تكبير الخط أو استخدام خطوط مخصصة
  static double body(double textScale, String? fontFamily) {
    double base = 1.75;
    if (textScale > 1.0) {
      base += (textScale - 1.0) * 0.3;
    }
    if (fontFamily != null && fontFamily != 'system') {
      base += 0.1;
    }
    return base;
  }

  /// ارتفاع السطر للعناوين (H1/H2)
  /// أقل من النص العادي لأن العناوين كبيرة أصلاً
  static double header(double textScale, String? fontFamily) {
    double base = 1.3;
    if (textScale > 1.0) {
      base += (textScale - 1.0) * 0.2;
    }
    if (fontFamily != null && fontFamily != 'system') {
      base += 0.1;
    }
    return base;
  }

  /// ارتفاع السطر للـ checklist items
  static double checklist(double textScale, String? fontFamily) {
    double base = 1.5;
    if (textScale > 1.0) {
      base += (textScale - 1.0) * 0.25;
    }
    if (fontFamily != null && fontFamily != 'system') {
      base += 0.08;
    }
    return base;
  }
}




