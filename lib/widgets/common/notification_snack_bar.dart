// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/widgets/common/unified_notification_service.dart';

/// يبني محتوى الـ SnackBar لخدمة الإشعارات
class NotificationSnackBar {
  /// بناء محتوى الإشعار الرئيسي
  static Widget buildContent(
    BuildContext context,
    NotificationConfig config,
    ScaffoldMessengerState messenger,
  ) {
    return Row(
      children: [
        Icon(
          getIcon(config.type),
          color: Colors.white,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            config.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (config.actionLabel != null && config.onAction != null)
          buildActionButton(config, messenger),
        if (config.dismissible && config.actionLabel == null)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
            onPressed: () => messenger.hideCurrentSnackBar(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  /// بناء زر الإجراء مع المؤقت الدائري
  static Widget buildActionButton(
    NotificationConfig config,
    ScaffoldMessengerState messenger,
  ) {
    if (config.showProgress) {
      if (config.executedEarlyNotifier != null) {
        return ValueListenableBuilder<bool>(
          valueListenable: config.executedEarlyNotifier!,
          builder: (context, executedEarly, _) {
            if (executedEarly) {
              return SizedBox(
                width: 40,
                height: 40,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (_, v, __) => CircularProgressIndicator(
                    value: v,
                    strokeWidth: 2.5,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              );
            }
            return buildProgressWithUndo(config, messenger);
          },
        );
      }
      return buildProgressWithUndo(config, messenger);
    } else {
      return TextButton(
        onPressed: () {
          messenger.hideCurrentSnackBar();
          config.onAction?.call();
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(
          config.actionLabel!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
  }

  /// progress دائري مع زر تراجع
  static Widget buildProgressWithUndo(
    NotificationConfig config,
    ScaffoldMessengerState messenger,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: config.duration,
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
            messenger.hideCurrentSnackBar();
            config.onAction?.call();
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  /// لون خلفية الإشعار حسب النوع
  static Color getBackgroundColor(NotificationType type, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case NotificationType.success:
        return isDark ? const Color(0xFF2E7D32) : const Color(0xFF43A047);
      case NotificationType.error:
        return isDark ? const Color(0xFFC62828) : const Color(0xFFE53935);
      case NotificationType.warning:
        return isDark ? const Color(0xFFEF6C00) : const Color(0xFFFB8C00);
      case NotificationType.info:
        return isDark ? const Color(0xFF1565C0) : const Color(0xFF1E88E5);
    }
  }

  /// أيقونة الإشعار حسب النوع
  static IconData getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
    }
  }
}
