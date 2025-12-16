// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui';
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
    final double progress = shrinkOffset / expandedHeight;
    final double curvedProgress =
        Curves.easeInOutCubic.transform(progress.clamp(0.0, 1.0));
    final double scale = 1.0 - (curvedProgress * 0.1);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: expandedHeight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    );
                  },
                  child:
                      selectionMode && selectionBar != null ? selectionBar! : child,
                ),
              ),
            ),
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
