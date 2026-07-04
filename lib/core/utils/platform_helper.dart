// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// نوع العرض — يحدد أي Layout يُستخدم
/// ═══════════════════════════════════════════════════════════════════════════
enum DisplayMode {
  /// هاتف عادي أو نافذة مصغّرة — واجهة واحدة
  phone,

  /// هاتف مطوي (شاشة داخلية مربعة مفتوحة) — واجهة هاتف أوسع
  foldableOpen,

  /// تابلت أفقي — Master-Detail
  tablet,

  /// Desktop (Windows/Mac/Linux) — Master-Detail دائماً
  desktop,
}

/// ═══════════════════════════════════════════════════════════════════════════
/// Helper class للتحقق من نوع الجهاز والتخطيط المناسب
///
/// **آلية الكشف (بالترتيب):**
/// 1. Platform — Desktop يُعرف فوراً
/// 2. DisplayFeatures API — كشف hinge/fold = مطوي مفتوح
/// 3. Physical vs Window size — كشف النافذة المصغرة (split/floating)
/// 4. Aspect ratio + shortestSide — تفريق تابلت من هاتف
/// ═══════════════════════════════════════════════════════════════════════════
class PlatformHelper {
  // ─── Platform checks ─────────────────────────────────────────────────

  /// Desktop حقيقي (Linux/Windows/macOS)
  static bool get isDesktopPlatform {
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }

  /// Mobile (Android/iOS)
  static bool get isMobilePlatform {
    return Platform.isAndroid || Platform.isIOS;
  }

  // ─── Display Mode Detection ──────────────────────────────────────────

  /// يحدد نوع العرض الحالي بناءً على كل الإشارات المتاحة
  static DisplayMode getDisplayMode(BuildContext context) {
    // 1. Desktop platform = desktop دائماً
    if (isDesktopPlatform) return DisplayMode.desktop;

    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;

    // 2. كشف النافذة المصغرة (split screen / floating window)
    //    إذا النافذة أصغر بكثير من الشاشة الفيزيائية = مصغّر → phone دائماً
    if (_isWindowedMode(context)) {
      return DisplayMode.phone;
    }

    // 3. كشف المطويات عبر DisplayFeatures API
    //    وجود hinge أو fold = جهاز مطوي مفتوح حالياً
    if (_hasFoldFeature(mediaQuery)) {
      return DisplayMode.foldableOpen;
    }

    // 4. كشف الشاشة المربعة بدون hinge (بعض المطويات لا تُبلّغ عن hinge)
    //    Android + shortestSide >= 500 + aspectRatio قريب من 1 = مطوي مفتوح
    if (Platform.isAndroid) {
      final aspectRatio = size.width / size.height;
      final isSquarish = aspectRatio > 0.85 && aspectRatio < 1.18;
      if (isSquarish && size.shortestSide >= 500 && size.shortestSide < 800) {
        return DisplayMode.foldableOpen;
      }
    }

    // 5. تابلت — shortestSide كبير + عرض كافٍ
    //    نشترط width >= 800 لمنع التابلت portrait من استخدام desktop layout
    final isTabletSize = size.shortestSide >= 600;
    if (isTabletSize && size.width >= 800) {
      return DisplayMode.tablet;
    }

    // 6. الباقي = هاتف
    return DisplayMode.phone;
  }

  /// هل يجب استخدام Desktop/Master-Detail Layout؟
  static bool shouldUseDesktopLayout(BuildContext context,
      {double breakpoint = 600}) {
    final mode = getDisplayMode(context);
    return mode == DisplayMode.desktop ||
        mode == DisplayMode.tablet ||
        mode == DisplayMode.foldableOpen;
  }

  /// هل الجهاز في وضع نافذة مصغرة (split screen / floating / picture-in-picture)
  static bool isInWindowedMode(BuildContext context) {
    return _isWindowedMode(context);
  }

  /// هل الجهاز مطوي مفتوح حالياً
  static bool isFoldableOpen(BuildContext context) {
    final mode = getDisplayMode(context);
    return mode == DisplayMode.foldableOpen;
  }

  // ─── Legacy helpers (backward compatible) ────────────────────────────

  /// التحقق من أن الجهاز هو موبايل صغير (ليس تابلت)
  static bool isMobilePhone(BuildContext context) {
    if (!isMobilePlatform) return false;
    final mode = getDisplayMode(context);
    return mode == DisplayMode.phone || mode == DisplayMode.foldableOpen;
  }

  /// التحقق من أن الجهاز هو تابلت
  static bool isTablet(BuildContext context) {
    if (!isMobilePlatform) return false;
    final mode = getDisplayMode(context);
    return mode == DisplayMode.tablet;
  }

  /// هل العرض الحالي يعتبر "عريض" بما يكفي لعرض عناصر إضافية
  /// (مثل dialog بدل bottom sheet, أو constraints على bottom sheet)
  /// يختلف عن shouldUseDesktopLayout — هذا للـ UI التفصيلي
  /// المطوي المفتوح + تابلت + desktop = عريض
  static bool isWideDisplay(BuildContext context) {
    if (isDesktopPlatform) return true;
    final mode = getDisplayMode(context);
    return mode == DisplayMode.tablet || mode == DisplayMode.foldableOpen;
  }

  // ─── Orientation lock ────────────────────────────────────────────────

  /// قفل اتجاه الشاشة للموبايل فقط (Portrait)
  /// يسمح بالتدوير للتابلت والديسكتوب والمطوي
  static Future<void> lockOrientationForMobile(BuildContext context) async {
    final mode = getDisplayMode(context);
    if (mode == DisplayMode.phone) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// إلغاء قفل الاتجاه
  static Future<void> unlockOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // ─── Private helpers ─────────────────────────────────────────────────

  /// كشف النافذة المصغرة عبر مقارنة حجم الشاشة الفيزيائية بحجم النافذة
  static bool _isWindowedMode(BuildContext context) {
    if (!isMobilePlatform) return false;

    try {
      final view = View.of(context);
      final physicalSize = view.display.size;
      final devicePixelRatio = view.devicePixelRatio;
      final windowSize = MediaQuery.of(context).size;

      // حجم الشاشة الفيزيائية بالوحدات المنطقية
      final physicalLogicalWidth = physicalSize.width / devicePixelRatio;
      final physicalLogicalHeight = physicalSize.height / devicePixelRatio;

      // إذا النافذة أصغر بنسبة ملحوظة (> 20%) من الشاشة = مصغّر
      final widthRatio = windowSize.width / physicalLogicalWidth;
      final heightRatio = windowSize.height / physicalLogicalHeight;

      // split screen عادة = 50% من أحد الأبعاد
      // floating window = أصغر من 80% في كلا البعدين
      if (widthRatio < 0.75 && heightRatio < 0.75) {
        return true; // floating window
      }

      // split screen أفقي — العرض نصف تقريباً لكن الارتفاع كامل
      // لا نعتبره windowed إذا كان split عادي — نتركه للمنطق العادي
      // فقط إذا كلا البعدين صغيرين جداً
    } catch (_) {
      // View.of قد يفشل في بعض الحالات — نتجاهل
    }
    return false;
  }

  /// كشف وجود hinge أو fold عبر MediaQuery.displayFeatures
  static bool _hasFoldFeature(MediaQueryData mediaQuery) {
    final features = mediaQuery.displayFeatures;
    if (features.isEmpty) return false;

    for (final feature in features) {
      if (feature.type == ui.DisplayFeatureType.hinge ||
          feature.type == ui.DisplayFeatureType.fold) {
        return true;
      }
    }
    return false;
  }
}
