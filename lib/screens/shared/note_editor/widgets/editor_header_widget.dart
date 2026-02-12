// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../widgets/editor/apex_editor_header.dart';

/// Extracted header widget for note editor
class EditorHeaderWidget extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final String title;
  final bool isLocked;
  final bool hasHistory;
  final bool hasReminder;
  final VoidCallback onReminderTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onTitleTap;
  final VoidCallback onSaveTap;

  const EditorHeaderWidget({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.title,
    required this.isLocked,
    required this.hasHistory,
    required this.hasReminder,
    required this.onReminderTap,
    required this.onHistoryTap,
    required this.onTitleTap,
    required this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ApexEditorHeader(
                backgroundColor: backgroundColor.withValues(alpha: 0.7),
                textColor: textColor,
                title: title,
                isLocked: isLocked,
                hasHistory: hasHistory,
                hasReminder: hasReminder,
                onReminderTap: () {
                  HapticFeedback.mediumImpact();
                  onReminderTap();
                },
                onHistoryTap: onHistoryTap,
                onTitleTap: () {
                  HapticFeedback.lightImpact();
                  onTitleTap();
                },
                onSaveTap: () async {
                  HapticFeedback.mediumImpact();
                  onSaveTap();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
