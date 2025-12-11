// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class SelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback onPin;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final bool isDark;
  final bool allPinned;

  const SelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.onClear,
    required this.onPin,
    required this.onArchive,
    required this.onDelete,
    required this.onShare,
    required this.isDark,
    this.allPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClear,
            tooltip: 'Clear',
          ),
          Expanded(
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(allPinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: onPin,
            tooltip: allPinned ? 'Unpin' : 'Pin',
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: onArchive,
            tooltip: 'Archive',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: onShare,
            tooltip: 'Share',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
