// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/utils/platform_helper.dart';
import 'package:flutter/material.dart';

/// Widget رئيسي يحدد أي Layout يجب عرضه بناءً على نوع الجهاز وحجم الشاشة
/// 
/// يستخدم Platform + LayoutBuilder للاختيار بين:
/// - mobileLayout: للأجهزة المحمولة (Android/iOS) - Navigation التقليدي
/// - masterDetailsLayout: لأجهزة Desktop (Linux/Windows/macOS) مع عرض >= 600px
/// 
/// يمنع تحول الموبايل إلى Desktop Layout عند التدوير
class ResponsiveLayoutWrapper extends StatelessWidget {
  /// Layout للشاشات الصغيرة (Mobile)
  final Widget mobileLayout;
  
  /// Layout للشاشات الكبيرة (Tablet/Desktop) - Master-Details
  final Widget masterDetailsLayout;
  
  /// نقطة التحول بين الشاشات الصغيرة والكبيرة (بالبكسل)
  /// القيمة الافتراضية: 600 بكسل (Material Design breakpoint)
  final double breakpoint;

  const ResponsiveLayoutWrapper({
    super.key,
    required this.mobileLayout,
    required this.masterDetailsLayout,
    this.breakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldUseDesktop = PlatformHelper.shouldUseDesktopLayout(
          context,
          breakpoint: breakpoint,
        );

        if (shouldUseDesktop) {
          return masterDetailsLayout;
        }
        return mobileLayout;
      },
    );
  }
}
