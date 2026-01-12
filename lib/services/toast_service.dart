// Copyright © 2025 Apex Flow Group. All rights reserved.

// ============================================================================
// 🎯 Toast Service - Professional Notification System
// ============================================================================
// Version: 3.0.0
// Added: Advanced Optimistic UI with Delayed Execution
// 
// Features:
// - ✅ Circular countdown timer around undo button
// - ✅ Optimistic UI: Hide items immediately, delete after timer
// - ✅ Smart undo: Restore items before database execution
// - ✅ Auto-cleanup: Execute pending actions on timer expiry
// - ✅ Memory efficient: Single timer per action type
// 
// Architecture:
// 1. User triggers action (delete/archive)
// 2. Item hidden from UI immediately (Optimistic)
// 3. Timer starts (3 seconds)
// 4. If user presses undo: Item restored, timer cancelled
// 5. If timer expires: Database operation executed
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';

/// Toast type for different notification styles
enum ToastType { success, error, info, warning }

/// Pending action waiting for execution
class PendingAction {
  final List<int> itemIds;
  final VoidCallback onExecute;
  final VoidCallback onCancel;
  Timer? timer;

  PendingAction({
    required this.itemIds,
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
}

/// Professional Toast Service with Optimistic UI
class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  // Active pending actions by type
  final Map<String, PendingAction> _pendingActions = {};

  /// Show toast with circular countdown and undo functionality
  /// 
  /// Usage:
  /// ```dart
  /// ToastService().showUndoToast(
  ///   context: context,
  ///   message: '3 notes deleted',
  ///   actionKey: 'delete_notes',
  ///   onExecute: () async {
  ///     // Execute actual database deletion
  ///     await notesProvider.deleteNotes(ids);
  ///   },
  ///   onUndo: () {
  ///     // Restore items in UI
  ///     setState(() => hiddenIds.clear());
  ///   },
  /// );
  /// ```
  void showUndoToast({
    required BuildContext context,
    required String message,
    required String actionKey,
    required VoidCallback onExecute,
    required VoidCallback onUndo,
    String undoLabel = 'Undo',
    Duration duration = const Duration(seconds: 3),
    ToastType type = ToastType.info,
  }) {
    // Cancel any existing action with same key
    _pendingActions[actionKey]?.cancel();

    // Create new pending action
    final pendingAction = PendingAction(
      itemIds: [],
      onExecute: onExecute,
      onCancel: onUndo,
    );

    // Start timer for delayed execution
    pendingAction.timer = Timer(duration, () {
      onExecute();
      _pendingActions.remove(actionKey);
    });

    _pendingActions[actionKey] = pendingAction;

    // Show toast
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = _getBackgroundColor(type, isDark);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIcon(type), color: Colors.white, size: 22),
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
            // Circular countdown with undo button
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
                        // ignore: deprecated_member_use
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    _pendingActions[actionKey]?.cancel();
                    _pendingActions.remove(actionKey);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  /// Show simple toast without undo
  void showToast({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = _getBackgroundColor(type, isDark);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIcon(type), color: Colors.white, size: 22),
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
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  /// Cancel all pending actions (call on screen dispose)
  void cancelAll() {
    for (final action in _pendingActions.values) {
      action.cancel();
    }
    _pendingActions.clear();
  }

  /// Cancel specific action
  void cancel(String actionKey) {
    _pendingActions[actionKey]?.cancel();
    _pendingActions.remove(actionKey);
  }

  Color _getBackgroundColor(ToastType type, bool isDark) {
    // Use theme-aware colors instead of hardcoded values
    switch (type) {
      case ToastType.success:
        return isDark ? const Color(0xFF2E7D32) : const Color(0xFF43A047);
      case ToastType.error:
        return isDark ? const Color(0xFFC62828) : const Color(0xFFE53935);
      case ToastType.warning:
        return isDark ? const Color(0xFFEF6C00) : const Color(0xFFFB8C00);
      case ToastType.info:
        return isDark ? const Color(0xFF1565C0) : const Color(0xFF1E88E5);
    }
  }

  IconData _getIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }
}
