// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/core/widgets/unified_notification_service.dart';

/// يبني محتوى الـ SnackBar لخدمة الإشعارات
class NotificationSnackBar {
  /// بناء محتوى الإشعار الرئيسي
  static Widget buildContent(
    BuildContext context,
    NotificationConfig config,
    ScaffoldMessengerState messenger,
  ) {
    final foreground = getForegroundColor(config.type, context);
    return Row(
      children: [
        Icon(
          getIcon(config.type),
          color: foreground,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            config.message,
            style: context.text.bodyMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (config.actionLabel != null && config.onAction != null)
          buildActionButton(context, config, messenger, foreground),
        if (config.dismissible && config.actionLabel == null)
          IconButton(
            icon: Icon(Icons.close, color: foreground, size: 18),
            onPressed: () => messenger.hideCurrentSnackBar(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  /// بناء زر الإجراء مع المؤقت الدائري
  static Widget buildActionButton(
    BuildContext context,
    NotificationConfig config,
    ScaffoldMessengerState messenger,
    Color foreground,
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
                    backgroundColor: foreground.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                ),
              );
            }
            return buildProgressWithUndo(config, messenger, foreground);
          },
        );
      }
      return buildProgressWithUndo(config, messenger, foreground);
    } else {
      return TextButton(
        onPressed: () {
          messenger.hideCurrentSnackBar();
          config.onAction?.call();
        },
        style: TextButton.styleFrom(
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(
          config.actionLabel!,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  /// progress دائري مع زر تراجع
  static Widget buildProgressWithUndo(
    NotificationConfig config,
    ScaffoldMessengerState messenger,
    Color foreground,
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
                backgroundColor: foreground.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(foreground),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.undo, color: foreground, size: 20),
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
    final colors = context.colors;
    switch (type) {
      case NotificationType.success:
        return colors.success;
      case NotificationType.error:
        return colors.danger;
      case NotificationType.warning:
        return colors.warning;
      case NotificationType.info:
        return colors.info;
    }
  }

  /// لون النص والأيقونات فوق خلفية الإشعار: أيّ طرفي الثيم (السطح أو ما
  /// عليه) أوضح تبايناً مع لون الخلفية.
  static Color getForegroundColor(NotificationType type, BuildContext context) {
    final background = getBackgroundColor(type, context);
    final scheme = context.scheme;
    final backgroundIsDark =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark;
    final surfaceIsDark =
        ThemeData.estimateBrightnessForColor(scheme.surface) == Brightness.dark;
    return backgroundIsDark == surfaceIsDark
        ? scheme.onSurface
        : scheme.surface;
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
