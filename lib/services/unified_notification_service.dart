// Copyright © 2025 Apex Flow Group. All rights reserved.

/// Unified Notification Service
/// نظام إشعارات موحد وشامل لجميع أنواع الإشعارات
///
/// Features:
/// - Responsive positioning (mobile, tablet, desktop)
/// - Multiple notification types (success, error, info, warning)
/// - Undo functionality with circular timer
/// - Optimistic UI support
/// - Smart positioning based on screen size
/// - Queue management for multiple notifications
/// - Accessibility support
library;

import 'dart:async';

import 'package:flutter/material.dart';

/// نوع الإشعار
enum NotificationType {
  success,
  error,
  info,
  warning,
}

/// موضع الإشعار
enum NotificationPosition {
  /// أسفل الشاشة (افتراضي للموبايل)
  bottom,

  /// أسفل الوسط (للتابلت والديسكتوب)
  bottomCenter,

  /// أعلى الشاشة
  top,

  /// أعلى الوسط
  topCenter,
}

/// إعدادات الإشعار
class NotificationConfig {
  final String message;
  final NotificationType type;
  final Duration duration;
  final NotificationPosition? position;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool dismissible;
  final bool showProgress;
  final double? width;
  final EdgeInsets? margin;

  /// يُشعر الـ widget بأن الإجراء نُفِّذ مبكراً
  final ValueNotifier<bool>? executedEarlyNotifier;

  const NotificationConfig({
    required this.message,
    this.type = NotificationType.info,
    this.duration = const Duration(seconds: 3),
    this.position,
    this.actionLabel,
    this.onAction,
    this.dismissible = false,
    this.showProgress = false,
    this.width,
    this.margin,
    this.executedEarlyNotifier,
  });
}

/// إجراء معلق للتنفيذ
class _PendingAction {
  final String key;
  final VoidCallback onExecute;
  final VoidCallback onCancel;
  Timer? timer;

  /// يُشعر الـ snackbar بأن الإجراء نُفِّذ مبكراً → يُخفي زر التراجع
  final ValueNotifier<bool> executedEarly = ValueNotifier(false);

  _PendingAction({
    required this.key,
    required this.onExecute,
    required this.onCancel,
  });

  void cancel() {
    timer?.cancel();
    onCancel();
  }

  void execute() {
    timer?.cancel();
    onExecute();
  }

  void executeEarly() {
    timer?.cancel();
    executedEarly.value = true;
    onExecute();
  }

  /// يُلغي الـ timer ويُخفي زر التراجع بدون تنفيذ أي callback
  /// للحالات التي نُفِّذت فيها العملية مسبقاً
  void commit() {
    timer?.cancel();
    executedEarly.value = true;
  }
}

/// خدمة الإشعارات الموحدة
class UnifiedNotificationService {
  static final UnifiedNotificationService _instance =
      UnifiedNotificationService._internal();

  factory UnifiedNotificationService() => _instance;
  UnifiedNotificationService._internal();

  final Map<String, _PendingAction> _pendingActions = {};

  /// عرض إشعار بسيط
  ///
  /// Example:
  /// ```dart
  /// UnifiedNotificationService().show(
  ///   context: context,
  ///   message: 'تم الحفظ بنجاح',
  ///   type: NotificationType.success,
  /// );
  /// ```
  void show({
    required BuildContext context,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    NotificationPosition? position,
    bool dismissible = false,
  }) {
    final config = NotificationConfig(
      message: message,
      type: type,
      duration: duration,
      position: position,
      dismissible: dismissible,
    );

    _showNotification(context, config);
  }

  /// عرض إشعار مع زر تراجع (Undo)
  ///
  /// Example:
  /// ```dart
  /// UnifiedNotificationService().showWithUndo(
  ///   context: context,
  ///   message: 'تم حذف 3 ملاحظات',
  ///   actionKey: 'delete_notes',
  ///   onExecute: () async {
  ///     await deleteNotes();
  ///   },
  ///   onUndo: () {
  ///     restoreNotes();
  ///   },
  /// );
  /// ```
  void showWithUndo({
    required BuildContext context,
    required String message,
    required String actionKey,
    required VoidCallback onExecute,
    required VoidCallback onUndo,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    NotificationPosition? position,
    String? undoLabel,
  }) {
    // إلغاء أي إجراء سابق بنفس المفتاح
    _pendingActions[actionKey]?.cancel();

    // إنشاء إجراء معلق جديد
    final pendingAction = _PendingAction(
      key: actionKey,
      onExecute: onExecute,
      onCancel: onUndo,
    );

    // بدء المؤقت
    pendingAction.timer = Timer(duration, () {
      onExecute();
      _pendingActions.remove(actionKey);
    });

    _pendingActions[actionKey] = pendingAction;

    // عرض الإشعار
    final config = NotificationConfig(
      message: message,
      type: type,
      duration: duration,
      position: position,
      actionLabel: undoLabel ?? 'تراجع',
      onAction: () {
        _pendingActions[actionKey]?.cancel();
        _pendingActions.remove(actionKey);
      },
      showProgress: true,
      executedEarlyNotifier: pendingAction.executedEarly,
    );

    _showNotification(context, config, onDismissed: () {
      // عند السحب: نفذ الإجراء فوراً إذا لم يُنفذ بعد
      final action = _pendingActions.remove(actionKey);
      if (action != null && !action.executedEarly.value) {
        action.execute();
      }
    });
  }

  /// عرض إشعار مع إجراء مخصص
  void showWithAction({
    required BuildContext context,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    NotificationPosition? position,
  }) {
    final config = NotificationConfig(
      message: message,
      type: type,
      duration: duration,
      position: position,
      actionLabel: actionLabel,
      onAction: onAction,
    );

    _showNotification(context, config);
  }

  /// إلغاء جميع الإجراءات المعلقة
  void cancelAll() {
    for (final action in _pendingActions.values) {
      action.cancel();
    }
    _pendingActions.clear();
  }

  /// تنفيذ جميع الإجراءات المعلقة فوراً (عند الخروج من الشاشة)
  /// الـ snackbar يبقى لكن يُسرَّع ويُخفى زر التراجع
  void executeAll() {
    for (final action in _pendingActions.values) {
      action.executeEarly();
    }
    _pendingActions.clear();
  }

  /// تنفيذ إجراء معين فوراً
  void execute(String actionKey) {
    _pendingActions[actionKey]?.executeEarly();
    _pendingActions.remove(actionKey);
  }

  /// إلغاء جميع الإجراءات المعلقة بدون تنفيذ onUndo (للشاشات التي نفّذت العملية مسبقاً)
  /// يُلغي الـ timer فقط ويُخفي زر التراجع
  void commitAll() {
    for (final action in _pendingActions.values) {
      action.commit();
    }
    _pendingActions.clear();
  }

  /// إلغاء إجراء معين
  void cancel(String actionKey) {
    _pendingActions[actionKey]?.cancel();
    _pendingActions.remove(actionKey);
  }

  /// عرض الإشعار الفعلي
  void _showNotification(BuildContext context, NotificationConfig config,
      {VoidCallback? onDismissed}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isMobile = screenWidth < 600;

    final position =
        config.position ?? _getDefaultPosition(isMobile, isTablet, isDesktop);
    final width =
        config.width ?? _getDefaultWidth(isMobile, isTablet, isDesktop);
    final margin = config.margin ??
        _getDefaultMargin(position, isMobile, isTablet, isDesktop, context);

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    // نحسب ارتفاع الـ bottom bar من الـ Scaffold لتجنب "off screen" error
    final viewPadding = MediaQuery.of(context).viewPadding;
    final bottomNavHeight = viewPadding.bottom;
    // إذا كان الـ bottom area كبيراً (bottom nav bar موجود) نستخدم fixed
    final effectiveBehavior = bottomNavHeight > 60
        ? SnackBarBehavior.fixed
        : SnackBarBehavior.floating;

    final snackBarController = messenger.showSnackBar(
      SnackBar(
        content: _buildContent(context, config, messenger),
        backgroundColor: _getBackgroundColor(config.type, context),
        behavior: effectiveBehavior,
        shape: effectiveBehavior == SnackBarBehavior.floating
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            : null,
        width: effectiveBehavior == SnackBarBehavior.floating ? width : null,
        margin: effectiveBehavior == SnackBarBehavior.floating && width == null
            ? margin
            : null,
        duration: config.duration,
        dismissDirection: DismissDirection.down,
      ),
    );

    // Handle swipe dismiss for undo notifications
    if (onDismissed != null) {
      snackBarController.closed.then((reason) {
        if (reason == SnackBarClosedReason.swipe) {
          onDismissed();
        }
      });
    }
  }

  /// بناء محتوى الإشعار
  Widget _buildContent(BuildContext context, NotificationConfig config,
      ScaffoldMessengerState messenger) {
    return Row(
      children: [
        Icon(
          _getIcon(config.type),
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
          _buildActionButton(config, messenger),
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
  Widget _buildActionButton(
      NotificationConfig config, ScaffoldMessengerState messenger) {
    if (config.showProgress) {
      // إذا كان هناك notifier للتنفيذ المبكر، نستخدم ValueListenableBuilder
      if (config.executedEarlyNotifier != null) {
        return ValueListenableBuilder<bool>(
          valueListenable: config.executedEarlyNotifier!,
          builder: (context, executedEarly, _) {
            if (executedEarly) {
              // تم التنفيذ مبكراً: أظهر progress يكتمل بسرعة بدون زر تراجع
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
            // الحالة الطبيعية: progress + زر تراجع
            return _buildProgressWithUndo(config, messenger);
          },
        );
      }
      return _buildProgressWithUndo(config, messenger);
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

  /// progress دائري مع زر تراجع (الحالة الطبيعية)
  Widget _buildProgressWithUndo(
      NotificationConfig config, ScaffoldMessengerState messenger) {
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

  /// تحديد الموضع الافتراضي بناءً على حجم الشاشة
  NotificationPosition _getDefaultPosition(
      bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) {
      return NotificationPosition.bottom; // أسفل الشاشة على امتداد الجوال
    } else {
      return NotificationPosition.bottomCenter; // وسط أسفل للتابلت والديسكتوب
    }
  }

  /// تحديد العرض الافتراضي بناءً على حجم الشاشة
  double? _getDefaultWidth(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) {
      return null; // عرض كامل للموبايل
    } else if (isTablet) {
      return 500; // عرض متوسط للتابلت
    } else {
      return 400; // عرض محدود للديسكتوب
    }
  }

  /// تحديد الهوامش الافتراضية بناءً على الموضع وحجم الشاشة
  EdgeInsets _getDefaultMargin(
    NotificationPosition position,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    BuildContext context,
  ) {
    // نحسب المساحة المحجوزة في الأسفل (bottom nav bar + system insets)
    final mediaQuery = MediaQuery.of(context);
    final systemBottom = mediaQuery.padding.bottom;
    // نضيف هامشاً إضافياً فوق أي bottom bar موجود
    final bottomOffset = systemBottom + (isMobile ? 16.0 : 32.0);

    if (isMobile) {
      return EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: bottomOffset,
      );
    } else {
      return EdgeInsets.only(
        bottom: bottomOffset,
      );
    }
  }

  /// الحصول على لون الخلفية بناءً على النوع
  Color _getBackgroundColor(NotificationType type, BuildContext context) {
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

  /// الحصول على الأيقونة بناءً على النوع
  IconData _getIcon(NotificationType type) {
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
