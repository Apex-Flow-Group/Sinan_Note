// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class SmoothSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final Widget child;
  final bool isDark;
  final bool selectionMode;
  final Widget? selectionBar;
  final bool isSearchActive;

  SmoothSearchHeaderDelegate({
    required this.expandedHeight,
    required this.child,
    required this.isDark,
    this.selectionMode = false,
    this.selectionBar,
    this.isSearchActive = false,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95);

    return Material(
      color: bgColor,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: expandedHeight,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selectionMode && selectionBar != null
                ? Container(key: const ValueKey('selection'), child: selectionBar!)
                : Container(key: const ValueKey('search'), child: child),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => expandedHeight;

  @override
  bool shouldRebuild(covariant SmoothSearchHeaderDelegate oldDelegate) {
    return oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.isDark != isDark ||
        oldDelegate.selectionMode != selectionMode ||
        oldDelegate.isSearchActive != isSearchActive;
  }
}
