// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/core/theme/app_theme.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:flutter/material.dart';

/// يُغلّف أي شريط ويضيف LinearProgressIndicator + نص المزامنة أسفله
class SyncProgressBar extends StatelessWidget {
  final Widget child;
  final bool showLabelOnly;
  final ValueNotifier<double>? pullDistanceNotifier;

  static const double _threshold = 80.0;

  const SyncProgressBar({
    super.key,
    required this.child,
    this.showLabelOnly = false,
    this.pullDistanceNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: GoogleDriveService.isSyncing,
      builder: (context, syncing, _) {
        if (syncing) {
          return Container(
            height: 40,
            color: colorScheme.primaryContainer.withValues(alpha: 0.35),
            child: Stack(
              children: [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? 'جارٍ المزامنة...' : 'Syncing...',
                        style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          );
        }

        if (pullDistanceNotifier != null) {
          return ValueListenableBuilder<double>(
            valueListenable: pullDistanceNotifier!,
            builder: (context, distance, _) {
              if (distance <= 0) {
                if (showLabelOnly) return const SizedBox.shrink();
                return child;
              }
              final progress = (distance / _threshold).clamp(0.0, 1.0);
              final ready = progress >= 1.0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: 40,
                color: ready
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : AppTheme.secondaryBackground(colorScheme),
                child: Stack(
                  children: [
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedRotation(
                            turns: progress * 0.5,
                            duration: const Duration(milliseconds: 100),
                            child: Icon(
                              ready ? Icons.refresh_rounded : Icons.arrow_downward_rounded,
                              size: 13,
                              color: ready ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ready
                                ? (isAr ? 'أطلق للتحديث' : 'Release to refresh')
                                : (isAr ? 'اسحب للتحديث' : 'Pull to refresh'),
                            style: TextStyle(
                              fontSize: 12,
                              color: ready ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              fontWeight: ready ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        color: (ready ? colorScheme.primary : colorScheme.secondary).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        if (showLabelOnly) return const SizedBox.shrink();
        return child;
      },
    );
  }
}
