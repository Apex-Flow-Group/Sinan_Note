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
        backgroundColor =
            isDark ? Colors.green.shade700 : Colors.green.shade600;
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        backgroundColor = isDark ? Colors.red.shade700 : Colors.red.shade600;
        icon = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        backgroundColor =
            isDark ? Colors.orange.shade700 : Colors.orange.shade600;
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        backgroundColor = isDark ? Colors.blue.shade700 : Colors.blue.shade600;
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
            if (dismissible)
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
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
