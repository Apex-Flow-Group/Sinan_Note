// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class SmoothSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double statusBarHeight;
  final Widget child;
  final bool selectionMode;
  final Widget? selectionBar;
  final bool isSearchActive;

  SmoothSearchHeaderDelegate({
    required this.expandedHeight,
    required this.statusBarHeight,
    required this.child,
    this.selectionMode = false,
    this.selectionBar,
    this.isSearchActive = false,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = isSearchActive
        ? 1.0
        : (1.0 - (shrinkOffset / expandedHeight)).clamp(0.0, 1.0);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(top: statusBarHeight),
        child: ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: expandedHeight,
              child: Opacity(
                opacity: t,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: selectionMode && selectionBar != null
                      ? selectionBar!
                      : child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight + statusBarHeight;

  // عند البحث: مثبت بالكامل — عند التمرير: يتقلص حتى statusBarHeight فقط
  @override
  double get minExtent =>
      isSearchActive ? expandedHeight + statusBarHeight : statusBarHeight;

  @override
  bool shouldRebuild(covariant SmoothSearchHeaderDelegate oldDelegate) {
    return true;
  }
}
