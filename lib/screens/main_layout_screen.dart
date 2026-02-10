// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/settings/settings_provider.dart';
import '../controllers/notes/notes_provider.dart';
import '../services/security/security_gate.dart';
import '../services/cloud/google_drive_service.dart';
import 'home_screen.dart';
import 'tabs/reminder_dashboard.dart';
import 'tabs/code_tab.dart';
import 'splash_screen.dart';
import '../widgets/home/add_menu_widget.dart' show isMenuOpenNotifier;
import '../widgets/navigation/bottom_nav_bar.dart';
import '../widgets/navigation/side_nav_rail.dart';

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
  final _securityController = SecurityController();
  
  // ✅ Cache screens to prevent rebuilds
  late final List<Widget> _cachedScreens;

  @override
  void initState() {
    super.initState();
    _securityController.addListener(_onSecurityChanged);
    _autoSyncOnStartup();
    
    // ✅ Cache screens to prevent unnecessary rebuilds
    // Each screen is created once and reused
    _cachedScreens = [
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
      const CodeTab(),
    ];
  }

  /// 🔄 Auto-sync on app startup
  Future<void> _autoSyncOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    final autoSync = prefs.getBool('google_drive_auto_sync') ?? false;
    
    if (autoSync && GoogleDriveService.isSignedIn) {
      await GoogleDriveService.uploadDatabase(context);
    }
  }

  @override
  void dispose() {
    _securityController.removeListener(_onSecurityChanged);
    super.dispose();
  }

  /// 🔒 Security: Lock screen when vault is locked
  void _onSecurityChanged() {
    if (_securityController.isLocked && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SplashScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  /// 📜 Auto-hide navigation on scroll (home screen only)
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
    final settings = Provider.of<SettingsProvider>(context);
    final notesProvider = Provider.of<NotesProvider>(context);
    final bool showBottomBar =
        settings.isSetupCompleted || notesProvider.isInitialDataLoaded;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      onDrawerChanged: _onDrawerChanged,
      body: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: Row(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(
                    index: _currentIndex,
                    children: _cachedScreens, // ✅ Use cached screens
                  ),
                  if (showBottomBar && !isLargeScreen)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: BottomNavBar(
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
                        isScrollHidden: _isScrollHidden,
                        isDrawerOpen: _isDrawerOpen,
                      ),
                    ),
                ],
              ),
            ),
            if (showBottomBar && isLargeScreen)
              SideNavRail(
                currentIndex: _currentIndex,
                onDestinationSelected: (index) {
                  if (isMenuOpenNotifier.value) {
                    isMenuOpenNotifier.value = false;
                  }
                  setState(() {
                    _currentIndex = index;
                    if (index != 0) _isScrollHidden = false;
                  });
                },
                isScrollHidden: _isScrollHidden,
                isDrawerOpen: _isDrawerOpen,
                isRTL: isRTL,
              ),
          ],
        ),
      ),
    );
  }
}
