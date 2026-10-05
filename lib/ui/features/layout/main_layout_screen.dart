// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/domain/models/note_mode.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/ui/core/navigation/app_navigation.dart';
import 'package:sinan_note/ui/core/platform/platform_helper.dart';
import 'package:sinan_note/ui/core/widgets/unified_notification_service.dart';
import 'package:sinan_note/ui/features/auth/pin_lock_screen.dart';
import 'package:sinan_note/ui/features/auth/view_models/app_lock.dart';
import 'package:sinan_note/ui/features/code/code_tab_responsive.dart';
import 'package:sinan_note/ui/features/home/home_screen_responsive.dart';
import 'package:sinan_note/ui/features/home/widgets/add_menu_widget.dart';
import 'package:sinan_note/ui/features/layout/bottom_nav_bar.dart';
import 'package:sinan_note/ui/features/layout/details_panel.dart';
import 'package:sinan_note/ui/features/notes/view_models/notes_provider.dart';
import 'package:sinan_note/ui/features/reminders/reminder_dashboard_responsive.dart';
import 'package:sinan_note/ui/features/settings/view_models/settings_provider.dart';

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
  late final AppLock _lock = context.read<AppLock>();
  late final AppNavigation _nav = context.read<AppNavigation>();
  DateTime? _lastBackPress;

  // ✅ Cache screens to prevent rebuilds
  late final List<Widget> _cachedScreens;
  late final Widget _sharedDetailsPanel;

  @override
  void initState() {
    super.initState();
    _lock.lockState.addListener(_onSecurityChanged);
    _nav.tab.addListener(_onTabIndexChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlatformHelper.lockOrientationForMobile(context);
    });

    // الشاشة لا تُفتح إلا بعد المصادقة: النوايا المنتظرة تُنفَّذ الآن
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _nav.intents.ready = true);

    _sharedDetailsPanel = const DetailsPanel();
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
          sharedDetailsPanel: _sharedDetailsPanel,
        ),
      ),
      const ReminderDashboardResponsive(),
      const CodeTabResponsive(),
    ];
  }

  // _autoSyncOnStartup حُذفت — SplashScreen يتولى المزامنة عند الفتح
  // لتجنب مزامنة مزدوجة متزامنة مع splash_screen

  @override
  void dispose() {
    _lock.lockState.removeListener(_onSecurityChanged);
    _nav.tab.removeListener(_onTabIndexChanged);
    _nav.intents.ready = false;
    PlatformHelper.unlockOrientation();
    super.dispose();
  }

  void _onTabIndexChanged() {
    final newIndex = _nav.tab.value;
    if (newIndex != _currentIndex && mounted) {
      setState(() {
        _currentIndex = newIndex;
        if (newIndex != 0) {
          _isScrollHidden = false;
          _nav.bottomBarHidden.value = false;
        }
      });
    }
  }

  bool _lockScreenVisible = false;

  void _onSecurityChanged() {
    if (!_lock.isLocked || !mounted) return;
    // منع فتح شاشة قفل مكررة
    if (_lockScreenVisible) return;
    _lockScreenVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      Navigator.of(context)
          .push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PinLockScreen(
                isSetup: false,
                isAppLock: true,
                autoBiometric: settings.biometricLockEnabled,
                onSuccess: () {
                  // مارك الجلسة وافتح القفل مباشرة — بدون requestUnlock
                  _lock.markAuthenticated();
                  _lock.forceUnlock();
                  _lockScreenVisible = false;
                  Navigator.of(context).pop();
                },
              ),
              settings: const RouteSettings(name: '/lock'),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          )
          .then((_) => _lockScreenVisible = false);
    });
  }

  void _handleScrollNotification(bool isScrollingDown) {
    if (_currentIndex != 0 || _isDrawerOpen) return;

    final isLargeScreen = PlatformHelper.shouldUseDesktopLayout(context);
    if (isLargeScreen) return;

    // إذا الإعداد معطّل → الشريط ثابت دائماً
    final hideOnScroll =
        Provider.of<SettingsProvider>(context, listen: false).hideNavOnScroll;
    if (!hideOnScroll) return;

    if (isScrollingDown && !_isScrollHidden) {
      setState(() => _isScrollHidden = true);
      _nav.bottomBarHidden.value = true;
    } else if (!isScrollingDown && _isScrollHidden) {
      setState(() => _isScrollHidden = false);
      _nav.bottomBarHidden.value = false;
    }
  }

  void _toggleMenu() {
    setState(() => _showAddMenu = !_showAddMenu);
  }

  void _onDrawerChanged(bool isOpen) {
    setState(() {
      _isDrawerOpen = isOpen;
      if (!isOpen) {
        _isScrollHidden = false;
        _nav.bottomBarHidden.value = false;
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

    final layout = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          _nav.tab.value = 0;
          return;
        }
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            UnifiedNotificationService.of(context).show(
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
                              if (index != 0) {
                                _isScrollHidden = false;
                                _nav.bottomBarHidden.value = false;
                              }
                            });
                            _nav.tab.value = index;
                          },
                          isScrollHidden: _isScrollHidden,
                          isDrawerOpen: _isDrawerOpen,
                        ),
                      ),
                    if (!isLargeScreen && !_isDrawerOpen)
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
            ],
          ),
        ),
      ),
    );
    // القفل عند العودة يُغطي المحتوى في الإطار نفسه، قبل أن تظهر شاشة PIN
    return Stack(
      children: [
        layout,
        Positioned.fill(
          child: ListenableBuilder(
            listenable: _lock.lockState,
            builder: (context, _) => IgnorePointer(
              ignoring: !_lock.isLocked,
              child: _lock.isLocked
                  ? ColoredBox(color: Theme.of(context).colorScheme.surface)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
