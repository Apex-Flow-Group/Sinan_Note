// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// Widget رئيسي يحدد أي Layout يجب عرضه بناءً على حجم الشاشة
/// 
/// يستخدم LayoutBuilder لقياس عرض الشاشة المتاح ويختار بين:
/// - mobileLayout: للشاشات الصغيرة (< 600px) - Navigation التقليدي
/// - masterDetailsLayout: للشاشات الكبيرة (>= 600px) - عرض Master-Details
/// 
/// يستجيب تلقائياً لتغييرات حجم الشاشة (مثل تدوير الجهاز أو تغيير حجم النافذة)
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
        // إذا كان عرض الشاشة >= breakpoint، نعرض Master-Details Layout
        if (constraints.maxWidth >= breakpoint) {
          return masterDetailsLayout;
        }
        // وإلا نعرض Mobile Layout التقليدي
        return mobileLayout;
      },
    );
  }
}
