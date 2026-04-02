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

  const DateBarHeader({
    super.key,
    required this.scrollController,
    required this.filteredNotesNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _DateBarDelegate(
        height: 40.0,
        child: DateIndicatorBar(
          scrollController: scrollController,
          filteredNotesNotifier: filteredNotesNotifier,
          noteHeights: NoteCardKeyRegistry.instance.heights,
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
    return SizedBox(height: height, child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_DateBarDelegate oldDelegate) => false;
}
