// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isScrollHidden;
  final bool isDrawerOpen;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isScrollHidden,
    required this.isDrawerOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = Theme.of(context).colorScheme.surface;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      offset: isDrawerOpen
          ? const Offset(0, 1)
          : (isScrollHidden ? const Offset(0, 1) : Offset.zero),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            selectedFontSize: 12,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.grid_view_rounded),
                activeIcon: const Icon(Icons.grid_view_rounded, size: 28),
                label: l10n.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.alarm_rounded),
                activeIcon: const Icon(Icons.alarm_rounded, size: 28),
                label: l10n.reminders,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.code_rounded),
                activeIcon: const Icon(Icons.code_rounded, size: 28),
                label: l10n.professional,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
