// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'settings_screen.dart';

/// نسخة Responsive من SettingsScreen
/// 
/// على الشاشات الكبيرة (>= 1000px):
/// - يعرض الأقسام في Grid (2 أعمدة)
/// - تخطيط أوسع ومريح للعين
/// 
/// على الشاشات الصغيرة (< 1000px):
/// - يعرض SettingsScreen التقليدي
class SettingsScreenResponsive extends StatelessWidget {
  const SettingsScreenResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint: 1000px للديسكتوب
        if (constraints.maxWidth >= 1000) {
          return const SettingsScreen(isDesktopLayout: true);
        }
        return const SettingsScreen();
      },
    );
  }
}
