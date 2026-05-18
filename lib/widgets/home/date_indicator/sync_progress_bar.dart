// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:sinan_note/services/sync/cloud_sync_gateway.dart';

/// شريط موحّد للسحب والتحديث والمزامنة
class SyncProgressBar extends StatelessWidget {
  final Widget child;
  final bool showLabelOnly;
  final ValueNotifier<double>? pullDistanceNotifier;
  final ValueNotifier<bool>? isRefreshingNotifier;

  static const double _threshold = 80.0;

  const SyncProgressBar({
    super.key,
    required this.child,
    this.showLabelOnly = false,
    this.pullDistanceNotifier,
    this.isRefreshingNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final colorScheme = Theme.of(context).colorScheme;

    // Priority 1: Google Drive syncing
    return ValueListenableBuilder<bool>(
      valueListenable: CloudSyncGateway.isSyncing,
      builder: (context, syncing, _) {
        if (syncing) {
          return _Bar(
            color: colorScheme.primary,
            label: isAr ? 'جارٍ المزامنة...' : 'Syncing...',
          );
        }

        // Priority 2: Refreshing or pulling
        if (isRefreshingNotifier != null) {
          return ValueListenableBuilder<bool>(
            valueListenable: isRefreshingNotifier!,
            builder: (context, refreshing, _) {
              if (refreshing) {
                return _Bar(
                  color: colorScheme.primary,
                  label: isAr ? 'جارٍ التحديث...' : 'Refreshing...',
                );
              }
              return _buildPull(context, colorScheme, isAr);
            },
          );
        }

        return _buildPull(context, colorScheme, isAr);
      },
    );
  }

  Widget _buildPull(BuildContext context, ColorScheme colorScheme, bool isAr) {
    if (pullDistanceNotifier == null) {
      if (showLabelOnly) return const SizedBox.shrink();
      return child;
    }

    return ValueListenableBuilder<double>(
      valueListenable: pullDistanceNotifier!,
      builder: (context, distance, _) {
        if (distance <= 0) {
          if (showLabelOnly) return const SizedBox.shrink();
          return child;
        }
        final progress = (distance / _threshold).clamp(0.0, 1.0);
        final ready = progress >= 1.0;

        // نفس شكل شريط التحديث/المزامنة لكن مع تقدم
        return _Bar(
          color: ready ? colorScheme.primary : colorScheme.onSurfaceVariant,
          label: ready
              ? (isAr ? 'أطلق للتحديث' : 'Release to refresh')
              : (isAr ? 'اسحب للتحديث' : 'Pull to refresh'),
          progress: progress,
          spinning: ready,
        );
      },
    );
  }
}

/// شريط موحّد: أيقونة دوارة + نص + شريط تقدم أسفله
class _Bar extends StatelessWidget {
  final Color color;
  final String label;
  final double? progress; // null = indeterminate
  final bool spinning;

  const _Bar({
    required this.color,
    required this.label,
    this.progress,
    this.spinning = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Stack(
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: spinning
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                          value: progress == null ? null : null,
                        )
                      : CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                          value: progress,
                        ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: progress == null || spinning
                ? LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: color.withValues(alpha: 0.6),
                  )
                : LinearProgressIndicator(
                    value: progress,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: color.withValues(alpha: 0.6),
                  ),
          ),
        ],
      ),
    );
  }
}

