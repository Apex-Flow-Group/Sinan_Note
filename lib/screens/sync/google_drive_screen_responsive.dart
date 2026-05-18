// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/screens/sync/google_drive_screen.dart';

/// نسخة Responsive من GoogleDriveScreen
/// 
/// على الشاشات الكبيرة (>= 900px):
/// - يعرض البطاقات في Grid (2 أعمدة)
/// - تخطيط أوسع ومريح للعين
/// 
/// على الشاشات الصغيرة (< 900px):
/// - يعرض GoogleDriveScreen التقليدي
class GoogleDriveScreenResponsive extends StatelessWidget {
  const GoogleDriveScreenResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint: 900px للديسكتوب
        if (constraints.maxWidth >= 900) {
          return const _GoogleDriveDesktopLayout();
        }
        return const GoogleDriveScreen();
      },
    );
  }
}

/// تخطيط الديسكتوب لشاشة Google Drive
class _GoogleDriveDesktopLayout extends StatelessWidget {
  const _GoogleDriveDesktopLayout();

  @override
  Widget build(BuildContext context) {
    return const GoogleDriveScreen(isDesktopLayout: true);
  }
}

