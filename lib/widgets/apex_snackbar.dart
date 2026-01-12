// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

enum SnackBarType { success, error, info, warning }

class ApexSnackBar {
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    bool clearPrevious = true,
    bool dismissible = false,
    double opacity = 1.0,
    bool aboveToolbar = false,
  }) {
    if (clearPrevious) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = isDark ? const Color(0xFF2E7D32) : const Color(0xFF43A047);
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        backgroundColor = isDark ? const Color(0xFFC62828) : const Color(0xFFE53935);
        icon = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        backgroundColor = isDark ? const Color(0xFFEF6C00) : const Color(0xFFFB8C00);
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        backgroundColor = isDark ? const Color(0xFF1565C0) : const Color(0xFF1E88E5);
        icon = Icons.info_rounded;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: duration,
                    builder: (context, value, _) {
                      return SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          value: 1.0 - value,
                          strokeWidth: 2.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.white, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      onAction();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            if (dismissible && (actionLabel == null || onAction == null))
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        backgroundColor: backgroundColor.withValues(alpha: opacity),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: aboveToolbar
            ? EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 80 + MediaQuery.of(context).viewInsets.bottom,
              )
            : const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }
}
