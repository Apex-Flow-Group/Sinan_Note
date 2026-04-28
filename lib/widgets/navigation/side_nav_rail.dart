// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:ui';

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SideNavRail extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final bool isScrollHidden;
  final bool isDrawerOpen;
  final bool isRTL;

  const SideNavRail({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.isScrollHidden,
    required this.isDrawerOpen,
    required this.isRTL,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      offset: isDrawerOpen
          ? (isRTL ? const Offset(1, 0) : const Offset(-1, 0))
          : (isScrollHidden
              ? (isRTL ? const Offset(1, 0) : const Offset(-1, 0))
              : Offset.zero),
      child: ClipRRect(
        borderRadius: isRTL
            ? const BorderRadius.horizontal(left: Radius.circular(16))
            : const BorderRadius.horizontal(right: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme.surface
                  .withValues(alpha: 0.85),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              backgroundColor: Colors.transparent,
              selectedIconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              unselectedIconTheme: IconThemeData(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                size: 24,
              ),
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
              unselectedLabelTextStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.grid_view_rounded),
                  selectedIcon: const Icon(Icons.grid_view_rounded),
                  label: Text(l10n.home),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.alarm_rounded),
                  selectedIcon: const Icon(Icons.alarm_rounded),
                  label: Text(l10n.reminders),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.code_rounded),
                  selectedIcon: const Icon(Icons.code_rounded),
                  label:
                      Text(l10n.professional, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
