// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/notes/notes_provider.dart';
import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/core/utils/platform_helper.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/main.dart'
    show tabToHomeNotifier, currentTabIndexNotifier;
import 'package:apex_note/models/note_mode.dart';
import 'package:apex_note/screens/desktop/code_tab_responsive.dart';
import 'package:apex_note/screens/desktop/home_screen_responsive.dart';
import 'package:apex_note/screens/desktop/reminder_dashboard_responsive.dart';
import 'package:apex_note/screens/onboarding/splash_screen.dart';
import 'package:apex_note/services/cloud/google_drive_service.dart';
import 'package:apex_note/services/security/security_gate.dart';
import 'package:apex_note/services/unified_notification_service.dart';
import 'package:apex_note/widgets/home/add_menu_widget.dart';
import 'package:apex_note/widgets/navigation/bottom_nav_bar.dart';
import 'package:apex_note/widgets/navigation/side_nav_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _showAddMenu = false;
  void Function(NoteMode)? _onModeSelected;
  final _securityController = SecurityController();
  DateTime? _lastBackPress;

  // ✅ Cache screens to prevent rebuilds
  late final List<Widget> _cachedScreens;

  @override
  void initState() {
    super.initState();
    _securityController.addListener(_onSecurityChanged);
    _autoSyncOnStartup();
    tabToHomeNotifier.addListener(_onBackToHome);

    // ⚠️ قفل الاتجاه للموبايل فقط
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlatformHelper.lockOrientationForMobile(context);
    });

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
        child: HomeScreenResponsive(
          sharedText: widget.sharedText,
          onDrawerChanged: _onDrawerChanged,
          showAddMenu: _showAddMenu,
          onToggleMenu: _toggleMenu,
          onRegisterModeHandler: (handler) => _onModeSelected = handler,
        ),
      ),
      const ReminderDashboardResponsive(),
      const CodeTabResponsive(),
    ];
  }

  /// 🔄 Auto-sync on app startup
  Future<void> _autoSyncOnStartup() async {
    await GoogleDriveService.initializeSignIn();

    final prefs = await SharedPreferences.getInstance();
    final autoSync = prefs.getBool('google_drive_auto_sync') ?? false;

    if (autoSync && GoogleDriveService.isSignedIn) {
      if (!mounted) return;
      await GoogleDriveService.uploadDatabase(context);
    }
  }

  @override
  void dispose() {
    _securityController.removeListener(_onSecurityChanged);
    tabToHomeNotifier.removeListener(_onBackToHome);
    PlatformHelper.unlockOrientation();
    super.dispose();
  }

  void _onBackToHome() {
    if (_currentIndex != 0 && mounted) {
      setState(() => _currentIndex = 0);
    }
  }

  /// 🔒 Security: Lock screen when vault is locked
  void _onSecurityChanged() {
    if (_securityController.isLocked && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SplashScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  /// 📜 Auto-hide navigation on scroll (home screen only)
  void _handleScrollNotification(bool isScrollingDown) {
    if (_currentIndex != 0 || _isDrawerOpen) return;

    final isLargeScreen = PlatformHelper.shouldUseDesktopLayout(context);
    if (isLargeScreen) return; // Don't hide on tablets/desktop

    if (isScrollingDown && !_isScrollHidden) {
      setState(() => _isScrollHidden = true);
    } else if (!isScrollingDown && _isScrollHidden) {
      setState(() => _isScrollHidden = false);
    }
  }

  void _toggleMenu() {
    setState(() => _showAddMenu = !_showAddMenu);
    isMenuOpenNotifier.value = _showAddMenu;
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
    final bool showBottomBar =
        context.select<SettingsProvider, bool>((s) => s.isSetupCompleted) ||
            context.select<NotesProvider, bool>((n) => n.isInitialDataLoaded);
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final isLargeScreen = PlatformHelper.shouldUseDesktopLayout(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // إذا كنا في تبويب غير الرئيسية → ارجع للتبويب الأول
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          currentTabIndexNotifier.value = 0;
          return;
        }
        // نحن في الرئيسية → double-back للخروج
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            UnifiedNotificationService().show(
              context: context,
              message: l10n.pressBackToExit,
              type: NotificationType.info,
              duration: const Duration(seconds: 2),
            );
          }
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
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
                      children: _cachedScreens,
                    ),
                    if (showBottomBar && !isLargeScreen)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: BottomNavBar(
                          currentIndex: _currentIndex,
                          onTap: (index) {
                            if (_showAddMenu) _toggleMenu();
                            setState(() {
                              _currentIndex = index;
                              if (index != 0) _isScrollHidden = false;
                            });
                            currentTabIndexNotifier.value = index;
                          },
                          isScrollHidden: _isScrollHidden,
                          isDrawerOpen: _isDrawerOpen,
                        ),
                      ),
                    if (!isLargeScreen)
                      AddMenuWidget(
                        showMenu: _showAddMenu,
                        onToggle: _toggleMenu,
                        onModeSelected: (mode) {
                          _onModeSelected?.call(mode);
                        },
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
                    currentTabIndexNotifier.value = index;
                  },
                  isScrollHidden: false,
                  isDrawerOpen: _isDrawerOpen,
                  isRTL: isRTL,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
