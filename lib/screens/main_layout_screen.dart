// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';
import '../services/notes_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'home_screen.dart';
import 'tabs/reminder_dashboard.dart';
import 'tabs/professional_tab.dart';
import '../widgets/home/add_menu_widget.dart' show isMenuOpenNotifier;

class MainLayoutScreen extends StatefulWidget {
  final String? sharedText;

  const MainLayoutScreen({
    super.key,
    this.sharedText,
  });

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;
  bool _isScrollHidden = false;
  bool _isDrawerOpen = false;

  void _handleScrollNotification(bool isScrollingDown) {
    if (_currentIndex != 0 || _isDrawerOpen) return;
    if (isScrollingDown && !_isScrollHidden) {
      setState(() => _isScrollHidden = true);
    } else if (!isScrollingDown && _isScrollHidden) {
      setState(() => _isScrollHidden = false);
    }
  }

  void _onDrawerChanged(bool isOpen) {
    setState(() {
      _isDrawerOpen = isOpen;
      if (!isOpen) {
        _isScrollHidden = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);
    final notesProvider = Provider.of<NotesProvider>(context);
    final bool showBottomBar =
        settings.isSetupCompleted || notesProvider.isInitialDataLoaded;

    final screens = [
      NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (!_isDrawerOpen) {
            if (notification.direction == ScrollDirection.reverse) {
              _handleScrollNotification(true);
            } else if (notification.direction == ScrollDirection.forward) {
              _handleScrollNotification(false);
            }
          }
          return false;
        },
        child: HomeScreen(
          sharedText: widget.sharedText,
          onDrawerChanged: _onDrawerChanged,
        ),
      ),
      const ReminderDashboard(),
      const ProfessionalTab(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      onDrawerChanged: _onDrawerChanged,
      body: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            if (showBottomBar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                offset: _isDrawerOpen 
                    ? const Offset(0, 1) 
                    : (_isScrollHidden ? const Offset(0, 1) : Offset.zero),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: BottomNavigationBar(
                        currentIndex: _currentIndex,
                        onTap: (index) {
                          if (isMenuOpenNotifier.value) {
                            isMenuOpenNotifier.value = false;
                          }
                          setState(() {
                            _currentIndex = index;
                            if (index != 0) _isScrollHidden = false;
                          });
                        },
                        type: BottomNavigationBarType.fixed,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        selectedItemColor: Theme.of(context).colorScheme.primary,
                        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        selectedFontSize: 12,
                        unselectedFontSize: 11,
                        selectedLabelStyle:
                            const TextStyle(fontWeight: FontWeight.w600),
                        unselectedLabelStyle:
                            const TextStyle(fontWeight: FontWeight.normal),
                        items: [
                          BottomNavigationBarItem(
                            icon: const Icon(Icons.grid_view_rounded),
                            activeIcon:
                                const Icon(Icons.grid_view_rounded, size: 28),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
