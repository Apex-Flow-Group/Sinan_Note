// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sinan_note/core/theme/app_theme.dart';

class SmoothSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double statusBarHeight;
  final Widget child;
  final bool selectionMode;
  final Widget? selectionBar;
  final bool isSearchActive;
  final TickerProvider tickerProvider;
  final bool hideOnScroll; // إذا false → الشريط ثابت دائماً

  SmoothSearchHeaderDelegate({
    required this.expandedHeight,
    required this.statusBarHeight,
    required this.child,
    required this.tickerProvider,
    this.selectionMode = false,
    this.selectionBar,
    this.isSearchActive = false,
    this.hideOnScroll = true,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final locked = isSearchActive || selectionMode || !hideOnScroll;
    final t =
        locked ? 1.0 : (1.0 - (shrinkOffset / expandedHeight)).clamp(0.0, 1.0);

    return Material(
      color: AppTheme.secondaryBackground(Theme.of(context).colorScheme),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(top: statusBarHeight),
        child: ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: expandedHeight,
              child: AnimatedOpacity(
                opacity: t,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: selectionMode && selectionBar != null
                    ? selectionBar!
                    : child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight + statusBarHeight;

  // عند البحث أو تثبيت الشريط: مثبت بالكامل — عند التمرير: يتقلص حتى statusBarHeight فقط
  @override
  double get minExtent => (isSearchActive || selectionMode || !hideOnScroll)
      ? expandedHeight + statusBarHeight
      : statusBarHeight;

  @override
  TickerProvider get vsync => tickerProvider;

  @override
  FloatingHeaderSnapConfiguration? get snapConfiguration => hideOnScroll
      ? FloatingHeaderSnapConfiguration(
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 200),
        )
      : null;

  @override
  PersistentHeaderShowOnScreenConfiguration get showOnScreenConfiguration =>
      const PersistentHeaderShowOnScreenConfiguration();

  @override
  bool shouldRebuild(covariant SmoothSearchHeaderDelegate oldDelegate) {
    return true;
  }
}

