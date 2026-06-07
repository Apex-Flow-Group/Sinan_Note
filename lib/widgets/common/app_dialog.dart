// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';


/// يفتح الشاشة كـ Dialog عائم على الشاشات الكبيرة (>= 800px)
/// وكـ push عادي على الشاشات الصغيرة
class AppDialog {
  static Future<T?> show<T>(
    BuildContext context,
    Widget screen, {
    double maxWidth = 720,
    double maxHeight = 860,
  }) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      return showGeneralDialog<T>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: screen,
            ),
          ),
        ),
        transitionBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      );
    }

    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

