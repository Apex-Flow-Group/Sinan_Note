// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/models/note.dart';
import 'package:apex_note/widgets/home/date_indicator_bar.dart';
import 'package:apex_note/widgets/home/note_locator_button.dart';
import 'package:flutter/material.dart';

class HomeScreenPopScope extends StatelessWidget {
  final bool canPop;
  final bool showAddMenu;
  final bool isSearchActive;
  final VoidCallback onClearSelection;
  final VoidCallback onCloseMenu;
  final VoidCallback onExitSearch;
  final Widget child;

  const HomeScreenPopScope({
    super.key,
    required this.canPop,
    required this.showAddMenu,
    required this.isSearchActive,
    required this.onClearSelection,
    required this.onCloseMenu,
    required this.onExitSearch,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!canPop) {
          if (showAddMenu) {
            onCloseMenu();
          } else if (isSearchActive) {
            onExitSearch();
          } else {
            onClearSelection();
          }
        }
      },
      child: child,
    );
  }
}

class DateBarHeader extends StatelessWidget {
  final ScrollController scrollController;
  final ValueNotifier<List<Note>> filteredNotesNotifier;
  final ValueNotifier<String?> activeFilterNotifier;
  final ValueNotifier<bool>? isPullingNotifier;
  final ValueNotifier<double>? pullDistanceNotifier;

  const DateBarHeader({
    super.key,
    required this.scrollController,
    required this.filteredNotesNotifier,
    required this.activeFilterNotifier,
    this.isPullingNotifier,
    this.pullDistanceNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      floating: false,
      delegate: _DateBarDelegate(
        height: 40.0,
        child: DateIndicatorBar(
          scrollController: scrollController,
          filteredNotesNotifier: filteredNotesNotifier,
          noteHeights: NoteCardKeyRegistry.instance.heights,
          activeFilterNotifier: activeFilterNotifier,
          isPullingNotifier: isPullingNotifier,
          pullDistanceNotifier: pullDistanceNotifier,
        ),
      ),
    );
  }
}

class _DateBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _DateBarDelegate({required this.height, required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _FadeInBar(height: height, child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_DateBarDelegate oldDelegate) => false;
}

class _FadeInBar extends StatefulWidget {
  final double height;
  final Widget child;
  const _FadeInBar({required this.height, required this.child});

  @override
  State<_FadeInBar> createState() => _FadeInBarState();
}

class _FadeInBarState extends State<_FadeInBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    // تأخير بسيط حتى تنتهي الـ layout ثم fade in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SizedBox(height: widget.height, child: widget.child),
    );
  }
}

