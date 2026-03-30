// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

class SmoothSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final Widget child;
  final bool selectionMode;
  final Widget? selectionBar;
  final bool isSearchActive;

  SmoothSearchHeaderDelegate({
    required this.expandedHeight,
    required this.child,
    this.selectionMode = false,
    this.selectionBar,
    this.isSearchActive = false,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bgColor = Theme.of(context).colorScheme.surface;

    return Material(
      color: bgColor,
      elevation: 0,
      shadowColor: Colors.transparent,
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
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => expandedHeight;

  @override
  bool shouldRebuild(covariant SmoothSearchHeaderDelegate oldDelegate) => true;
}
