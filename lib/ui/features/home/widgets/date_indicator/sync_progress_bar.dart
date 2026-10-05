// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/theme/app_colors.dart';
import 'package:sinan_note/ui/features/sync/view_models/sync_view_model.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // Priority 1: Google Drive syncing
    return Selector<SyncViewModel, bool>(
      selector: (_, sync) => sync.isSyncing,
      builder: (context, syncing, _) {
        if (syncing) {
          return _Bar(
            color: colorScheme.primary,
            label: l10n.syncingProgress,
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
                  label: l10n.refreshing,
                );
              }
              return _buildPull(context, colorScheme, l10n);
            },
          );
        }

        return _buildPull(context, colorScheme, l10n);
      },
    );
  }

  Widget _buildPull(
      BuildContext context, ColorScheme colorScheme, AppLocalizations l10n) {
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
          label: ready ? l10n.releaseToRefresh : l10n.pullToRefresh,
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
                  style: context.text.labelMedium?.copyWith(
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
