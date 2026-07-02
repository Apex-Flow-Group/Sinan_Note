// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// Base widget موحد لكل bottom sheets في التطبيق.
///
/// يوفر:
/// - handle bar موحد
/// - header موحد (أيقونة + عنوان)
/// - shape وإعدادات showModalBottomSheet موحدة
///
/// الاستخدام:
/// ```dart
/// AppBottomSheet.show(
///   context,
///   child: AppBottomSheet(
///     title: 'عنوان',
///     titleIcon: Icons.filter_list_rounded,
///     child: Column(...),
///   ),
/// );
/// ```
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final Widget child;
  final bool scrollable;

  /// أزرار تظهر في يمين الـ header (مثل أزرار الإغلاق والحفظ)
  final List<Widget>? actions;

  const AppBottomSheet({
    super.key,
    this.title,
    this.titleIcon,
    required this.child,
    this.scrollable = true,
    this.actions,
  });

  /// يفتح bottom sheet بإعدادات موحدة
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    bool isScrollControlled = false,
    bool useSafeArea = true,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      constraints: isDesktop ? const BoxConstraints(maxWidth: 480) : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ── Header (اختياري) ─────────────────────────────
                if (title != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        if (titleIcon != null) ...[
                          Icon(titleIcon, size: 22),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (actions != null) ...actions!,
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (title != null) const Divider(height: 1),

          // ── المحتوى ──────────────────────────────────────────────
          if (scrollable)
            Flexible(child: SingleChildScrollView(child: child))
          else
            child,
        ],
      ),
    );
  }
}
