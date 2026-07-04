// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/screens/sync/google_drive_screen.dart';

/// نسخة Responsive من GoogleDriveScreen
///
/// على الشاشات الكبيرة (Desktop/Tablet/Foldable مفتوح):
/// - يعرض البطاقات في Grid (2 أعمدة)
/// - تخطيط أوسع ومريح للعين
///
/// على الشاشات الصغيرة (هاتف عادي):
/// - يعرض GoogleDriveScreen التقليدي
class GoogleDriveScreenResponsive extends StatelessWidget {
  const GoogleDriveScreenResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.shouldUseDesktopLayout(context)) {
      return const GoogleDriveScreen(isDesktopLayout: true);
    }
    return const GoogleDriveScreen();
  }
}
