// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class ApexEditorHeader extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final String title;
  final bool isLocked;
  final bool hasHistory;
  final VoidCallback onHistoryTap;
  final VoidCallback onSaveTap;
  final VoidCallback? onBackTap;
  final bool hasReminder;
  final VoidCallback? onReminderTap;
  final VoidCallback? onTitleTap;

  const ApexEditorHeader({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.title,
    required this.isLocked,
    required this.hasHistory,
    required this.onHistoryTap,
    required this.onSaveTap,
    this.hasReminder = false,
    this.onReminderTap,
    this.onTitleTap,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
            bottom:
                BorderSide(color: textColor.withValues(alpha: 0.08), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 24),
              onPressed: onBackTap ?? () => Navigator.pop(context),
              splashRadius: 24,
            ),
            Expanded(
              child: GestureDetector(
                onTap: onTitleTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onTitleTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit,
                        size: 14,
                        color: textColor.withValues(alpha: 0.4),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            if (onReminderTap != null)
              IconButton(
                icon: Icon(
                  hasReminder
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: hasReminder
                      ? Colors.orange
                      : textColor.withValues(alpha: 0.7),
                  size: 22,
                ),
                onPressed: onReminderTap,
                splashRadius: 24,
                tooltip: 'تذكير',
              ),
            if (hasHistory)
              IconButton(
                icon: Icon(Icons.history_rounded, color: textColor, size: 22),
                onPressed: onHistoryTap,
                splashRadius: 24,
              ),
            IconButton(
              icon: Icon(Icons.check_rounded, color: textColor, size: 24),
              onPressed: onSaveTap,
              splashRadius: 24,
            ),
          ],
        ),
      ),
    );
  }
}
